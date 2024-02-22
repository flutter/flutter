# Contributing to the Flutter engine

_See also: [Flutter's code of conduct][code_of_conduct]_

## Welcome

For an introduction to contributing to Flutter, see [our contributor
guide][contrib_guide].

For specific instructions regarding building Flutter's engine, see [Setting up
the Engine development environment][engine_dev_setup] on our wiki. Those
instructions are part of the broader onboarding instructions described in the
contributing guide.

## Style

The Flutter engine follows Google style for the languages it uses:

- [C++](https://google.github.io/styleguide/cppguide.html)
  - **Note**: The Linux embedding generally follows idiomatic GObject-based C
    style. Use of C++ is discouraged in that embedding to avoid creating hybrid
    code that feels unfamiliar to either developers used to working with
    `GObject` or C++ developers. For example, do not use STL collections or
    `std::string`. Exceptions:
    - C-style casts are forbidden; use C++ casts.
    - Use `nullptr` rather than `NULL`.
    - Avoid `#define`; for internal constants use `static constexpr` instead.
- [Objective-C][objc_style] (including [Objective-C++][objcc_style])
- [Java][java_style]

C/C++ and Objective-C/C++ files are formatted with `clang-format`, and GN files
with `gn format`.

[code_of_conduct]: https://github.com/flutter/flutter/blob/master/CODE_OF_CONDUCT.md
[contrib_guide]: https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md
[engine_dev_setup]: https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment
[objc_style]: https://google.github.io/styleguide/objcguide.html
[objcc_style]: https://google.github.io/styleguide/objcguide.html#objective-c
[java_style]: https://google.github.io/styleguide/javaguide.html

## Testing

The testing policy for contributing to the flutter engine can be found at the
[Tree Hygiene Wiki][tree_hygiene_wiki]. The summary is that all PR's to the
engine should be tested or have an explicit test exemption.

Because the engine targets multiple platforms the testing infrastructure is
fairly complicated. Here are some more resources to help guide writing tests:

- [Testing the engine wiki][testing_the_engine_wiki] - A guide on writing tests
  for the engine including an overview of the different tests and the different
  technologies the engine uses.
- [`//testing`](./testing) - This is where the `run_tests.py` script is located.
  All tests will have the ability to be executed with `run_tests.py`.
- [`//ci/builders`](./ci/builders) - The JSON files that determine how tests are
  executed on CI.

Tests will be executed on CI, but some tests will be executed before PR's can be
merged (presubmit) and others after they have been merged (postsubmit). Ideally
everything would be presubmit but tests that take up more resources are executed
in postsubmit.

### Skia Gold

The Flutter engine uses [Skia Gold][skia_gold] for image comparison tests which fail if:

- The image is different from an accepted baseline.
- An image is not uploaded but is expected to be (see
  [`dir_contents_diff`][dir_contents_diff]).

[skia_gold]: https://flutter-engine-gold.skia.org/
[dir_contents_diff]: ./tools/dir_contents_diff/

Any untriaged failures will block presubmit and postsubmit tests.

### Example run_tests.py invocation

```sh
# Configure host build for macOS arm64 debug.
$ flutter/tools/gn --runtime-mode=debug --unoptimized --no-lto --mac-cpu=arm64
# Compile default targets (should cover all applicable run_tests.py requirements).
$ ninja -j100 -C out/host_debug_unopt_arm64
# Run all cross-platform C++ tests for the debug build arm64 variant.
$ cd flutter/testing
$ ./run_tests.py --variant=host_debug_unopt_arm64 --type=engine`
```

### Directory

| Name                                     | run_tests.py type   | Description                                                     |
| ---------------------------------------- | ------------------- | --------------------------------------------------------------- |
| accessibility_unittests                  | engine              |                                                                 |
| client_wrapper_glfw_unittests            | engine              |                                                                 |
| client_wrapper_unittests                 | engine              |                                                                 |
| common_cpp_core_unittests                | engine              |                                                                 |
| common_cpp_unittests                     | engine              |                                                                 |
| dart_plugin_registrant_unittests         | engine              |                                                                 |
| display_list_rendertests                 | engine              |                                                                 |
| display_list_unittests                   | engine              |                                                                 |
| embedder_a11y_unittests                  | engine              |                                                                 |
| embedder_proctable_unittests             | engine              |                                                                 |
| embedder_unittests                       | engine              |                                                                 |
| felt                                     | n/a                 | The test runner for flutter web. See //lib/web_ui               |
| flow_unittests                           | engine              |                                                                 |
| flutter_tester                           | dart                | Launcher for engine dart tests.                                 |
| fml_arc_unittests                        | engine              |                                                                 |
| fml_unittests                            | engine              | Unit tests for //fml                                            |
| framework_common_unittests               | engine(mac)         |                                                                 |
| gpu_surface_metal_unittests              | engine(mac)         |                                                                 |
| impeller_dart_unittests                  | engine              |                                                                 |
| impeller_golden_tests                    | engine(mac)         | Generates golden images for impeller (vulkan, metal, opengles). |
| impeller_unittests                       | engine              | impeller unit tests and interactive tests                       |
| ios_test_flutter                         | objc                | dynamic library of objc tests to be run with XCTest             |
| jni_unittests                            | engine(not windows) |                                                                 |
| no_dart_plugin_registrant_unittests      | engine              |                                                                 |
| platform_view_android_delegate_unittests | engine(not windows) |                                                                 |
| runtime_unittests                        | engine              |                                                                 |
| shell_unittests                          | engine(not windows) |                                                                 |
| scenario_app                             | android             | Integration and golden tests for Android, iOS                   |
| testing_unittests                        | engine              |                                                                 |
| tonic_unittests                          | engine              | Unit tests for //third_party/tonic                              |
| txt_unittests                            | engine(linux)       |                                                                 |
| ui_unittests                             | engine              |                                                                 |

[tree_hygiene_wiki]: https://github.com/flutter/flutter/wiki/Tree-hygiene#tests
[testing_the_engine_wiki]: https://github.com/flutter/flutter/wiki/Testing-the-engine

## Fuchsia Contributions from Googlers

Googlers contributing to Fuchsia should follow the additional steps at:
go/flutter-fuchsia-pr-policy.
