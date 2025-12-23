# Claude Code Instructions для Health Flutter

Этот проект использует Flutter 3.32+ с модульной архитектурой monorepo, BLoC паттерном и базой данных Drift.

## Архитектура проекта

### Структура Monorepo

```
project_root/
├── app/                    # Основное Flutter приложение
├── core/                   # Базовые модули (database, ui_library, analytics, etc.)
└── feature/                # Feature модули (home, auth, settings, etc.)
```

### Принципы модульной архитектуры

- Каждый модуль имеет свой `pubspec.yaml`
- Модули зависят друг от друга через workspace зависимости
- Feature модули следуют Clean Architecture (presentation/domain/data)
- Core модули предоставляют общую функциональность

## Детальные инструкции по категориям

### Обычные правила - папка common

- [SOLID принципы](.claude/common/solid-principles.md) - 5 принципов SOLID на примере во Flutter

### Архитектура - папка architecture

- [BLoC паттерн](.claude/architecture/bloc-pattern.md) - BLoC с миксинами SetStateMixin и BlocController
- [Project Architecture](.claude/architecture/architecture-project.md) - архитектура всего приложения
- [Dependency Injection](.claude/architecture/dependency-injection.md) - DI в приложении

### Flutter зависимые инструкции - папка common-flutter

- [Общие правила для любого Flutter приложения](.claude/common-flutter/flutter-general.md)
- [Навигация](.claude/common-flutter/navigation.md) - Навигация во Flutter приложении
- [Правила пользования FVM](.claude/common-flutter/fvm-usage.md) - TODO правила пользованием версионным менджером флаттер

### Dart зависимые инструкции - папка common-dart

- [Общие правила для Dart](.claude/common-dart/dart-general.md)

### UI и виджеты

- [Создание виджетов](.claude/layers/presentation/ui/widgets.md) - Правила создания и извлечения виджетов
- [Темизация](.claude/layers/presentation/ui/theming.md) - Правила для реализации темы в приложении
- [Как сделать компонент](.claude/layers/presentation/ui/implement-component.md) - Правила для компонента по макету в Figma через MCP
- [Создание локализации](.claude/layers/presentation/ui/localization.md) - Правила создания локализации

### Работа с данными

- [База данных (Drift)](.claude/database/database.md) - БД SQL lite для в Flutter через пакет Drift
- [API клиент](.claude/common-flutter/rest-client.md) - Инструкция как работает API клиент
- [Модели данных](.claude/common-dart/models.md)

### Модульная структура 

- [Создание Core модулей](.claude/modules/core-modules.md)
- [Создание Feature модулей](.claude/modules/feature-modules.md)

### Тестирование

- [Unit тесты](.claude/testing/bloc-testing.md) - инструкиця на Unit тесты
- [Widget тесты](testing/widget-tests.md) - TODO

### Make команды

[Смотреть фаил с инструкицей по мекйфалам](.claude/commands/make_info.md)

## 🔧 Специфика проекта

### BLoC с миксинами

В проекте используется кастомная реализация BLoC с миксинами:

- `SetStateMixin` - для упрощения emit состояний
- `BlocController` - для обработки ошибок и общей логики

### Навигация

Навигация вынесена в отдельный модуль `navigator_api` с интерфейсами для каждого feature.

### UI Library

Все переиспользуемые компоненты находятся в `core/ui_library`.

### Translations

Локализация через `flutter_intl` с поддержкой en/ru.

## Дополнительные ресурсы

- [Flutter Documentation](https://flutter.dev/docs)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [BLoC Library](https://bloclibrary.dev/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

---
