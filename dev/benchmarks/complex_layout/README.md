# complex_layout

## Scrolling benchmark

To run the scrolling benchmark on a device:

```
flutter drive --profile test_driver/scroll_perf.dart
```

Results should be in the file `build/complex_layout_scroll_perf.timeline_summary.json`.

More detailed logs should be in `build/complex_layout_scroll_perf.timeline.json`.


## Startup benchmark

To measure startup time on a device:

```
flutter run --profile --trace-startup
```

Results should be in the logs.

Additional results should be in the file `build/start_up_info.json`.
