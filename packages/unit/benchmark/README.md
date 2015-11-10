# Benchmarks

This directory (and its sub-directories) contain benchmarks for Flutter.
The reporting format for benchmarks is not standardized yet, so benchmarks
here are typically run by hand. To run a benchmark:

1. Build `sky_shell` for Linux Release using the instructions in the
   [Engine repository](https://github.com/flutter/engine).

2. Run `pub get` in the `packages/unit` directory.

3. Run the benchmark:

```
/path/to/engine/src/out/Release/sky_shell packages/unit/benchmark/stocks/layout_bench.dart --package-root=packages/unit/package
```
