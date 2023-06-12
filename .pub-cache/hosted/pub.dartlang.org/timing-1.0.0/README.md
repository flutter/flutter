# [![Build Status](https://github.com/dart-lang/timing/workflows/Dart%20CI/badge.svg)](https://github.com/dart-lang/timing/actions?query=workflow%3A"Dart+CI"+branch%3Amaster)

Timing is a simple package for tracking performance of both async and sync actions

```dart
var tracker = AsyncTimeTracker();
await tracker.track(() async {
  // some async code here
});

// Use results
print('${tracker.duration} ${tracker.innerDuration} ${tracker.slices}');
```


## Building

Use the following command to re-generate `lib/src/timing.g.dart` file:

```bash
pub run build_runner build
```
