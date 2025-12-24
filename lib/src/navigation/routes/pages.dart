// Pages and screens, just for the example

import 'package:flutter/material.dart';
import 'package:template_flutter_claude/src/feature/home/home.dart';

enum AppPages {
  home('home', title: 'Home');

  const AppPages(this.name, {this.title});

  final String name;

  final String? title;

  // Метод для получения страницы с передачей аргументов
  Page<Object?> page({Map<String, String>? arguments}) => MaterialPage<Object?>(
    key: ValueKey<Object>(arguments == null ? this : arguments.values.first),
    child: Builder(
      builder: (context) {
        return builder(context, arguments);
      },
    ),
  );

  // Обновленный метод builder с поддержкой аргументов
  Widget builder(BuildContext context, Map<String, String>? arguments) {
    switch (this) {
      case AppPages.home:
        return const HomeScreen();
    }
  }
}
