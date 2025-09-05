# High Contrast Override Example

This example demonstrates how to manually control high contrast accessibility settings in Flutter applications using MediaQuery override pattern.

## Problem Statement

Developers sometimes need to override the system's high contrast accessibility setting to:
- Test high contrast themes during development
- Provide in-app accessibility controls
- Override system settings for specific use cases

## Solution

Instead of adding new API parameters to MaterialApp, you can use MediaQuery to override the high contrast setting:

```dart
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        highContrast: true, // Force high contrast
      ),
      child: child!,
    );
  },
  theme: ThemeData(...),
  highContrastTheme: ThemeData(...),
  // ... other properties
)
```

## How It Works

1. **MediaQuery Override**: The `MediaQuery.copyWith()` method creates a new MediaQuery data object with the high contrast setting overridden.

2. **Theme Selection**: MaterialApp automatically detects the MediaQuery high contrast setting and selects the appropriate theme:
   - If `MediaQuery.highContrastOf(context)` is `true`, it uses `highContrastTheme` or `highContrastDarkTheme`
   - If `false`, it uses the standard `theme` or `darkTheme`

3. **Widget Consistency**: Any widget that checks `MediaQuery.highContrastOf(context)` will see the overridden value, ensuring consistency across the app.

## Usage Patterns

### 1. Always Force High Contrast

```dart
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(highContrast: true),
      child: child!,
    );
  },
  // ... themes
)
```

### 2. Conditional Override

```dart
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        highContrast: shouldForceHighContrast(),
      ),
      child: child!,
    );
  },
  // ... themes
)
```

### 3. User-Controlled Override

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _forceHighContrast = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            highContrast: _forceHighContrast,
          ),
          child: child!,
        );
      },
      // Add UI to toggle _forceHighContrast
      // ... themes
    );
  }
}
```

## Benefits

- **No API Surface Expansion**: Leverages existing MediaQuery mechanism
- **Comprehensive**: Affects both theme selection and MediaQuery.highContrastOf() calls
- **Flexible**: Can be applied conditionally or dynamically
- **Consistent**: All widgets see the same high contrast state

## Testing

This pattern is particularly useful for testing high contrast themes during development:

```dart
// In your test app or development build
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        highContrast: true, // Always test with high contrast
      ),
      child: child!,
    );
  },
  // ... your themes
)
```

## Running the Example

To run this example:

1. Navigate to the example directory
2. Run `flutter run`
3. Use the toggle switch to see the high contrast override in action
4. Observe how the theme changes and how MediaQuery values are affected

The example shows:
- Current system high contrast setting
- Whether the override is active
- The effective high contrast state seen by widgets
- Sample UI elements that demonstrate the visual differences
