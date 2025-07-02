import 'package:auth/src/bloc/auth_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:navigator_api/home_navigator.dart';

/// Dependencies container for the Auth feature.
class AuthDependencies {
  AuthDependencies({required this.authBloc, required this.homeNavigator});

  /// Provides the dependencies of the Auth feature to the widget tree.
  static AuthDependencies of(BuildContext context) {
    final inherited = context.getInheritedWidgetOfExactType<AuthDependenciesInherited>();

    if (inherited == null) {
      throw FlutterError(
        'AuthDependencies.of() called with a context that does not contain a AuthDependenciesInherited widget.',
      );
    }

    return inherited.dependencies;
  }

  final AuthBloc authBloc;

  final HomeNavigator homeNavigator;
}

class AuthDependenciesInherited extends InheritedWidget {
  const AuthDependenciesInherited({required this.dependencies, required super.child, super.key});

  /// The dependencies of the Auth feature.
  final AuthDependencies dependencies;

  @override
  bool updateShouldNotify(AuthDependenciesInherited oldWidget) {
    // Dependencies are not expected to change, so we return false
    return false;
  }
}
