# Benchmarks

This directory (and its sub-directories) contain benchmarks for
Flutter. The reporting format for benchmarks is not standardized yet,
so benchmarks here are typically run by hand. To run a benchmark:

1. Build `sky_shell` for Linux Release using the instructions in the
   [Engine repository](https://github.com/flutter/engine).

2. Run `pub get` in the `packages/flutter` directory.

3. Run the benchmarks by running the following command from the root
   of the flutter repository. Replace `stocks/layout_bench.dart` with
   the path to whichever benchmark you want to run. If you didn't
   build the engine in the recommended place, then also update the
   path accordingly. If you made changes to sky_services, you'll also
   need to update the `pubspec.yaml` file to point to that using a
   dependency_override.

```
../engine/src/out/Release/sky_shell packages/flutter/benchmark/stocks/layout_bench.dart --package-root=packages/flutter/packages
```
