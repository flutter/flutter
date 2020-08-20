# microbenchmarks

To run these benchmarks on a device, first run `flutter logs' in one
window to see the device logs, then, in a different window, run any of
these:

```
flutter run --release lib/gestures/velocity_tracker_bench.dart
flutter run --release lib/gestures/gesture_detector_bench.dart
flutter run --release lib/stocks/animation_bench.dart
flutter run --release lib/stocks/build_bench.dart
flutter run --release lib/stocks/layout_bench.dart
```

The results should be in the device logs.

### Avoid changing names of the benchmarks

Each microbenchmark is identified by a name, for example,
"catmullrom_transform_iteration". Changing the name of an existing
microbenchmarks will effectively remove the old benchmark and create a new one,
losing the historical data associated with the old benchmark in the process.
