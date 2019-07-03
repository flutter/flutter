# Macrobenchmarks

Performance benchmarks using flutter drive.

## Cull opacity benchmark

To run the cull opacity benchmark on a device:

```
flutter drive --profile test_driver/cull_opacity_perf.dart
```

Results should be in the file `build/cull_opacity_perf.timeline_summary.json`.

More detailed logs should be in `build/cull_opacity_perf.timeline.json`.

## Cubic bezier benchmark

To run the cubic bezier benchmark on a device:

```
flutter drive --profile test_driver/cubic_bezier_perf.dart
```

Results should be in the file `build/cubic_bezier_perf.timeline_summary.json`.

More detailed logs should be in `build/cubic_bezier_perf.timeline.json`.

## Backdrop filter benchmark

To run the backdrop filter benchmark on a device:

```
flutter drive --profile test_driver/backdrop_filter_perf.dart
```

Results should be in the file `build/backdrop_filter_perf.timeline_summary.json`.

More detailed logs should be in `build/backdrop_filter_perf.timeline.json`.
