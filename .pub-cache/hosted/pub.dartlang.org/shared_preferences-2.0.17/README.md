# Shared preferences plugin

[![pub package](https://img.shields.io/pub/v/shared_preferences.svg)](https://pub.dev/packages/shared_preferences)

Wraps platform-specific persistent storage for simple data
(NSUserDefaults on iOS and macOS, SharedPreferences on Android, etc.).
Data may be persisted to disk asynchronously,
and there is no guarantee that writes will be persisted to disk after
returning, so this plugin must not be used for storing critical data.

Supported data types are `int`, `double`, `bool`, `String` and `List<String>`.

|             | Android | iOS  | Linux | macOS  | Web | Windows     |
|-------------|---------|------|-------|--------|-----|-------------|
| **Support** | SDK 16+ | 9.0+ | Any   | 10.11+ | Any | Any         |

## Usage
To use this plugin, add `shared_preferences` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/platform-integration/platform-channels).

### Examples
Here are small examples that show you how to use the API.

#### Write data
```dart
// Obtain shared preferences.
final prefs = await SharedPreferences.getInstance();

// Save an integer value to 'counter' key.
await prefs.setInt('counter', 10);
// Save an boolean value to 'repeat' key.
await prefs.setBool('repeat', true);
// Save an double value to 'decimal' key.
await prefs.setDouble('decimal', 1.5);
// Save an String value to 'action' key.
await prefs.setString('action', 'Start');
// Save an list of strings to 'items' key.
await prefs.setStringList('items', <String>['Earth', 'Moon', 'Sun']);
```

#### Read data
```dart
// Try reading data from the 'counter' key. If it doesn't exist, returns null.
final int? counter = prefs.getInt('counter');
// Try reading data from the 'repeat' key. If it doesn't exist, returns null.
final bool? repeat = prefs.getBool('repeat');
// Try reading data from the 'decimal' key. If it doesn't exist, returns null.
final double? decimal = prefs.getDouble('decimal');
// Try reading data from the 'action' key. If it doesn't exist, returns null.
final String? action = prefs.getString('action');
// Try reading data from the 'items' key. If it doesn't exist, returns null.
final List<String>? items = prefs.getStringList('items');
```

#### Remove an entry
```dart
// Remove data for the 'counter' key.
final success = await prefs.remove('counter');
```

### Testing

You can populate `SharedPreferences` with initial values in your tests by running this code:

```dart
Map<String, Object> values = <String, Object>{'counter': 1};
SharedPreferences.setMockInitialValues(values);
```

### Storage location by platform

| Platform | Location |
| :--- | :--- |
| Android | SharedPreferences |
| iOS | NSUserDefaults |
| Linux | In the XDG_DATA_HOME directory |
| macOS | NSUserDefaults |
| Web | LocalStorage |
| Windows | In the roaming AppData directory |
