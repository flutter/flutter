# This file is automatically processed to create .DEPS.git which is the file
# that gclient uses under git.
#
# See http://code.google.com/p/chromium/wiki/UsingGit
#
# To test manually, run:
#   python tools/deps2git/deps2git.py -o .DEPS.git -w <gclientdir>
# where <gcliendir> is the absolute path to the directory containing the
# .gclient file (the parent of 'src').
#
# Then commit .DEPS.git locally (gclient doesn't like dirty trees) and run
#   gclient sync
# Verify the thing happened you wanted. Then revert your .DEPS.git change
# DO NOT CHECK IN CHANGES TO .DEPS.git upstream. It will be automatically
# updated by a bot when you modify this one.
#
# When adding a new dependency, please update the top-level .gitignore file
# to list the dependency's destination directory.

vars = {
  'chromium_git': 'https://chromium.googlesource.com',
  'dart_git': 'https://dart.googlesource.com',
  'fuchsia_git': 'https://fuchsia.googlesource.com',
  'github_git': 'https://github.com',
  'skia_git': 'https://skia.googlesource.com',
  'skia_revision': '03588412c89899fba09893e1812866f0069fc6f6',

  # When updating the Dart revision, ensure that all entries that are
  # dependencies of Dart are also updated to match the entries in the
  # Dart SDK's DEPS file for that revision of Dart. The DEPS file for
  # Dart is: https://github.com/dart-lang/sdk/blob/master/DEPS.
  # You can use //tools/dart/create_updated_flutter_deps.py to produce
  # updated revision list of existing dependencies.
  'dart_revision': 'e7b7b68ef6e7b1e5df379b628134764c489901dc',

  'dart_args_tag': '0.13.7',
  'dart_async_tag': '2.0.0',
  'dart_barback_tag': '0.15.2+13',
  'dart_bazel_worker_tag': 'v0.1.4',
  'dart_boolean_selector_tag': '1.0.2',
  'dart_boringssl_gen_rev': 'd2b56d1b7657e52eb5a1f075968c773aa3e53614',
  'dart_boringssl_rev': 'd519bf6be0b447fb80fbc539d4bff4479b5482a2',
  'dart_charcode_tag': 'v1.1.1',
  'dart_cli_util_tag': '0.1.2+1',
  'dart_collection_tag': '1.14.3',
  'dart_convert_tag': '2.0.1',
  'dart_crypto_tag': '2.0.2+1',
  'dart_csslib_tag': '0.14.1',
  'dart_dart2js_info_tag': '0.5.5+1',
  'dart_dart_style_tag': '1.0.7',
  'dart_dartdoc_tag': 'v0.14.1',
  'dart_fixnum_tag': '0.10.5',
  'dart_glob_tag': '1.1.5',
  'dart_html_tag': '0.13.2',
  'dart_http_multi_server_tag': '2.0.4',
  'dart_http_parser_tag': '3.1.1',
  'dart_http_tag': '0.11.3+14',
  'dart_http_throttle_tag': '1.0.1',
  'dart_intl_tag': '0.15.2',
  'dart_isolate_tag': '1.1.0',
  'dart_json_rpc_2_tag': '2.0.4',
  'dart_linter_tag': '0.1.40',
  'dart_logging_tag': '0.11.3+1',
  'dart_markdown_tag': '0.11.4',
  'dart_matcher_tag': '0.12.1+4',
  'dart_mime_tag': '0.9.4',
  'dart_mockito_tag': '2.0.2',
  'dart_mustache4dart_tag': 'v1.1.0',
  'dart_oauth2_tag': '1.1.0',
  'dart_observatory_pub_packages_rev': '4c282bb240b68f407c8c7779a65c68eeb0139dc6',
  'dart_package_config_tag': '1.0.3',
  'dart_package_resolver_tag': '1.0.2+1',
  'dart_path_tag': '1.4.2',
  'dart_plugin_tag': '0.2.0',
  'dart_pool_tag': '1.3.3',
  'dart_protobuf_tag': '0.5.4',
  'dart_pub_rev': 'cde958f157d3662bf968bcbed05580d5c0355e89',
  'dart_pub_semver_tag': '1.3.2',
  'dart_quiver_tag': '0.25.0',
  'dart_resource_rev': 'af5a5bf65511943398146cf146e466e5f0b95cb9',
  'dart_root_certificates_rev': 'a4c7c6f23a664a37bc1b6f15a819e3f2a292791a',
  'dart_shelf_packages_handler_tag': '1.0.3',
  'dart_shelf_static_tag': '0.2.5',
  'dart_shelf_tag': '0.6.8',
  'dart_shelf_web_socket_tag': '0.2.1',
  'dart_source_map_stack_trace_tag': '1.1.4',
  'dart_source_maps_tag': '0.10.4',
  'dart_source_span_tag': '1.4.0',
  'dart_stack_trace_tag': '1.8.2',
  'dart_stream_channel_tag': '1.6.2',
  'dart_string_scanner_tag': '1.0.2',
  'dart_test_tag': '0.12.24+6',
  'dart_tuple_tag': 'v1.0.1',
  'dart_typed_data_tag': '1.1.3',
  'dart_usage_tag': '3.3.0',
  'dart_utf_tag': '0.9.0+3',
  'dart_watcher_tag': '0.9.7+4',
  'dart_web_socket_channel_tag': '1.0.6',
  'dart_yaml_tag': '2.1.12',

  # Build bot tooling for iOS
  'ios_tools_revision': '69b7c1b160e7107a6a98d948363772dc9caea46f',

  'buildtools_revision': '5b8eb38aaf523f0124756454276cd0a5b720c17e',
}

# Only these hosts are allowed for dependencies in this DEPS file.
# If you need to add a new host, contact chrome infrastructure team.
allowed_hosts = [
  'chromium.googlesource.com',
  'fuchsia.googlesource.com',
  'github.com',
  'skia.googlesource.com',
]

deps = {
  'src': 'https://github.com/flutter/buildroot.git' + '@' + '82a50e874d17d810886ec6d782662ab79ebbd921',

   # Fuchsia compatibility
   #
   # The dependencies in this section should match the layout in the Fuchsia gn
   # build. Eventually, we'll manage these dependencies together with Fuchsia
   # and not have to specific specific hashes.

  'src/garnet':
   Var('fuchsia_git') + '/garnet' + '@' + 'b3ba6b6d6ab8ef658278cc43c9f839a8a8d1718e',

  'src/topaz':
   Var('fuchsia_git') + '/topaz' + '@' + '1eb2e77be92ed968223b0cea19fe2108e689dcd5',

  'src/third_party/benchmark':
   Var('fuchsia_git') + '/third_party/benchmark' + '@' + '296537bc48d380adf21567c5d736ab79f5363d22',

  'src/third_party/gtest':
   Var('fuchsia_git') + '/third_party/gtest' + '@' + 'c00f82917331efbbd27124b537e4ccc915a02b72',

  'src/third_party/rapidjson':
   Var('fuchsia_git') + '/third_party/rapidjson' + '@' + '9defbb0209a534ffeb3a2b79d5ee440a77407292',

  'src/third_party/harfbuzz':
   Var('fuchsia_git') + '/third_party/harfbuzz' + '@' + '39b423660aacf916f1cb01f24913f78eaacb3baf',

   # Chromium-style
   #
   # As part of integrating with Fuchsia, we should eventually remove all these
   # Chromium-style dependencies.

  'src/buildtools':
   Var('fuchsia_git') + '/buildtools' + '@' +  Var('buildtools_revision'),

  'src/ios_tools':
   Var('chromium_git') + '/chromium/src/ios.git' + '@' + Var('ios_tools_revision'),

  'src/third_party/icu':
   Var('chromium_git') + '/chromium/deps/icu.git' + '@' + '08cb956852a5ccdba7f9c941728bb833529ba3c6',

  'src/third_party/dart':
   Var('dart_git') + '/sdk.git' + '@' + Var('dart_revision'),

  'src/third_party/boringssl':
   Var('github_git') + '/dart-lang/boringssl_gen.git' + '@' + Var('dart_boringssl_gen_rev'),

  'src/third_party/boringssl/src':
   'https://boringssl.googlesource.com/boringssl.git' + '@' + Var('dart_boringssl_rev'),

  'src/third_party/dart/third_party/observatory_pub_packages':
   Var('chromium_git') + '/external/github.com/dart-lang/observatory_pub_packages' + '@' + Var('dart_observatory_pub_packages_rev'),

  'src/third_party/dart/third_party/pkg/oauth2':
   Var('chromium_git') + '/external/github.com/dart-lang/oauth2' + '@' + Var('dart_oauth2_tag'),

  'src/third_party/dart/third_party/pkg/args':
   Var('chromium_git') + '/external/github.com/dart-lang/args' + '@' + Var('dart_args_tag'),

  'src/third_party/dart/third_party/pkg/async':
   Var('chromium_git') + '/external/github.com/dart-lang/async' + '@' +   Var('dart_async_tag'),

  'src/third_party/dart/third_party/pkg/barback':
   Var('chromium_git') + '/external/github.com/dart-lang/barback' + '@' +   Var('dart_barback_tag'),

  'src/third_party/dart/third_party/pkg/bazel_worker':
   Var('chromium_git') + '/external/github.com/dart-lang/bazel_worker' + '@' +   Var('dart_bazel_worker_tag'),

  'src/third_party/dart/third_party/pkg/boolean_selector':
   Var('chromium_git') + '/external/github.com/dart-lang/boolean_selector' + '@' +   Var('dart_boolean_selector_tag'),

  'src/third_party/dart/third_party/pkg/charcode':
   Var('chromium_git') + '/external/github.com/dart-lang/charcode' + '@' + Var('dart_charcode_tag'),

  'src/third_party/dart/third_party/pkg/cli_util':
   Var('chromium_git') + '/external/github.com/dart-lang/cli_util' + '@' + Var('dart_cli_util_tag'),

  'src/third_party/dart/third_party/pkg/collection':
   Var('chromium_git') + '/external/github.com/dart-lang/collection' + '@' + Var('dart_collection_tag'),

  'src/third_party/dart/third_party/pkg/convert':
   Var('chromium_git') + '/external/github.com/dart-lang/convert' + '@' + Var('dart_convert_tag'),

  'src/third_party/dart/third_party/pkg/crypto':
   Var('chromium_git') + '/external/github.com/dart-lang/crypto' + '@' + Var('dart_crypto_tag'),

  'src/third_party/dart/third_party/pkg/csslib':
   Var('chromium_git') + '/external/github.com/dart-lang/csslib' + '@' + Var('dart_csslib_tag'),

  'src/third_party/dart/third_party/pkg/dart2js_info':
   Var('chromium_git') + '/external/github.com/dart-lang/dart2js_info' + '@' + Var('dart_dart2js_info_tag'),

  'src/third_party/dart/third_party/pkg/dartdoc':
   Var('chromium_git') + '/external/github.com/dart-lang/dartdoc' + '@' + Var('dart_dartdoc_tag'),

  'src/third_party/dart/third_party/pkg/isolate':
   Var('chromium_git') + '/external/github.com/dart-lang/isolate' + '@' + Var('dart_isolate_tag'),

  'src/third_party/dart/third_party/pkg/json_rpc_2':
   Var('chromium_git') + '/external/github.com/dart-lang/json_rpc_2' + '@' + Var('dart_json_rpc_2_tag'),

  'src/third_party/dart/third_party/pkg/intl':
   Var('chromium_git') + '/external/github.com/dart-lang/intl' + '@' + Var('dart_intl_tag'),

  'src/third_party/dart/third_party/pkg/fixnum':
   Var('chromium_git') + '/external/github.com/dart-lang/fixnum' + '@' + Var('dart_fixnum_tag'),

  'src/third_party/dart/third_party/pkg/glob':
   Var('chromium_git') + '/external/github.com/dart-lang/glob' + '@' + Var('dart_glob_tag'),

  'src/third_party/dart/third_party/pkg/html':
   Var('chromium_git') + '/external/github.com/dart-lang/html' + '@' + Var('dart_html_tag'),

  'src/third_party/dart/third_party/pkg/http':
   Var('chromium_git') + '/external/github.com/dart-lang/http' + '@' + Var('dart_http_tag'),

  'src/third_party/dart/third_party/pkg/http_parser':
   Var('chromium_git') + '/external/github.com/dart-lang/http_parser' + '@' + Var('dart_http_parser_tag'),

  'src/third_party/dart/third_party/pkg/http_throttle':
   Var('chromium_git') + '/external/github.com/dart-lang/http_throttle' + '@' + Var('dart_http_throttle_tag'),

  'src/third_party/dart/third_party/pkg/http_multi_server':
   Var('chromium_git') + '/external/github.com/dart-lang/http_multi_server' + '@' + Var('dart_http_multi_server_tag'),

  'src/third_party/dart/third_party/pkg/logging':
   Var('chromium_git') + '/external/github.com/dart-lang/logging' + '@' + Var('dart_logging_tag'),

  'src/third_party/dart/third_party/pkg/linter':
   Var('chromium_git') + '/external/github.com/dart-lang/linter' + '@' + Var('dart_linter_tag'),

  'src/third_party/dart/third_party/pkg/markdown':
   Var('chromium_git') + '/external/github.com/dart-lang/markdown' + '@' + Var('dart_markdown_tag'),

  'src/third_party/dart/third_party/pkg/matcher':
   Var('chromium_git') + '/external/github.com/dart-lang/matcher' + '@' + Var('dart_matcher_tag'),

  'src/third_party/dart/third_party/pkg/mime':
   Var('chromium_git') + '/external/github.com/dart-lang/mime' + '@' + Var('dart_mime_tag'),

  'src/third_party/dart/third_party/pkg/mockito':
   Var('chromium_git') + '/external/github.com/dart-lang/mockito' + '@' + Var('dart_mockito_tag'),

  'src/third_party/dart/third_party/pkg/mustache4dart':
   Var('chromium_git') + '/external/github.com/valotas/mustache4dart' + '@' + Var('dart_mustache4dart_tag'),

  'src/third_party/dart/third_party/pkg_tested/package_config':
   Var('chromium_git') + '/external/github.com/dart-lang/package_config' + '@' + Var('dart_package_config_tag'),

  'src/third_party/dart/third_party/pkg_tested/package_resolver':
   Var('chromium_git') + '/external/github.com/dart-lang/package_resolver' + '@' + Var('dart_package_resolver_tag'),

  'src/third_party/dart/third_party/pkg/path':
   Var('chromium_git') + '/external/github.com/dart-lang/path' + '@' + Var('dart_path_tag'),

  'src/third_party/dart/third_party/pkg/pool':
   Var('chromium_git') + '/external/github.com/dart-lang/pool' + '@' + Var('dart_pool_tag'),

  'src/third_party/dart/third_party/pkg/plugin':
   Var('chromium_git') + '/external/github.com/dart-lang/plugin' + '@' + Var('dart_plugin_tag'),

  'src/third_party/dart/third_party/pkg/protobuf':
   Var('chromium_git') + '/external/github.com/dart-lang/protobuf' + '@' + Var('dart_protobuf_tag'),

  'src/third_party/dart/third_party/pkg/pub_semver':
   Var('chromium_git') + '/external/github.com/dart-lang/pub_semver' + '@' + Var('dart_pub_semver_tag'),

  'src/third_party/dart/third_party/pkg/pub':
   Var('chromium_git') + '/external/github.com/dart-lang/pub' + '@' + Var('dart_pub_rev'),

  'src/third_party/dart/third_party/pkg/quiver':
   Var('chromium_git') + '/external/github.com/google/quiver-dart' + '@' + Var('dart_quiver_tag'),

  'src/third_party/dart/third_party/pkg/resource':
   Var('chromium_git') + '/external/github.com/dart-lang/resource' + '@' + Var('dart_resource_rev'),

  'src/third_party/dart/third_party/pkg/shelf':
   Var('chromium_git') + '/external/github.com/dart-lang/shelf' + '@' + Var('dart_shelf_tag'),

  'src/third_party/dart/third_party/pkg/shelf_packages_handler':
   Var('chromium_git') + '/external/github.com/dart-lang/shelf_packages_handler' + '@' + Var('dart_shelf_packages_handler_tag'),

  'src/third_party/dart/third_party/pkg/shelf_static':
   Var('chromium_git') + '/external/github.com/dart-lang/shelf_static' + '@' + Var('dart_shelf_static_tag'),

  'src/third_party/dart/third_party/pkg/shelf_web_socket':
   Var('chromium_git') + '/external/github.com/dart-lang/shelf_web_socket' + '@' + Var('dart_shelf_web_socket_tag'),

  'src/third_party/dart/third_party/pkg/source_span':
   Var('chromium_git') + '/external/github.com/dart-lang/source_span' + '@' + Var('dart_source_span_tag'),

  'src/third_party/dart/third_party/pkg/source_map_stack_trace':
   Var('chromium_git') + '/external/github.com/dart-lang/source_map_stack_trace' + '@' + Var('dart_source_map_stack_trace_tag'),

  'src/third_party/dart/third_party/pkg/source_maps':
   Var('chromium_git') + '/external/github.com/dart-lang/source_maps' + '@' + Var('dart_source_maps_tag'),

  'src/third_party/dart/third_party/pkg/string_scanner':
   Var('chromium_git') + '/external/github.com/dart-lang/string_scanner' + '@' + Var('dart_string_scanner_tag'),

  'src/third_party/dart/third_party/pkg/stream_channel':
   Var('chromium_git') + '/external/github.com/dart-lang/stream_channel' + '@' + Var('dart_stream_channel_tag'),

  'src/third_party/dart/third_party/pkg/stack_trace':
   Var('chromium_git') + '/external/github.com/dart-lang/stack_trace' + '@' + Var('dart_stack_trace_tag'),

  'src/third_party/dart/third_party/pkg_tested/dart_style':
   Var('chromium_git') + '/external/github.com/dart-lang/dart_style' + '@' + Var('dart_dart_style_tag'),

  'src/third_party/dart/third_party/pkg/typed_data':
   Var('chromium_git') + '/external/github.com/dart-lang/typed_data' + '@' + Var('dart_typed_data_tag'),

  'src/third_party/dart/third_party/pkg/test':
   Var('chromium_git') + '/external/github.com/dart-lang/test' + '@' + Var('dart_test_tag'),

  'src/third_party/dart/third_party/pkg/tuple':
   Var('chromium_git') + '/external/github.com/dart-lang/tuple' + '@' + Var('dart_tuple_tag'),

  'src/third_party/dart/third_party/pkg/utf':
   Var('chromium_git') + '/external/github.com/dart-lang/utf' + '@' + Var('dart_utf_tag'),

  'src/third_party/dart/third_party/pkg/usage':
   Var('chromium_git') + '/external/github.com/dart-lang/usage' + '@' + Var('dart_usage_tag'),

  'src/third_party/dart/third_party/pkg/watcher':
   Var('chromium_git') + '/external/github.com/dart-lang/watcher' + '@' + Var('dart_watcher_tag'),

  'src/third_party/dart/third_party/pkg/web_socket_channel':
   Var('chromium_git') + '/external/github.com/dart-lang/web_socket_channel' + '@' + Var('dart_web_socket_channel_tag'),

  'src/third_party/dart/third_party/pkg/yaml':
   Var('chromium_git') + '/external/github.com/dart-lang/yaml' + '@' + Var('dart_yaml_tag'),

  'src/third_party/colorama/src':
   Var('chromium_git') + '/external/colorama.git' + '@' + '799604a1041e9b3bc5d2789ecbd7e8db2e18e6b8',

  'src/third_party/freetype2':
   Var('fuchsia_git') + '/third_party/freetype2' + '@' + 'e23a030e9b43c648249477fdf7bf5305d2cc8f59',

  'src/third_party/root_certificates':
   Var('chromium_git') + '/external/github.com/dart-lang/root_certificates' + '@' + Var('dart_root_certificates_rev'),

  'src/third_party/skia':
   Var('skia_git') + '/skia.git' + '@' +  Var('skia_revision'),

  'src/third_party/libjpeg-turbo':
   Var('skia_git') + '/third_party/libjpeg-turbo.git' + '@' + 'debddedc75850bcdeb8a57258572f48b802a4bb3',

  'src/third_party/libwebp':
   Var('chromium_git') + '/webm/libwebp.git' + '@' + '0.6.0',

  'src/third_party/gyp':
   Var('chromium_git') + '/external/gyp.git' + '@' + '4801a5331ae62da9769a327f11c4213d32fb0dad',

   # Headers for Vulkan 1.0
   'src/third_party/vulkan':
   Var('github_git') + '/KhronosGroup/Vulkan-Docs.git' + '@' + 'e29c2489e238509c41aeb8c7bce9d669a496344b',

  'src/third_party/pkg/when':
   Var('chromium_git') + '/external/github.com/dart-lang/when' + '@' + '0.2.0',
}

recursedeps = [
  'src/buildtools',
]

hooks = [
  {
    # This clobbers when necessary (based on get_landmines.py). It must be the
    # first hook so that other things that get/generate into the output
    # directory will not subsequently be clobbered.
    'name': 'landmines',
    'pattern': '.',
    'action': [
        'python',
        'src/build/landmines.py',
    ],
  },
  {
    # Update the Windows toolchain if necessary.
    'name': 'win_toolchain',
    'pattern': '.',
    'action': ['python', 'src/build/vs_toolchain.py', 'update'],
  },
  {
    'name': 'download_android_tools',
    'pattern': '.',
    'action': [
        'python',
        'src/tools/android/download_android_tools.py',
    ],
  },
  {
    'name': 'buildtools',
    'pattern': '.',
    'action': [
      'python',
      'src/tools/buildtools/update.py',
    ],
  },
  {
    # Pull dart sdk if needed
    'name': 'dart',
    'pattern': '.',
    'action': ['python', 'src/tools/dart/update.py'],
  },
  {
    # Ensure that we don't accidentally reference any .pyc files whose
    # corresponding .py files have already been deleted.
    'name': 'remove_stale_pyc_files',
    'pattern': 'src/tools/.*\\.py',
    'action': [
        'python',
        'src/tools/remove_stale_pyc_files.py',
        'src/tools',
    ],
  },
  {
    "name": "7zip",
    "pattern": ".",
    "action": [
      "download_from_google_storage",
      "--no_auth",
      "--no_resume",
      "--bucket",
      "dart-dependencies",
      "--platform=win32",
      "--extract",
      "-s",
      "src/third_party/dart/third_party/7zip.tar.gz.sha1",
    ],
  },
]
