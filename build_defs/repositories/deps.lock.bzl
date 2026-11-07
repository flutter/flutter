# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# DO NOT EDIT. Generated from //DEPS by engine/src/flutter/tools/bazel_tools/bin/gen_deps.dart.
# Re-run that tool whenever DEPS changes; CI checks that this file is up to date.

"""Dependency pins mirrored from the repository's DEPS file.

Bazel never runs gclient. During the GN/Bazel transition the trees that
gclient syncs are consumed in place (see the root .bazelignore) and the
pins below let module extensions fetch the same CIPD packages and git
revisions hermetically.

Conditions are gclient expressions kept verbatim. Strings may contain
`{host_os}`-style placeholders for the variables gclient computes per host.
"""

# The `vars` dictionary from DEPS.
VARS = {
    "android_git": "https://android.googlesource.com",
    "build_devtools_from_sources": False,
    "checkout_llvm": False,
    "chromium_git": "https://chromium.googlesource.com",
    "clang_version": "git_revision:07d67299a15ce03b053736e2d31a668ee0576987",
    "dart_ai_rev": "9c96bfe5f091c9451eff5b59c9bffeb2e806b875",
    "dart_binaryen_rev": "a631c1445ced72a905b3303b26f148fc706647dd",
    "dart_boringssl_rev": "95f9e9f22f23f429c441c93d476ea52ee05b25e0",
    "dart_core_rev": "24e09c4c39b64644cbbe2618d971a2f9aeca4082",
    "dart_devtools_rev": "04999fa04267c131211a3e928009239de1b6a774",
    "dart_ecosystem_rev": "f8faabf263f94a7a8508c5e57f1ff3752fa23915",
    "dart_git": "https://dart.googlesource.com",
    "dart_http_rev": "8c0d66acd2385761182d34b48c4c80ca6cfa4513",
    "dart_i18n_rev": "7475ce643ed6210e5e787b310bb5bc24de9a2158",
    "dart_perfetto_rev": "13ce0c9e13b0940d2476cd0cff2301708a9a2e2b",
    "dart_protobuf_rev": "1d52301b3dd61be159c55143c048a745175fead3",
    "dart_pub_rev": "9df389a76385f82c1165c7cf93b78807b5ea8890",
    "dart_revision": "3b174b7217fe09b21da836ea623932b5f041b091",
    "dart_sync_http_rev": "6666fff944221891182e1f80bf56569338164d72",
    "dart_tools_rev": "1579f8d690d28e7e38adf469d35d31a573ed5132",
    "dart_vector_math_rev": "cf3b5db7340d317dd3489e5a35434b408020a852",
    "dart_web_rev": "45166fdeb32174969888d88c0feeea9a5c380036",
    "dart_webdriver_rev": "8e5c611ea242efdc9f597a8a37c38a9c586120ee",
    "dart_webkit_inspection_protocol_rev": "2c255f2a153239d009385774f12eb57e1c3056eb",
    "download_android_deps": "host_os == \"mac\" or (host_os == \"linux\" and host_cpu == \"x64\")",
    "download_bazelisk": False,
    "download_dart_sdk": True,
    "download_emsdk": False,
    "download_esbuild": True,
    "download_fuchsia_deps": "host_os == \"linux\" and host_cpu == \"x64\"",
    "download_fuchsia_sdk": False,
    "download_linux_deps": "host_os == \"linux\"",
    "download_windows_deps": "host_os == \"win\"",
    "esbuild_version": "0.19.5",
    "flutter_git": "https://flutter.googlesource.com",
    "fuchsia_gn_sdk_version": "kFdyRnojbVy0cxvRZueVcnyi4XuxGnAiSK0YOvpzOG8C",
    "fuchsia_sdk_path": "",
    "fuchsia_test_scripts_version": "Jo-ZgQSNDuPsjlZ4sB-U6cItneMqP6YJj0u-a3ne05UC",
    "gcloud_version": "version:3@591.0.0.chromium.4",
    "llvm_git": "https://llvm.googlesource.com",
    "ocmock_rev": "c4ec0e3a7a9f56cfdbd0aa01f4f97bb4b75c5ef8",
    "reclient_version": "re_client_version:0.185.0.db415f21-gomaip",
    "release_candidate": False,
    "run_fuchsia_emu": False,
    "setup_githooks": True,
    "skia_git": "https://skia.googlesource.com",
    "skia_revision": "b11315d0a0963ad29614a966dc8a7bcc4931bd54",
    "upstream_VulkanMemoryAllocator": "https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git",
    "upstream_abseil-cpp": "https://github.com/abseil/abseil-cpp.git",
    "upstream_angle": "https://github.com/google/angle.git",
    "upstream_archive": "https://github.com/brendan-duncan/archive.git",
    "upstream_benchmark": "https://github.com/google/benchmark.git",
    "upstream_boringssl": "https://github.com/openssl/openssl.git",
    "upstream_brotli": "https://github.com/google/brotli.git",
    "upstream_dart_style": "https://github.com/dart-lang/dart_style.git",
    "upstream_dartdoc": "https://github.com/dart-lang/dartdoc.git",
    "upstream_equatable": "https://github.com/felangel/equatable.git",
    "upstream_ffi": "https://github.com/dart-lang/ffi.git",
    "upstream_flatbuffers": "https://github.com/google/flatbuffers.git",
    "upstream_freetype2": "https://gitlab.freedesktop.org/freetype/freetype.git",
    "upstream_gcloud": "https://github.com/dart-lang/gcloud.git",
    "upstream_glfw": "https://github.com/glfw/glfw.git",
    "upstream_googleapis": "https://github.com/google/googleapis.dart.git",
    "upstream_googletest": "https://github.com/google/googletest.git",
    "upstream_gtest-parallel": "https://github.com/google/gtest-parallel.git",
    "upstream_harfbuzz": "https://github.com/harfbuzz/harfbuzz.git",
    "upstream_http": "https://github.com/dart-lang/http.git",
    "upstream_icu": "https://github.com/unicode-org/icu.git",
    "upstream_imgui": "https://github.com/ocornut/imgui.git",
    "upstream_inja": "https://github.com/pantor/inja.git",
    "upstream_json": "https://github.com/nlohmann/json.git",
    "upstream_leak_tracker": "https://github.com/dart-lang/leak_tracker.git",
    "upstream_libcxx": "https://github.com/llvm-mirror/libcxx.git",
    "upstream_libcxxabi": "https://github.com/llvm-mirror/libcxxabi.git",
    "upstream_libexpat": "https://github.com/libexpat/libexpat.git",
    "upstream_libjpeg-turbo": "https://github.com/libjpeg-turbo/libjpeg-turbo.git",
    "upstream_libpng": "https://github.com/glennrp/libpng.git",
    "upstream_libtess2": "https://github.com/memononen/libtess2.git",
    "upstream_libwebp": "https://chromium.googlesource.com/webm/libwebp.git",
    "upstream_mockito": "https://github.com/dart-lang/mockito.git",
    "upstream_ocmock": "https://github.com/erikdoe/ocmock.git",
    "upstream_packages": "https://github.com/flutter/packages.git",
    "upstream_process": "https://github.com/google/process.dart.git",
    "upstream_process_runner": "https://github.com/google/process_runner.git",
    "upstream_protobuf": "https://github.com/google/protobuf.dart.git",
    "upstream_pub": "https://github.com/dart-lang/pub.git",
    "upstream_pub_semver": "https://github.com/dart-lang/pub_semver.git",
    "upstream_pyyaml": "https://github.com/yaml/pyyaml.git",
    "upstream_quiver-dart": "https://github.com/google/quiver-dart.git",
    "upstream_rapidjson": "https://github.com/Tencent/rapidjson.git",
    "upstream_sdk": "https://github.com/dart-lang/sdk.git",
    "upstream_shaderc": "https://github.com/google/shaderc.git",
    "upstream_shelf": "https://github.com/dart-lang/shelf.git",
    "upstream_skia": "https://skia.googlesource.com/skia.git",
    "upstream_sqlite": "https://github.com/sqlite/sqlite.git",
    "upstream_tar": "https://github.com/simolus3/tar.git",
    "upstream_test": "https://github.com/dart-lang/test.git",
    "upstream_usage": "https://github.com/dart-lang/usage.git",
    "upstream_vector_math": "https://github.com/google/vector_math.dart.git",
    "upstream_webdev": "https://github.com/dart-lang/webdev.git",
    "upstream_webkit_inspection_protocol": "https://github.com/google/webkit_inspection_protocol.dart.git",
    "upstream_wuffs-mirror-release-c": "https://github.com/google/wuffs-mirror-release-c.git",
    "upstream_yapf": "https://github.com/google/yapf.git",
    "upstream_zlib": "https://github.com/madler/zlib.git",
    "use_rbe": False,
}

# Git dependencies keyed by checkout path relative to the repository root.
GIT_DEPS = {
    "engine/src/flutter/prebuilts/emsdk": {
        "url": "https://skia.googlesource.com/external/github.com/emscripten-core/emsdk.git",
        "revision": "2514ec738de72cebbba7f4fdba0cf2fabcb779a5",
        "condition": "download_emsdk",
    },
    "engine/src/flutter/third_party/ai": {
        "url": "https://dart.googlesource.com/ai.git",
        "revision": "9c96bfe5f091c9451eff5b59c9bffeb2e806b875",
    },
    "engine/src/flutter/third_party/angle": {
        "url": "https://flutter.googlesource.com/third_party/angle",
        "revision": "a8d74ca3e5e9e4ffa241330ceedcbe302443e472",
    },
    "engine/src/flutter/third_party/benchmark": {
        "url": "https://chromium.googlesource.com/external/github.com/google/benchmark",
        "revision": "431abd149fd76a072f821913c0340137cc755f36",
    },
    "engine/src/flutter/third_party/boringssl/src": {
        "url": "https://boringssl.googlesource.com/boringssl.git",
        "revision": "95f9e9f22f23f429c441c93d476ea52ee05b25e0",
    },
    "engine/src/flutter/third_party/brotli": {
        "url": "https://skia.googlesource.com/external/github.com/google/brotli.git",
        "revision": "db24a98aed38a16de78cc05ca15cdd8dc2a0d92d",
    },
    "engine/src/flutter/third_party/cpu_features/src": {
        "url": "https://chromium.googlesource.com/external/github.com/google/cpu_features.git",
        "revision": "936b9ab5515dead115606559502e3864958f7f6e",
    },
    "engine/src/flutter/third_party/dart": {
        "url": "https://dart.googlesource.com/sdk.git",
        "revision": "3b174b7217fe09b21da836ea623932b5f041b091",
    },
    "engine/src/flutter/third_party/dart/third_party/binaryen/src": {
        "url": "https://chromium.googlesource.com/external/github.com/WebAssembly/binaryen.git",
        "revision": "a631c1445ced72a905b3303b26f148fc706647dd",
    },
    "engine/src/flutter/third_party/dart/third_party/perfetto/src": {
        "url": "https://chromium.googlesource.com/external/github.com/google/perfetto",
        "revision": "13ce0c9e13b0940d2476cd0cff2301708a9a2e2b",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/core": {
        "url": "https://dart.googlesource.com/core.git",
        "revision": "24e09c4c39b64644cbbe2618d971a2f9aeca4082",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/dart_style": {
        "url": "https://dart.googlesource.com/dart_style.git",
        "revision": "76978d23bfb3d225c81ce3f119ab7055a2a57136",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/dartdoc": {
        "url": "https://dart.googlesource.com/dartdoc.git",
        "revision": "db94437c1e4246571ca32ab27cb43cca2307c93e",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/ecosystem": {
        "url": "https://dart.googlesource.com/ecosystem.git",
        "revision": "f8faabf263f94a7a8508c5e57f1ff3752fa23915",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/http": {
        "url": "https://dart.googlesource.com/http.git",
        "revision": "8c0d66acd2385761182d34b48c4c80ca6cfa4513",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/i18n": {
        "url": "https://dart.googlesource.com/i18n.git",
        "revision": "7475ce643ed6210e5e787b310bb5bc24de9a2158",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/leak_tracker": {
        "url": "https://dart.googlesource.com/leak_tracker.git",
        "revision": "f5620600a5ce1c44f65ddaa02001e200b096e14c",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/native": {
        "url": "https://dart.googlesource.com/native.git",
        "revision": "e0ca7c60ffa6fe7377b26712569e9535c28f90ed",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/protobuf": {
        "url": "https://dart.googlesource.com/protobuf.git",
        "revision": "1d52301b3dd61be159c55143c048a745175fead3",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/pub": {
        "url": "https://dart.googlesource.com/pub.git",
        "revision": "9df389a76385f82c1165c7cf93b78807b5ea8890",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/shelf": {
        "url": "https://dart.googlesource.com/shelf.git",
        "revision": "9946de555f1eb3abd8ae5054848b9c3c2bd36e4d",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/sync_http": {
        "url": "https://dart.googlesource.com/sync_http.git",
        "revision": "6666fff944221891182e1f80bf56569338164d72",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/tar": {
        "url": "https://dart.googlesource.com/external/github.com/simolus3/tar.git",
        "revision": "201952a191be34a993f4ae182612c891ea4ef0a2",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/test": {
        "url": "https://dart.googlesource.com/test.git",
        "revision": "2a9e01756f42123102a34faf2964130ba7e0f77a",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/tools": {
        "url": "https://dart.googlesource.com/tools.git",
        "revision": "1579f8d690d28e7e38adf469d35d31a573ed5132",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/vector_math": {
        "url": "https://dart.googlesource.com/external/github.com/google/vector_math.dart.git",
        "revision": "cf3b5db7340d317dd3489e5a35434b408020a852",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/web": {
        "url": "https://dart.googlesource.com/web.git",
        "revision": "45166fdeb32174969888d88c0feeea9a5c380036",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/webdriver": {
        "url": "https://dart.googlesource.com/external/github.com/google/webdriver.dart.git",
        "revision": "8e5c611ea242efdc9f597a8a37c38a9c586120ee",
    },
    "engine/src/flutter/third_party/dart/third_party/pkg/webkit_inspection_protocol": {
        "url": "https://dart.googlesource.com/external/github.com/google/webkit_inspection_protocol.dart.git",
        "revision": "2c255f2a153239d009385774f12eb57e1c3056eb",
    },
    "engine/src/flutter/third_party/depot_tools": {
        "url": "https://chromium.googlesource.com/chromium/tools/depot_tools.git",
        "revision": "580b4ff3f5cd0dcaa2eacda28cefe0f45320e8f7",
    },
    "engine/src/flutter/third_party/expat": {
        "url": "https://chromium.googlesource.com/external/github.com/libexpat/libexpat.git",
        "revision": "8e49998f003d693213b538ef765814c7d21abada",
    },
    "engine/src/flutter/third_party/flatbuffers": {
        "url": "https://chromium.googlesource.com/external/github.com/google/flatbuffers",
        "revision": "067bfdbde9b10c1beb5d6b02d67ae9db8b96f736",
    },
    "engine/src/flutter/third_party/freetype2": {
        "url": "https://flutter.googlesource.com/third_party/freetype2",
        "revision": "db7276fd53cda30c7f0fcd6b11e2e8f43b4b5e82",
    },
    "engine/src/flutter/third_party/glfw": {
        "url": "https://flutter.googlesource.com/third_party/glfw",
        "revision": "9352d8fe93cd443be18157abe81f16500549aec0",
    },
    "engine/src/flutter/third_party/googletest": {
        "url": "https://chromium.googlesource.com/external/github.com/google/googletest",
        "revision": "e9907112b47255d50b4d343e7e2160bce8dc85d1",
    },
    "engine/src/flutter/third_party/gtest-parallel": {
        "url": "https://chromium.googlesource.com/external/github.com/google/gtest-parallel",
        "revision": "38191e2733d7cbaeaef6a3f1a942ddeb38a2ad14",
    },
    "engine/src/flutter/third_party/harfbuzz": {
        "url": "https://flutter.googlesource.com/third_party/harfbuzz",
        "revision": "49844c32a7a3f6be371355a1213c952a3f4a44e7",
    },
    "engine/src/flutter/third_party/icu": {
        "url": "https://chromium.googlesource.com/chromium/deps/icu.git",
        "revision": "a0ea93436c528ca316a6e698e483e258839101a5",
    },
    "engine/src/flutter/third_party/imgui": {
        "url": "https://flutter.googlesource.com/third_party/imgui.git",
        "revision": "2a1b69f05748ad909f03acf4533447cac1331611",
    },
    "engine/src/flutter/third_party/inja": {
        "url": "https://flutter.googlesource.com/third_party/inja",
        "revision": "88bd6112575a80d004e551c98cf956f88ff4d445",
    },
    "engine/src/flutter/third_party/json": {
        "url": "https://flutter.googlesource.com/third_party/json.git",
        "revision": "17d9eacd248f58b73f4d1be518ef649fe2295642",
    },
    "engine/src/flutter/third_party/libcxx": {
        "url": "https://llvm.googlesource.com/llvm-project/libcxx",
        "revision": "bd557f6f764d1e40b62528a13b124ce740624f8f",
    },
    "engine/src/flutter/third_party/libcxxabi": {
        "url": "https://llvm.googlesource.com/llvm-project/libcxxabi",
        "revision": "a4dda1589d37a7e4b4f7a81ebad01b1083f2e726",
    },
    "engine/src/flutter/third_party/libjpeg-turbo/src": {
        "url": "https://flutter.googlesource.com/third_party/libjpeg-turbo",
        "revision": "0fb821f3b2e570b2783a94ccd9a2fb1f4916ae9f",
    },
    "engine/src/flutter/third_party/libpng": {
        "url": "https://flutter.googlesource.com/third_party/libpng",
        "revision": "ced6b6c0c1e24716423a417b399d3c7d4623890d",
    },
    "engine/src/flutter/third_party/libtess2": {
        "url": "https://flutter.googlesource.com/third_party/libtess2",
        "revision": "725e5e08ec8751477565f1d603fd7eb9058c277c",
    },
    "engine/src/flutter/third_party/libwebp": {
        "url": "https://chromium.googlesource.com/webm/libwebp.git",
        "revision": "ca332209cb5567c9b249c86788cb2dbf8847e760",
    },
    "engine/src/flutter/third_party/llvm_libc": {
        "url": "https://llvm.googlesource.com/llvm-project/libc",
        "revision": "5af39a19a1ad51ce93972cdab206dcd3ff9b6afa",
    },
    "engine/src/flutter/third_party/ocmock": {
        "url": "https://flutter.googlesource.com/third_party/ocmock",
        "revision": "c4ec0e3a7a9f56cfdbd0aa01f4f97bb4b75c5ef8",
    },
    "engine/src/flutter/third_party/pkg/archive": {
        "url": "https://chromium.googlesource.com/external/github.com/brendan-duncan/archive.git",
        "revision": "f1d164f8f5d8aea0be620a9b1e8d300b75a29388",
    },
    "engine/src/flutter/third_party/pkg/equatable": {
        "url": "https://flutter.googlesource.com/third_party/equatable.git",
        "revision": "2117551ff3054f8edb1a58f63ffe1832a8d25623",
    },
    "engine/src/flutter/third_party/pkg/flutter_packages": {
        "url": "https://flutter.googlesource.com/mirrors/packages",
        "revision": "25454e63851fe7933f04d025606e68c1eac4fe0f",
    },
    "engine/src/flutter/third_party/pkg/gcloud": {
        "url": "https://flutter.googlesource.com/third_party/gcloud.git",
        "revision": "a5276b85c4714378e84b1fb478b8feeeb686ac26",
    },
    "engine/src/flutter/third_party/pkg/googleapis": {
        "url": "https://flutter.googlesource.com/third_party/googleapis.dart.git",
        "revision": "526011f56d98eab183cc6075ee1392e8303e43e2",
    },
    "engine/src/flutter/third_party/pkg/io": {
        "url": "https://flutter.googlesource.com/third_party/io.git",
        "revision": "997a6243aad20af4238147d9ec00bf638b9169af",
    },
    "engine/src/flutter/third_party/pkg/node_preamble": {
        "url": "https://flutter.googlesource.com/third_party/node_preamble.dart.git",
        "revision": "47245865175929ec452d8058e563c267b64c3d64",
    },
    "engine/src/flutter/third_party/pkg/process": {
        "url": "https://dart.googlesource.com/process.dart",
        "revision": "0c9aeac86dcc4e3a6cf760b76fed507107e244d5",
    },
    "engine/src/flutter/third_party/pkg/process_runner": {
        "url": "https://flutter.googlesource.com/third_party/process_runner.git",
        "revision": "f24c69efdcaf109168f23d381fa281453d2bc9b1",
    },
    "engine/src/flutter/third_party/pkg/vector_math": {
        "url": "https://dart.googlesource.com/external/github.com/google/vector_math.dart.git",
        "revision": "0a5fd95449083d404df9768bc1b321b88a7d2eef",
    },
    "engine/src/flutter/third_party/pyyaml": {
        "url": "https://flutter.googlesource.com/third_party/pyyaml.git",
        "revision": "03c67afd452cdff45b41bfe65e19a2fb5b80a0e8",
    },
    "engine/src/flutter/third_party/rapidjson": {
        "url": "https://flutter.googlesource.com/third_party/rapidjson",
        "revision": "47253cab97e9cfe99dbd6b90836fc11589d7d802",
    },
    "engine/src/flutter/third_party/re2": {
        "url": "https://chromium.googlesource.com/external/github.com/google/re2",
        "revision": "c84a140c93352cdabbfb547c531be34515b12228",
    },
    "engine/src/flutter/third_party/shaderc": {
        "url": "https://flutter.googlesource.com/third_party/shaderc",
        "revision": "70b1130380fcbf1d1e9719ee78ba7202a5161424",
    },
    "engine/src/flutter/third_party/skia": {
        "url": "https://skia.googlesource.com/skia.git",
        "revision": "b11315d0a0963ad29614a966dc8a7bcc4931bd54",
    },
    "engine/src/flutter/third_party/sqlite": {
        "url": "https://flutter.googlesource.com/third_party/sqlite",
        "revision": "0f61bd2023ba94423b4e4c8cfb1a23de1fe6a21c",
    },
    "engine/src/flutter/third_party/swiftshader": {
        "url": "https://flutter.googlesource.com/third_party/swiftshader.git",
        "revision": "1be9f83618f8ba258431c0c13d7a083eb193df11",
    },
    "engine/src/flutter/third_party/vulkan-deps": {
        "url": "https://chromium.googlesource.com/vulkan-deps",
        "revision": "0582f446e54aa4ea389c89cd027067ee0f5459aa",
    },
    "engine/src/flutter/third_party/vulkan-deps/glslang/src": {
        "url": "https://flutter.googlesource.com/third_party/glslang",
        "revision": "fdbdca9263a4c09dbfb4a51c76e3e9d9f52bc504",
    },
    "engine/src/flutter/third_party/vulkan-deps/lunarg-vulkantools/src": {
        "url": "https://chromium.googlesource.com/external/github.com/LunarG/VulkanTools",
        "revision": "be9744eb74f522c6829c5e8d842cc29dce8259bd",
    },
    "engine/src/flutter/third_party/vulkan-deps/spirv-cross/src": {
        "url": "https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Cross",
        "revision": "b8fcf307f1f347089e3c46eb4451d27f32ebc8d3",
    },
    "engine/src/flutter/third_party/vulkan-deps/spirv-headers/src": {
        "url": "https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Headers",
        "revision": "c63848ecf2200425511319fd8bf2c17b751e501e",
    },
    "engine/src/flutter/third_party/vulkan-deps/spirv-tools/src": {
        "url": "https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Tools",
        "revision": "58fe144fdc8847b303be51d4f8fcc9e7da17056e",
    },
    "engine/src/flutter/third_party/vulkan-deps/vulkan-headers/src": {
        "url": "https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Headers",
        "revision": "0307c70bfbf0646d56a604384b2a91525cefea15",
    },
    "engine/src/flutter/third_party/vulkan-deps/vulkan-loader/src": {
        "url": "https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Loader",
        "revision": "ddaf5c7c2302b07ef2385727c9a54b073ebb563e",
    },
    "engine/src/flutter/third_party/vulkan-deps/vulkan-tools/src": {
        "url": "https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Tools",
        "revision": "b7ae55b37cda76d16368c302f37cb0c7ea2f8409",
    },
    "engine/src/flutter/third_party/vulkan-deps/vulkan-utility-libraries/src": {
        "url": "https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Utility-Libraries",
        "revision": "8183a0b86632bf1107553eab1e69d7b85d455477",
    },
    "engine/src/flutter/third_party/vulkan-deps/vulkan-validation-layers/src": {
        "url": "https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-ValidationLayers",
        "revision": "9a47aeb53821f5fe54b715fa9fc9d74b66077c46",
    },
    "engine/src/flutter/third_party/vulkan_memory_allocator": {
        "url": "https://chromium.googlesource.com/external/github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator",
        "revision": "c788c52156f3ef7bc7ab769cb03c110a53ac8fcb",
    },
    "engine/src/flutter/third_party/wuffs": {
        "url": "https://skia.googlesource.com/external/github.com/google/wuffs-mirror-release-c.git",
        "revision": "600cd96cf47788ee3a74b40a6028b035c9fd6a61",
    },
    "engine/src/flutter/third_party/yapf": {
        "url": "https://flutter.googlesource.com/third_party/yapf",
        "revision": "212c5b5ad8e172d2d914ae454c121c89cccbcb35",
    },
    "engine/src/flutter/third_party/zlib": {
        "url": "https://chromium.googlesource.com/chromium/src/third_party/zlib.git",
        "revision": "9ffe2c6bfb76203167aa15b468050e3d34891562",
    },
    "engine/src/third_party/abseil-cpp": {
        "url": "https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp",
        "revision": "ff6e8ce3e932c16cebd1611c8fc42c45080a0e55",
    },
}

# CIPD dependencies keyed by install path relative to the repository root.
CIPD_DEPS = {
    "engine/src/flutter/build/rbe": {
        "packages": [
            {
                "package": "flutter_internal/rbe/reclient_cfgs",
                "version": "Vk7WiSKwQdBHbCrZ9PtRl3po2WpRFQZSag9M6-sxF_0C",
            },
        ],
        "condition": "use_rbe",
    },
    "engine/src/flutter/buildtools/linux-arm64/clang": {
        "packages": [
            {
                "package": "fuchsia/third_party/clang/linux-arm64",
                "version": "git_revision:07d67299a15ce03b053736e2d31a668ee0576987",
            },
        ],
        "condition": "host_os == \"linux\" and host_cpu == \"arm64\"",
    },
    "engine/src/flutter/buildtools/linux-x64/clang": {
        "packages": [
            {
                "package": "fuchsia/third_party/clang/linux-amd64",
                "version": "git_revision:07d67299a15ce03b053736e2d31a668ee0576987",
            },
        ],
        "condition": "host_os == \"linux\" or host_os == \"mac\"",
    },
    "engine/src/flutter/buildtools/linux-x64/gcloud": {
        "packages": [
            {
                "package": "infra/3pp/tools/gcloud/${platform}",
                "version": "version:3@591.0.0.chromium.4",
            },
        ],
        "condition": "use_rbe and host_os == \"linux\" and host_cpu == \"x64\"",
    },
    "engine/src/flutter/buildtools/linux-x64/reclient": {
        "packages": [
            {
                "package": "infra/rbe/client/${platform}",
                "version": "re_client_version:0.185.0.db415f21-gomaip",
            },
        ],
        "condition": "use_rbe and host_os == \"linux\" and host_cpu == \"x64\"",
    },
    "engine/src/flutter/buildtools/mac-arm64/clang": {
        "packages": [
            {
                "package": "fuchsia/third_party/clang/mac-arm64",
                "version": "git_revision:07d67299a15ce03b053736e2d31a668ee0576987",
            },
        ],
        "condition": "host_os == \"mac\" and host_cpu == \"arm64\"",
    },
    "engine/src/flutter/buildtools/mac-arm64/gcloud": {
        "packages": [
            {
                "package": "infra/3pp/tools/gcloud/${platform}",
                "version": "version:3@591.0.0.chromium.4",
            },
        ],
        "condition": "use_rbe and host_os == \"mac\" and host_cpu == \"arm64\"",
    },
    "engine/src/flutter/buildtools/mac-arm64/reclient": {
        "packages": [
            {
                "package": "infra/rbe/client/${platform}",
                "version": "re_client_version:0.185.0.db415f21-gomaip",
            },
        ],
        "condition": "use_rbe and host_os == \"mac\" and host_cpu == \"arm64\"",
    },
    "engine/src/flutter/buildtools/mac-x64/clang": {
        "packages": [
            {
                "package": "fuchsia/third_party/clang/mac-amd64",
                "version": "git_revision:07d67299a15ce03b053736e2d31a668ee0576987",
            },
        ],
        "condition": "host_os == \"mac\"",
    },
    "engine/src/flutter/buildtools/mac-x64/reclient": {
        "packages": [
            {
                "package": "infra/rbe/client/${platform}",
                "version": "re_client_version:0.185.0.db415f21-gomaip",
            },
        ],
        "condition": "use_rbe and host_os == \"mac\" and host_cpu == \"x64\"",
    },
    "engine/src/flutter/buildtools/windows-x64/clang": {
        "packages": [
            {
                "package": "fuchsia/third_party/clang/windows-amd64",
                "version": "git_revision:07d67299a15ce03b053736e2d31a668ee0576987",
            },
        ],
        "condition": "download_windows_deps",
    },
    "engine/src/flutter/buildtools/windows-x64/reclient": {
        "packages": [
            {
                "package": "infra/rbe/client/${platform}",
                "version": "re_client_version:0.185.0.db415f21-gomaip",
            },
        ],
        "condition": "use_rbe and download_windows_deps",
    },
    "engine/src/flutter/prebuilts/linux-arm64/dart-sdk": {
        "packages": [
            {
                "package": "flutter/dart-sdk/linux-arm64",
                "version": "git_revision:3b174b7217fe09b21da836ea623932b5f041b091",
            },
        ],
        "condition": "host_os == \"linux\" and download_dart_sdk",
    },
    "engine/src/flutter/prebuilts/linux-x64/dart-sdk": {
        "packages": [
            {
                "package": "flutter/dart-sdk/linux-amd64",
                "version": "git_revision:3b174b7217fe09b21da836ea623932b5f041b091",
            },
        ],
        "condition": "host_os == \"linux\" and download_dart_sdk",
    },
    "engine/src/flutter/prebuilts/linux-x64/esbuild": {
        "packages": [
            {
                "package": "flutter/tools/esbuild/linux-amd64",
                "version": "0.19.5",
            },
        ],
        "condition": "host_os == \"linux\" and download_esbuild",
    },
    "engine/src/flutter/prebuilts/macos-arm64/dart-sdk": {
        "packages": [
            {
                "package": "flutter/dart-sdk/mac-arm64",
                "version": "git_revision:3b174b7217fe09b21da836ea623932b5f041b091",
            },
        ],
        "condition": "host_os == \"mac\" and download_dart_sdk",
    },
    "engine/src/flutter/prebuilts/macos-arm64/esbuild": {
        "packages": [
            {
                "package": "flutter/tools/esbuild/mac-arm64",
                "version": "0.19.5",
            },
        ],
        "condition": "host_os == \"mac\" and download_esbuild",
    },
    "engine/src/flutter/prebuilts/macos-x64/dart-sdk": {
        "packages": [
            {
                "package": "flutter/dart-sdk/mac-amd64",
                "version": "git_revision:3b174b7217fe09b21da836ea623932b5f041b091",
            },
        ],
        "condition": "host_os == \"mac\" and download_dart_sdk",
    },
    "engine/src/flutter/prebuilts/macos-x64/esbuild": {
        "packages": [
            {
                "package": "flutter/tools/esbuild/mac-amd64",
                "version": "0.19.5",
            },
        ],
        "condition": "host_os == \"mac\" and download_esbuild",
    },
    "engine/src/flutter/prebuilts/windows-arm64/dart-sdk": {
        "packages": [
            {
                "package": "flutter/dart-sdk/windows-arm64",
                "version": "git_revision:3b174b7217fe09b21da836ea623932b5f041b091",
            },
        ],
        "condition": "host_os == \"win\" and download_dart_sdk",
    },
    "engine/src/flutter/prebuilts/windows-x64/dart-sdk": {
        "packages": [
            {
                "package": "flutter/dart-sdk/windows-amd64",
                "version": "git_revision:3b174b7217fe09b21da836ea623932b5f041b091",
            },
        ],
        "condition": "host_os == \"win\" and download_dart_sdk",
    },
    "engine/src/flutter/prebuilts/windows-x64/esbuild": {
        "packages": [
            {
                "package": "flutter/tools/esbuild/windows-amd64",
                "version": "0.19.5",
            },
        ],
        "condition": "host_os == \"win\" and download_esbuild",
    },
    "engine/src/flutter/third_party/android_embedding_dependencies": {
        "packages": [
            {
                "package": "flutter/android/embedding_bundle",
                "version": "last_updated:2025-10-15T09:53:03-0700",
            },
        ],
        "condition": "download_android_deps",
    },
    "engine/src/flutter/third_party/android_tools": {
        "packages": [
            {
                "package": "flutter/android/sdk/all/${platform}",
                "version": "version:37v2",
            },
        ],
        "condition": "download_android_deps",
    },
    "engine/src/flutter/third_party/android_tools/google-java-format": {
        "packages": [
            {
                "package": "flutter/android/google-java-format",
                "version": "version:1.7-1",
            },
        ],
    },
    "engine/src/flutter/third_party/android_tools/trace_to_text": {
        "packages": [
            {
                "package": "perfetto/trace_to_text/${platform}",
                "version": "git_tag:v25.0",
            },
        ],
        "condition": "download_android_deps",
    },
    "engine/src/flutter/third_party/bazelisk": {
        "packages": [
            {
                "package": "infra/3pp/tools/bazelisk/${platform}",
                "version": "version:3@1.30.0",
            },
        ],
        "condition": "download_bazelisk",
    },
    "engine/src/flutter/third_party/cpython3": {
        "packages": [
            {
                "package": "infra/3pp/tools/cpython3/${platform}",
                "version": "version:3@3.11.9.chromium.38",
            },
        ],
    },
    "engine/src/flutter/third_party/dart/third_party/devtools": {
        "packages": [
            {
                "package": "dart/third_party/flutter/devtools",
                "version": "git_revision:04999fa04267c131211a3e928009239de1b6a774",
            },
        ],
    },
    "engine/src/flutter/third_party/dart/tools/sdks/dart-sdk": {
        "packages": [
            {
                "package": "dart/dart-sdk/${platform}",
                "version": "git_revision:5521341774cb336e5b4c39c9c970dab2cd666854",
            },
        ],
    },
    "engine/src/flutter/third_party/gn": {
        "packages": [
            {
                "package": "gn/gn/${platform}",
                "version": "git_revision:f9eca75ae5549af4a6d4a2e2a912c652590de9da",
            },
        ],
    },
    "engine/src/flutter/third_party/google_fonts_for_unit_tests": {
        "packages": [
            {
                "package": "flutter/flutter_font_fallbacks",
                "version": "eafae0f49fbf9af7858049ad666b7223bdd7588162d8a687ec7870eb5952055d",
            },
        ],
    },
    "engine/src/flutter/third_party/gradle": {
        "packages": [
            {
                "package": "flutter/gradle",
                "version": "version:9.5.0",
            },
        ],
        "condition": "download_android_deps",
    },
    "engine/src/flutter/third_party/java/openjdk": {
        "packages": [
            {
                "package": "flutter/java/openjdk/${platform}",
                "version": "version:25.0.2",
            },
        ],
        "condition": "not (host_os == \"linux\" and host_cpu == \"arm64\")",
    },
    "engine/src/flutter/tools/fuchsia/gn-sdk": {
        "packages": [
            {
                "package": "chromium/fuchsia/gn-sdk",
                "version": "kFdyRnojbVy0cxvRZueVcnyi4XuxGnAiSK0YOvpzOG8C",
            },
        ],
        "condition": "download_fuchsia_deps",
    },
    "engine/src/flutter/tools/fuchsia/test_scripts": {
        "packages": [
            {
                "package": "chromium/fuchsia/test-scripts",
                "version": "Jo-ZgQSNDuPsjlZ4sB-U6cItneMqP6YJj0u-a3ne05UC",
            },
        ],
        "condition": "download_fuchsia_deps",
    },
    "engine/src/third_party/fuchsia-sdk/sdk": {
        "packages": [
            {
                "package": "fuchsia/sdk/core/linux-amd64",
                "version": "KIc0XZbhLmvDpTluZZ-23XdBfPGzo-L2ZH0T-ojFqOYC",
            },
        ],
        "condition": "download_fuchsia_deps and not download_fuchsia_sdk",
    },
    "third_party/ninja": {
        "packages": [
            {
                "package": "infra/3pp/tools/ninja/${platform}",
                "version": "version:2@1.11.1.chromium.4",
            },
        ],
    },
}

# The GN arguments gclient writes to GCLIENT_GN_ARGS_FILE (values in VARS).
GCLIENT_GN_ARGS_FILE = "engine/src/flutter/third_party/dart/build/config/gclient_args.gni"

GCLIENT_GN_ARGS = [
    "checkout_llvm",
    "build_devtools_from_sources",
]
