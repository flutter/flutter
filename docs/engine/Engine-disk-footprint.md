# Engine disk footprint

Here are all the tools to help track and debug the disk size of the Flutter
engine.

## Treemaps

For each commit to [flutter/flutter](https://github.com/flutter/flutter) the
Chromebots generate treemaps illustrating the sizes of the individual components
within release builds of `libflutter.so`. The treemap is uploaded to Google
Cloud Storage and linked from the
[LUCI](https://ci.chromium.org/p/flutter/g/engine/console) console.

To find a treemap for a given commit follow these steps:

1) go to the list of all flutter commits:
   <https://github.com/flutter/flutter/commits/main/>
1) find the commit you want to evaluate, then click on the green checkbox to see
   the checks
1) find the check titled `Linux linux_android_aot_engine`, click on `details`
1) Click on `View more details on flutter-dashboard` to get access to the LUCI
   build page (example:
   <https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20linux_android_aot_engine/17969/overview>).
1) expand the section called `launch builds`
1) find the launched build named something like `Linux Production Engine Drone
   for ci/android_release_arm64`, click it (example
   <https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20Production%20Engine%20Drone/1294317/overview>).
1) look for the build section called `log links`, click the `index.html` link
   under it (example:
   <https://storage.googleapis.com/flutter_logs/engine/96fe3b3df509d451116124f0abbd288e36a03805/builder/ff60e5a3-b415-42ae-a7b4-025b1af8ec71/index.html>).

Treemaps can also be generated locally with the following call:

```shell
flutter/ci/binary_size_treemap.sh <path/to/libflutter.so> <output_directory>
```

## Benchmarks

In [devicelab](https://github.com/flutter/flutter/tree/main/dev/devicelab) we
run various benchmarks to track the APK/IPA sizes and various (engine) artifacts
contained within. These benchmarks run for every commit to
[flutter/flutter](https://github.com/flutter/flutter) and are visible on our
[build dashboard](https://flutter-dashboard.appspot.com/). The most relevant
benchmarks for engine size are:

* APK/IPA size of Flutter Gallery
  * Android: `flutter_gallery_android__compile/release_size_bytes`
  * iOS: `flutter_gallery_ios__compile/release_size_bytes`
* APK/IPA size of minimal hello_world app
  * Android: `hello_world_android__compile/release_size_bytes`
  * iOS: `hello_world_ios__compile/release_size_bytes`
* Size of bundled `icudtl.dat`
  * Compressed in APK: `hello_world_android__compile/icudtl_compressed_bytes`
  * Uncompressed: `hello_world_android__compile/icudtl_uncompressed_bytes`
* Size of bundled `libflutter.so` (release mode)
  * Compressed in APK: `hello_world_android__compile/libflutter_compressed_bytes`
  * Uncompressed: `hello_world_android__compile/libflutter_uncompressed_bytes`
* Size of VM & isolate snapshots (data and instructions)
  * Compressed in APK: `hello_world_android__compile/snapshot_compressed_bytes`
  * Uncompressed: `hello_world_android__compile/snapshot_uncompressed_bytes`

## Comparing AOT Snapshot Sizes

A detailed comparison of AOT snapshot sizes can be performed using the
[instructions documented here](./benchmarks/Comparing-AOT-Snapshot-Sizes.md).
