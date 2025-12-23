#!/bin/bash

# Bootstrap script for single package architecture
# This script initializes the project after cloning

set -e

echo "🚀 Bootstrapping Flutter project..."
echo ""

# Step 1: Install Flutter dependencies
echo "📦 Step 1/3: Installing Flutter dependencies..."
fvm flutter pub get
echo "✅ Dependencies installed"
echo ""

# Step 2: Run code generation
echo "🔨 Step 2/3: Running code generation..."
if grep -q "build_runner" pubspec.yaml; then
  fvm dart run build_runner build --delete-conflicting-outputs
  echo "✅ Code generation complete"
else
  echo "⚠️  No build_runner found, skipping code generation"
fi
echo ""

# Step 3: Run analyzer
echo "🔍 Step 3/3: Running analyzer..."
fvm flutter analyze
echo "✅ Analysis complete"
echo ""

echo "✅ Bootstrap complete!"
echo ""
echo "📝 Next steps:"
echo "   - Run the app: make run"
echo "   - Run tests: make test"
echo "   - View available commands: make help"
echo ""
