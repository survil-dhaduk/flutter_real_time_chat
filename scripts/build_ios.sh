#!/bin/bash

# Build script for iOS
set -e

echo "🚀 Building iOS App for Real-Time Chat App"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Generate necessary files
echo "📦 Generating build files..."
dart run build_runner build --delete-conflicting-outputs

# Build iOS
echo "🔨 Building iOS release..."
flutter build ios --release \
  --tree-shake-icons \
  --split-debug-info=build/ios/symbols \
  --obfuscate \
  --dart-define=ENVIRONMENT=production

echo "✅ iOS build completed!"
echo "📁 Build location: build/ios/iphoneos/Runner.app"
echo "ℹ️  Use Xcode to archive and distribute to App Store"