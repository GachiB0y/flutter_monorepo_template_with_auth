# Define phony targets to avoid conflicts with files
.PHONY: fvm flutter-get dart-gen dart-gen-watch template-dev-init tmpl-git-config

# Default help command
help:
	@echo "Available commands:"
	@{ \
	  printf "%-25s %s\n" "make get" "Get Flutter dependencies"; \
		printf "%-25s %s\n" "make bootstrap" "Bootstrap Project"; \
	  printf "%-25s %s\n" "make gen" "Generate Dart files"; \
	  printf "%-25s %s\n" "make gen-watch" "Watch and generate Dart files"; \
	  printf "%-25s %s\n" "make create-feature NAME=<name>" "Create new feature module"; \
	  printf "%-25s %s\n" "make create-core NAME=<name>" "Create new core module"; \
	}

# Task: Get flutter dependencies
get:
	@echo "Getting Flutter dependencies..."
	fvm flutter pub get

# Task: Bootstrap Project
bootstrap:
	bash scripts/bootstrap.bash

# Task: Generate Dart files
gen:
	@echo "Running Dart codegen..."
	fvm dart run build_runner build -d

# Task: Watch Dart codegen
gen-watch:
	@echo "Watching Dart codegen..."
	fvm dart run build_runner watch -d

#Task: auto fix code dart files
autofix:
	@echo "Auto fixing Dart code..."
	fvm dart fix --apply $(SCOPE)

# Task: analyze dart files
analyze:
	@echo "Analyzing Dart code..."
	fvm dart analyze $(SCOPE)

# Task: create new clean feature
create-feature:
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required"; \
		echo "Usage: make create-feature NAME=<feature_name>"; \
		exit 1; \
	fi
	@echo "Creating feature: $(NAME)..."
	@bash scripts/create_clean_feature.bash $(NAME)

# Task: create new core module
create-core:
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required"; \
		echo "Usage: make create-core NAME=<module_name>"; \
		exit 1; \
	fi
	@echo "Creating core module: $(NAME)..."
	@bash scripts/create_clean_core_feature.bash $(NAME)

