import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template_flutter_claude/src/core/common/common.dart';
import 'package:template_flutter_claude/src/core/navigator_api/home_navigator.dart';
import 'package:template_flutter_claude/src/feature/auth/src/bloc/auth_bloc.dart';
import 'package:template_flutter_claude/src/feature/auth/src/logic/auth_interceptor.dart';

/// Dependencies container for the Auth feature.
class AuthDependencies {
  AuthDependencies({required this.authBloc, required this.homeNavigator});

  final AuthBloc authBloc;
  final HomeNavigator homeNavigator;
}

/// Auth controller interface
abstract interface class AuthController {
  /// Authentication status
  AuthenticationStatus get status;

  /// Sign in with email and password
  void signInWithEmailAndPassword(String email, String password);

  /// Sign out
  void signOut();
}

/// Scope that controls the authentication state and provides AuthDependencies
class AuthScope extends StatefulWidget {
  /// Create an [AuthScope]
  const AuthScope({
    required this.dependencies,
    required this.child,
    super.key,
  });

  /// Auth dependencies
  final AuthDependencies dependencies;

  /// The child widget
  final Widget child;

  /// Get the [AuthController] from the [BuildContext]
  static AuthController of(BuildContext context, {bool listen = true}) =>
      context.inhOf<_AuthInherited>(listen: listen).controller;

  /// Get the [AuthDependencies] from the [BuildContext]
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
  void signInWithEmailAndPassword(
    String email,
    String password,
  ) =>
      _authBloc.add(
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
            dependencies: widget.dependencies,
            state: _authBloc.state,
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
  bool updateShouldNotify(covariant _AuthInherited oldWidget) => state != oldWidget.state;
}
