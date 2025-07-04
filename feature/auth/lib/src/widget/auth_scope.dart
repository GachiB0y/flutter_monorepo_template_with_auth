import 'package:auth/src/bloc/auth_bloc.dart';
import 'package:auth/src/dependencies/auth_dependencies.dart';
import 'package:auth/src/logic/auth_interceptor.dart';
import 'package:common/common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Auth controller
abstract interface class AuthController {
  /// Authentication status
  AuthenticationStatus get status;

  /// Sign in with email and password
  void signInWithEmailAndPassword(String email, String password);

  /// Sign out
  void signOut();
}

/// Scope that controls the authentication state
class AuthScope extends StatefulWidget {
  /// Create an [AuthScope]
  const AuthScope({required this.child, super.key});

  /// The child widget
  final Widget child;

  /// Get the [AuthController] from the [BuildContext]
  static AuthController of(BuildContext context, {bool listen = true}) =>
      context.inhOf<_AuthInherited>(listen: listen).controller;

  @override
  State<AuthScope> createState() => _AuthScopeState();
}

class _AuthScopeState extends State<AuthScope> implements AuthController {
  late final AuthBloc _authBloc;
  late AuthState _state;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthDependencies.of(context).authBloc;
    _state = _authBloc.state;
  }

  @override
  AuthenticationStatus get status => _state.status;

  @override
  void signInWithEmailAndPassword(
    String email,
    String password,
  ) => _authBloc.add(
    AuthEvent.signInWithEmailAndPassword(
      email: email,
      password: password,
    ),
  );

  @override
  void signOut() => _authBloc.add(const AuthEvent.signOut());

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    bloc: _authBloc,
    builder: (context, state) {
      _state = state;

      return _AuthInherited(
        controller: this,
        state: _authBloc.state,
        child: widget.child,
      );
    },
  );
}

final class _AuthInherited extends InheritedWidget {
  final AuthController controller;
  final AuthState state;

  const _AuthInherited({
    required super.child,
    required this.controller,
    required this.state,
  });

  @override
  bool updateShouldNotify(covariant _AuthInherited oldWidget) => state != oldWidget.state;
}
