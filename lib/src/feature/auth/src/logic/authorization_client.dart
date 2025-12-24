import 'dart:async';
import 'dart:convert';

// ignore: library_prefixes
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart';
import 'package:template_flutter_claude/src/feature/auth/src/data/authorization_client.dart';
import 'package:template_flutter_claude/src/feature/auth/src/logic/auth_interceptor.dart';

/// Example client that can be used for JWT tokens
///
/// It is not used in this guide, but serves as an example.
final class JWTAuthorizationClient implements AuthorizationClient<Token> {
  final Client _client;
  final String _baseUrl;

  /// {@macro authorization_client}
  JWTAuthorizationClient(this._client, {required String baseUrl}) : _baseUrl = baseUrl;

  @override
  FutureOr<bool> isRefreshTokenValid(Token token) {
    final jwt = JWT.decode(token.refreshToken);

    // Check if JWT token is expired
    if (jwt.payload case {'exp': final int exp}) {
      return DateTime.now().isBefore(
        DateTime.fromMillisecondsSinceEpoch(exp),
      );
    }

    return false;
  }

  @override
  FutureOr<bool> isAccessTokenValid(Token token) {
    final jwt = JWT.decode(token.accessToken);

    // Check if JWT token is expired
    if (jwt.payload case {'exp': final int exp}) {
      return DateTime.now().isBefore(
        DateTime.fromMillisecondsSinceEpoch(exp),
      );
    }

    return false;
  }

  @override
  Future<Token> refresh(Token token) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/refresh'),
      headers: {
        'Authorization': 'Bearer ${token.accessToken}',
      },
    );

    final json = jsonDecode(response.body);

    if (json
        case {
          'access_token': final String aToken,
          'refresh_token': final String rToken,
        }) {
      return Token(aToken, rToken);
    }

    throw const RevokeTokenException('Invalid token');
  }
}

// /// Dummy [AuthorizationClient] that always returns true
// class DummyAuthorizationClient implements AuthorizationClient<Token> {
//   final RestClientBase _client;

//   /// {@macro authorization_client}
//   DummyAuthorizationClient(this._client);

//   @override
//   FutureOr<bool> isRefreshTokenValid(Token token) => !ShowcaseHelper().expireRefresh;

//   @override
//   FutureOr<bool> isAccessTokenValid(Token token) => !ShowcaseHelper().expireAccess;

//   @override
//   Future<Token> refresh(Token token) async {
//     final response = await _client.post(
//       '/refresh',
//       body: {},
//       headers: {
//         'Authorization': 'Bearer ${token.accessToken}',
//       },
//     );

//     // final json = jsonDecode(response.body);

//     if (json case {
//       'access_token': final String aToken,
//       'refresh_token': final String rToken,
//     }) {
//       return Token(aToken, rToken);
//     }

//     throw const RevokeTokenException('Invalid token');
//   }
// }
