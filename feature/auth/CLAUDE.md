# Инструкция по авторизации

### Компоненты

- **AuthBloc**: управляет состоянием авторизации (authenticated/unauthenticated)
- **RegistrationBloc**: управляет процессом регистрации
- **Controllers**: управляют формами (валидация, FocusNode, ValueNotifier)
- **Scopes**: InheritedWidget для DI (AuthScope, RegistrationScope)
- **TokenStorage**: хранит токены в SharedPreferences + Stream<Token?>
- **AuthInterceptor**: автоматически обновляет токены в HTTP запросах

---

## Сценарий 1: Первый запуск (неавторизован)

### Startup

1. **main.dart** → `startup()`
2. **composeDependencies()**:
   - `TokenStorage.load()` → **null** (токенов нет в SharedPreferences)
   - Создаёт `AuthBloc(AuthState.idle(status: unauthenticated))`
   - Создаёт `AuthInterceptor` без токена
3. **RootContext** → `DependenciesScope` → `MaterialContext`
4. **MaterialContext BlocBuilder**:
   - Слушает `AuthBloc.state`
   - `status == unauthenticated` → `homePage = WelcomePage`
5. **AppNavigator** отображает `WelcomeScreen` ✅

### AuthBloc реактивность

```dart
// В конструкторе AuthBloc:
authRepository.authStatus
  .map(($status) => AuthState.idle(status: $status))
  .listen(($state) {
    if ($state != state) setState($state);
  });

// authStatus:
Stream<AuthenticationStatus> get authStatus =>
  tokenStorage.getStream().map(
    (token) => token != null
      ? AuthenticationStatus.authenticated
      : AuthenticationStatus.unauthenticated,
  );
```

---

## Сценарий 2: Логин + Перезапуск

### Логин процесс

1. **LoginScreen**: пользователь вводит email/password
2. **LoginController**:
   - Валидация через `ValidateInputMixin`
   - `Listenable.merge()` автоматически валидирует при изменении полей
   - `ValueNotifier<bool> validNotifier` управляет кнопкой
3. **AuthScope.signInWithEmailAndPassword()**:
   - `authBloc.add(AuthEvent.signInWithEmailAndPassword(...))`
4. **AuthBloc.\_signInWithEmailAndPassword()**:
   - `emit(AuthState.processing)` → UI показывает лоадер
   - `authRepository.signInWithEmailAndPassword()`
5. **AuthRepositoryImpl**:

   ```dart
   // Получаем Firebase token
   final fcmToken = await analyticsService.getDeviceToken(vapidKey);

   // API запрос
   final token = await dataSource.signInWithEmailAndPassword(
     email, password, fcmToken,
   );

   // Сохраняем токен
   await storage.save(token);
   ```

6. **AuthDataSourceNetwork**:
   - POST `/api/authentication/login`
   - Body: `{email, password, rememberMe: true, fcmToken, timezoneOffset}`
   - Response: `{accessToken, refreshToken}`
   - Использует миксин `AuthErrorHandler` для обработки ошибок
7. **TokenStorage.save()**:

   ```dart
   await (
     _accessToken.set(token.accessToken),
     _refreshToken.set(token.refreshToken)
   ).wait;

   _streamController.add(token); // ← Триггерит stream!
   ```

8. **Stream реакция**:
   - `TokenStorage` эмитит новый `Token`
   - `authRepository.authStatus` преобразует в `authenticated`
   - `AuthBloc` обновляет state → `emit(AuthState.idle(authenticated))`
9. **MaterialContext**:
   - `BlocBuilder` получает новый state
   - `status == authenticated` → `homePage = HomePage`
   - `AppNavigator` навигирует на `HomeScreen`

### Перезапуск приложения

1. **composeDependencies()**:
   - `TokenStorage.load()` → **Token** (читает из SharedPreferences)
   - Создаёт `AuthBloc(AuthState.idle(status: authenticated))`
   - Создаёт `AuthInterceptor(token: token)` с существующим токеном
2. **MaterialContext**:
   - `status == authenticated` → `homePage = HomePage`
   - Сразу отображает `HomeScreen`
   - **Никаких API запросов на проверку токена!**

---

## Сценарий 3: Протухшие токены

### AuthInterceptor: двухуровневая защита

#### 1. interceptRequest() - Проактивная проверка

```dart
Future<void> interceptRequest(BaseRequest request, RequestHandler handler) async {
  var token = await _loadToken(); // Из памяти (_token поле)

  if (token == null) {
    return handler.rejectRequest(RevokeTokenException(...));
  }

  // Проверка access token (клиентская, парсит JWT)
  if (await authorizationClient.isAccessTokenValid(token)) {
    request.headers.addAll({'Authorization': 'Bearer ${token.accessToken}'});
    return handler.next(request);
  }

  // Access token протух, проверяем refresh (всегда true)
  if (await authorizationClient.isRefreshTokenValid(token)) {
    try {
      // Обновляем токен через API
      token = await authorizationClient.refresh(token);
      await tokenStorage.save(token);

      request.headers.addAll({'Authorization': 'Bearer ${token.accessToken}'});
      return handler.next(request);

    } on RevokeTokenException {
      // Refresh token отозван → logout
      await tokenStorage.clear();
      rethrow;
    }
  }

  // Оба токена протухли → logout
  await tokenStorage.clear();
  return handler.rejectRequest(RevokeTokenException(...));
}
```

#### 2. interceptResponse() - Реактивная проверка

```dart
Future<void> interceptResponse(StreamedResponse response, ResponseHandler handler) async {
  if (response.statusCode != 401) {
    return handler.resolveResponse(response);
  }

  var token = await _loadToken();
  final tokenFromHeaders = _extractTokenFromHeaders(response.request?.headers);

  // Если токен в headers совпадает с текущим → refresh
  if (tokenFromHeaders == token.accessToken) {
    try {
      token = await authorizationClient.refresh(token);
      await tokenStorage.save(token);
    } on RevokeTokenException {
      await tokenStorage.clear();
      return handler.rejectResponse(...);
    }
  }

  // Токен уже обновлен другим запросом → retry
  final newResponse = await retryRequest(response, retryClient);
  return handler.resolveResponse(newResponse);
}
```

### JWTAuthorizationClient

```dart
// Клиентская проверка JWT (без API запроса)
@override
bool isAccessTokenValid(Token token) {
  final jwt = JWT.decode(token.accessToken);
  if (jwt.payload case {'exp': final int exp}) {
    return DateTime.now().isBefore(
      DateTime.fromMillisecondsSinceEpoch(exp * 1000),
    );
  }
  return false;
}

// Всегда true (серверная проверка при refresh)
@override
bool isRefreshTokenValid(Token token) => true;

// API запрос на обновление токенов
@override
Future<Token> refresh(Token token) async {
  final fcmToken = await analyticsService.getDeviceToken(null);
  final response = await client.post(
    Uri.parse('$baseUrl/api/authentication/refresh-token'),
    headers: {
      'Authorization': 'Bearer ${token.accessToken}',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'refreshToken': token.refreshToken,
      'firebaseRegistrationToken': fcmToken ?? '',
    }),
  );

  final json = jsonDecode(response.body);
  if (json case {'accessToken': String a, 'refreshToken': String r}) {
    return Token(a, r);
  }

  throw RevokeTokenException('Invalid token');
}
```

### Автоматический logout

1. **API возвращает 401/403** при `refresh()`
2. **JWTAuthorizationClient** → `throw RevokeTokenException`
3. **AuthInterceptor** → `tokenStorage.clear()`
4. **TokenStorage.clear()**:
   ```dart
   await (_accessToken.remove(), _refreshToken.remove()).wait;
   _streamController.add(null); // ← Эмитит null
   ```
5. **Stream реакция**:
   - `authRepository.authStatus` → `unauthenticated`
   - `AuthBloc` → `emit(AuthState.idle(unauthenticated))`
6. **MaterialContext**:
   - `homePage = WelcomePage`
   - Редирект на `WelcomeScreen` ✅

---

## 🎯 Ключевые особенности

### 1. Реактивность через Stream

```dart
TokenStorage Stream → AuthRepository authStatus → AuthBloc state → MaterialContext BlocBuilder
```

- Единый источник истины: `TokenStorage`
- Все изменения автоматически распространяются через stream
- UI реагирует на изменения через `BlocBuilder`

### 2. Двухуровневая валидация токенов

- **Клиентская**: парсинг JWT, проверка `exp` field
- **Серверная**: API запрос `/refresh-token`

### 3. Race Condition Protection

```dart
// В interceptResponse:
if (tokenFromHeaders == token.accessToken) {
  // Токен не обновлялся → делаем refresh
} else {
  // Токен уже обновлен другим запросом → просто retry
}
```

### 4. Разделение ответственности

- **BLoC**: асинхронные операции (API calls)
- **Controller**: UI логика форм (валидация, фокус)
- **Scope**: DI через InheritedWidget
- **Interceptor**: автоматическое управление токенами

---

## 📊 Модели данных

### Universal Entity

```dart
// EmailVerifyModel - используется на всех слоях
class EmailVerifyModel {
  final String sessionId;
  final int resendLockLifetime; // В секундах

  // fromMap/toMap, fromJson/toJson, copyWith
}
```

### Form Data

```dart
// RegistrationData - с валидацией
class RegistrationData with ValidateInputMixin {
  final String? name, email, password, confirmPassword, confirmationId;
  final Country? country;

  // Методы валидации
  ValidationErrorKey? validateName() => validateNameKey(name);
  ValidationErrorKey? validateEmail() => validateEmailKey(email);

  // toJson, copyWith
}
```

### Value Object

```dart
// Token - для пары токенов
class Token {
  final String accessToken;
  final String refreshToken;
}
```

### DTO

```dart
// EmailVerifyDto - только для API
class EmailVerifyDto {
  final String sessionId;
  final String resendLockLifetime; // "HH:MM:SS" из API

  // fromMap/toMap, fromJson/toJson
}
```

### Mapper

```dart
class EmailVerifyMapper {
  EmailVerifyModel emailVerifyDtoToEntity(EmailVerifyDto dto) =>
    EmailVerifyModel(
      sessionId: dto.sessionId,
      resendLockLifetime: _parseTime(dto.resendLockLifetime), // String → int
    );
}
```

---

## 🔄 Email Verification (4 потока)

### 1. Регистрация (неавторизован)

- `RegistrationEmailVerification` (http.Client без интерцептора)
- POST `/api/registration/email/begin-confirm`
- POST `/api/registration/email/complete-confirm`

### 2. Забыл пароль (неавторизован)

- `AuthForgotPasswordEmailVerification` (http.Client без интерцептора)
- POST `/api/authentication/reset-password/email/begin-confirm`
- POST `/api/authentication/reset-password/email/complete-confirm`

### 3. Смена пароля в профиле (авторизован)

- `ForgotPasswordUserProfileEmailVerification` (RestClientBase + AuthInterceptor)
- POST `/api/profile/change-password/begin-confirm`
- POST `/api/profile/change-password/complete-confirm`

### 4. Смена email в профиле (авторизован)

- `ChangeEmailUserProfileEmailVerification` (RestClientBase + AuthInterceptor)
- POST `/api/profile/change-email/begin-confirm`
- POST `/api/profile/change-email/complete-confirm`

---

## 🛠️ Регистрация (пример многошагового процесса)

1. **RegistrationScreen**: 2 шага с `ProgressStepper`
2. **RegistrationController**:
   - `_step1ValidNotifier` (имя, страна)
   - `_step2ValidNotifier` (email, пароли)
   - Валидация через `ValidateInputMixin`
3. **RegistrationScope**:
   - `RegistrationBloc` (управляет данными)
   - `EmailVerifyBloc` (верификация email)
   - `RegistrationController` (форма)
   - `EmailVerificationController` (таймер повторной отправки)
4. **Flow**:
   - Шаг 1 → Шаг 2 → Email verification → Confirm code → Registration
   - `RegistrationScope.registration()` → API `/api/registration/perform`
   - Возвращает Token → автоматический login через `TokenStorage.save()`

---

## ✅ Чеклист для новых фич

- [ ] Используй `BLoC` для асинхронных операций
- [ ] Используй `Controller` (ChangeNotifier) для форм
- [ ] Используй `Scope` (InheritedWidget) для DI
- [ ] Universal Entity для моделей на всех слоях
- [ ] Form Data для форм с валидацией
- [ ] DTO только для API (с маппером → Entity)
- [ ] Repository Interface в domain/
- [ ] Repository Implementation в data/
- [ ] Обрабатывай ошибки через миксины (AuthErrorHandler)
- [ ] Используй sealed classes для Events/States
