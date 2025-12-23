#!/bin/bash

set -e

NAME=$1

if [ -z "$NAME" ]; then
  echo "❌ Error: Core module name is required"
  echo "Usage: $0 <core_module_name>"
  echo "Example: $0 cache"
  exit 1
fi

# Paths for single package architecture
CORE_DIR="lib/src/core/$NAME"
TEST_DIR="test/src/core/$NAME"

# Check if module already exists
if [ -d "$CORE_DIR" ]; then
  echo "❌ Error: Core module '$NAME' already exists at $CORE_DIR"
  exit 1
fi

echo "📁 Creating core module: $NAME"

# Create core module structure
mkdir -p "$CORE_DIR"
mkdir -p "$TEST_DIR"

# Create interface file
cat > "$CORE_DIR/${NAME}.dart" << EOF
/// Interface for $NAME module
abstract interface class $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}') {
  // TODO: Define interface methods
}
EOF

# Create implementation file
cat > "$CORE_DIR/${NAME}_impl.dart" << EOF
import '${NAME}.dart';

/// Implementation of $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
final class $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Impl implements $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}') {
  $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Impl();
  
  // TODO: Implement interface methods
}
EOF

# Create test file
cat > "$TEST_DIR/${NAME}_test.dart" << EOF
import 'package:flutter_test/flutter_test.dart';
import 'package:$(grep '^name:' pubspec.yaml | awk '{print $2}')/src/core/$NAME/${NAME}_impl.dart';

void main() {
  group('$(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Impl', () {
    late $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Impl $(echo "$NAME" | sed 's/_//g');

    setUp(() {
      $(echo "$NAME" | sed 's/_//g') = $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Impl();
    });

    test('should be instantiated', () {
      expect($(echo "$NAME" | sed 's/_//g'), isNotNull);
    });

    // TODO: Add more tests
  });
}
EOF

# Create README
cat > "$CORE_DIR/README.md" << EOF
# $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}') Core Module

## Purpose

Core module for $NAME functionality.

## Structure

\`\`\`
$NAME/
├── ${NAME}.dart           # Interface
├── ${NAME}_impl.dart      # Implementation
└── README.md
\`\`\`

## Usage

\`\`\`dart
import 'package:template_flutter_claude/src/core/$NAME/${NAME}.dart';
import 'package:template_flutter_claude/src/core/$NAME/${NAME}_impl.dart';

// Create instance
final $(echo "$NAME" | sed 's/_//g') = $(echo "$NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')Impl();
\`\`\`

## Testing

\`\`\`bash
flutter test test/src/core/$NAME/
\`\`\`

## Next Steps

1. [ ] Define interface methods in ${NAME}.dart
2. [ ] Implement methods in ${NAME}_impl.dart
3. [ ] Write unit tests
4. [ ] Add documentation (dartdoc comments)
EOF

echo ""
echo "✅ Core module '$NAME' created successfully!"
echo ""
echo "📂 Structure:"
echo "   lib/src/core/$NAME/"
echo "   ├── ${NAME}.dart (interface)"
echo "   ├── ${NAME}_impl.dart (implementation)"
echo "   └── README.md"
echo ""
echo "   test/src/core/$NAME/"
echo "   └── ${NAME}_test.dart"
echo ""
echo "📝 Next steps:"
echo "   1. Define interface in ${NAME}.dart"
echo "   2. Implement in ${NAME}_impl.dart"
echo "   3. Write tests in ${NAME}_test.dart"
echo "   4. Import using: import 'package:template_flutter_claude/src/core/$NAME/${NAME}.dart'"
echo ""
