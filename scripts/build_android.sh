#!/bin/bash

# Build script for Android
set -e

echo "🚀 Building Android APK for Real-Time Chat App"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Generate necessary files
echo "📦 Generating build files..."
dart run build_runner build --delete-conflicting-outputs

# Build APK
echo "🔨 Building release APK..."
flutter build apk --release \
  --tree-shake-icons \
  --split-debug-info=build/app/outputs/symbols \
  --obfuscate \
  --dart-define=ENVIRONMENT=production

# Build App Bundle for Play Store
echo "📱 Building App Bundle..."
flutter build appbundle --release \
  --tree-shake-icons \
  --split-debug-info=build/app/outputs/symbols \
  --obfuscate \
  --dart-define=ENVIRONMENT=production

echo "✅ Android build completed!"
echo "📁 APK location: build/app/outputs/flutter-apk/app-release.apk"
echo "📁 Bundle location: build/app/outputs/bundle/release/app-release.aab"