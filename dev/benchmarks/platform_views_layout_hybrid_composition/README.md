# platform_views_layout_hybrid_composition

## Scrolling benchmark

To run the scrolling benchmark on a device:

```sh
flutter drive --profile test_driver/scroll_perf.dart
```

Results should be in the file `build/platform_views_scroll_perf_hybrid_composition.timeline_summary.json`.

More detailed logs should be in `build/platform_views_scroll_perf_hybrid_composition.timeline.json`.


## Startup benchmark

To measure startup time on a device:

```sh
flutter run --profile --trace-startup
```

Results should be in the logs.

Additional results should be in the file `build/start_up_info.json`.
