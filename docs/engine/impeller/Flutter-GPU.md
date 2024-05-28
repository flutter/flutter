**Flutter GPU** (previously referred to as "Dart GPU" or "Impeller Dart") is an effort to expose a low level graphics API in the Flutter Framework.

Design doc: https://flutter.dev/go/impeller-dart

Flutter GPU's runtime is a thin wrapper over [Impeller](README.md)'s HAL, from which custom renderers may be entirely built using Dart. Just like with Impeller, Flutter GPU shader bundles are compiled ahead of time using [impellerc](https://github.com/flutter/engine/tree/main/impeller/compiler). As such, Flutter GPU is only available on platforms that support Impeller.

## Dart FFI

Under the hood, the API communicates with Flutter Engine via Dart FFI, calling symbols publicly exported by libflutter and/or embedders. These symbols are prefixed with `InternalFlutterGpu`, and are considered unstable. Direct usage of the exported symbols is not supported and will break without notice; the only supported way to use Flutter GPU is by importing `package:flutter_gpu`.

## Try out Flutter GPU

Once released, Flutter GPU will be shipped as part of the Flutter SDK in the form of a Dart package called `flutter_gpu`. An early implementation of the `flutter_gpu` package is being developed under the [`lib/gpu` directory](https://github.com/flutter/engine/tree/main/lib/gpu) of the Flutter Engine repository.

> [!CAUTION]
> _All_ aspects of Flutter GPU are subject to breakage or removal at any time without prior deprecation notice or viable feature replacement. DO NOT rely on Flutter GPU for production projects at this time, but DO have fun playing with it and sharing your experiments with the community.

Flutter GPU is currently unfinished, extremely experimental, and not well documented. [bdero](https://github.com/bdero) is actively developing and testing Flutter GPU against the MacOS desktop embedder; shader compilation and import likely don't function correctly on other platforms yet. However, if you wish to experiment with Flutter GPU, it is possible to do so without a custom Engine build:

1. Update your Flutter checkout to the latest version in the [master channel](https://docs.flutter.dev/release/upgrade#other-channels).
1. Clone [Flutter Engine](https://github.com/flutter/engine) and checkout the Engine commit that the Flutter master channel is currently pinned to. This can be found in the [`bin/internal/engine.version` file](https://github.com/flutter/flutter/blob/main/bin/internal/engine.version) of the main Flutter repository.
    ```sh
    git clone https://github.com/flutter/engine.git
    cd engine
    git reset --hard [PINNED_ENGINE_COMMIT]
    ```
1. Create a new Flutter project using the Flutter tool and add `flutter_gpu` as a dependency in `pubspec.yaml` with a local path pointing to the `lib/gpu` directory within the Flutter Engine repository cloned in step 2. For example:
    ```yaml
    dependencies:
      flutter:
        sdk: flutter
      flutter_gpu:
        path: ../engine/src/flutter/lib/gpu
    ```
1. From here, you can import the API and begin using it.
    ```dart
    import 'package:flutter_gpu/gpu.dart' as gpu;
    ```
    Check out this [examples repository](https://github.com/bdero/flutter-gpu-examples), which includes an example of [drawing a triangle](https://github.com/bdero/flutter-gpu-examples/blob/master/lib/triangle.dart), among other things.

## Reporting bugs

If you run into issues while using Flutter GPU, please file a bug using the standard [bug report template](https://github.com/flutter/flutter/issues/new?template=2_bug.yml). Additionally, mention "Flutter GPU" in the title, label the bug with the `e: impeller` label, and tag [bdero](https://github.com/bdero) in the issue description.

## Questions or feedback?

If you have non-bug report questions surrounding Flutter GPU, there are several ways you can reach out to the developer:
* Create a thread in the #help channel of the [Discord server](../../contributing/Chat.md). Place "Flutter GPU" in the title of the thread and tag @bdero in the message.
* Send a Twitter DM to [@algebrandon](https://twitter.com/algebrandon).
