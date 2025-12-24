import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template_flutter_claude/src/feature/auth/auth.dart';
import 'package:template_flutter_claude/src/feature/settings/settings_api/settings_api.dart';
import 'package:template_flutter_claude/src/navigation/router.dart';
import 'package:template_flutter_claude/src/navigation/routes/pages.dart';
import 'package:template_flutter_claude/src/widget/media_query_override.dart';

/// Entry point for the application that uses [MaterialApp].
class MaterialContext extends StatelessWidget {
  const MaterialContext({required this.controller, super.key});

  /// This global key is needed for Flutter to work properly
  /// when Widgets Inspector is enabled.
  static final _globalKey = GlobalKey(debugLabel: 'MaterialContext');
  final ValueNotifier<List<Page<Object?>>> controller;
  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.settingsOf(context);
    final themeMode = settings.themeConfiguration?.themeMode ?? ThemeModeVO.system;
    final seedColor = settings.themeConfiguration?.seedColor ?? Colors.blue;

    final materialThemeMode = switch (themeMode) {
      ThemeModeVO.system => ThemeMode.system,
      ThemeModeVO.light => ThemeMode.light,
      ThemeModeVO.dark => ThemeMode.dark,
    };

    final darkTheme = ThemeData(colorSchemeSeed: seedColor, brightness: Brightness.dark);
    final lightTheme = ThemeData(colorSchemeSeed: seedColor, brightness: Brightness.light);

    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: materialThemeMode,
      locale: settings.locale,
      home: Builder(
        builder: (context) {
          return KeyedSubtree(
            key: _globalKey,
            child: MediaQueryRootOverride(
              child: BlocBuilder<AuthBloc, AuthState>(
                bloc: AuthScope.dependenciesOf(context).authBloc,
                builder: (context, state) {
                  return state.status == AuthenticationStatus.authenticated
                      ? AppNavigator(
                          home: AppPages.home.page(),
                          controller: controller,
                        )
                      : const LoginScreen();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
