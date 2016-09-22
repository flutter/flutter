# microbenchmarks

To run these benchmarks on a device, first run `flutter logs' in one
window to see the device logs, then, in a different window, run any of
these:

```
flutter run --release lib/gestures/velocity_tracker_data.dart
flutter run --release lib/stocks/animation_bench.dart
flutter run --release lib/stocks/build_bench.dart
flutter run --release lib/stocks/layout_bench.dart
```

The results should be in the device logs.
