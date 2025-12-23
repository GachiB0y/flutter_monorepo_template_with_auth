#!/bin/bash

set -e

NAME=$1

if [ -z "$NAME" ]; then
  echo "Usage: $0 <core_module_name>"
  echo "Example: $0 logger"
  exit 1
fi

CORE_DIR="core/$NAME"

# Проверяем, существует ли уже такой модуль
if [ -d "$CORE_DIR" ]; then
  echo "Error: Core module '$NAME' already exists in core/$NAME"
  exit 1
fi

echo "Creating core module: $NAME..."

# Создаём пакет через Flutter
flutter create --template=package "$CORE_DIR"

cd "$CORE_DIR"

# Удаляем всё, кроме нужного
find . -mindepth 1 -maxdepth 1 ! -name '.gitignore' ! -name '.metadata' ! -name 'pubspec.yaml' ! -name '.dart_tool' ! -name 'lib' -exec rm -rf {} +

# Создаём структуру папок для Core модуля
mkdir -p lib/src
mkdir -p test


echo "✅ Core модуль '$NAME' создан в core/$NAME"
