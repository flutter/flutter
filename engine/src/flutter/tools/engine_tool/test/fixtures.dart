// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String testConfig(String osDimension, String osPlatform,
        {String suffix = ''}) =>
    '''
{
  "builds": [
    {
      "archives": [
        {
          "name": "build_name$suffix",
          "base_path": "base/path",
          "type": "gcs",
          "include_paths": ["include/path"],
          "realm": "archive_realm"
        }
      ],
      "drone_dimensions": [
        "os=$osDimension"
      ],
      "gclient_variables": {
        "variable": false
      },
      "gn": ["--gn-arg", "--lto", "--no-rbe"],
      "name": "ci/build_name$suffix",
      "description": "This is a very long description that will test that the help message is wrapped correctly at an appropriate number of characters.",
      "ninja": {
        "config": "build_name$suffix",
        "targets": ["ninja_target"]
      },
      "tests": [
        {
          "language": "python3",
          "name": "build_name$suffix tests",
          "parameters": ["--test-params"],
          "script": "test/script.py",
          "contexts": ["context"]
        }
      ],
      "generators": {
        "tasks": [
          {
            "name": "generator_task",
            "language": "python",
            "parameters": ["--gen-param"],
            "scripts": ["gen/script.py"]
          }
        ]
      }
    },
    {},
    {},
    {
      "drone_dimensions": [
        "os=$osDimension"
      ],
      "gn": ["--gn-arg", "--lto", "--no-rbe"],
      "name": "$osPlatform/host_debug$suffix",
      "ninja": {
        "config": "host_debug$suffix",
        "targets": ["ninja_target"]
      }
    },
    {
      "drone_dimensions": [
        "os=$osDimension"
      ],
      "gn": ["--gn-arg", "--lto", "--no-rbe"],
      "name": "$osPlatform/android_debug${suffix}_arm64",
      "ninja": {
        "config": "android_debug${suffix}_arm64",
        "targets": ["ninja_target"]
      }
    },
    {
      "drone_dimensions": [
        "os=$osDimension"
      ],
      "gn": ["--gn-arg", "--lto", "--rbe"],
      "name": "ci/android_debug${suffix}_rbe_arm64",
      "ninja": {
        "config": "android_debug${suffix}_rbe_arm64",
        "targets": ["ninja_target"]
      }
    }
  ],
  "generators": {
    "tasks": [
      {
        "name": "global generator task",
        "parameters": ["--global-gen-param"],
        "script": "global/gen_script.dart",
        "language": "dart"
      }
    ]
  },
  "tests": [
    {
      "name": "global test",
      "recipe": "engine_v2/tester_engine",
      "drone_dimensions": [
        "os=$osDimension"
      ],
      "gclient_variables": {
        "variable": false
      },
      "dependencies": ["dependency"],
      "test_dependencies": [
        {
          "dependency": "test_dependency",
          "version": "git_revision:3a77d0b12c697a840ca0c7705208e8622dc94603"
        }
      ],
      "tasks": [
        {
          "name": "global test task",
          "parameters": ["--test-parameter"],
          "script": "global/test/script.py"
        }
      ]
    }
  ]
}
''';

const String configsToTestNamespacing = '''
{
  "builds": [
    {
      "drone_dimensions": [
        "os=Linux"
      ],
      "gn": ["--gn-arg", "--lto", "--no-rbe"],
      "name": "linux/host_debug",
      "ninja": {
        "config": "local_host_debug",
        "targets": ["ninja_target"]
      }
    },
    {
      "drone_dimensions": [
        "os=Linux"
      ],
      "gn": ["--gn-arg", "--lto", "--no-rbe"],
      "name": "ci/host_debug",
      "ninja": {
        "config": "ci/host_debug",
        "targets": ["ninja_target"]
      }
    }
  ]
}
''';

String attachedDevices() => '''
[
  {
    "name": "sdk gphone64 arm64",
    "id": "emulator-5554",
    "isSupported": true,
    "targetPlatform": "android-arm64",
    "emulator": true,
    "sdk": "Android 14 (API 34)",
    "capabilities": {
      "hotReload": true,
      "hotRestart": true,
      "screenshot": true,
      "fastStart": true,
      "flutterExit": true,
      "hardwareRendering": true,
      "startPaused": true
    }
  },
  {
    "name": "macOS",
    "id": "macos",
    "isSupported": true,
    "targetPlatform": "darwin",
    "emulator": false,
    "sdk": "macOS 14.3.1 23D60 darwin-arm64",
    "capabilities": {
      "hotReload": true,
      "hotRestart": true,
      "screenshot": false,
      "fastStart": false,
      "flutterExit": true,
      "hardwareRendering": false,
      "startPaused": true
    }
  },
  {
    "name": "Mac Designed for iPad",
    "id": "mac-designed-for-ipad",
    "isSupported": true,
    "targetPlatform": "darwin",
    "emulator": false,
    "sdk": "macOS 14.3.1 23D60 darwin-arm64",
    "capabilities": {
      "hotReload": true,
      "hotRestart": true,
      "screenshot": false,
      "fastStart": false,
      "flutterExit": true,
      "hardwareRendering": false,
      "startPaused": true
    }
  },
  {
    "name": "Chrome",
    "id": "chrome",
    "isSupported": true,
    "targetPlatform": "web-javascript",
    "emulator": false,
    "sdk": "Google Chrome 122.0.6261.94",
    "capabilities": {
      "hotReload": true,
      "hotRestart": true,
      "screenshot": false,
      "fastStart": false,
      "flutterExit": false,
      "hardwareRendering": false,
      "startPaused": true
    }
  }
]
''';

String gnDescOutput() => '''
{
   "//flutter/display_list:display_list_unittests": {
      "all_dependent_configs": [ "//flutter/skia:fontmgr_mac_ct_public", "//flutter/skia:gpu_public", "//flutter/skia:gpu_shared_public", "//flutter/skia:jpeg_encode_public", "//flutter/skia:png_encode_public", "//flutter/skia:webp_encode_public", "//flutter/skia:jpeg_decode_public", "//flutter/skia:png_decode_public", "//flutter/skia:webp_decode_public", "//flutter/skia:wuffs_public", "//flutter/skia:xml_public" ],
      "allow_circular_includes_from": [  ],
      "asmflags": [ "-fno-strict-aliasing", "-fstack-protector-all", "--target=x86_64-apple-macos", "-arch", "x86_64", "-fcolor-diagnostics" ],
      "cflags": [ "-fno-strict-aliasing", "-fstack-protector-all", "--target=x86_64-apple-macos", "-arch", "x86_64", "-fcolor-diagnostics", "-Wall", "-Wextra", "-Wendif-labels", "-Werror", "-Wno-missing-field-initializers", "-Wno-unused-parameter", "-Wno-unused-but-set-parameter", "-Wno-unused-but-set-variable", "-Wno-implicit-int-float-conversion", "-Wno-deprecated-copy", "-Wno-psabi", "-Wno-deprecated-literal-operator", "-Wno-unqualified-std-cast-call", "-Wno-non-c-typedef-for-linkage", "-Wno-range-loop-construct", "-Wunguarded-availability", "-Wno-deprecated-declarations", "-fvisibility=hidden", "-Wstring-conversion", "-Wnewline-eof", "-O2", "-fno-ident", "-fdata-sections", "-ffunction-sections", "-g2", "-Wunreachable-code", "-Wno-newline-eof" ],
      "cflags_c": [ "-std=c99" ],
      "cflags_cc": [ "-fvisibility-inlines-hidden", "-std=c++17", "-fno-rtti", "-nostdinc++", "-nostdinc++", "-fvisibility=hidden", "-fno-exceptions", "-stdlib=libc++", "-Wno-inconsistent-missing-override" ],
      "cflags_objcc": [ "-fvisibility-inlines-hidden", "-fobjc-call-cxx-cdtors", "-std=c++17", "-fno-rtti", "-nostdinc++", "-nostdinc++", "-fvisibility=hidden", "-fno-exceptions", "-Wno-unguarded-availability" ],
      "check_includes": true,
      "configs": [ "//build/config:feature_flags", "//build/config/compiler:compiler", "//build/config/compiler:cxx_version_default", "//build/config/compiler:compiler_arm_fpu", "//build/config/compiler:chromium_code", "//build/config/compiler:default_include_dirs", "//build/config/compiler:no_rtti", "//build/config/compiler:runtime_library", "//third_party/libcxxabi:libcxxabi_config", "//third_party/libcxx:libcxx_config", "//build/config/gcc:no_exceptions", "//build/config/gcc:symbol_visibility_hidden", "//build/config:symbol_visibility_hidden", "//build/config/mac:sdk", "//build/config/clang:extra_warnings", "//build/config/clang:find_bad_constructs", "//build/config:release", "//build/config/compiler:optimize", "//build/config/compiler:default_optimization", "//build/config/compiler:symbols", "//build/config:default_libs", "//build/config/mac:mac_dynamic_flags", "//build/config/mac:mac_executable_flags", "//flutter/skia:fontmgr_mac_ct_public", "//flutter/skia:gpu_public", "//flutter/skia:gpu_shared_public", "//flutter/skia:jpeg_encode_public", "//flutter/skia:png_encode_public", "//flutter/skia:webp_encode_public", "//flutter/skia:jpeg_decode_public", "//flutter/skia:png_decode_public", "//flutter/skia:webp_decode_public", "//flutter/skia:wuffs_public", "//flutter/skia:xml_public", "//flutter/display_list:display_list_config", "//flutter:config", "//flutter/common:flutter_config", "//flutter/impeller:impeller_public_config", "//flutter/impeller/runtime_stage:runtime_stage_config", "//flutter/third_party/flatbuffers:flatbuffers_public_configs", "//flutter/impeller/renderer:embed_embed_mtl_compute_shaders", "//flutter/impeller/renderer:reflect_reflect_mtl_compute_shaders", "//flutter/impeller/renderer:embed_embed_vk_compute_shaders", "//flutter/skia:skia_public", "//flutter/testing:dynamic_symbols", "//flutter/third_party/googletest:gmock_config", "//flutter/third_party/googletest:gtest_config" ],
      "defines": [ "USE_OPENSSL=1", "__STDC_CONSTANT_MACROS", "__STDC_FORMAT_MACROS", "_FORTIFY_SOURCE=2", "_LIBCPP_DISABLE_AVAILABILITY=1", "_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS", "_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS", "NDEBUG", "NVALGRIND", "DYNAMIC_ANNOTATIONS_ENABLED=0", "SK_TYPEFACE_FACTORY_CORETEXT", "SK_FONTMGR_CORETEXT_AVAILABLE", "SK_GL", "SK_METAL", "SK_CODEC_DECODES_JPEG", "SK_CODEC_DECODES_PNG", "SK_CODEC_DECODES_ICO", "SK_CODEC_DECODES_WEBP", "SK_HAS_WUFFS_LIBRARY", "SK_CODEC_DECODES_GIF", "SK_XML", "FLUTTER_RUNTIME_MODE_DEBUG=1", "FLUTTER_RUNTIME_MODE_PROFILE=2", "FLUTTER_RUNTIME_MODE_RELEASE=3", "FLUTTER_RUNTIME_MODE_JIT_RELEASE=4", "DART_LEGACY_API=[[deprecated]]", "FLUTTER_RUNTIME_MODE=1", "FLUTTER_JIT_RUNTIME=1", "IMPELLER_DEBUG=1", "IMPELLER_ENABLE_CAPTURE=1", "IMPELLER_SUPPORTS_RENDERING=1", "IMPELLER_ENABLE_METAL=1", "IMPELLER_ENABLE_OPENGLES=1", "IMPELLER_ENABLE_VULKAN=1", "SK_CODEC_DECODES_BMP", "SK_CODEC_DECODES_WBMP", "SK_ENABLE_DUMP_GPU", "SK_FORCE_AAA", "SK_LEGACY_IGNORE_DRAW_VERTICES_BLEND_WITH_NO_SHADER", "SK_RESOLVE_FILTERS_BEFORE_RESTORE", "SK_DISABLE_LEGACY_METAL_BACKEND_SURFACE", "SK_DISABLE_LEGACY_SHADERCONTEXT", "SK_DISABLE_LOWP_RASTER_PIPELINE", "SK_FORCE_RASTER_PIPELINE_BLITTER", "SK_METAL_WAIT_UNTIL_SCHEDULED", "SK_DISABLE_EFFECT_DESERIALIZATION", "SK_ENABLE_PRECOMPILE", "SK_GANESH", "SK_USE_PERFETTO" ],
      "deps": [ "//flutter/display_list:display_list", "//flutter/display_list:display_list_fixtures", "//flutter/display_list/testing:display_list_testing", "//flutter/testing:skia", "//flutter/testing:testing", "//third_party/libcxx:libcxx" ],
      "externs": {

      },
      "frameworks": [ "Foundation.framework", "ApplicationServices.framework", "OpenGL.framework", "AppKit.framework", "Metal.framework" ],
      "include_dirs": [ "//", "//out/host_debug/gen/", "//third_party/libcxx/include/", "//third_party/libcxxabi/include/", "//flutter/build/secondary/third_party/libcxx/config/", "//flutter/", "//out/host_debug/gen/flutter/", "//out/host_debug/gen/flutter/impeller/runtime_stage/", "//flutter/third_party/flatbuffers/include/", "//flutter/third_party/skia/", "//flutter/third_party/googletest/googlemock/include/", "//flutter/third_party/googletest/googletest/include/" ],
      "ldflags": [ "--target=x86_64-apple-macos", "-arch", "x86_64", "-nostdlib++", "-Wl,-dead_strip", "-Wl,-search_paths_first", "-L.", "-Wl,-rpath,@loader_path/.", "-Wl,-rpath,/usr/local/lib/.", "-Wl,-rpath,@loader_path/../../..", "-Wl,-pie" ],
      "libs": [ "dl" ],
      "metadata": {

      },
      "outputs": [ "//out/host_debug/display_list_unittests" ],
      "public": "*",
      "sources": [ "//flutter/display_list/benchmarking/dl_complexity_unittests.cc", "//flutter/display_list/display_list_unittests.cc", "//flutter/display_list/dl_color_unittests.cc", "//flutter/display_list/dl_paint_unittests.cc", "//flutter/display_list/dl_vertices_unittests.cc", "//flutter/display_list/effects/dl_color_filter_unittests.cc", "//flutter/display_list/effects/dl_color_source_unittests.cc", "//flutter/display_list/effects/dl_image_filter_unittests.cc", "//flutter/display_list/effects/dl_mask_filter_unittests.cc", "//flutter/display_list/effects/dl_path_effect_unittests.cc", "//flutter/display_list/geometry/dl_region_unittests.cc", "//flutter/display_list/geometry/dl_rtree_unittests.cc", "//flutter/display_list/skia/dl_sk_conversions_unittests.cc", "//flutter/display_list/skia/dl_sk_paint_dispatcher_unittests.cc", "//flutter/display_list/utils/dl_matrix_clip_tracker_unittests.cc" ],
      "testonly": true,
      "toolchain": "//build/toolchain/mac:clang_x64",
      "type": "executable",
      "visibility": [ "*" ]
   },
   "//flutter/flow:flow_unittests": {
      "all_dependent_configs": [ "//flutter/skia:fontmgr_mac_ct_public", "//flutter/skia:gpu_public", "//flutter/skia:gpu_shared_public", "//flutter/skia:jpeg_encode_public", "//flutter/skia:png_encode_public", "//flutter/skia:webp_encode_public", "//flutter/skia:jpeg_decode_public", "//flutter/skia:png_decode_public", "//flutter/skia:webp_decode_public", "//flutter/skia:wuffs_public", "//flutter/skia:xml_public" ],
      "allow_circular_includes_from": [  ],
      "asmflags": [ "-fno-strict-aliasing", "-fstack-protector-all", "--target=x86_64-apple-macos", "-arch", "x86_64", "-fcolor-diagnostics" ],
      "cflags": [ "-fno-strict-aliasing", "-fstack-protector-all", "--target=x86_64-apple-macos", "-arch", "x86_64", "-fcolor-diagnostics", "-Wall", "-Wextra", "-Wendif-labels", "-Werror", "-Wno-missing-field-initializers", "-Wno-unused-parameter", "-Wno-unused-but-set-parameter", "-Wno-unused-but-set-variable", "-Wno-implicit-int-float-conversion", "-Wno-deprecated-copy", "-Wno-psabi", "-Wno-deprecated-literal-operator", "-Wno-unqualified-std-cast-call", "-Wno-non-c-typedef-for-linkage", "-Wno-range-loop-construct", "-Wunguarded-availability", "-Wno-deprecated-declarations", "-fvisibility=hidden", "-Wstring-conversion", "-Wnewline-eof", "-O2", "-fno-ident", "-fdata-sections", "-ffunction-sections", "-g2", "-Wunreachable-code", "-Wno-newline-eof" ],
      "cflags_c": [ "-std=c99" ],
      "cflags_cc": [ "-fvisibility-inlines-hidden", "-std=c++17", "-fno-rtti", "-nostdinc++", "-nostdinc++", "-fvisibility=hidden", "-fno-exceptions", "-stdlib=libc++", "-Wno-inconsistent-missing-override" ],
      "cflags_objcc": [ "-fvisibility-inlines-hidden", "-fobjc-call-cxx-cdtors", "-std=c++17", "-fno-rtti", "-nostdinc++", "-nostdinc++", "-fvisibility=hidden", "-fno-exceptions", "-Wno-unguarded-availability" ],
      "check_includes": true,
      "configs": [ "//build/config:feature_flags", "//build/config/compiler:compiler", "//build/config/compiler:cxx_version_default", "//build/config/compiler:compiler_arm_fpu", "//build/config/compiler:chromium_code", "//build/config/compiler:default_include_dirs", "//build/config/compiler:no_rtti", "//build/config/compiler:runtime_library", "//third_party/libcxxabi:libcxxabi_config", "//third_party/libcxx:libcxx_config", "//build/config/gcc:no_exceptions", "//build/config/gcc:symbol_visibility_hidden", "//build/config:symbol_visibility_hidden", "//build/config/mac:sdk", "//build/config/clang:extra_warnings", "//build/config/clang:find_bad_constructs", "//build/config:release", "//build/config/compiler:optimize", "//build/config/compiler:default_optimization", "//build/config/compiler:symbols", "//build/config:default_libs", "//build/config/mac:mac_dynamic_flags", "//build/config/mac:mac_executable_flags", "//flutter/skia:fontmgr_mac_ct_public", "//flutter/skia:gpu_public", "//flutter/skia:gpu_shared_public", "//flutter/skia:jpeg_encode_public", "//flutter/skia:png_encode_public", "//flutter/skia:webp_encode_public", "//flutter/skia:jpeg_decode_public", "//flutter/skia:png_decode_public", "//flutter/skia:webp_decode_public", "//flutter/skia:wuffs_public", "//flutter/skia:xml_public", "//flutter:config", "//flutter/common:flutter_config", "//flutter/display_list:display_list_config", "//flutter/impeller:impeller_public_config", "//flutter/impeller/runtime_stage:runtime_stage_config", "//flutter/third_party/flatbuffers:flatbuffers_public_configs", "//flutter/impeller/renderer:embed_embed_mtl_compute_shaders", "//flutter/impeller/renderer:reflect_reflect_mtl_compute_shaders", "//flutter/impeller/renderer:embed_embed_vk_compute_shaders", "//flutter/skia:skia_public", "//flutter/third_party/txt:txt_config", "//flutter/third_party/harfbuzz:harfbuzz_config", "//flutter/third_party/icu:icu_config", "//flutter/third_party/googletest:gmock_config", "//flutter/third_party/googletest:gtest_config", "//third_party/dart/runtime:dart_public_config" ],
      "defines": [ "USE_OPENSSL=1", "__STDC_CONSTANT_MACROS", "__STDC_FORMAT_MACROS", "_FORTIFY_SOURCE=2", "_LIBCPP_DISABLE_AVAILABILITY=1", "_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS", "_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS", "NDEBUG", "NVALGRIND", "DYNAMIC_ANNOTATIONS_ENABLED=0", "SK_TYPEFACE_FACTORY_CORETEXT", "SK_FONTMGR_CORETEXT_AVAILABLE", "SK_GL", "SK_METAL", "SK_CODEC_DECODES_JPEG", "SK_CODEC_DECODES_PNG", "SK_CODEC_DECODES_ICO", "SK_CODEC_DECODES_WEBP", "SK_HAS_WUFFS_LIBRARY", "SK_CODEC_DECODES_GIF", "SK_XML", "FLUTTER_RUNTIME_MODE_DEBUG=1", "FLUTTER_RUNTIME_MODE_PROFILE=2", "FLUTTER_RUNTIME_MODE_RELEASE=3", "FLUTTER_RUNTIME_MODE_JIT_RELEASE=4", "DART_LEGACY_API=[[deprecated]]", "FLUTTER_RUNTIME_MODE=1", "FLUTTER_JIT_RUNTIME=1", "IMPELLER_DEBUG=1", "IMPELLER_ENABLE_CAPTURE=1", "IMPELLER_SUPPORTS_RENDERING=1", "IMPELLER_ENABLE_METAL=1", "IMPELLER_ENABLE_OPENGLES=1", "IMPELLER_ENABLE_VULKAN=1", "SK_CODEC_DECODES_BMP", "SK_CODEC_DECODES_WBMP", "SK_ENABLE_DUMP_GPU", "SK_FORCE_AAA", "SK_LEGACY_IGNORE_DRAW_VERTICES_BLEND_WITH_NO_SHADER", "SK_RESOLVE_FILTERS_BEFORE_RESTORE", "SK_DISABLE_LEGACY_METAL_BACKEND_SURFACE", "SK_DISABLE_LEGACY_SHADERCONTEXT", "SK_DISABLE_LOWP_RASTER_PIPELINE", "SK_FORCE_RASTER_PIPELINE_BLITTER", "SK_METAL_WAIT_UNTIL_SCHEDULED", "SK_DISABLE_EFFECT_DESERIALIZATION", "SK_ENABLE_PRECOMPILE", "SK_GANESH", "SK_USE_PERFETTO", "U_USING_ICU_NAMESPACE=0", "U_ENABLE_DYLOAD=0", "USE_CHROMIUM_ICU=1", "U_ENABLE_TRACING=1", "U_ENABLE_RESOURCE_TRACING=0", "U_STATIC_IMPLEMENTATION", "ICU_UTIL_DATA_IMPL=ICU_UTIL_DATA_FILE" ],
      "deps": [ "//flutter/common/graphics:graphics", "//flutter/display_list/testing:display_list_testing", "//flutter/flow:flow", "//flutter/flow:flow_fixtures", "//flutter/flow:flow_testing", "//flutter/fml:fml", "//flutter/shell/common:base64", "//flutter/skia:skia", "//flutter/testing:skia", "//flutter/testing:testing_lib", "//flutter/third_party/googletest:gtest", "//third_party/dart/runtime:libdart_jit", "//third_party/libcxx:libcxx" ],
      "externs": {

      },
      "frameworks": [ "Foundation.framework", "ApplicationServices.framework", "OpenGL.framework", "AppKit.framework", "Metal.framework" ],
      "include_dirs": [ "//", "//out/host_debug/gen/", "//third_party/libcxx/include/", "//third_party/libcxxabi/include/", "//flutter/build/secondary/third_party/libcxx/config/", "//flutter/", "//out/host_debug/gen/flutter/", "//out/host_debug/gen/flutter/impeller/runtime_stage/", "//flutter/third_party/flatbuffers/include/", "//flutter/third_party/skia/", "//flutter/third_party/txt/src/", "//flutter/third_party/harfbuzz/src/", "//flutter/third_party/icu/source/common/", "//flutter/third_party/icu/source/i18n/", "//flutter/third_party/googletest/googlemock/include/", "//flutter/third_party/googletest/googletest/include/", "//third_party/dart/runtime/", "//third_party/dart/runtime/include/" ],
      "ldflags": [ "--target=x86_64-apple-macos", "-arch", "x86_64", "-nostdlib++", "-Wl,-dead_strip", "-Wl,-search_paths_first", "-L.", "-Wl,-rpath,@loader_path/.", "-Wl,-rpath,/usr/local/lib/.", "-Wl,-rpath,@loader_path/../../..", "-Wl,-pie" ],
      "libs": [ "dl", "pthread" ],
      "metadata": {

      },
      "outputs": [ "//out/host_debug/flow_unittests" ],
      "public": "*",
      "sources": [ "//flutter/flow/diff_context_unittests.cc", "//flutter/flow/embedded_view_params_unittests.cc", "//flutter/flow/flow_run_all_unittests.cc", "//flutter/flow/flow_test_utils.cc", "//flutter/flow/flow_test_utils.h", "//flutter/flow/frame_timings_recorder_unittests.cc", "//flutter/flow/gl_context_switch_unittests.cc", "//flutter/flow/layers/backdrop_filter_layer_unittests.cc", "//flutter/flow/layers/checkerboard_layertree_unittests.cc", "//flutter/flow/layers/clip_path_layer_unittests.cc", "//flutter/flow/layers/clip_rect_layer_unittests.cc", "//flutter/flow/layers/clip_rrect_layer_unittests.cc", "//flutter/flow/layers/color_filter_layer_unittests.cc", "//flutter/flow/layers/container_layer_unittests.cc", "//flutter/flow/layers/display_list_layer_unittests.cc", "//flutter/flow/layers/image_filter_layer_unittests.cc", "//flutter/flow/layers/layer_state_stack_unittests.cc", "//flutter/flow/layers/layer_tree_unittests.cc", "//flutter/flow/layers/offscreen_surface_unittests.cc", "//flutter/flow/layers/opacity_layer_unittests.cc", "//flutter/flow/layers/performance_overlay_layer_unittests.cc", "//flutter/flow/layers/platform_view_layer_unittests.cc", "//flutter/flow/layers/shader_mask_layer_unittests.cc", "//flutter/flow/layers/texture_layer_unittests.cc", "//flutter/flow/layers/transform_layer_unittests.cc", "//flutter/flow/mutators_stack_unittests.cc", "//flutter/flow/raster_cache_unittests.cc", "//flutter/flow/skia_gpu_object_unittests.cc", "//flutter/flow/stopwatch_dl_unittests.cc", "//flutter/flow/stopwatch_unittests.cc", "//flutter/flow/surface_frame_unittests.cc", "//flutter/flow/testing/mock_layer_unittests.cc", "//flutter/flow/testing/mock_texture_unittests.cc", "//flutter/flow/texture_unittests.cc" ],
      "testonly": true,
      "toolchain": "//build/toolchain/mac:clang_x64",
      "type": "executable",
      "visibility": [ "*" ]
   },
   "//flutter/fml:fml_arc_unittests": {
      "all_dependent_configs": [ "//flutter/skia:fontmgr_mac_ct_public", "//flutter/skia:gpu_public", "//flutter/skia:gpu_shared_public", "//flutter/skia:jpeg_encode_public", "//flutter/skia:png_encode_public", "//flutter/skia:webp_encode_public", "//flutter/skia:jpeg_decode_public", "//flutter/skia:png_decode_public", "//flutter/skia:webp_decode_public", "//flutter/skia:wuffs_public", "//flutter/skia:xml_public" ],
      "allow_circular_includes_from": [  ],
      "asmflags": [ "-fno-strict-aliasing", "-fstack-protector-all", "--target=x86_64-apple-macos", "-arch", "x86_64", "-fcolor-diagnostics" ],
      "cflags": [ "-fno-strict-aliasing", "-fstack-protector-all", "--target=x86_64-apple-macos", "-arch", "x86_64", "-fcolor-diagnostics", "-Wall", "-Wextra", "-Wendif-labels", "-Werror", "-Wno-missing-field-initializers", "-Wno-unused-parameter", "-Wno-unused-but-set-parameter", "-Wno-unused-but-set-variable", "-Wno-implicit-int-float-conversion", "-Wno-deprecated-copy", "-Wno-psabi", "-Wno-deprecated-literal-operator", "-Wno-unqualified-std-cast-call", "-Wno-non-c-typedef-for-linkage", "-Wno-range-loop-construct", "-Wunguarded-availability", "-Wno-deprecated-declarations", "-fvisibility=hidden", "-Wstring-conversion", "-Wnewline-eof", "-O2", "-fno-ident", "-fdata-sections", "-ffunction-sections", "-g2", "-Wunreachable-code", "-Wno-newline-eof" ],
      "cflags_c": [ "-std=c99" ],
      "cflags_cc": [ "-fvisibility-inlines-hidden", "-std=c++17", "-fno-rtti", "-nostdinc++", "-nostdinc++", "-fvisibility=hidden", "-fno-exceptions", "-stdlib=libc++", "-Wno-inconsistent-missing-override" ],
      "cflags_objcc": [ "-Werror=overriding-method-mismatch", "-Werror=undeclared-selector", "-fapplication-extension", "-fobjc-arc", "-fvisibility-inlines-hidden", "-fobjc-call-cxx-cdtors", "-std=c++17", "-fno-rtti", "-nostdinc++", "-nostdinc++", "-fvisibility=hidden", "-fno-exceptions", "-Wno-unguarded-availability" ],
      "check_includes": true,
      "configs": [ "//build/config:feature_flags", "//build/config/compiler:compiler", "//build/config/compiler:cxx_version_default", "//build/config/compiler:compiler_arm_fpu", "//build/config/compiler:chromium_code", "//build/config/compiler:default_include_dirs", "//build/config/compiler:no_rtti", "//build/config/compiler:runtime_library", "//third_party/libcxxabi:libcxxabi_config", "//third_party/libcxx:libcxx_config", "//build/config/gcc:no_exceptions", "//build/config/gcc:symbol_visibility_hidden", "//build/config:symbol_visibility_hidden", "//build/config/mac:sdk", "//build/config/clang:extra_warnings", "//build/config/clang:find_bad_constructs", "//build/config:release", "//build/config/compiler:optimize", "//build/config/compiler:default_optimization", "//build/config/compiler:symbols", "//build/config:default_libs", "//build/config/mac:mac_dynamic_flags", "//build/config/mac:mac_executable_flags", "//flutter/skia:fontmgr_mac_ct_public", "//flutter/skia:gpu_public", "//flutter/skia:gpu_shared_public", "//flutter/skia:jpeg_encode_public", "//flutter/skia:png_encode_public", "//flutter/skia:webp_encode_public", "//flutter/skia:jpeg_decode_public", "//flutter/skia:png_decode_public", "//flutter/skia:webp_decode_public", "//flutter/skia:wuffs_public", "//flutter/skia:xml_public", "//flutter:config", "//flutter/common:flutter_config", "//flutter/testing:dynamic_symbols", "//flutter/display_list:display_list_config", "//flutter/impeller:impeller_public_config", "//flutter/impeller/runtime_stage:runtime_stage_config", "//flutter/third_party/flatbuffers:flatbuffers_public_configs", "//flutter/impeller/renderer:embed_embed_mtl_compute_shaders", "//flutter/impeller/renderer:reflect_reflect_mtl_compute_shaders", "//flutter/impeller/renderer:embed_embed_vk_compute_shaders", "//flutter/skia:skia_public", "//flutter/third_party/googletest:gmock_config", "//flutter/third_party/googletest:gtest_config" ],
      "defines": [ "USE_OPENSSL=1", "__STDC_CONSTANT_MACROS", "__STDC_FORMAT_MACROS", "_FORTIFY_SOURCE=2", "_LIBCPP_DISABLE_AVAILABILITY=1", "_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS", "_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS", "NDEBUG", "NVALGRIND", "DYNAMIC_ANNOTATIONS_ENABLED=0", "SK_TYPEFACE_FACTORY_CORETEXT", "SK_FONTMGR_CORETEXT_AVAILABLE", "SK_GL", "SK_METAL", "SK_CODEC_DECODES_JPEG", "SK_CODEC_DECODES_PNG", "SK_CODEC_DECODES_ICO", "SK_CODEC_DECODES_WEBP", "SK_HAS_WUFFS_LIBRARY", "SK_CODEC_DECODES_GIF", "SK_XML", "FLUTTER_RUNTIME_MODE_DEBUG=1", "FLUTTER_RUNTIME_MODE_PROFILE=2", "FLUTTER_RUNTIME_MODE_RELEASE=3", "FLUTTER_RUNTIME_MODE_JIT_RELEASE=4", "DART_LEGACY_API=[[deprecated]]", "FLUTTER_RUNTIME_MODE=1", "FLUTTER_JIT_RUNTIME=1", "IMPELLER_DEBUG=1", "IMPELLER_ENABLE_CAPTURE=1", "IMPELLER_SUPPORTS_RENDERING=1", "IMPELLER_ENABLE_METAL=1", "IMPELLER_ENABLE_OPENGLES=1", "IMPELLER_ENABLE_VULKAN=1", "SK_CODEC_DECODES_BMP", "SK_CODEC_DECODES_WBMP", "SK_ENABLE_DUMP_GPU", "SK_FORCE_AAA", "SK_LEGACY_IGNORE_DRAW_VERTICES_BLEND_WITH_NO_SHADER", "SK_RESOLVE_FILTERS_BEFORE_RESTORE", "SK_DISABLE_LEGACY_METAL_BACKEND_SURFACE", "SK_DISABLE_LEGACY_SHADERCONTEXT", "SK_DISABLE_LOWP_RASTER_PIPELINE", "SK_FORCE_RASTER_PIPELINE_BLITTER", "SK_METAL_WAIT_UNTIL_SCHEDULED", "SK_DISABLE_EFFECT_DESERIALIZATION", "SK_ENABLE_PRECOMPILE", "SK_GANESH", "SK_USE_PERFETTO" ],
      "deps": [ "//flutter/fml:fml", "//flutter/fml:fml_fixtures", "//flutter/testing:testing", "//third_party/libcxx:libcxx" ],
      "externs": {

      },
      "frameworks": [ "Foundation.framework", "ApplicationServices.framework", "OpenGL.framework", "AppKit.framework", "Metal.framework" ],
      "include_dirs": [ "//", "//out/host_debug/gen/", "//third_party/libcxx/include/", "//third_party/libcxxabi/include/", "//flutter/build/secondary/third_party/libcxx/config/", "//flutter/", "//out/host_debug/gen/flutter/", "//out/host_debug/gen/flutter/impeller/runtime_stage/", "//flutter/third_party/flatbuffers/include/", "//flutter/third_party/skia/", "//flutter/third_party/googletest/googlemock/include/", "//flutter/third_party/googletest/googletest/include/" ],
      "ldflags": [ "--target=x86_64-apple-macos", "-arch", "x86_64", "-nostdlib++", "-Wl,-dead_strip", "-Wl,-search_paths_first", "-L.", "-Wl,-rpath,@loader_path/.", "-Wl,-rpath,/usr/local/lib/.", "-Wl,-rpath,@loader_path/../../..", "-Wl,-pie" ],
      "libs": [ "dl" ],
      "metadata": {

      },
      "outputs": [ "//out/host_debug/fml_arc_unittests" ],
      "public": "*",
      "sources": [ "//flutter/fml/platform/darwin/scoped_nsobject_arc_unittests.mm", "//flutter/fml/platform/darwin/weak_nsobject_arc_unittests.mm" ],
      "testonly": true,
      "toolchain": "//build/toolchain/mac:clang_x64",
      "type": "executable",
      "visibility": [ "*" ]
   }
}
''';

String gnDescOutputEmpty({required String gnPattern}) => '''
The input $gnPattern matches no targets, configs or files.
''';
