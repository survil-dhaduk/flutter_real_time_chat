#!/bin/bash

# Build script for Web
set -e

echo "🚀 Building Web App for Real-Time Chat App"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Generate necessary files
echo "📦 Generating build files..."
dart run build_runner build --delete-conflicting-outputs

# Build Web
echo "🔨 Building web release..."
flutter build web --release \
  --tree-shake-icons \
  --dart-define=ENVIRONMENT=production \
  --web-renderer canvaskit \
  --pwa-strategy offline-first

echo "✅ Web build completed!"
echo "📁 Build location: build/web/"
echo "🌐 Ready for deployment to hosting service"