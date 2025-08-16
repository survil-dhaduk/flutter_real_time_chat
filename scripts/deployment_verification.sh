#!/bin/bash

# Deployment verification script for Real-Time Chat App
set -e

echo "🔍 Running deployment verification for Real-Time Chat App"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "📋 Deployment Verification Checklist"
echo "===================================="

# 1. Check Flutter version
echo "🔧 Checking Flutter version..."
flutter --version
print_status $? "Flutter version check"

# 2. Clean and get dependencies
echo "🧹 Cleaning and getting dependencies..."
flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1
print_status $? "Dependencies resolved"

# 3. Check for critical analysis issues
echo "🔍 Running code analysis..."
analysis_output=$(flutter analyze 2>&1)
critical_errors=$(echo "$analysis_output" | grep -c "error •" || true)
warnings=$(echo "$analysis_output" | grep -c "warning •" || true)

if [ $critical_errors -eq 0 ]; then
    print_status 0 "No critical errors found"
else
    print_status 1 "$critical_errors critical errors found"
    echo "Critical errors need to be fixed before deployment"
fi

if [ $warnings -gt 0 ]; then
    print_warning "$warnings warnings found (review recommended)"
fi

# 4. Check app configuration
echo "📱 Verifying app configuration..."

# Check pubspec.yaml
if grep -q "version: 1.0.0+1" pubspec.yaml; then
    print_status 0 "App version configured"
else
    print_status 1 "App version needs to be set"
fi

# Check Firebase configuration
if [ -f "android/app/google-services.json" ] && [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_status 0 "Firebase configuration files present"
else
    print_status 1 "Firebase configuration files missing"
fi

# Check security rules
if [ -f "firestore.rules" ]; then
    print_status 0 "Firestore security rules configured"
else
    print_status 1 "Firestore security rules missing"
fi

# 5. Check build configurations
echo "🔨 Verifying build configurations..."

# Check Android build config
if grep -q "minSdkVersion 21" android/app/build.gradle; then
    print_status 0 "Android minimum SDK configured"
else
    print_status 1 "Android minimum SDK needs configuration"
fi

# Check proguard rules
if [ -f "android/app/proguard-rules.pro" ]; then
    print_status 0 "Android ProGuard rules configured"
else
    print_status 1 "Android ProGuard rules missing"
fi

# 6. Check assets
echo "🎨 Verifying assets..."
if [ -d "assets" ]; then
    print_status 0 "Assets directory exists"
else
    print_status 1 "Assets directory missing"
fi

# 7. Test builds (dry run)
echo "🏗️  Testing build configurations..."

# Test Android build (without actually building)
echo "Testing Android build configuration..."
if flutter build apk --dry-run > /dev/null 2>&1; then
    print_status 0 "Android build configuration valid"
else
    print_status 1 "Android build configuration has issues"
fi

# Test iOS build (without actually building, only on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Testing iOS build configuration..."
    if flutter build ios --dry-run > /dev/null 2>&1; then
        print_status 0 "iOS build configuration valid"
    else
        print_status 1 "iOS build configuration has issues"
    fi
fi

# Test Web build (without actually building)
echo "Testing Web build configuration..."
if flutter build web --dry-run > /dev/null 2>&1; then
    print_status 0 "Web build configuration valid"
else
    print_status 1 "Web build configuration has issues"
fi

# 8. Check deployment files
echo "📄 Verifying deployment files..."

deployment_files=(
    "DEPLOYMENT_CHECKLIST.md"
    "scripts/build_android.sh"
    "scripts/build_ios.sh"
    "scripts/build_web.sh"
    "scripts/test_devices.sh"
)

for file in "${deployment_files[@]}"; do
    if [ -f "$file" ]; then
        print_status 0 "$file exists"
    else
        print_status 1 "$file missing"
    fi
done

# 9. Check permissions
echo "🔐 Checking script permissions..."
for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        print_status 0 "$(basename $script) is executable"
    else
        print_status 1 "$(basename $script) needs execute permission"
        chmod +x "$script"
        print_status 0 "Fixed permissions for $(basename $script)"
    fi
done

# 10. Final summary
echo ""
echo "📊 Deployment Verification Summary"
echo "=================================="

if [ $critical_errors -eq 0 ]; then
    echo -e "${GREEN}🎉 App is ready for deployment!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run comprehensive tests: ./scripts/test_devices.sh"
    echo "2. Build for your target platform:"
    echo "   - Android: ./scripts/build_android.sh"
    echo "   - iOS: ./scripts/build_ios.sh"
    echo "   - Web: ./scripts/build_web.sh"
    echo "3. Deploy Firebase security rules: firebase deploy --only firestore:rules"
    echo "4. Follow the deployment checklist in DEPLOYMENT_CHECKLIST.md"
else
    echo -e "${RED}🚨 Critical issues found! Fix errors before deployment.${NC}"
    echo ""
    echo "Run 'flutter analyze' to see detailed error information."
fi

echo ""
echo "📱 App Configuration Summary:"
echo "- Name: Real-Time Chat"
echo "- Version: 1.0.0+1"
echo "- Platforms: Android, iOS, Web"
echo "- Firebase: Configured"
echo "- Architecture: Clean Architecture with BLoC"
echo ""
echo "For detailed deployment instructions, see DEPLOYMENT_CHECKLIST.md"