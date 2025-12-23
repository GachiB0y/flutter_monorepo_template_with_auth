#!/bin/bash

set -e

NAME=$1

if [ -z "$NAME" ]; then
  echo "❌ Error: Feature name is required"
  echo "Usage: $0 <feature_name>"
  echo "Example: $0 profile"
  exit 1
fi

# Paths for single package architecture
FEATURE_DIR="lib/src/feature/$NAME"
TEST_DIR="test/src/feature/$NAME"

# Check if feature already exists
if [ -d "$FEATURE_DIR" ]; then
  echo "❌ Error: Feature '$NAME' already exists at $FEATURE_DIR"
  exit 1
fi

echo "📁 Creating feature module: $NAME"

# Create feature structure
mkdir -p "$FEATURE_DIR/presentation/bloc"
mkdir -p "$FEATURE_DIR/presentation/widget/components"
mkdir -p "$FEATURE_DIR/domain/models"
mkdir -p "$FEATURE_DIR/domain/repositories"
mkdir -p "$FEATURE_DIR/data/models"
mkdir -p "$FEATURE_DIR/data/repositories"
mkdir -p "$FEATURE_DIR/data/datasources"
mkdir -p "$FEATURE_DIR/dependencies"

# Create test structure
mkdir -p "$TEST_DIR/presentation/bloc"
mkdir -p "$TEST_DIR/domain"
mkdir -p "$TEST_DIR/data/repositories"
mkdir -p "$TEST_DIR/data/datasources"

# Create placeholder files
cat > "$FEATURE_DIR/presentation/bloc/${NAME}_bloc.dart" << 'EOF'
import 'package:flutter_bloc/flutter_bloc.dart';

part '${NAME}_event.dart';
part '${NAME}_state.dart';

class ${NAME^}Bloc extends Bloc<${NAME^}Event, ${NAME^}State> {
  ${NAME^}Bloc() : super(const ${NAME^}State.idle()) {
    on<${NAME^}EventLoad>(_onLoad);
  }

  Future<void> _onLoad(
    ${NAME^}EventLoad event,
    Emitter<${NAME^}State> emit,
  ) async {
    emit(const ${NAME^}State.loading());
    
    try {
      // TODO: Implement load logic
      emit(const ${NAME^}State.success());
    } catch (e, st) {
      emit(${NAME^}State.error(error: e, stackTrace: st));
    }
  }
}
EOF

# Replace ${NAME^} with capitalized name
sed -i '' "s/\${NAME^}/$(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')/g" "$FEATURE_DIR/presentation/bloc/${NAME}_bloc.dart"
sed -i '' "s/\${NAME}/$NAME/g" "$FEATURE_DIR/presentation/bloc/${NAME}_bloc.dart"

cat > "$FEATURE_DIR/presentation/bloc/${NAME}_event.dart" << EOF
part of '${NAME}_bloc.dart';

sealed class $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Event {
  const $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Event();
}

final class $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')EventLoad extends $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Event {
  const $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')EventLoad();
}
EOF

cat > "$FEATURE_DIR/presentation/bloc/${NAME}_state.dart" << EOF
part of '${NAME}_bloc.dart';

sealed class $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State {
  const $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State();
  
  const factory $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State.idle() = _Idle;
  const factory $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State.loading() = _Loading;
  const factory $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State.success() = _Success;
  const factory $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _Error;
}

final class _Idle extends $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State {
  const _Idle();
}

final class _Loading extends $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State {
  const _Loading();
}

final class _Success extends $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State {
  const _Success();
}

final class _Error extends $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State {
  const _Error({required this.error, required this.stackTrace});
  
  final Object error;
  final StackTrace stackTrace;
}
EOF

cat > "$FEATURE_DIR/presentation/widget/${NAME}_screen.dart" << EOF
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template_flutter_claude/src/feature/$NAME/presentation/bloc/${NAME}_bloc.dart';

class $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Screen extends StatelessWidget {
  const $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$NAME'),
      ),
      body: BlocBuilder<$(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Bloc, $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')State>(
        builder: (context, state) {
          return switch (state) {
            _Idle() => const Center(child: Text('Ready')),
            _Loading() => const Center(child: CircularProgressIndicator()),
            _Success() => const Center(child: Text('Success!')),
            _Error(:final error) => Center(child: Text('Error: \$error')),
          };
        },
      ),
    );
  }
}
EOF

# Create README
cat > "$FEATURE_DIR/README.md" << EOF
# $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}') Feature

## Structure

\`\`\`
$NAME/
├── presentation/        # UI + BLoC
│   ├── bloc/
│   └── widget/
├── domain/              # Business logic
│   ├── models/
│   └── repositories/
├── data/                # Data sources
│   ├── models/
│   ├── repositories/
│   └── datasources/
└── dependencies/        # DI
\`\`\`

## Next Steps

1. [ ] Implement domain models
2. [ ] Create repository interfaces
3. [ ] Implement data sources
4. [ ] Complete BLoC logic
5. [ ] Build UI components
6. [ ] Write tests
EOF

echo ""
echo "✅ Feature '$NAME' created successfully!"
echo ""
echo "📂 Structure:"
echo "   lib/src/feature/$NAME/"
echo "   test/src/feature/$NAME/"
echo ""
echo "📝 Next steps:"
echo "   1. Implement domain models in domain/models/"
echo "   2. Create repository interfaces in domain/repositories/"
echo "   3. Implement data layer in data/"
echo "   4. Complete BLoC logic in presentation/bloc/"
echo "   5. Build UI in presentation/widget/"
echo ""