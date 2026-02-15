# microbenchmarks

To run these benchmarks on a device, first run `flutter logs` in one
window to see the device logs, then, in a different window, run:

```sh
flutter run -d $DEVICE_ID --profile lib/benchmark_collection.dart
```

To run a subset of tests:

```shell
flutter run -d $DEVICE_ID --profile lib/benchmark_collection.dart --dart-define=tests=foundation/change_notifier_bench.dart,language/sync_star_bench.dart
```

To specify a seed value for shuffling tests:

```shell
flutter run -d $DEVICE_ID --profile lib/benchmark_collection.dart --dart-define=seed=12345
```


The results should be in the device logs.

## Avoid changing names of the benchmarks

Each microbenchmark is identified by a name, for example,
"catmullrom_transform_iteration". Changing the name passed to `BenchmarkResultPrinter.addResult`
will effectively remove the old benchmark and create a new one,
losing the historical data associated with the old benchmark in the process.
