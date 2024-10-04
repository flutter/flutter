This wiki is for [Framework](https://github.com/flutter/flutter) CI, and is not applicable to other repositories like Engine, Packages. The integration test is referred to an end-to-end target/test presented in [Flutter build dashboard](https://flutter-dashboard.appspot.com/#/build), which is a one-on-one mapping to the entries listed in the [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml) file.

## Overview
Types of integration tests (based on how they are being executed):
* DeviceLab
  * Uses test harness: [`test_runner.dart`](https://github.com/flutter/flutter/blob/main/dev/devicelab/bin/test_runner.dart)
  * Relies on recipe: [`devicelab_drone.py`](https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/devicelab/devicelab_drone.py)
  * This consists of two types further
    * One needs a physical phone (a valid value for either `device_type` or `device_os` in [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml))
    * The other runs on a host only testbed (either `none` or not defined for both `device_type` or `device_os` in [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml))
      * `DeviceLab` here for host only testbed is a legacy name which refers to using the `devicelab_drone.py` recipes and relying on a `task.dart` file defined under `dev/devicelab/bin/tasks`. But this does NOT need a physical device. In the long term, we may want to rename to avoid confusion.
* Shard
  * Uses test harness: [`test.dart`](https://github.com/flutter/flutter/blob/main/dev/bots/test.dart)
  * Relies on recipe: [`flutter_drone.py`](https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/flutter/flutter_drone.py)
  * A `shard` property is defined for these targets
* Others
  * most likely are specific targets used to test specific functionality
  * examples:
    * [firebaselab](https://github.com/flutter/flutter/blob/2d3166b7f9d94c8449fd7224c0b36787146434cd/.ci.yaml#L435)
    * [packaging](https://github.com/flutter/flutter/blob/2d3166b7f9d94c8449fd7224c0b36787146434cd/.ci.yaml#L529)
    * [docs](https://github.com/flutter/flutter/blob/2d3166b7f9d94c8449fd7224c0b36787146434cd/.ci.yaml#L5980)
    * [test_ownership](https://github.com/flutter/flutter/blob/2d3166b7f9d94c8449fd7224c0b36787146434cd/.ci.yaml#L944)
    * [pub_autoroller](https://github.com/flutter/flutter/blob/2d3166b7f9d94c8449fd7224c0b36787146434cd/.ci.yaml#L261)

The word `DeviceLab` initially was used to represent targets running in Flutter's self-maintained hardware lab where bots are connected with a physical device. Later it has been extended to represent targets that use the test harness `test_runner.dart` which is located under `dev/devicelab/bin`. All these targets need an entry defined under `dev/devicelab/bin/tasks`, and they include ones that do not need a physical device (known as host only tests).

`Shard` tests are using the test harness `test.dart`, which supports targets that are shardable to run in parallel. Additionally it supports tests with a single shard, which means these tests are not feasible to run in parallel. These tests have only a single shard running a block of scripts.

There is an overlap happens between `DeviceLab` and `Shard`: a single shard test can also run under the `DeviceLab` test harness.

## Where to add an integration test
Most likely, we can fit a new integration test to existing types, like `DeviceLab`, `Shard` or other case-by-case tests that use their own **`recipes`** in addition to `DeviceLab` and `Shard`, e.g. firebaselab, packaging, docs, etc. If your new test doesn't fit in any of these (very rarely), it may need a new recipe.

> [!NOTE]
> **`Recipes`** are just python scripts detailing steps to set up env. and execute corresponding test harness. Different recipes basically mean different test harness with different environment setup.

For the two main types (`DeviceLab`/`Shard`):
* if a new integration test needs a physical device, it should be under `DeviceLab`
* if a new integration test doesn't need a physical device but needs to collect benchmarks, it should be under host only `Devicelab`
* if a new integration test need to run in parallel with sharding, it should be under `Shard`
* others should be good with either host only `DeviceLab` or `Shard` with a single shard.

## How to add an integration test as a `DeviceLab` target

Please refer to how to write a [`DeviceLab` test](https://github.com/flutter/flutter/tree/main/dev/devicelab#writing-tests) and how to add it to [continuous integration](https://github.com/flutter/flutter/tree/main/dev/devicelab#adding-tests-to-continuous-integration).

Quick steps:
* creates a test file under `dev/devicelab/bin/tasks/<test>.dart`
* adds a new [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml) entry by mirroring an existing target with `recipe: devicelab_drone` (see .ci.yaml [readme](https://github.com/flutter/cocoon/blob/main/CI_YAML.md))
  * begins with `bringup: true`
  * specifies `device_type` or `device_os` if needed
  * removes `bringup: true` after validated in post-submit CI (in staging pool).
* adds an ownership entry to [TESTOWNERS](https://github.com/flutter/flutter/blob/main/TESTOWNERS)
* adds entries for other platforms if needed

## How to add an integration test as a `Shard` target

Please refer to [steps-to-add-a-new-framework-test-shard](./Adding-a-new-Test-Shard.md#steps-to-add-a-new-framework-test-shard).

## How to add an integration tests with Android emulator support

In this section we will build a new target for the `Linux` platform that will run in the `DeviceLab` with an Android emulator. Note: it is also supported in `Shard`.

### Name and platform

To add a test in the Framework Repository with Android Emulators via the DeviceLab recipe, you will not have to do anything on the recipe side of the code as simply specifying the configuration will allow you to create an Android Emulator on demand. Using other custom tests will possibly require changes in the recipes repository.

When adding a new target make sure that the target platform is `Linux_android_emu`. This is done through the name of the target. This means that you can define your new target as something like:

```yaml
- name: Linux_android_emu new_test_to_add
```

This tells the CI that you want to use the `Linux` platform and your test is named `new_test_to_add`. See [.ci.yaml] (https://github.com/flutter/cocoon/blob/main/CI_YAML.md) for more details. The platform-level config already defines all necessary dimensions/properties that an emulator test needs.

The `dimensions` are a way to use the correct machine type with the supported virtualization, the `dependency` on the android_virtual_device tells the recipes framework that an emulator was requested and which api level to use and finally the `device_type` tells it to use a machine without a connected device. This will avoid issues with multiple devices found during testing.

### Target configs

Add any additional properties/dependencies your test may need.

```yaml
 name: Linux_android_emu new_test_to_add
    recipe: devicelab/devicelab_drone
    bringup: true
    properties:
      tags: >
        ["framework","hostonly","linux"]
      task_name: android_views
    timeout: 60
```

You will notice that `task_name` is new and the `tags` are new. The `task_name` is the name of your test script (minus the .dart suffix) and the tags allow infra to perform statistical analysis based on these in order to monitor SLO for task times, execution time as well as many other metrics.

The above target can be added and run assuming there exists a ·new_test_to_add.dart· file in the Flutter repo.
