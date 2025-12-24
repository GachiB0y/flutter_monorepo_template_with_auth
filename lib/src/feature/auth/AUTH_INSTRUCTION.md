# Инструкция по авторизации

### Компоненты

- **AuthBloc**: управляет состоянием авторизации (authenticated/unauthenticated)
- **RegistrationBloc**: управляет процессом регистрации
- **AuthController**: интерфейс для управления авторизацией (signIn, signOut, status)
- **Controllers**: управляют формами (валидация, FocusNode, ValueNotifier)
- **Scopes**: InheritedWidget для DI
  - **DependenciesScope**: корневой контейнер зависимостей
  - **AuthScope**: предоставляет AuthController и AuthDependencies
  - **RegistrationScope**: управляет зависимостями регистрации
- **TokenStorage**: хранит токены в SharedPreferences + Stream<Token?>
- **AuthInterceptor**: автоматически обновляет токены в HTTP запросах

> **Примечание**: `AuthDependencies`, `AuthController`, `AuthScope` и `_AuthInherited` находятся в одном файле `lib/src/feature/auth/src/dependencies/auth_dependencies.dart` для упрощения управления DI.

---

## Сценарий 1: Первый запуск (неавторизован)

### Startup

1. **main.dart** → `startup()`
2. **composeDependencies()**:
   - `TokenStorage.load()` → **null** (токенов нет в SharedPreferences)
   - Создаёт `AuthBloc(AuthState.idle(status: unauthenticated))`
   - Создаёт `AuthInterceptor` без токена
3. **Иерархия виджетов DI**:
   - `DependenciesScope` (корневой контейнер зависимостей)
   - `AuthScope` (предоставляет AuthController и AuthDependencies)
   - `SettingsScope` (управляет настройками приложения)
   - `MaterialContext` (обёртка MaterialApp с BlocBuilder)
4. **MaterialContext BlocBuilder**:
   - Слушает `AuthBloc.state` через `home` (не `builder`)
   - `status == unauthenticated` → рендерит `LoginScreen`
   - `status == authenticated` → рендерит `AppNavigator`
5. **Результат**: отображает `LoginScreen` ✅

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

### AuthScope и AuthController

```dart
// lib/src/feature/auth/src/dependencies/auth_dependencies.dart

/// Интерфейс для управления авторизацией
abstract interface class AuthController {
  AuthenticationStatus get status;
  void signInWithEmailAndPassword(String email, String password);
  void signOut();
}

/// Scope предоставляет AuthController через InheritedWidget
class AuthScope extends StatefulWidget {
  const AuthScope({
    required this.dependencies,
    required this.child,
    super.key,
  });

  final AuthDependencies dependencies;
  final Widget child;

  /// Получить AuthController из контекста
  static AuthController of(BuildContext context, {bool listen = true}) =>
      context.inhOf<_AuthInherited>(listen: listen).controller;

  /// Получить AuthDependencies из контекста
  static AuthDependencies dependenciesOf(BuildContext context) =>
      context.inhOf<_AuthInherited>(listen: false).dependencies;

  @override
  State<AuthScope> createState() => _AuthScopeState();
}

class _AuthScopeState extends State<AuthScope> implements AuthController {
  late final AuthBloc _authBloc;
  late AuthState _state;

  @override
  void initState() {
    super.initState();
    _authBloc = widget.dependencies.authBloc;
    _state = _authBloc.state;
  }

  @override
  AuthenticationStatus get status => _state.status;

  @override
  void signInWithEmailAndPassword(String email, String password) =>
      _authBloc.add(AuthEvent.signInWithEmailAndPassword(
        email: email,
        password: password,
      ));

  @override
  void signOut() => _authBloc.add(const AuthEvent.signOut());

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
        bloc: _authBloc,
        builder: (context, state) {
          _state = state;
          return _AuthInherited(
            controller: this,
            dependencies: widget.dependencies,
            state: state,
            child: widget.child,
          );
        },
      );
}

final class _AuthInherited extends InheritedWidget {
  const _AuthInherited({
    required super.child,
    required this.controller,
    required this.dependencies,
    required this.state,
  });

  final AuthController controller;
  final AuthDependencies dependencies;
  final AuthState state;

  @override
  bool updateShouldNotify(covariant _AuthInherited oldWidget) =>
      state != oldWidget.state;
}
```

### Использование в UI

```dart
// В LoginScreen или любом виджете внутри AuthScope
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Получаем AuthController из контекста
    final authController = AuthScope.of(context);
    
    return ElevatedButton(
      onPressed: () {
        // Вызываем метод авторизации
        authController.signInWithEmailAndPassword(
          'user@example.com',
          'password123',
        );
      },
      child: Text('Sign In'),
    );
  }
}
```

---

## Сценарий 2: Логин + Перезапуск

### Логин процесс

1. **LoginScreen**: пользователь вводит email/password
2. **LoginController**:
   - Валидация через `ValidateInputMixin`
   - `Listenable.merge()` автоматически валидирует при изменении полей
   - `ValueNotifier<bool> validNotifier` управляет кнопкой
3. **Вызов авторизации**:
   - `LoginController` получает `AuthController` через `AuthScope.of(context)`
   - Вызывает `authController.signInWithEmailAndPassword(email, password)`
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
   - `BlocBuilder` получает новый state через `home`
   - `status == authenticated` → рендерит `AppNavigator`
   - Навигирует на домашний экран приложения

### Перезапуск приложения

1. **composeDependencies()**:
   - `TokenStorage.load()` → **Token** (читает из SharedPreferences)
   - Создаёт `AuthBloc(AuthState.idle(status: authenticated))`
   - Создаёт `AuthInterceptor(token: token)` с существующим токеном
2. **MaterialContext**:
   - `status == authenticated` → рендерит `AppNavigator`
   - Сразу отображает домашний экран
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
   - `BlocBuilder` в `home` получает новый state
   - `status == unauthenticated` → рендерит `LoginScreen`
   - Редирект на экран авторизации ✅

---

## 🎯 Ключевые особенности

### 1. Реактивность через Stream

```dart
TokenStorage Stream → AuthRepository authStatus → AuthBloc state → MaterialContext BlocBuilder (home)
```

- Единый источник истины: `TokenStorage`
- Все изменения автоматически распространяются через stream
- UI реагирует на изменения через `BlocBuilder` в `MaterialContext.home`

### 2. Иерархия Dependency Injection

```
main.dart
  └─ startup()
      └─ DependenciesScope (корневой контейнер)
          └─ AuthScope (AuthController + AuthDependencies)
              └─ SettingsScope (настройки приложения)
                  └─ MaterialContext
                      └─ MaterialApp
                          └─ home: BlocBuilder<AuthBloc, AuthState>
                              ├─ unauthenticated → LoginScreen
                              └─ authenticated → AppNavigator
```

**Получение зависимостей:**
- `AuthScope.of(context)` → `AuthController` (signIn, signOut, status)
- `AuthScope.dependenciesOf(context)` → `AuthDependencies` (authBloc, homeNavigator)
- `DependenciesScope.of(context)` → глобальные зависимости

### 3. Двухуровневая валидация токенов

- **Клиентская**: парсинг JWT, проверка `exp` field
- **Серверная**: API запрос `/refresh-token`

### 4. Race Condition Protection

```dart
// В interceptResponse:
if (tokenFromHeaders == token.accessToken) {
  // Токен не обновлялся → делаем refresh
} else {
  // Токен уже обновлен другим запросом → просто retry
}
```

### 5. Разделение ответственности

- **BLoC**: асинхронные операции (API calls), управление состоянием
- **Controller** (ChangeNotifier): UI логика форм (валидация, фокус)
- **AuthController** (интерфейс): API для управления авторизацией
- **Scope** (InheritedWidget): DI через контекст
- **Interceptor**: автоматическое управление токенами в HTTP-запросах

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
   - `RegistrationBloc` (управляет данными регистрации)
   - `EmailVerifyBloc` (верификация email)
   - `RegistrationController` (управление формой)
   - `EmailVerificationController` (таймер повторной отправки)
4. **Flow**:
   - Шаг 1 → Шаг 2 → Email verification → Confirm code → Registration
   - Получение контроллера: `RegistrationScope.of(context).registration(data)`
   - API `/api/registration/perform`
   - Возвращает Token → автоматический login через `TokenStorage.save()`

**Получение зависимостей в RegistrationScope:**
```dart
// Получить RegistrationController
final controller = RegistrationScope.of(context);

// Вызвать регистрацию
await controller.registration(registrationData);
```

---

## ✅ Чеклист для новых фич

### Архитектура

- [ ] Используй `BLoC` для асинхронных операций и управления состоянием
- [ ] Используй `Controller` (ChangeNotifier) для UI логики форм
- [ ] Используй `Scope` (InheritedWidget) для DI
- [ ] Получай зависимости через `Scope.of(context)` или `Scope.dependenciesOf(context)`

### Модели данных

- [ ] Universal Entity для моделей на всех слоях (domain, data, presentation)
- [ ] Form Data для форм с валидацией (используй `ValidateInputMixin`)
- [ ] DTO только для API (с маппером → Entity)
- [ ] Value Object для простых типов (Token, Email, etc.)

### Слои и зависимости

- [ ] Repository Interface в `domain/`
- [ ] Repository Implementation в `data/`
- [ ] Обрабатывай ошибки через миксины (`AuthErrorHandler`)
- [ ] Используй sealed classes для Events/States в BLoC

### Imports

- [ ] Используй package-style импорты: `package:template_flutter_claude/src/...`
- [ ] Избегай относительных импортов (`../`, `./`)
- [ ] Группируй импорты: dart → flutter → packages → project

### Dependency Injection

- [ ] Зависимости создаются в `composeDependencies()`
- [ ] Передаются через Scope виджеты
- [ ] Структура файла: Dependencies class + Controller interface + Scope widget + _Inherited widget
- [ ] Пример: `lib/src/feature/auth/src/dependencies/auth_dependencies.dart`

### Практические примеры

**Получение AuthController в UI:**
```dart
// В любом виджете внутри AuthScope
final authController = AuthScope.of(context);
authController.signInWithEmailAndPassword(email, password);

// Без подписки на изменения
final authController = AuthScope.of(context, listen: false);
authController.signOut();
```

**Получение зависимостей:**
```dart
// AuthDependencies (содержит authBloc, homeNavigator)
final deps = AuthScope.dependenciesOf(context);
final bloc = deps.authBloc;

// Глобальные зависимости
final globalDeps = DependenciesScope.of(context);
```

**Создание нового Scope:**
```dart
// 1. Создай класс зависимостей
class FeatureDependencies {
  final FeatureBloc bloc;
  final FeatureRepository repository;
}

// 2. Создай интерфейс контроллера
abstract interface class FeatureController {
  void doSomething();
}

// 3. Создай Scope widget
class FeatureScope extends StatefulWidget {
  static FeatureController of(BuildContext context) =>
    context.inhOf<_FeatureInherited>().controller;
  
  static FeatureDependencies dependenciesOf(BuildContext context) =>
    context.inhOf<_FeatureInherited>().dependencies;
}

// 4. Создай State с реализацией контроллера
class _FeatureScopeState extends State<FeatureScope> 
    implements FeatureController {
  // Реализация методов контроллера
}

// 5. Создай _Inherited widget
class _FeatureInherited extends InheritedWidget {
  final FeatureController controller;
  final FeatureDependencies dependencies;
}
```
