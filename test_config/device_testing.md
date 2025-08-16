# Device Testing Configuration

## Target Devices and Screen Sizes

### Mobile Phones

- **iPhone SE (2nd gen)**: 375x667 (Small screen)
- **iPhone 12/13/14**: 390x844 (Standard)
- **iPhone 12/13/14 Pro Max**: 428x926 (Large screen)
- **Samsung Galaxy S21**: 360x800 (Android standard)
- **Google Pixel 6**: 411x891 (Android large)

### Tablets

- **iPad (9th gen)**: 820x1180 (Standard tablet)
- **iPad Pro 12.9"**: 1024x1366 (Large tablet)
- **Samsung Galaxy Tab S7**: 753x1037 (Android tablet)

### Desktop/Web

- **1366x768**: Laptop standard
- **1920x1080**: Desktop standard
- **2560x1440**: High-resolution desktop

## Testing Checklist

### Authentication Flow

- [ ] Login form displays correctly on all screen sizes
- [ ] Register form is accessible and functional
- [ ] Error messages are visible and readable
- [ ] Loading states work properly
- [ ] Keyboard doesn't obscure input fields

### Chat Room List

- [ ] Room cards display properly in different orientations
- [ ] Pull-to-refresh works on all devices
- [ ] Navigation is smooth and responsive
- [ ] Empty state displays correctly
- [ ] Loading indicators are visible

### Chat Interface

- [ ] Message bubbles adapt to screen width
- [ ] Input field remains accessible when keyboard is open
- [ ] Scroll behavior works smoothly
- [ ] Message status indicators are visible
- [ ] Timestamps display correctly
- [ ] Long messages wrap properly

### Performance

- [ ] App launches within 3 seconds
- [ ] Real-time updates are smooth
- [ ] Memory usage stays reasonable
- [ ] No frame drops during scrolling
- [ ] Network requests complete within timeout

### Accessibility

- [ ] Screen reader compatibility
- [ ] Proper contrast ratios
- [ ] Touch targets meet minimum size requirements
- [ ] Focus indicators are visible
- [ ] Text scales properly with system settings

## Test Commands

```bash
# Test on different screen sizes (Web)
flutter run -d chrome --web-port 8080
# Then use browser dev tools to simulate different devices

# Test on iOS Simulator
flutter run -d "iPhone SE (3rd generation)"
flutter run -d "iPhone 14 Pro Max"
flutter run -d "iPad Pro (12.9-inch) (6th generation)"

# Test on Android Emulator
flutter run -d emulator-5554  # Configure different AVDs

# Performance testing
flutter run --profile -d <device>
```

## Responsive Design Breakpoints

```dart
// Screen size categories
enum ScreenSize {
  small,    // < 600px width
  medium,   // 600px - 1024px width
  large,    // > 1024px width
}

// Usage in widgets
class ResponsiveWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return MobileLayout();
    } else if (screenWidth < 1024) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  }
}
```
