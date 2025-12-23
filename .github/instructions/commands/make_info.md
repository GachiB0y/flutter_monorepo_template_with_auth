### Make команды

```bash
# Основные команды
make bootstrap   # Установить зависимости
make get         # Получить Flutter зависимости
make gen         # Запустить build_runner (codegen)
make gen-watch   # Запустить build_runner в режиме watch
make format      # Форматирование кода
make test        # Запустить тесты

# Анализ и автофикс
make analyze                      # Анализ всего кода
make analyze SCOPE={path}         # Анализ конкретного файла/папки
make autofix                      # Автофикс warnings во всём проекте
make autofix SCOPE={path}         # Автофикс warnings в конкретном файле/папке

# Создание модулей
make create-core NAME=my_module      # Создать новый Core модуль
make create-feature NAME=my_feature  # Создать новый Feature модуль
```

**Примеры использования:**

```bash
# Создание модулей
make create-core NAME=logger
make create-core NAME=notification_service
make create-feature NAME=user_profile
make create-feature NAME=settings

# Анализ и фикс
make autofix SCOPE=feature/user_profile
make analyze SCOPE=core/logger/lib/src/app_logger.dart
```
