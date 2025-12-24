import 'package:flutter/material.dart';
import 'package:template_flutter_claude/src/core/ui_library/ui_library.dart';
import 'package:template_flutter_claude/src/logic/composition_root.dart';
import 'package:template_flutter_claude/src/widget/dependencies_scope.dart';
import 'package:template_flutter_claude/src/widget/material_context.dart';

/// [RootContext] is an entry point to the application.
///
/// If a scope doesn't depend on any inherited widget returned by
/// [MaterialApp] or [WidgetsApp], like [Directionality] or [Theme],
/// and it should be available in the whole application, it should be
/// placed here.
class RootContext extends StatelessWidget {
  const RootContext({required this.compositionResult, super.key});

  final CompositionResult compositionResult;

  @override
  Widget build(BuildContext context) {
    return DependenciesScope(
      dependencies: compositionResult.dependencies,
      child: WindowSizeScope(
        child: MaterialContext(
          controller: ValueNotifier<List<Page<Object?>>>([]),
        ),
      ),
    );
  }
}
