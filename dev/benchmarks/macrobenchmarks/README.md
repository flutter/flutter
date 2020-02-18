# Macrobenchmarks

Performance benchmarks use either flutter drive or the web benchmark harness.

## Mobile benchmarks

### Cull opacity benchmark

To run the cull opacity benchmark on a device:

```
flutter drive --profile test_driver/cull_opacity_perf.dart
```

Results should be in the file `build/cull_opacity_perf.timeline_summary.json`.

More detailed logs should be in `build/cull_opacity_perf.timeline.json`.

### Cubic bezier benchmark

To run the cubic bezier benchmark on a device:

```
flutter drive --profile test_driver/cubic_bezier_perf.dart
```

Results should be in the file `build/cubic_bezier_perf.timeline_summary.json`.

More detailed logs should be in `build/cubic_bezier_perf.timeline.json`.

### Backdrop filter benchmark

To run the backdrop filter benchmark on a device:

```
flutter drive --profile test_driver/backdrop_filter_perf.dart
```

Results should be in the file `build/backdrop_filter_perf.timeline_summary.json`.

More detailed logs should be in `build/backdrop_filter_perf.timeline.json`.

### Post Backdrop filter benchmark

To run the post-backdrop filter benchmark on a device:

```
flutter drive --profile test_driver/post_backdrop_filter_perf.dart
```

Results should be in the file `build/post_backdrop_filter_perf.timeline_summary.json`.

More detailed logs should be in `build/post_backdrop_filter_perf.timeline.json`.

## Web benchmarks

Web benchmarks are compiled from the same entrypoint in `lib/web_benchmarks.dart`.

### How to write a web benchmark

Create a new file for your benchmark under `lib/src/web`. See `bench_draw_rect.dart`
as an example.

Choose one of the two benchmark types:

* A "raw benchmark" records performance metrics from direct interactions with
  `dart:ui` with no framework. This kind of benchmark is good for benchmarking
  low-level engine primitives, such as layer, picture, and semantics performance.
* A "widget benchmark" records performance metrics using a widget. This kind of
  benchmark is good for measuring the performance of widgets, often together with
  engine work that widget-under-test incurs.

For a raw benchmark implement `RawRecorder` (tip: you can start by copying
`bench_draw_rect.dart`).

For a widget benchmark implement `WidgetRecorder` (tip: you can start by copying
`bench_simple_lazy_text_scroll.dart`).

Pick a unique benchmark name and class name and add it to the `benchmarks` list
in `lib/web_benchmarks.dart`.

### How to run a web benchmark

Web benchmarks can be run using `flutter run` in debug, profile, and release
modes. Note, however, that running in debug mode will result in worse numbers.
Profile mode is useful for profiling in Chrome DevTools because the numbers
are close to release mode and the profile contains unobfuscated numbers.

Example:

```
flutter run --profile -d web-server lib/web_benchmarks.dart
```
