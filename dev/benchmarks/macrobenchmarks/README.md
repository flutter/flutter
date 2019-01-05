# Macrobenchmarks

Performance benchmarks using flutter drive.

## Cull opacity benchmark

To run the cull opacity benchmark on a device:

```
flutter drive --profile test_driver/cull_opacity_perf.dart
```

Results should be in the file `build/cull_opacity_perf.timeline_summary.json`.

More detailed logs should be in `build/cull_opacity_perf.timeline.json`.
