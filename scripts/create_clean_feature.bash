#!/bin/bash

set -e

NAME=$1

if [ -z "$NAME" ]; then
  echo "Usage: $0 <feature_name>"
  exit 1
fi

FEATURE_DIR="feature/$NAME"

flutter create --template=package "$FEATURE_DIR"

cd "$FEATURE_DIR"

# Удаляем всё, кроме нужного
find . -mindepth 1 -maxdepth 1 ! -name '.gitignore' ! -name '.metadata' ! -name 'pubspec.yaml' ! -name 'dart_tool' ! -name 'lib' -exec rm -rf {} +

# Создаём структуру папок
mkdir -p lib/src/bloc
mkdir -p lib/src/data
mkdir -p lib/src/domain/repositories
mkdir -p lib/src/domain/models
mkdir -p lib/src/widget
mkdir -p lib/src/dependencies

echo "Фича $NAME создана в feature/$NAME и структура папок добавлена!"