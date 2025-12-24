import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_flutter_claude/src/core/common/common.dart';
import 'package:template_flutter_claude/src/feature/auth/src/data/token_storage.dart';
import 'package:template_flutter_claude/src/feature/auth/src/logic/auth_interceptor.dart';

/// {@template token_storage_sp}
/// Implementation of [TokenStorage] that uses [SharedPreferencesColumn] to store
/// the authorization info.
/// {@endtemplate}
final class TokenStorageSP implements TokenStorage<Token> {
  /// {@macro token_storage_sp}
  TokenStorageSP({required SharedPreferencesAsync sharedPreferences})
      : _accessToken = SharedPreferencesColumnString(
          sharedPreferences: sharedPreferences,
          key: 'authorization.access_token',
        ),
        _refreshToken = SharedPreferencesColumnString(
          sharedPreferences: sharedPreferences,
          key: 'authorization.refresh_token',
        );

  late final SharedPreferencesColumnString _accessToken;
  late final SharedPreferencesColumnString _refreshToken;
  final _streamController = StreamController<Token?>.broadcast();

  @override
  Future<Token?> load() async {
    final accessToken = await _accessToken.read();
    final refreshToken = await _refreshToken.read();

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return Token(accessToken, refreshToken);
  }

  @override
  Future<void> save(Token tokenPair) async {
    await (_accessToken.set(tokenPair.accessToken), _refreshToken.set(tokenPair.refreshToken)).wait;

    _streamController.add(tokenPair);
  }

  @override
  Future<void> clear() async {
    await (_accessToken.remove(), _refreshToken.remove()).wait;

    _streamController.add(null);
  }

  @override
  Stream<Token?> getStream() => _streamController.stream;

  @override
  Future<void> close() => _streamController.close();
}
