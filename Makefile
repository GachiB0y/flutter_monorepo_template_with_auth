# Define phony targets to avoid conflicts with files
.PHONY: help get bootstrap gen gen-watch autofix analyze format test clean run build create-feature create-core

# Default help command
help:
	@echo "📚 Available commands:"
	@echo ""
	@{ \
	  printf "%-30s %s\n" "make get" "Get Flutter dependencies"; \
	  printf "%-30s %s\n" "make bootstrap" "Bootstrap project (init after clone)"; \
	  printf "%-30s %s\n" "make gen" "Generate Dart files (build_runner)"; \
	  printf "%-30s %s\n" "make gen-watch" "Watch and generate Dart files"; \
	  printf "%-30s %s\n" "make gen-clean" "Clean and regenerate Dart files"; \
	  echo ""; \
	  printf "%-30s %s\n" "make analyze" "Analyze Dart code"; \
	  printf "%-30s %s\n" "make autofix" "Auto fix Dart code issues"; \
	  printf "%-30s %s\n" "make format" "Format Dart code"; \
	  echo ""; \
	  printf "%-30s %s\n" "make test" "Run all tests"; \
	  printf "%-30s %s\n" "make test-coverage" "Run tests with coverage"; \
	  echo ""; \
	  printf "%-30s %s\n" "make run" "Run the app (debug mode)"; \
	  printf "%-30s %s\n" "make run-release" "Run the app (release mode)"; \
	  printf "%-30s %s\n" "make build-android" "Build Android APK"; \
	  printf "%-30s %s\n" "make build-ios" "Build iOS app"; \
	  echo ""; \
	  printf "%-30s %s\n" "make create-feature NAME=<name>" "Create new feature module"; \
	  printf "%-30s %s\n" "make create-core NAME=<name>" "Create new core module"; \
	  echo ""; \
	  printf "%-30s %s\n" "make clean" "Clean build files"; \
	  printf "%-30s %s\n" "make clean-all" "Deep clean (pub cache, build)"; \
	}

# Task: Get flutter dependencies
get:
	@echo "📦 Getting Flutter dependencies..."
	fvm flutter pub get

# Task: Bootstrap project (after clone)
bootstrap:
	@echo "🚀 Bootstrapping project..."
	@bash scripts/bootstrap.bash

# Task: Generate Dart files
gen:
	@echo "🔨 Running Dart codegen..."
	fvm dart run build_runner build -d

# Task: Watch Dart codegen
gen-watch:
	@echo "👀 Watching Dart codegen..."
	fvm dart run build_runner watch -d

# Task: Clean and regenerate
gen-clean:
	@echo "🧹 Cleaning and regenerating Dart files..."
	fvm dart run build_runner build --delete-conflicting-outputs

# Task: auto fix code dart files
autofix:
	@echo "🔧 Auto fixing Dart code..."
	fvm dart fix --apply

# Task: analyze dart files
analyze:
	@echo "🔍 Analyzing Dart code..."
	fvm flutter analyze

# Task: format dart files
format:
	@echo "✨ Formatting Dart code..."
	@bash scripts/format.bash

# Task: run tests
test:
	@echo "🧪 Running tests..."
	@bash scripts/test.bash

# Task: run tests with coverage
test-coverage:
	@echo "📊 Running tests with coverage..."
	fvm flutter test --coverage
	@echo "Coverage report generated in coverage/lcov.info"

# Task: run app in debug mode
run:
	@echo "🚀 Running app (debug mode)..."
	fvm flutter run

# Task: run app in release mode
run-release:
	@echo "🚀 Running app (release mode)..."
	fvm flutter run --release

# Task: build Android APK
build-android:
	@echo "📱 Building Android APK..."
	fvm flutter build apk --release

# Task: build iOS app
build-ios:
	@echo "📱 Building iOS app..."
	fvm flutter build ios --release

# Task: clean build files
clean:
	@echo "🧹 Cleaning build files..."
	@bash scripts/clean.bash

# Task: deep clean
clean-all: clean
	@echo "🧹 Deep cleaning..."
	fvm flutter pub cache clean
	rm -rf .dart_tool
	rm -rf build
	@echo "✅ Deep clean complete. Run 'make get' to restore dependencies."

# Task: create new feature module
create-feature:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Error: NAME is required"; \
		echo "Usage: make create-feature NAME=<feature_name>"; \
		echo "Example: make create-feature NAME=profile"; \
		exit 1; \
	fi
	@echo "📁 Creating feature: $(NAME)..."
	@bash scripts/create_clean_feature.bash $(NAME)

# Task: create new core module
create-core:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Error: NAME is required"; \
		echo "Usage: make create-core NAME=<module_name>"; \
		echo "Example: make create-core NAME=cache"; \
		exit 1; \
	fi
	@echo "📁 Creating core module: $(NAME)..."
	@bash scripts/create_clean_core_feature.bash $(NAME)

