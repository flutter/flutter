# Battery

---

## Deprecation Notice

This plugin has been replaced by the [Flutter Community Plus
Plugins](https://plus.fluttercommunity.dev/) version,
[`battery_plus`](https://pub.dev/packages/battery_plus).
No further updates are planned to this plugin, and we encourage all users to
migrate to the Plus version.

Critical fixes (e.g., for any security incidents) will be provided through the
end of 2021, at which point this package will be marked as discontinued.

---

[![pub package](https://img.shields.io/pub/v/battery.svg)](https://pub.dev/packages/battery)

A Flutter plugin to access various information about the battery of the device the app is running on.

## Usage
To use this plugin, add `battery` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/platform-integration/platform-channels).

### Example

``` dart
// Import package
import 'package:battery/battery.dart';

// Instantiate it
var _battery = Battery();

// Access current battery level
print(await _battery.batteryLevel);

// Be informed when the state (full, charging, discharging) changes
_battery.onBatteryStateChanged.listen((BatteryState state) {
  // Do something with new state
});
```
