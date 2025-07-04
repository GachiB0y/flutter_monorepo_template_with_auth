import 'package:auth/src/data/auth_data_source.dart';
import 'package:auth/src/data/token_storage.dart';
import 'package:auth/src/logic/auth_interceptor.dart';

/// AuthRepository
abstract interface class AuthRepository<T> implements AuthStatusSource {
  /// Sign in with email and password
  Future<T> signInWithEmailAndPassword(String email, String password);

  /// Sign out
  Future<void> signOut();
}

/// AuthRepositoryImpl
final class AuthRepositoryImpl<T> implements AuthRepository<T> {
  final AuthDataSource<T> _dataSource;
  final TokenStorage<T> _storage;

  /// Create an [AuthRepositoryImpl]
  const AuthRepositoryImpl({
    required AuthDataSource<T> dataSource,
    required TokenStorage<T> storage,
  })  : _dataSource = dataSource,
        _storage = storage;

  @override
  Future<T> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final token = await _dataSource.signInWithEmailAndPassword(email, password);
    await _storage.save(token);

    return token;
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
    await _storage.clear();
  }

  @override
  Stream<AuthenticationStatus> get authStatus => _storage.getStream().map(
        (token) => token != null
            ? AuthenticationStatus.authenticated
            : AuthenticationStatus.unauthenticated,
      );
}
