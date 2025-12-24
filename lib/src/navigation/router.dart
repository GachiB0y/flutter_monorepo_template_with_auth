import 'dart:collection';

import 'package:flutter/material.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator({required this.home, required this.controller, super.key});

  /// Экран  при пустом стаке страниц
  final Page<Object?> home;

  /// Контроллер для навигации по страницам декаларативно
  final ValueNotifier<List<Page<Object?>>>? controller;

  /// Метод для декларативной навигации по страницам
  static void change(BuildContext context, List<Page<Object?>> Function(List<Page<Object?>>) fn) {
    context.findAncestorStateOfType<_AppNavigatorState>()?.change(fn);
  }

  /// Метод для получения текущих страниц в навигаторе
  /// Например для использования хлебных крошек
  static List<Page<Object?>> pagesOf(BuildContext context) =>
      context.findAncestorStateOfType<_AppNavigatorState>()?._controller.value.toList(
        growable: false,
      ) ??
      <Page<Object?>>[];

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  late ValueNotifier<List<Page<Object?>>> _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? ValueNotifier<List<Page<Object?>>>(<Page<Object?>>[widget.home]);
    if (_controller.value.isEmpty) {
      _controller.value = <Page<Object?>>[widget.home];
    }
    _controller.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant AppNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(_controller, widget.controller)) {
      _controller.removeListener(_onStateChanged);
      _controller =
          widget.controller ?? ValueNotifier<List<Page<Object?>>>(<Page<Object?>>[widget.home]);
      if (_controller.value.isEmpty)
        // ignore: curly_braces_in_flow_control_structures
        _controller.value = <Page<Object?>>[widget.home];
      _controller.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    super.dispose();
  }

  /// Декларативное изменение страниц
  void change(List<Page<Object?>> Function(List<Page<Object?>>) fn) {
    final pages = fn(_controller.value);
    if (identical(pages, _controller.value)) return;

    /// Если состояние ( стек ) страниц не изменилось, то выходим без имзенений
    /// Далее идет проверка на дубликаты и на null ключ
    final set = <LocalKey>{};
    final newPages = <Page<Object?>>[];
    for (var i = pages.length - 1; i >= 0; i--) {
      final page = pages[i];
      final key = page.key;
      if (set.contains(page.key) || key == null) continue;

      /// Если есть дубликат или ключ null, то выходим без имзенений
      set.add(key);

      /// Т.к. это стек, то добавляем в начало
      newPages.insert(0, page);
    }
    if (newPages.isEmpty) newPages.add(widget.home);

    /// Возвращаем иммутабельный список новых страниц
    _controller.value = UnmodifiableListView<Page<Object?>>(newPages);
  }

  @protected
  void _onStateChanged() => setState(() {});

  @protected
  bool _onPopPage(Route<Object?> route, Object? result) {
    if (!route.didPop(result)) return false;
    final pages = _controller.value;
    if (pages.length <= 1) return false;
    // Здесь можно разместить вашу кастомную обработку метода onPopPage
    _controller.value = UnmodifiableListView<Page<Object?>>(pages.sublist(0, pages.length - 1));
    return true;
  }

  @override
  Widget build(BuildContext context) => Navigator(
    pages: _controller.value.toList(growable: false),
    onPopPage: _onPopPage,
  );
}
