import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:template_flutter_claude/src/core/common/common.dart';
import 'package:template_flutter_claude/src/feature/auth/auth.dart' show AuthScope;
import 'package:template_flutter_claude/src/feature/settings/settings_api/src/presentation/widget/settings_scope.dart'
    show SettingsScope;
import 'package:template_flutter_claude/src/model/dependencies_container.dart';

class DependenciesScope extends StatelessWidget {
  const DependenciesScope({required this.dependencies, required this.child, super.key});

  final DependenciesContainer dependencies;
  final Widget child;

  /// Get the dependencies from the [context].
  static DependenciesContainer of(BuildContext context) =>
      context.inhOf<_DependenciesInherited>(listen: false).dependencies;

  @override
  Widget build(BuildContext context) {
    return _DependenciesInherited(
      dependencies: dependencies,
      child: AuthScope(
        dependencies: dependencies.authDependencies,
        child: SettingsScope(
          settingsContainer: dependencies.settingsContainer,
          child: child,
        ),
      ),
    );
  }
}

/// A scope that provides composed [DependenciesContainer].
class _DependenciesInherited extends InheritedWidget {
  const _DependenciesInherited({required super.child, required this.dependencies});

  /// Container with dependencies.
  final DependenciesContainer dependencies;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DependenciesContainer>('dependencies', dependencies));
  }

  @override
  bool updateShouldNotify(_DependenciesInherited oldWidget) {
    return !identical(dependencies, oldWidget.dependencies);
  }
}
