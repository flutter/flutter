Benchmarks
==========
This directory (and its sub-directories) contain benchmarks for Flutter.
The reporting format for benchmarks is not standardized yet, so benchmarks
here are typically run by hand. To run a particular benchmark, use a command
similar to that used to run individual unit tests. For example:

```
sky/tools/run_tests --debug -r expanded benchmark/gestures/velocity_tracker_bench.dart
```

(The `-r expanded` flag prints one line per test, which can be more helpful
than the default format when running individual tests.)
