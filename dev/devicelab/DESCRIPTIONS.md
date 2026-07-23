### [analyzer_benchmark](bin/tasks/analyzer_benchmark.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danalyzer_benchmark](https://flutter-flutter-perf.luci.app/e?queries=test%253Danalyzer_benchmark)
- description:
  Benchmarks the performance of the Dart Analyzer on the Flutter repository.
  Measures analysis time and memory usage during bulk analysis operations.

### [android_choreographer_do_frame_test](bin/tasks/android_choreographer_do_frame_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies Android Choreographer frame callbacks and vsync timing behavior in the Flutter engine.
  Tests frame scheduling and execution smoothness on Android devices.

### [android_defines_test](bin/tasks/android_defines_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies that Dart --dart-define flags are properly passed and accessible in Android builds.
  Tests integration between Flutter tool build configurations and Android runtime execution.

### [android_display_cutout](bin/tasks/android_display_cutout.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/display_cutout_rotation](../integration_tests/display_cutout_rotation)
- benchmarks: None
- description:
  DeviceLab test verifying android display cutout behavior and execution on android devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [android_engine_flags_debug_test](bin/tasks/android_engine_flags_debug_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of android engine flags debug on android devices.
  Tests integration between framework components and underlying platform APIs.

### [android_engine_flags_release_test](bin/tasks/android_engine_flags_release_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of android engine flags release on android devices.
  Tests integration between framework components and underlying platform APIs.

### [android_java11_dependency_smoke_tests](bin/tasks/android_java11_dependency_smoke_tests.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Smoke tests for Android builds running under Java 11 environment.
  Ensures compatibility of Gradle and Android SDK toolchains with Java 11.

### [android_java17_dependency_smoke_tests](bin/tasks/android_java17_dependency_smoke_tests.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Smoke tests verifying Flutter APK builds across various supported AGP, Gradle, and Kotlin versions under Java 17.
  Tests minimum supported, template default, and maximum known dependency version combinations.

### [android_lifecycles_test](bin/tasks/android_lifecycles_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Tests Android activity and application lifecycle transitions in Flutter apps.
  Verifies engine and framework behavior during pause, resume, stop, and destroy events.

### [android_picture_cache_complexity_scoring_perf__timeline_summary](bin/tasks/android_picture_cache_complexity_scoring_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dandroid_picture_cache_complexity_scoring_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dandroid_picture_cache_complexity_scoring_perf__timeline_summary)
- description:
  Benchmarks the performance of picture cache complexity scoring during rendering on Android.
  Measures frame timing and rasterizer cache efficiency under complex visual workloads.

### [android_release_builds_exclude_dev_dependencies_test](bin/tasks/android_release_builds_exclude_dev_dependencies_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of android release builds exclude dev dependencies on android devices.
  Tests integration between framework components and underlying platform APIs.

### [android_semantics_integration_test](bin/tasks/android_semantics_integration_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/android_semantics_testing](../integration_tests/android_semantics_testing)
- benchmarks: None
- description:
  Verifies functionality and correctness of android semantics integration on pixel devices.
  Tests integration between framework components and underlying platform APIs.

### [android_verified_input_test](bin/tasks/android_verified_input_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/android_verified_input](../integration_tests/android_verified_input)
- benchmarks: None
- description:
  Tests verified motion events and touch input handling on Android devices.
  Verifies input event dispatching and security verification features in the Android embedding.

### [android_view_scroll_perf__timeline_summary](bin/tasks/android_view_scroll_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dandroid_view_scroll_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dandroid_view_scroll_perf__timeline_summary)
- description:
  Benchmarks scrolling performance of hybrid AndroidView platform views embedded in Flutter.
  Measures frame render durations and UI thread synchronization during scrolling.

### [android_views](bin/tasks/android_views.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/android_views](../integration_tests/android_views)
- benchmarks: None
- description:
  DeviceLab test verifying android views behavior and execution on android devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [animated_advanced_blend_perf__timeline_summary](bin/tasks/animated_advanced_blend_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_advanced_blend_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_advanced_blend_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for animated advanced blend on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [animated_advanced_blend_perf_ios__timeline_summary](bin/tasks/animated_advanced_blend_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_advanced_blend_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_advanced_blend_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for animated advanced blend ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [animated_advanced_blend_perf_opengles__timeline_summary](bin/tasks/animated_advanced_blend_perf_opengles__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_advanced_blend_perf_opengles__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_advanced_blend_perf_opengles__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for animated advanced blend opengles on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [animated_blur_backdrop_filter_perf__timeline_summary](bin/tasks/animated_blur_backdrop_filter_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_blur_backdrop_filter_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_blur_backdrop_filter_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for animated blur backdrop filter on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [animated_blur_backdrop_filter_perf_ios__timeline_summary](bin/tasks/animated_blur_backdrop_filter_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_blur_backdrop_filter_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_blur_backdrop_filter_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for animated blur backdrop filter ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [animated_blur_backdrop_filter_perf_opengles__timeline_summary](bin/tasks/animated_blur_backdrop_filter_perf_opengles__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_blur_backdrop_filter_perf_opengles__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_blur_backdrop_filter_perf_opengles__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for animated blur backdrop filter opengles on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [animated_complex_image_filtered_perf__e2e_summary](bin/tasks/animated_complex_image_filtered_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_complex_image_filtered_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_complex_image_filtered_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for animated complex image filtered on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [animated_complex_opacity_perf__e2e_summary](bin/tasks/animated_complex_opacity_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_complex_opacity_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_complex_opacity_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for animated complex opacity on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [animated_complex_opacity_perf_ios__e2e_summary](bin/tasks/animated_complex_opacity_perf_ios__e2e_summary.dart)
- host_platform: linux
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_complex_opacity_perf_ios__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_complex_opacity_perf_ios__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for animated complex opacity ios on ios devices.
  Verifies overall rendering performance and animation frame drops under load.

### [animated_complex_opacity_perf_macos__e2e_summary](bin/tasks/animated_complex_opacity_perf_macos__e2e_summary.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_complex_opacity_perf_macos__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_complex_opacity_perf_macos__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for animated complex opacity macos on benchmark devices.
  Verifies overall rendering performance and animation frame drops under load.

### [animated_image_gc_perf](bin/tasks/animated_image_gc_perf.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_image_gc_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_image_gc_perf)
- description:
  DeviceLab test verifying animated image gc behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [animated_placeholder_perf__e2e_summary](bin/tasks/animated_placeholder_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimated_placeholder_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimated_placeholder_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for animated placeholder on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [animation_with_microtasks_perf_ios__timeline_summary](bin/tasks/animation_with_microtasks_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Danimation_with_microtasks_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Danimation_with_microtasks_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for animation with microtasks ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [backdrop_filter_perf__e2e_summary](bin/tasks/backdrop_filter_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dbackdrop_filter_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dbackdrop_filter_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for backdrop filter on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [backdrop_filter_perf__timeline_summary](bin/tasks/backdrop_filter_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dbackdrop_filter_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dbackdrop_filter_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for backdrop filter on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [backdrop_filter_perf_ios__timeline_summary](bin/tasks/backdrop_filter_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dbackdrop_filter_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dbackdrop_filter_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for backdrop filter ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [basic_material_app_android__compile](bin/tasks/basic_material_app_android__compile.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dbasic_material_app_android__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dbasic_material_app_android__compile)
- description:
  Measures compile time and application binary metrics for basic material app android on pixel.
  Verifies build system performance and output artifact sizing.

### [basic_material_app_ios__compile](bin/tasks/basic_material_app_ios__compile.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dbasic_material_app_ios__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dbasic_material_app_ios__compile)
- description:
  Measures compile time and application binary metrics for basic material app ios on arm64.
  Verifies build system performance and output artifact sizing.

### [basic_material_app_macos__compile](bin/tasks/basic_material_app_macos__compile.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dbasic_material_app_macos__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dbasic_material_app_macos__compile)
- description:
  Measures compile time and application binary metrics for basic material app macos on benchmark.
  Verifies build system performance and output artifact sizing.

### [basic_material_app_win__compile](bin/tasks/basic_material_app_win__compile.dart)
- host_platform: windows
- target_platform: android
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dbasic_material_app_win__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dbasic_material_app_win__compile)
- description:
  Measures compile time and application binary metrics for basic material app win on mokey.
  Verifies build system performance and output artifact sizing.

### [build_aar_module_test](bin/tasks/build_aar_module_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of build aar module on host systems.
  Tests integration between framework components and underlying platform APIs.

### [build_android_host_app_with_module_aar](bin/tasks/build_android_host_app_with_module_aar.dart)
- host_platform: windows
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying build android host app with module aar behavior and execution on android devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [build_android_host_app_with_module_source](bin/tasks/build_android_host_app_with_module_source.dart)
- host_platform: windows
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying build android host app with module source behavior and execution on android devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [build_ios_framework_module_test](bin/tasks/build_ios_framework_module_test.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of build ios framework module on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [build_mode_test](bin/tasks/build_mode_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of build mode on host systems.
  Tests integration between framework components and underlying platform APIs.

### [channels_integration_test](bin/tasks/channels_integration_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/channels](../integration_tests/channels)
- benchmarks: None
- description:
  Verifies functionality and correctness of channels integration on pixel devices.
  Tests integration between framework components and underlying platform APIs.

### [channels_integration_test_ios](bin/tasks/channels_integration_test_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/channels](../integration_tests/channels)
- benchmarks: None
- description:
  Verifies functionality and correctness of channels integration ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [channels_integration_test_macos](bin/tasks/channels_integration_test_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/channels](../integration_tests/channels)
- benchmarks: None
- description:
  Verifies functionality and correctness of channels integration macos on macos devices.
  Tests integration between framework components and underlying platform APIs.

### [channels_integration_test_win](bin/tasks/channels_integration_test_win.dart)
- host_platform: windows
- target_platform: android
- dependencies: [//dev/integration_tests/channels](../integration_tests/channels)
- benchmarks: None
- description:
  Verifies functionality and correctness of channels integration win on mokey devices.
  Tests integration between framework components and underlying platform APIs.

### [clipper_cache_perf__e2e_summary](bin/tasks/clipper_cache_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dclipper_cache_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dclipper_cache_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for clipper cache on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [color_filter_and_fade_perf__e2e_summary](bin/tasks/color_filter_and_fade_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcolor_filter_and_fade_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcolor_filter_and_fade_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for color filter and fade on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [color_filter_and_fade_perf__timeline_summary](bin/tasks/color_filter_and_fade_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: linux
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcolor_filter_and_fade_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcolor_filter_and_fade_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for color filter and fade on host systems.
  Measures rasterization smoothness and UI thread synchronization duration.

### [color_filter_and_fade_perf_ios__e2e_summary](bin/tasks/color_filter_and_fade_perf_ios__e2e_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcolor_filter_and_fade_perf_ios__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcolor_filter_and_fade_perf_ios__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for color filter and fade ios on ios devices.
  Verifies overall rendering performance and animation frame drops under load.

### [color_filter_cache_perf__e2e_summary](bin/tasks/color_filter_cache_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcolor_filter_cache_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcolor_filter_cache_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for color filter cache on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [color_filter_with_unstable_child_perf__e2e_summary](bin/tasks/color_filter_with_unstable_child_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcolor_filter_with_unstable_child_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcolor_filter_with_unstable_child_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for color filter with unstable child on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [complex_layout__start_up](bin/tasks/complex_layout__start_up.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout__start_up)
- description:
  Measures the startup time and first frame rendering performance of a complex Flutter layout on Android devices.
  Tests engine initialization, widget tree construction, and initial layout passes.

### [complex_layout_android__scroll_smoothness](bin/tasks/complex_layout_android__scroll_smoothness.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_android__scroll_smoothness](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_android__scroll_smoothness)
- description:
  DeviceLab test verifying complex layout android behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [complex_layout_ios__start_up](bin/tasks/complex_layout_ios__start_up.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_ios__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_ios__start_up)
- description:
  Measures application startup time and initial frame rendering for complex layout ios on ios devices.
  Tests engine initialization speed and first layout pass duration.

### [complex_layout_macos__start_up](bin/tasks/complex_layout_macos__start_up.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_macos__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_macos__start_up)
- description:
  Measures application startup time and initial frame rendering for complex layout macos on benchmark devices.
  Tests engine initialization speed and first layout pass duration.

### [complex_layout_macos_impeller__start_up](bin/tasks/complex_layout_macos_impeller__start_up.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_macos_impeller__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_macos_impeller__start_up)
- description:
  Measures application startup time and initial frame rendering for complex layout macos impeller on benchmark devices.
  Tests engine initialization speed and first layout pass duration.

### [complex_layout_scroll_perf__devtools_memory](bin/tasks/complex_layout_scroll_perf__devtools_memory.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_scroll_perf__devtools_memory](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_scroll_perf__devtools_memory)
- description:
  DeviceLab test verifying complex layout scroll  devtools memory behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [complex_layout_scroll_perf__memory](bin/tasks/complex_layout_scroll_perf__memory.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_scroll_perf__memory](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_scroll_perf__memory)
- description:
  Benchmarks memory consumption and Dart GC behavior during complex layout scroll on mokey devices.
  Measures peak heap usage and memory leak regressions during execution.

### [complex_layout_scroll_perf__timeline_summary](bin/tasks/complex_layout_scroll_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_scroll_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_scroll_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for complex layout scroll on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [complex_layout_scroll_perf_bad_ios__timeline_summary](bin/tasks/complex_layout_scroll_perf_bad_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_scroll_perf_bad_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_scroll_perf_bad_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for complex layout scroll bad ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [complex_layout_scroll_perf_impeller__timeline_summary](bin/tasks/complex_layout_scroll_perf_impeller__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_scroll_perf_impeller__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_scroll_perf_impeller__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for complex layout scroll impeller on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [complex_layout_scroll_perf_impeller_gles__timeline_summary](bin/tasks/complex_layout_scroll_perf_impeller_gles__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_scroll_perf_impeller_gles__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_scroll_perf_impeller_gles__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for complex layout scroll impeller gles on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [complex_layout_scroll_perf_ios__timeline_summary](bin/tasks/complex_layout_scroll_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_scroll_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_scroll_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for complex layout scroll ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [complex_layout_scroll_perf_macos__timeline_summary](bin/tasks/complex_layout_scroll_perf_macos__timeline_summary.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_scroll_perf_macos__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_scroll_perf_macos__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for complex layout scroll macos on benchmark devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [complex_layout_scroll_perf_macos_impeller__timeline_summary](bin/tasks/complex_layout_scroll_perf_macos_impeller__timeline_summary.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_scroll_perf_macos_impeller__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_scroll_perf_macos_impeller__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for complex layout scroll macos impeller on benchmark devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [complex_layout_semantics_perf](bin/tasks/complex_layout_semantics_perf.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_semantics_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_semantics_perf)
- description:
  DeviceLab test verifying complex layout semantics behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [complex_layout_win_desktop__start_up](bin/tasks/complex_layout_win_desktop__start_up.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//dev/benchmarks/complex_layout](../benchmarks/complex_layout)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcomplex_layout_win_desktop__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcomplex_layout_win_desktop__start_up)
- description:
  Measures application startup time and initial frame rendering for complex layout win desktop on arm64 devices.
  Tests engine initialization speed and first layout pass duration.

### [cubic_bezier_perf__e2e_summary](bin/tasks/cubic_bezier_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcubic_bezier_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcubic_bezier_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for cubic bezier on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [cubic_bezier_perf__timeline_summary](bin/tasks/cubic_bezier_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcubic_bezier_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcubic_bezier_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for cubic bezier on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [cull_opacity_perf__e2e_summary](bin/tasks/cull_opacity_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcull_opacity_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcull_opacity_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for cull opacity on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [cull_opacity_perf__timeline_summary](bin/tasks/cull_opacity_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dcull_opacity_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dcull_opacity_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for cull opacity on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [dart_plugin_registry_test](bin/tasks/dart_plugin_registry_test.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of dart plugin registry on host systems.
  Tests integration between framework components and underlying platform APIs.

### [devtools_profile_start_test](bin/tasks/devtools_profile_start_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of devtools profile start on mokey devices.
  Tests integration between framework components and underlying platform APIs.

### [draw_arcs_all_fill_styles_perf__timeline_summary](bin/tasks/draw_arcs_all_fill_styles_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_arcs_all_fill_styles_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_arcs_all_fill_styles_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw arcs all fill styles on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_arcs_all_fill_styles_perf_ios__timeline_summary](bin/tasks/draw_arcs_all_fill_styles_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_arcs_all_fill_styles_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_arcs_all_fill_styles_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw arcs all fill styles ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_arcs_all_stroke_styles_perf__timeline_summary](bin/tasks/draw_arcs_all_stroke_styles_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_arcs_all_stroke_styles_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_arcs_all_stroke_styles_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw arcs all stroke styles on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_arcs_all_stroke_styles_perf_ios__timeline_summary](bin/tasks/draw_arcs_all_stroke_styles_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_arcs_all_stroke_styles_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_arcs_all_stroke_styles_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw arcs all stroke styles ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_atlas_perf__timeline_summary](bin/tasks/draw_atlas_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_atlas_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_atlas_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw atlas on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_atlas_perf_ios__timeline_summary](bin/tasks/draw_atlas_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_atlas_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_atlas_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw atlas ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_atlas_perf_opengles__timeline_summary](bin/tasks/draw_atlas_perf_opengles__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_atlas_perf_opengles__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_atlas_perf_opengles__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw atlas opengles on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_points_perf_ios__timeline_summary](bin/tasks/draw_points_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_points_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_points_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw points ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_vertices_perf__timeline_summary](bin/tasks/draw_vertices_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_vertices_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_vertices_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw vertices on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_vertices_perf_ios__timeline_summary](bin/tasks/draw_vertices_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_vertices_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_vertices_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw vertices ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [draw_vertices_perf_opengles__timeline_summary](bin/tasks/draw_vertices_perf_opengles__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddraw_vertices_perf_opengles__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddraw_vertices_perf_opengles__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for draw vertices opengles on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [drive_perf_debug_warning](bin/tasks/drive_perf_debug_warning.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddrive_perf_debug_warning](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddrive_perf_debug_warning)
- description:
  DeviceLab test verifying drive debug warning behavior and execution on pixel devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [dynamic_path_stroke_tessellation_perf__timeline_summary](bin/tasks/dynamic_path_stroke_tessellation_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddynamic_path_stroke_tessellation_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddynamic_path_stroke_tessellation_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for dynamic path stroke tessellation on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [dynamic_path_stroke_tessellation_perf_ios__timeline_summary](bin/tasks/dynamic_path_stroke_tessellation_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddynamic_path_stroke_tessellation_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddynamic_path_stroke_tessellation_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for dynamic path stroke tessellation ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [dynamic_path_tessellation_perf__timeline_summary](bin/tasks/dynamic_path_tessellation_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddynamic_path_tessellation_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddynamic_path_tessellation_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for dynamic path tessellation on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [dynamic_path_tessellation_perf_ios__timeline_summary](bin/tasks/dynamic_path_tessellation_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Ddynamic_path_tessellation_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Ddynamic_path_tessellation_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for dynamic path tessellation ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [engine_dependency_proxy_test](bin/tasks/engine_dependency_proxy_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of engine dependency proxy on host systems.
  Tests integration between framework components and underlying platform APIs.

### [entrypoint_dart_registrant](bin/tasks/entrypoint_dart_registrant.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying entrypoint dart registrant behavior and execution on arm64 devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [external_textures_integration_test](bin/tasks/external_textures_integration_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/external_textures](../integration_tests/external_textures)
- benchmarks: None
- description:
  Verifies functionality and correctness of external textures integration on android devices.
  Tests integration between framework components and underlying platform APIs.

### [external_textures_integration_test_ios](bin/tasks/external_textures_integration_test_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/external_textures](../integration_tests/external_textures)
- benchmarks: None
- description:
  Verifies functionality and correctness of external textures integration ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [fading_child_animation_perf__timeline_summary](bin/tasks/fading_child_animation_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dfading_child_animation_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dfading_child_animation_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for fading child animation on mokey devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [fast_scroll_heavy_gridview__memory](bin/tasks/fast_scroll_heavy_gridview__memory.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dfast_scroll_heavy_gridview__memory](https://flutter-flutter-perf.luci.app/e?queries=test%253Dfast_scroll_heavy_gridview__memory)
- description:
  Benchmarks memory consumption and Dart GC behavior during fast scroll heavy gridview on mokey devices.
  Measures peak heap usage and memory leak regressions during execution.

### [fast_scroll_large_images__memory](bin/tasks/fast_scroll_large_images__memory.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dfast_scroll_large_images__memory](https://flutter-flutter-perf.luci.app/e?queries=test%253Dfast_scroll_large_images__memory)
- description:
  Benchmarks memory consumption and Dart GC behavior during fast scroll large images on mokey devices.
  Measures peak heap usage and memory leak regressions during execution.

### [flavors_test](bin/tasks/flavors_test.dart)
- host_platform: windows
- target_platform: android
- dependencies: [//dev/integration_tests/flavors](../integration_tests/flavors)
- benchmarks: None
- description:
  Verifies functionality and correctness of flavors on mokey devices.
  Tests integration between framework components and underlying platform APIs.

### [flavors_test_ios](bin/tasks/flavors_test_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/flavors](../integration_tests/flavors)
- benchmarks: None
- description:
  Verifies functionality and correctness of flavors ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [flavors_test_macos](bin/tasks/flavors_test_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/flavors](../integration_tests/flavors)
- benchmarks: None
- description:
  Verifies functionality and correctness of flavors macos on macos devices.
  Tests integration between framework components and underlying platform APIs.

### [flutter_engine_group_performance](bin/tasks/flutter_engine_group_performance.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_engine_group_performance](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_engine_group_performance)
- description:
  DeviceLab test verifying flutter engine groupormance behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [flutter_gallery__back_button_memory](bin/tasks/flutter_gallery__back_button_memory.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__back_button_memory](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__back_button_memory)
- description:
  DeviceLab test verifying flutter gallery  back button memory behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [flutter_gallery__image_cache_memory](bin/tasks/flutter_gallery__image_cache_memory.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__image_cache_memory](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__image_cache_memory)
- description:
  DeviceLab test verifying flutter gallery  image cache memory behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [flutter_gallery__memory_nav](bin/tasks/flutter_gallery__memory_nav.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__memory_nav](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__memory_nav)
- description:
  Benchmarks memory consumption and Dart GC behavior during flutter gallery nav on mokey devices.
  Measures peak heap usage and memory leak regressions during execution.

### [flutter_gallery__start_up](bin/tasks/flutter_gallery__start_up.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__start_up)
- description:
  Measures application startup time and initial frame rendering for flutter gallery on mokey devices.
  Tests engine initialization speed and first layout pass duration.

### [flutter_gallery__start_up_delayed](bin/tasks/flutter_gallery__start_up_delayed.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__start_up_delayed](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__start_up_delayed)
- description:
  Measures application startup time and initial frame rendering for flutter gallery delayed on mokey devices.
  Tests engine initialization speed and first layout pass duration.

### [flutter_gallery__transition_perf](bin/tasks/flutter_gallery__transition_perf.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__transition_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__transition_perf)
- description:
  Benchmarks page transition animation performance for flutter gallery on build devices.
  Measures frame drop rates and build durations during navigation transitions.

### [flutter_gallery__transition_perf_e2e](bin/tasks/flutter_gallery__transition_perf_e2e.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__transition_perf_e2e](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__transition_perf_e2e)
- description:
  Benchmarks page transition animation performance for flutter gallery e2e on build devices.
  Measures frame drop rates and build durations during navigation transitions.

### [flutter_gallery__transition_perf_e2e_ios](bin/tasks/flutter_gallery__transition_perf_e2e_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__transition_perf_e2e_ios](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__transition_perf_e2e_ios)
- description:
  Benchmarks page transition animation performance for flutter gallery e2e ios on build devices.
  Measures frame drop rates and build durations during navigation transitions.

### [flutter_gallery__transition_perf_hybrid](bin/tasks/flutter_gallery__transition_perf_hybrid.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__transition_perf_hybrid](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__transition_perf_hybrid)
- description:
  Benchmarks page transition animation performance for flutter gallery hybrid on build devices.
  Measures frame drop rates and build durations during navigation transitions.

### [flutter_gallery__transition_perf_with_semantics](bin/tasks/flutter_gallery__transition_perf_with_semantics.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery__transition_perf_with_semantics](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery__transition_perf_with_semantics)
- description:
  Benchmarks page transition animation performance for flutter gallery with semantics on mokey devices.
  Measures frame drop rates and build durations during navigation transitions.

### [flutter_gallery_android__compile](bin/tasks/flutter_gallery_android__compile.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_android__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_android__compile)
- description:
  Measures compile time and application binary metrics for flutter gallery android on pixel.
  Verifies build system performance and output artifact sizing.

### [flutter_gallery_ios__compile](bin/tasks/flutter_gallery_ios__compile.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_ios__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_ios__compile)
- description:
  Measures compile time and application binary metrics for flutter gallery ios on arm64.
  Verifies build system performance and output artifact sizing.

### [flutter_gallery_ios__start_up](bin/tasks/flutter_gallery_ios__start_up.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_ios__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_ios__start_up)
- description:
  Measures application startup time and initial frame rendering for flutter gallery ios on ios devices.
  Tests engine initialization speed and first layout pass duration.

### [flutter_gallery_lazy__start_up](bin/tasks/flutter_gallery_lazy__start_up.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_lazy__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_lazy__start_up)
- description:
  Measures application startup time and initial frame rendering for flutter gallery lazy on mokey devices.
  Tests engine initialization speed and first layout pass duration.

### [flutter_gallery_macos__compile](bin/tasks/flutter_gallery_macos__compile.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_macos__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_macos__compile)
- description:
  Measures compile time and application binary metrics for flutter gallery macos on benchmark.
  Verifies build system performance and output artifact sizing.

### [flutter_gallery_macos__start_up](bin/tasks/flutter_gallery_macos__start_up.dart)
- host_platform: linux
- target_platform: macos
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_macos__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_macos__start_up)
- description:
  Measures application startup time and initial frame rendering for flutter gallery macos on macos devices.
  Tests engine initialization speed and first layout pass duration.

### [flutter_gallery_v2_chrome_run_test](bin/tasks/flutter_gallery_v2_chrome_run_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: None
- description:
  Verifies functionality and correctness of flutter gallery v2 chrome run on pixel devices.
  Tests integration between framework components and underlying platform APIs.

### [flutter_gallery_v2_web_compile_test](bin/tasks/flutter_gallery_v2_web_compile_test.dart)
- host_platform: linux
- target_platform: web
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_v2_web_compile_test](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_v2_web_compile_test)
- description:
  Verifies functionality and correctness of flutter gallery v2 web compile on web devices.
  Tests integration between framework components and underlying platform APIs.

### [flutter_gallery_win__compile](bin/tasks/flutter_gallery_win__compile.dart)
- host_platform: windows
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_win__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_win__compile)
- description:
  Measures compile time and application binary metrics for flutter gallery win on mokey.
  Verifies build system performance and output artifact sizing.

### [flutter_gallery_win_desktop__compile](bin/tasks/flutter_gallery_win_desktop__compile.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_win_desktop__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_win_desktop__compile)
- description:
  Measures compile time and application binary metrics for flutter gallery win desktop on arm64.
  Verifies build system performance and output artifact sizing.

### [flutter_gallery_win_desktop__start_up](bin/tasks/flutter_gallery_win_desktop__start_up.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_gallery_win_desktop__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_gallery_win_desktop__start_up)
- description:
  Measures application startup time and initial frame rendering for flutter gallery win desktop on arm64 devices.
  Tests engine initialization speed and first layout pass duration.

### [flutter_test_performance](bin/tasks/flutter_test_performance.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_test_performance](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_test_performance)
- description:
  Verifies functionality and correctness of flutterormance on mokey devices.
  Tests integration between framework components and underlying platform APIs.

### [flutter_tool_startup](bin/tasks/flutter_tool_startup.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying flutter tool startup behavior and execution on benchmark devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [flutter_view__start_up](bin/tasks/flutter_view__start_up.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//examples/flutter_view](../../examples/flutter_view)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_view__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_view__start_up)
- description:
  Measures application startup time and initial frame rendering for flutter view on mokey devices.
  Tests engine initialization speed and first layout pass duration.

### [flutter_view_ios__start_up](bin/tasks/flutter_view_ios__start_up.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//examples/flutter_view](../../examples/flutter_view)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_view_ios__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_view_ios__start_up)
- description:
  Measures application startup time and initial frame rendering for flutter view ios on ios devices.
  Tests engine initialization speed and first layout pass duration.

### [flutter_view_macos__start_up](bin/tasks/flutter_view_macos__start_up.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//examples/flutter_view](../../examples/flutter_view)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_view_macos__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_view_macos__start_up)
- description:
  Measures application startup time and initial frame rendering for flutter view macos on benchmark devices.
  Tests engine initialization speed and first layout pass duration.

### [flutter_view_win_desktop__start_up](bin/tasks/flutter_view_win_desktop__start_up.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//examples/flutter_view](../../examples/flutter_view)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dflutter_view_win_desktop__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dflutter_view_win_desktop__start_up)
- description:
  Measures application startup time and initial frame rendering for flutter view win desktop on arm64 devices.
  Tests engine initialization speed and first layout pass duration.

### [fullscreen_textfield_perf](bin/tasks/fullscreen_textfield_perf.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dfullscreen_textfield_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dfullscreen_textfield_perf)
- description:
  DeviceLab test verifying fullscreen textfield behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [fullscreen_textfield_perf__e2e_summary](bin/tasks/fullscreen_textfield_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dfullscreen_textfield_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dfullscreen_textfield_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for fullscreen textfield on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [fullscreen_textfield_perf__timeline_summary](bin/tasks/fullscreen_textfield_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: linux
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dfullscreen_textfield_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dfullscreen_textfield_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for fullscreen textfield on host systems.
  Measures rasterization smoothness and UI thread synchronization duration.

### [fullscreen_textfield_perf_ios__e2e_summary](bin/tasks/fullscreen_textfield_perf_ios__e2e_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dfullscreen_textfield_perf_ios__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dfullscreen_textfield_perf_ios__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for fullscreen textfield ios on ios devices.
  Verifies overall rendering performance and animation frame drops under load.

### [gradient_consistent_perf__e2e_summary](bin/tasks/gradient_consistent_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dgradient_consistent_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dgradient_consistent_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for gradient consistent on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [gradient_dynamic_perf__e2e_summary](bin/tasks/gradient_dynamic_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dgradient_dynamic_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dgradient_dynamic_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for gradient dynamic on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [gradient_static_perf__e2e_summary](bin/tasks/gradient_static_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dgradient_static_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dgradient_static_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for gradient static on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [gradle_desugar_classes_test](bin/tasks/gradle_desugar_classes_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of gradle desugar classes on host systems.
  Tests integration between framework components and underlying platform APIs.

### [gradle_java8_compile_test](bin/tasks/gradle_java8_compile_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dgradle_java8_compile_test](https://flutter-flutter-perf.luci.app/e?queries=test%253Dgradle_java8_compile_test)
- description:
  Verifies functionality and correctness of gradle java8 compile on host systems.
  Tests integration between framework components and underlying platform APIs.

### [gradle_plugin_bundle_test](bin/tasks/gradle_plugin_bundle_test.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of gradle plugin bundle on host systems.
  Tests integration between framework components and underlying platform APIs.

### [gradle_plugin_fat_apk_test](bin/tasks/gradle_plugin_fat_apk_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of gradle plugin fat apk on host systems.
  Tests integration between framework components and underlying platform APIs.

### [gradle_plugin_light_apk_test](bin/tasks/gradle_plugin_light_apk_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of gradle plugin light apk on host systems.
  Tests integration between framework components and underlying platform APIs.

### [hello_world__memory](bin/tasks/hello_world__memory.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhello_world__memory](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhello_world__memory)
- description:
  Benchmarks memory consumption and Dart GC behavior during hello world on mokey devices.
  Measures peak heap usage and memory leak regressions during execution.

### [hello_world_android__compile](bin/tasks/hello_world_android__compile.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhello_world_android__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhello_world_android__compile)
- description:
  Measures compile time and application binary metrics for hello world android on arm64.
  Verifies build system performance and output artifact sizing.

### [hello_world_impeller](bin/tasks/hello_world_impeller.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: None
- description:
  DeviceLab test verifying hello world impeller behavior and execution on pixel devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [hello_world_impeller_ios_sdfs](bin/tasks/hello_world_impeller_ios_sdfs.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: None
- description:
  DeviceLab test verifying hello world impeller ios sdfs behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [hello_world_impeller_linux](bin/tasks/hello_world_impeller_linux.dart)
- host_platform: linux
- target_platform: linux
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: None
- description:
  DeviceLab test verifying hello world impeller linux behavior and execution on host systems.
  Ensures stability and prevents regressions in standard test scenarios.

### [hello_world_impeller_macos_sdfs](bin/tasks/hello_world_impeller_macos_sdfs.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: None
- description:
  DeviceLab test verifying hello world impeller macos sdfs behavior and execution on macos devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [hello_world_ios__compile](bin/tasks/hello_world_ios__compile.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhello_world_ios__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhello_world_ios__compile)
- description:
  Measures compile time and application binary metrics for hello world ios on arm64.
  Verifies build system performance and output artifact sizing.

### [hello_world_macos__compile](bin/tasks/hello_world_macos__compile.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhello_world_macos__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhello_world_macos__compile)
- description:
  Measures compile time and application binary metrics for hello world macos on benchmark.
  Verifies build system performance and output artifact sizing.

### [hello_world_win_desktop__compile](bin/tasks/hello_world_win_desktop__compile.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhello_world_win_desktop__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhello_world_win_desktop__compile)
- description:
  Measures compile time and application binary metrics for hello world win desktop on arm64.
  Verifies build system performance and output artifact sizing.

### [hello_world_windows_impeller](bin/tasks/hello_world_windows_impeller.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//examples/hello_world](../../examples/hello_world)
- benchmarks: None
- description:
  DeviceLab test verifying hello world windows impeller behavior and execution on arm64 devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [home_scroll_perf__timeline_summary](bin/tasks/home_scroll_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhome_scroll_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhome_scroll_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for home scroll on mokey devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [hot_mode_dev_cycle__benchmark](bin/tasks/hot_mode_dev_cycle__benchmark.dart)
- host_platform: macos
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhot_mode_dev_cycle__benchmark](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhot_mode_dev_cycle__benchmark)
- description:
  Benchmarks execution duration and performance metrics for hot mode dev cycle on mokey devices.
  Measures throughput and latency regressions during standard operations.

### [hot_mode_dev_cycle_ios__benchmark](bin/tasks/hot_mode_dev_cycle_ios__benchmark.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhot_mode_dev_cycle_ios__benchmark](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhot_mode_dev_cycle_ios__benchmark)
- description:
  Benchmarks execution duration and performance metrics for hot mode dev cycle ios on arm64 devices.
  Measures throughput and latency regressions during standard operations.

### [hot_mode_dev_cycle_ios_simulator](bin/tasks/hot_mode_dev_cycle_ios_simulator.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying hot mode dev cycle ios simulator behavior and execution on x64 devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [hot_mode_dev_cycle_linux__benchmark](bin/tasks/hot_mode_dev_cycle_linux__benchmark.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhot_mode_dev_cycle_linux__benchmark](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhot_mode_dev_cycle_linux__benchmark)
- description:
  Benchmarks execution duration and performance metrics for hot mode dev cycle linux on mokey devices.
  Measures throughput and latency regressions during standard operations.

### [hot_mode_dev_cycle_linux_target__benchmark](bin/tasks/hot_mode_dev_cycle_linux_target__benchmark.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhot_mode_dev_cycle_linux_target__benchmark](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhot_mode_dev_cycle_linux_target__benchmark)
- description:
  Benchmarks execution duration and performance metrics for hot mode dev cycle linux target on host systems.
  Measures throughput and latency regressions during standard operations.

### [hot_mode_dev_cycle_macos_target__benchmark](bin/tasks/hot_mode_dev_cycle_macos_target__benchmark.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhot_mode_dev_cycle_macos_target__benchmark](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhot_mode_dev_cycle_macos_target__benchmark)
- description:
  Benchmarks execution duration and performance metrics for hot mode dev cycle macos target on arm64 devices.
  Measures throughput and latency regressions during standard operations.

### [hot_mode_dev_cycle_win__benchmark](bin/tasks/hot_mode_dev_cycle_win__benchmark.dart)
- host_platform: windows
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhot_mode_dev_cycle_win__benchmark](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhot_mode_dev_cycle_win__benchmark)
- description:
  Benchmarks execution duration and performance metrics for hot mode dev cycle win on mokey devices.
  Measures throughput and latency regressions during standard operations.

### [hot_mode_dev_cycle_win_target__benchmark](bin/tasks/hot_mode_dev_cycle_win_target__benchmark.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dhot_mode_dev_cycle_win_target__benchmark](https://flutter-flutter-perf.luci.app/e?queries=test%253Dhot_mode_dev_cycle_win_target__benchmark)
- description:
  Benchmarks execution duration and performance metrics for hot mode dev cycle win target on arm64 devices.
  Measures throughput and latency regressions during standard operations.

### [hybrid_android_views_integration_test](bin/tasks/hybrid_android_views_integration_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/hybrid_android_views](../integration_tests/hybrid_android_views)
- benchmarks: None
- description:
  Verifies functionality and correctness of hybrid android views integration on mokey devices.
  Tests integration between framework components and underlying platform APIs.

### [image_list_jit_reported_duration](bin/tasks/image_list_jit_reported_duration.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//examples/image_list](../../examples/image_list)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dimage_list_jit_reported_duration](https://flutter-flutter-perf.luci.app/e?queries=test%253Dimage_list_jit_reported_duration)
- description:
  DeviceLab test verifying image list jit reported duration behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [image_list_reported_duration](bin/tasks/image_list_reported_duration.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//examples/image_list](../../examples/image_list)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dimage_list_reported_duration](https://flutter-flutter-perf.luci.app/e?queries=test%253Dimage_list_reported_duration)
- description:
  DeviceLab test verifying image list reported duration behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [imagefiltered_transform_animation_perf__timeline_summary](bin/tasks/imagefiltered_transform_animation_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dimagefiltered_transform_animation_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dimagefiltered_transform_animation_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for imagefiltered transform animation on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [imagefiltered_transform_animation_perf_ios__timeline_summary](bin/tasks/imagefiltered_transform_animation_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dimagefiltered_transform_animation_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dimagefiltered_transform_animation_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for imagefiltered transform animation ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [imitation_game_flutter__compile](bin/tasks/imitation_game_flutter__compile.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/benchmarks/imitation_game_flutter](../benchmarks/imitation_game_flutter)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dimitation_game_flutter__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dimitation_game_flutter__compile)
- description:
  Measures compile time and application binary metrics for imitation game flutter on arm64.
  Verifies build system performance and output artifact sizing.

### [imitation_game_swiftui__compile](bin/tasks/imitation_game_swiftui__compile.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/benchmarks/imitation_game_swiftui](../benchmarks/imitation_game_swiftui)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dimitation_game_swiftui__compile](https://flutter-flutter-perf.luci.app/e?queries=test%253Dimitation_game_swiftui__compile)
- description:
  Measures compile time and application binary metrics for imitation game swiftui on arm64.
  Verifies build system performance and output artifact sizing.

### [integration_test_test](bin/tasks/integration_test_test.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of integration on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [integration_test_test_ios](bin/tasks/integration_test_test_ios.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of integration ios on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [integration_ui_driver](bin/tasks/integration_ui_driver.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: None
- description:
  DeviceLab test verifying integration ui driver behavior and execution on pixel devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [integration_ui_frame_number](bin/tasks/integration_ui_frame_number.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: None
- description:
  DeviceLab test verifying integration ui frame number behavior and execution on arm64 devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [integration_ui_ios_driver](bin/tasks/integration_ui_ios_driver.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: None
- description:
  DeviceLab test verifying integration ui ios driver behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [integration_ui_ios_frame_number](bin/tasks/integration_ui_ios_frame_number.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: None
- description:
  DeviceLab test verifying integration ui ios frame number behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [integration_ui_ios_keyboard_resize](bin/tasks/integration_ui_ios_keyboard_resize.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dintegration_ui_ios_keyboard_resize](https://flutter-flutter-perf.luci.app/e?queries=test%253Dintegration_ui_ios_keyboard_resize)
- description:
  DeviceLab test verifying integration ui ios keyboard resize behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [integration_ui_ios_screenshot](bin/tasks/integration_ui_ios_screenshot.dart)
- host_platform: linux
- target_platform: ios
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: None
- description:
  DeviceLab test verifying integration ui ios screenshot behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [integration_ui_ios_textfield](bin/tasks/integration_ui_ios_textfield.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: None
- description:
  DeviceLab test verifying integration ui ios textfield behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [integration_ui_keyboard_resize](bin/tasks/integration_ui_keyboard_resize.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dintegration_ui_keyboard_resize](https://flutter-flutter-perf.luci.app/e?queries=test%253Dintegration_ui_keyboard_resize)
- description:
  DeviceLab test verifying integration ui keyboard resize behavior and execution on pixel devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [integration_ui_screenshot](bin/tasks/integration_ui_screenshot.dart)
- host_platform: linux
- target_platform: linux
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: None
- description:
  DeviceLab test verifying integration ui screenshot behavior and execution on host systems.
  Ensures stability and prevents regressions in standard test scenarios.

### [integration_ui_test_test_macos](bin/tasks/integration_ui_test_test_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: None
- description:
  Verifies functionality and correctness of integration ui macos on macos devices.
  Tests integration between framework components and underlying platform APIs.

### [integration_ui_textfield](bin/tasks/integration_ui_textfield.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/ui](../integration_tests/ui)
- benchmarks: None
- description:
  DeviceLab test verifying integration ui textfield behavior and execution on pixel devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [ios_app_with_extensions_test](bin/tasks/ios_app_with_extensions_test.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/ios_app_with_extensions](../integration_tests/ios_app_with_extensions)
- benchmarks: None
- description:
  Verifies functionality and correctness of ios app with extensions on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [ios_debug_workflow](bin/tasks/ios_debug_workflow.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying ios debug workflow behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [ios_defines_test](bin/tasks/ios_defines_test.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of ios defines on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [ios_platform_view_tests](bin/tasks/ios_platform_view_tests.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/ios_platform_view_tests](../integration_tests/ios_platform_view_tests)
- benchmarks: None
- description:
  Verifies functionality and correctness of ios platform views on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [keyboard_hot_restart_ios](bin/tasks/keyboard_hot_restart_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/keyboard_hot_restart](../integration_tests/keyboard_hot_restart)
- benchmarks: None
- description:
  DeviceLab test verifying keyboard hot restart ios behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [large_image_changer_perf_android](bin/tasks/large_image_changer_perf_android.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dlarge_image_changer_perf_android](https://flutter-flutter-perf.luci.app/e?queries=test%253Dlarge_image_changer_perf_android)
- description:
  DeviceLab test verifying large image changer android behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [large_image_changer_perf_ios](bin/tasks/large_image_changer_perf_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dlarge_image_changer_perf_ios](https://flutter-flutter-perf.luci.app/e?queries=test%253Dlarge_image_changer_perf_ios)
- description:
  DeviceLab test verifying large image changer ios behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [linux_chrome_dev_mode](bin/tasks/linux_chrome_dev_mode.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying linux chrome dev mode behavior and execution on pixel devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [linux_desktop_impeller](bin/tasks/linux_desktop_impeller.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying linux desktop impeller behavior and execution on host systems.
  Ensures stability and prevents regressions in standard test scenarios.

### [linux_feature_flags_test](bin/tasks/linux_feature_flags_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of linux feature flags on host systems.
  Tests integration between framework components and underlying platform APIs.

### [list_text_layout_impeller_perf__e2e_summary](bin/tasks/list_text_layout_impeller_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dlist_text_layout_impeller_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dlist_text_layout_impeller_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for list text layout impeller on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [list_text_layout_perf__e2e_summary](bin/tasks/list_text_layout_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dlist_text_layout_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dlist_text_layout_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for list text layout on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [mac_desktop_impeller](bin/tasks/mac_desktop_impeller.dart)
- host_platform: linux
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying mac desktop impeller behavior and execution on macos devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [macos_chrome_dev_mode](bin/tasks/macos_chrome_dev_mode.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying macos chrome dev mode behavior and execution on arm64 devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [microbenchmarks](bin/tasks/microbenchmarks.dart)
- host_platform: macos
- target_platform: android
- dependencies: [//dev/benchmarks/microbenchmarks](../benchmarks/microbenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dmicrobenchmarks](https://flutter-flutter-perf.luci.app/e?queries=test%253Dmicrobenchmarks)
- description:
  DeviceLab test verifying microbenchmarks behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [microbenchmarks_ios](bin/tasks/microbenchmarks_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/microbenchmarks](../benchmarks/microbenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dmicrobenchmarks_ios](https://flutter-flutter-perf.luci.app/e?queries=test%253Dmicrobenchmarks_ios)
- description:
  DeviceLab test verifying microbenchmarks ios behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [module_custom_host_app_name_test](bin/tasks/module_custom_host_app_name_test.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of module custom host app name on host systems.
  Tests integration between framework components and underlying platform APIs.

### [module_host_with_custom_build_test](bin/tasks/module_host_with_custom_build_test.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of module host with custom build on host systems.
  Tests integration between framework components and underlying platform APIs.

### [module_test_ios](bin/tasks/module_test_ios.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of module ios on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [module_uiscene_test_ios](bin/tasks/module_uiscene_test_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of module uiscene ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [multi_widget_construction_perf__e2e_summary](bin/tasks/multi_widget_construction_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dmulti_widget_construction_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dmulti_widget_construction_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for multi widget construction on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [native_assets_android](bin/tasks/native_assets_android.dart)
- host_platform: windows
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying native assets android behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [native_assets_ios](bin/tasks/native_assets_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying native assets ios behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [native_assets_ios_simulator](bin/tasks/native_assets_ios_simulator.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying native assets ios simulator behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [native_platform_view_ui_tests_ios](bin/tasks/native_platform_view_ui_tests_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of native platform view uis ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [native_ui_tests_macos](bin/tasks/native_ui_tests_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of native uis macos on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [new_gallery__crane_perf](bin/tasks/new_gallery__crane_perf.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/new_gallery](../integration_tests/new_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dnew_gallery__crane_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dnew_gallery__crane_perf)
- description:
  DeviceLab test verifying new gallery behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [new_gallery__transition_perf](bin/tasks/new_gallery__transition_perf.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/new_gallery](../integration_tests/new_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dnew_gallery__transition_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dnew_gallery__transition_perf)
- description:
  Benchmarks page transition animation performance for new gallery on pixel devices.
  Measures frame drop rates and build durations during navigation transitions.

### [new_gallery_impeller__transition_perf](bin/tasks/new_gallery_impeller__transition_perf.dart)
- host_platform: linux
- target_platform: galaxy
- dependencies: [//dev/integration_tests/new_gallery](../integration_tests/new_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dnew_gallery_impeller__transition_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dnew_gallery_impeller__transition_perf)
- description:
  Benchmarks page transition animation performance for new gallery impeller on galaxy devices.
  Measures frame drop rates and build durations during navigation transitions.

### [new_gallery_impeller_old_zoom__transition_perf](bin/tasks/new_gallery_impeller_old_zoom__transition_perf.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/new_gallery](../integration_tests/new_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dnew_gallery_impeller_old_zoom__transition_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dnew_gallery_impeller_old_zoom__transition_perf)
- description:
  Benchmarks page transition animation performance for new gallery impeller old zoom on pixel devices.
  Measures frame drop rates and build durations during navigation transitions.

### [new_gallery_ios__transition_perf](bin/tasks/new_gallery_ios__transition_perf.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/new_gallery](../integration_tests/new_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dnew_gallery_ios__transition_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dnew_gallery_ios__transition_perf)
- description:
  Benchmarks page transition animation performance for new gallery ios on ios devices.
  Measures frame drop rates and build durations during navigation transitions.

### [new_gallery_macos_impeller__transition_perf](bin/tasks/new_gallery_macos_impeller__transition_perf.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/new_gallery](../integration_tests/new_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dnew_gallery_macos_impeller__transition_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dnew_gallery_macos_impeller__transition_perf)
- description:
  Benchmarks page transition animation performance for new gallery macos impeller on benchmark devices.
  Measures frame drop rates and build durations during navigation transitions.

### [new_gallery_opengles_impeller__transition_perf](bin/tasks/new_gallery_opengles_impeller__transition_perf.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/new_gallery](../integration_tests/new_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dnew_gallery_opengles_impeller__transition_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dnew_gallery_opengles_impeller__transition_perf)
- description:
  Benchmarks page transition animation performance for new gallery opengles impeller on pixel devices.
  Measures frame drop rates and build durations during navigation transitions.

### [new_gallery_skia_ios__transition_perf](bin/tasks/new_gallery_skia_ios__transition_perf.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/new_gallery](../integration_tests/new_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dnew_gallery_skia_ios__transition_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dnew_gallery_skia_ios__transition_perf)
- description:
  Benchmarks page transition animation performance for new gallery skia ios on ios devices.
  Measures frame drop rates and build durations during navigation transitions.

### [old_gallery__transition_perf](bin/tasks/old_gallery__transition_perf.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/flutter_gallery](../integration_tests/flutter_gallery)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dold_gallery__transition_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dold_gallery__transition_perf)
- description:
  Benchmarks page transition animation performance for old gallery on mokey devices.
  Measures frame drop rates and build durations during navigation transitions.

### [opacity_peephole_col_of_alpha_savelayer_rows_perf__e2e_summary](bin/tasks/opacity_peephole_col_of_alpha_savelayer_rows_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dopacity_peephole_col_of_alpha_savelayer_rows_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dopacity_peephole_col_of_alpha_savelayer_rows_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for opacity peephole col of alpha savelayer rows on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [opacity_peephole_col_of_rows_perf__e2e_summary](bin/tasks/opacity_peephole_col_of_rows_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dopacity_peephole_col_of_rows_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dopacity_peephole_col_of_rows_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for opacity peephole col of rows on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [opacity_peephole_fade_transition_text_perf__e2e_summary](bin/tasks/opacity_peephole_fade_transition_text_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dopacity_peephole_fade_transition_text_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dopacity_peephole_fade_transition_text_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for opacity peephole fade transition text on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [opacity_peephole_grid_of_alpha_savelayers_perf__e2e_summary](bin/tasks/opacity_peephole_grid_of_alpha_savelayers_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dopacity_peephole_grid_of_alpha_savelayers_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dopacity_peephole_grid_of_alpha_savelayers_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for opacity peephole grid of alpha savelayers on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [opacity_peephole_grid_of_opacity_perf__e2e_summary](bin/tasks/opacity_peephole_grid_of_opacity_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dopacity_peephole_grid_of_opacity_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dopacity_peephole_grid_of_opacity_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for opacity peephole grid of opacity on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [opacity_peephole_one_rect_perf__e2e_summary](bin/tasks/opacity_peephole_one_rect_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dopacity_peephole_one_rect_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dopacity_peephole_one_rect_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for opacity peephole one rect on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [opacity_peephole_opacity_of_grid_perf__e2e_summary](bin/tasks/opacity_peephole_opacity_of_grid_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dopacity_peephole_opacity_of_grid_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dopacity_peephole_opacity_of_grid_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for opacity peephole opacity of grid on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [openpay_benchmarks__scroll_perf](bin/tasks/openpay_benchmarks__scroll_perf.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dopenpay_benchmarks__scroll_perf](https://flutter-flutter-perf.luci.app/e?queries=test%253Dopenpay_benchmarks__scroll_perf)
- description:
  DeviceLab test verifying openpay benchmarks behavior and execution on host systems.
  Ensures stability and prevents regressions in standard test scenarios.

### [picture_cache_perf__e2e_summary](bin/tasks/picture_cache_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dpicture_cache_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dpicture_cache_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for picture cache on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [picture_cache_perf__timeline_summary](bin/tasks/picture_cache_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dpicture_cache_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dpicture_cache_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for picture cache on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [platform_channel_sample_test](bin/tasks/platform_channel_sample_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//examples/platform_channel](../../examples/platform_channel)
- benchmarks: None
- description:
  Verifies functionality and correctness of platform channel sample on pixel devices.
  Tests integration between framework components and underlying platform APIs.

### [platform_channel_sample_test_ios](bin/tasks/platform_channel_sample_test_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//examples/platform_channel](../../examples/platform_channel)
- benchmarks: None
- description:
  Verifies functionality and correctness of platform channel sample ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [platform_channel_sample_test_macos](bin/tasks/platform_channel_sample_test_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//examples/platform_channel](../../examples/platform_channel)
- benchmarks: None
- description:
  Verifies functionality and correctness of platform channel sample macos on macos devices.
  Tests integration between framework components and underlying platform APIs.

### [platform_channel_sample_test_swift](bin/tasks/platform_channel_sample_test_swift.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//examples/platform_channel_swift](../../examples/platform_channel_swift)
- benchmarks: None
- description:
  Verifies functionality and correctness of platform channel sample swift on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [platform_channel_sample_test_windows](bin/tasks/platform_channel_sample_test_windows.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//examples/platform_channel](../../examples/platform_channel)
- benchmarks: None
- description:
  Verifies functionality and correctness of platform channel sample windows on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [platform_channels_benchmarks](bin/tasks/platform_channels_benchmarks.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/platform_channels_benchmarks](../benchmarks/platform_channels_benchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_channels_benchmarks](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_channels_benchmarks)
- description:
  DeviceLab test verifying platform channels benchmarks behavior and execution on pixel devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [platform_channels_benchmarks_ios](bin/tasks/platform_channels_benchmarks_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/platform_channels_benchmarks](../benchmarks/platform_channels_benchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_channels_benchmarks_ios](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_channels_benchmarks_ios)
- description:
  DeviceLab test verifying platform channels benchmarks ios behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [platform_interaction_test](bin/tasks/platform_interaction_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/integration_tests/platform_interaction](../integration_tests/platform_interaction)
- benchmarks: None
- description:
  Verifies functionality and correctness of platform interaction on pixel devices.
  Tests integration between framework components and underlying platform APIs.

### [platform_interaction_test_ios](bin/tasks/platform_interaction_test_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/platform_interaction](../integration_tests/platform_interaction)
- benchmarks: None
- description:
  Verifies functionality and correctness of platform interaction ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [platform_view__start_up](bin/tasks/platform_view__start_up.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_view__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_view__start_up)
- description:
  Measures application startup time and initial frame rendering for platform view on mokey devices.
  Tests engine initialization speed and first layout pass duration.

### [platform_view_ios__start_up](bin/tasks/platform_view_ios__start_up.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_view_ios__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_view_ios__start_up)
- description:
  Measures application startup time and initial frame rendering for platform view ios on ios devices.
  Tests engine initialization speed and first layout pass duration.

### [platform_view_macos__start_up](bin/tasks/platform_view_macos__start_up.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_view_macos__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_view_macos__start_up)
- description:
  Measures application startup time and initial frame rendering for platform view macos on benchmark devices.
  Tests engine initialization speed and first layout pass duration.

### [platform_view_macos_impeller__start_up](bin/tasks/platform_view_macos_impeller__start_up.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_view_macos_impeller__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_view_macos_impeller__start_up)
- description:
  Measures application startup time and initial frame rendering for platform view macos impeller on benchmark devices.
  Tests engine initialization speed and first layout pass duration.

### [platform_view_win_desktop__start_up](bin/tasks/platform_view_win_desktop__start_up.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_view_win_desktop__start_up](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_view_win_desktop__start_up)
- description:
  Measures application startup time and initial frame rendering for platform view win desktop on arm64 devices.
  Tests engine initialization speed and first layout pass duration.

### [platform_views_hcpp_scroll_perf__timeline_summary](bin/tasks/platform_views_hcpp_scroll_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_views_hcpp_scroll_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_views_hcpp_scroll_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for platform views hcpp scroll on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [platform_views_scroll_perf__timeline_summary](bin/tasks/platform_views_scroll_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_views_scroll_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_views_scroll_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for platform views scroll on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [platform_views_scroll_perf_ad_banners__timeline_summary](bin/tasks/platform_views_scroll_perf_ad_banners__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_views_scroll_perf_ad_banners__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_views_scroll_perf_ad_banners__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for platform views scroll ad banners on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [platform_views_scroll_perf_bottom_ad_banner__timeline_summary](bin/tasks/platform_views_scroll_perf_bottom_ad_banner__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_views_scroll_perf_bottom_ad_banner__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_views_scroll_perf_bottom_ad_banner__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for platform views scroll bottom ad banner on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [platform_views_scroll_perf_impeller__timeline_summary](bin/tasks/platform_views_scroll_perf_impeller__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_views_scroll_perf_impeller__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_views_scroll_perf_impeller__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for platform views scroll impeller on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [platform_views_scroll_perf_ios__timeline_summary](bin/tasks/platform_views_scroll_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_views_scroll_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_views_scroll_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for platform views scroll ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [platform_views_scroll_perf_non_intersecting_impeller_ios__timeline_summary](bin/tasks/platform_views_scroll_perf_non_intersecting_impeller_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dplatform_views_scroll_perf_non_intersecting_impeller_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dplatform_views_scroll_perf_non_intersecting_impeller_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for platform views scroll non intersecting impeller ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [plugin_dependencies_test](bin/tasks/plugin_dependencies_test.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of plugin dependencies on host systems.
  Tests integration between framework components and underlying platform APIs.

### [plugin_lint_mac](bin/tasks/plugin_lint_mac.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying plugin lint mac behavior and execution on arm64 devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [plugin_test_android_standard](bin/tasks/plugin_test_android_standard.dart)
- host_platform: windows
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of plugin android standard on android devices.
  Tests integration between framework components and underlying platform APIs.

### [plugin_test_android_variants](bin/tasks/plugin_test_android_variants.dart)
- host_platform: windows
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of plugin android variants on android devices.
  Tests integration between framework components and underlying platform APIs.

### [plugin_test_ios](bin/tasks/plugin_test_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of plugin ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [plugin_test_linux](bin/tasks/plugin_test_linux.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of plugin linux on host systems.
  Tests integration between framework components and underlying platform APIs.

### [plugin_test_macos](bin/tasks/plugin_test_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of plugin macos on macos devices.
  Tests integration between framework components and underlying platform APIs.

### [plugin_test_windows](bin/tasks/plugin_test_windows.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of plugin windows on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [post_backdrop_filter_perf_ios__timeline_summary](bin/tasks/post_backdrop_filter_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dpost_backdrop_filter_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dpost_backdrop_filter_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for post backdrop filter ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [route_test_ios](bin/tasks/route_test_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of route ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [routing_test](bin/tasks/routing_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of routing on pixel devices.
  Tests integration between framework components and underlying platform APIs.

### [rrect_blur_perf__timeline_summary](bin/tasks/rrect_blur_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Drrect_blur_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Drrect_blur_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for rrect blur on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [rrect_blur_perf_ios__timeline_summary](bin/tasks/rrect_blur_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Drrect_blur_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Drrect_blur_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for rrect blur ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [run_debug_test_android](bin/tasks/run_debug_test_android.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of run debug android on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [run_debug_test_linux](bin/tasks/run_debug_test_linux.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of run debug linux on host systems.
  Tests integration between framework components and underlying platform APIs.

### [run_debug_test_macos](bin/tasks/run_debug_test_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of run debug macos on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [run_debug_test_windows](bin/tasks/run_debug_test_windows.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of run debug windows on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [run_release_test](bin/tasks/run_release_test.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of run release on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [run_release_test_linux](bin/tasks/run_release_test_linux.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of run release linux on host systems.
  Tests integration between framework components and underlying platform APIs.

### [run_release_test_macos](bin/tasks/run_release_test_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of run release macos on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [run_release_test_windows](bin/tasks/run_release_test_windows.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of run release windows on arm64 devices.
  Tests integration between framework components and underlying platform APIs.

### [service_extensions_test](bin/tasks/service_extensions_test.dart)
- host_platform: linux
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of service extensions on pixel devices.
  Tests integration between framework components and underlying platform APIs.

### [shader_mask_cache_perf__e2e_summary](bin/tasks/shader_mask_cache_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dshader_mask_cache_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dshader_mask_cache_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for shader mask cache on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [simple_animation_perf_ios](bin/tasks/simple_animation_perf_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dsimple_animation_perf_ios](https://flutter-flutter-perf.luci.app/e?queries=test%253Dsimple_animation_perf_ios)
- description:
  DeviceLab test verifying simple animation ios behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [slider_perf_android](bin/tasks/slider_perf_android.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dslider_perf_android](https://flutter-flutter-perf.luci.app/e?queries=test%253Dslider_perf_android)
- description:
  DeviceLab test verifying slider android behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [smoke_test_build_test](bin/tasks/smoke_test_build_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of smoke build on host systems.
  Tests integration between framework components and underlying platform APIs.

### [smoke_test_device](bin/tasks/smoke_test_device.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of smoke device on host systems.
  Tests integration between framework components and underlying platform APIs.

### [smoke_test_failure](bin/tasks/smoke_test_failure.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of smoke failure on host systems.
  Tests integration between framework components and underlying platform APIs.

### [smoke_test_setup_failure](bin/tasks/smoke_test_setup_failure.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of smoke setup failure on host systems.
  Tests integration between framework components and underlying platform APIs.

### [smoke_test_success](bin/tasks/smoke_test_success.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of smoke success on host systems.
  Tests integration between framework components and underlying platform APIs.

### [smoke_test_throws](bin/tasks/smoke_test_throws.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  Verifies functionality and correctness of smoke throws on host systems.
  Tests integration between framework components and underlying platform APIs.

### [spell_check_test](bin/tasks/spell_check_test.dart)
- host_platform: linux
- target_platform: linux
- dependencies: [//dev/integration_tests/spell_check](../integration_tests/spell_check)
- benchmarks: None
- description:
  Verifies functionality and correctness of spell check on host systems.
  Tests integration between framework components and underlying platform APIs.

### [spell_check_test_ios](bin/tasks/spell_check_test_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/spell_check](../integration_tests/spell_check)
- benchmarks: None
- description:
  Verifies functionality and correctness of spell check ios on ios devices.
  Tests integration between framework components and underlying platform APIs.

### [static_path_stroke_tessellation_perf__timeline_summary](bin/tasks/static_path_stroke_tessellation_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dstatic_path_stroke_tessellation_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dstatic_path_stroke_tessellation_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for static path stroke tessellation on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [static_path_stroke_tessellation_perf_ios__timeline_summary](bin/tasks/static_path_stroke_tessellation_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dstatic_path_stroke_tessellation_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dstatic_path_stroke_tessellation_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for static path stroke tessellation ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [static_path_tessellation_perf__timeline_summary](bin/tasks/static_path_tessellation_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dstatic_path_tessellation_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dstatic_path_tessellation_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for static path tessellation on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [static_path_tessellation_perf_ios__timeline_summary](bin/tasks/static_path_tessellation_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dstatic_path_tessellation_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dstatic_path_tessellation_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for static path tessellation ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [technical_debt__cost](bin/tasks/technical_debt__cost.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dtechnical_debt__cost](https://flutter-flutter-perf.luci.app/e?queries=test%253Dtechnical_debt__cost)
- description:
  DeviceLab test verifying technical debt behavior and execution on host systems.
  Ensures stability and prevents regressions in standard test scenarios.

### [textfield_perf__e2e_summary](bin/tasks/textfield_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dtextfield_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dtextfield_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for textfield on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [textfield_perf__timeline_summary](bin/tasks/textfield_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dtextfield_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dtextfield_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for textfield on pixel devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [texture_impeller_linux](bin/tasks/texture_impeller_linux.dart)
- host_platform: linux
- target_platform: linux
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying texture impeller linux behavior and execution on host systems.
  Ensures stability and prevents regressions in standard test scenarios.

### [texture_impeller_windows](bin/tasks/texture_impeller_windows.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying texture impeller windows behavior and execution on windows devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [tiles_scroll_perf__timeline_summary](bin/tasks/tiles_scroll_perf__timeline_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dtiles_scroll_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dtiles_scroll_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for tiles scroll on mokey devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [tiles_scroll_perf_ios__timeline_summary](bin/tasks/tiles_scroll_perf_ios__timeline_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dtiles_scroll_perf_ios__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dtiles_scroll_perf_ios__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for tiles scroll ios on ios devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [very_long_picture_scrolling_perf__e2e_summary](bin/tasks/very_long_picture_scrolling_perf__e2e_summary.dart)
- host_platform: linux
- target_platform: android
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dvery_long_picture_scrolling_perf__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dvery_long_picture_scrolling_perf__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for very long picture scrolling on mokey devices.
  Verifies overall rendering performance and animation frame drops under load.

### [very_long_picture_scrolling_perf_ios__e2e_summary](bin/tasks/very_long_picture_scrolling_perf_ios__e2e_summary.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dvery_long_picture_scrolling_perf_ios__e2e_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dvery_long_picture_scrolling_perf_ios__e2e_summary)
- description:
  End-to-end performance benchmark measuring frame timing and smoothness for very long picture scrolling ios on ios devices.
  Verifies overall rendering performance and animation frame drops under load.

### [web_benchmarks_canvaskit](bin/tasks/web_benchmarks_canvaskit.dart)
- host_platform: linux
- target_platform: web
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dweb_benchmarks_canvaskit](https://flutter-flutter-perf.luci.app/e?queries=test%253Dweb_benchmarks_canvaskit)
- description:
  DeviceLab test verifying web benchmarks canvaskit behavior and execution on web devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [web_benchmarks_ddc](bin/tasks/web_benchmarks_ddc.dart)
- host_platform: linux
- target_platform: web
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dweb_benchmarks_ddc](https://flutter-flutter-perf.luci.app/e?queries=test%253Dweb_benchmarks_ddc)
- description:
  DeviceLab test verifying web benchmarks ddc behavior and execution on web devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [web_benchmarks_ddc_hot_reload](bin/tasks/web_benchmarks_ddc_hot_reload.dart)
- host_platform: linux
- target_platform: web
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dweb_benchmarks_ddc_hot_reload](https://flutter-flutter-perf.luci.app/e?queries=test%253Dweb_benchmarks_ddc_hot_reload)
- description:
  DeviceLab test verifying web benchmarks ddc hot reload behavior and execution on web devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [web_benchmarks_skwasm](bin/tasks/web_benchmarks_skwasm.dart)
- host_platform: linux
- target_platform: web
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dweb_benchmarks_skwasm](https://flutter-flutter-perf.luci.app/e?queries=test%253Dweb_benchmarks_skwasm)
- description:
  DeviceLab test verifying web benchmarks skwasm behavior and execution on web devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [web_benchmarks_skwasm_st](bin/tasks/web_benchmarks_skwasm_st.dart)
- host_platform: linux
- target_platform: web
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dweb_benchmarks_skwasm_st](https://flutter-flutter-perf.luci.app/e?queries=test%253Dweb_benchmarks_skwasm_st)
- description:
  DeviceLab test verifying web benchmarks skwasm st behavior and execution on web devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [web_size__compile_test](bin/tasks/web_size__compile_test.dart)
- host_platform: linux
- target_platform: web
- dependencies: None
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dweb_size__compile_test](https://flutter-flutter-perf.luci.app/e?queries=test%253Dweb_size__compile_test)
- description:
  Measures compile time and application binary metrics for web size on web.
  Verifies build system performance and output artifact sizing.

### [wide_gamut_ios](bin/tasks/wide_gamut_ios.dart)
- host_platform: macos
- target_platform: ios
- dependencies: [//dev/integration_tests/wide_gamut_test](../integration_tests/wide_gamut_test)
- benchmarks: None
- description:
  DeviceLab test verifying wide gamut ios behavior and execution on ios devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [wide_gamut_macos](bin/tasks/wide_gamut_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/wide_gamut_test](../integration_tests/wide_gamut_test)
- benchmarks: None
- description:
  DeviceLab test verifying wide gamut macos behavior and execution on arm64 devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [windowing_test_linux](bin/tasks/windowing_test_linux.dart)
- host_platform: linux
- target_platform: windows
- dependencies: [//dev/integration_tests/windowing_test](../integration_tests/windowing_test)
- benchmarks: None
- description:
  Verifies functionality and correctness of windowing linux on windows devices.
  Tests integration between framework components and underlying platform APIs.

### [windowing_test_macos](bin/tasks/windowing_test_macos.dart)
- host_platform: macos
- target_platform: macos
- dependencies: [//dev/integration_tests/windowing_test](../integration_tests/windowing_test)
- benchmarks: None
- description:
  Verifies functionality and correctness of windowing macos on macos devices.
  Tests integration between framework components and underlying platform APIs.

### [windowing_test_windows](bin/tasks/windowing_test_windows.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//dev/integration_tests/windowing_test](../integration_tests/windowing_test)
- benchmarks: None
- description:
  Verifies functionality and correctness of windowing windows on windows devices.
  Tests integration between framework components and underlying platform APIs.

### [windows_chrome_dev_mode](bin/tasks/windows_chrome_dev_mode.dart)
- host_platform: windows
- target_platform: android
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying windows chrome dev mode behavior and execution on mokey devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [windows_desktop_impeller](bin/tasks/windows_desktop_impeller.dart)
- host_platform: windows
- target_platform: windows
- dependencies: None
- benchmarks: None
- description:
  DeviceLab test verifying windows desktop impeller behavior and execution on windows devices.
  Ensures stability and prevents regressions in standard test scenarios.

### [windows_home_scroll_perf__timeline_summary](bin/tasks/windows_home_scroll_perf__timeline_summary.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//dev/benchmarks/macrobenchmarks](../benchmarks/macrobenchmarks)
- benchmarks: [https://flutter-flutter-perf.luci.app/e?queries=test%3Dwindows_home_scroll_perf__timeline_summary](https://flutter-flutter-perf.luci.app/e?queries=test%253Dwindows_home_scroll_perf__timeline_summary)
- description:
  Benchmarks frame render times and timeline GPU metrics for windows home scroll on arm64 devices.
  Measures rasterization smoothness and UI thread synchronization duration.

### [windows_startup_test](bin/tasks/windows_startup_test.dart)
- host_platform: windows
- target_platform: windows
- dependencies: [//dev/integration_tests/windows_startup_test](../integration_tests/windows_startup_test)
- benchmarks: None
- description:
  Verifies functionality and correctness of windows startup on arm64 devices.
  Tests integration between framework components and underlying platform APIs.
