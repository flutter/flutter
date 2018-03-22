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
  'skia_revision': 'abf7b763e2c1ba069942dedec914494817fd27a8',

  # When updating the Dart revision, ensure that all entries that are
  # dependencies of Dart are also updated to match the entries in the
  # Dart SDK's DEPS file for that revision of Dart. The DEPS file for
  # Dart is: https://github.com/dart-lang/sdk/blob/master/DEPS.
  # You can use //tools/dart/create_updated_flutter_deps.py to produce
  # updated revision list of existing dependencies.
  'dart_revision': '95e9e890a996b9a61ade6cc81830dd7cf295ec9d',

  'dart_args_tag': '1.4.1',
  'dart_async_tag': '2.0.6',
  'dart_barback_tag': '0.15.2+14',
  'dart_bazel_worker_tag': 'v0.1.9',
  'dart_boolean_selector_tag': '1.0.3',
  'dart_boringssl_gen_rev': '344f455fd13d46f054726638e76026156ea73aa9',
  'dart_boringssl_rev': '672f6fc2486745d0cabc3aaeb4e0a3cd13b37b12',
  'dart_charcode_tag': 'v1.1.1',
  'dart_cli_util_tag': '0.1.2+1',
  'dart_collection_tag': '1.14.6',
  'dart_convert_tag': '2.0.1',
  'dart_crypto_tag': '2.0.2+1',
  'dart_csslib_tag': '0.14.1',
  'dart_dart2js_info_tag': '0.5.5+1',
  'dart_dart_style_tag': '1.0.10',
  'dart_dartdoc_tag': 'v0.17.1+1',
  'dart_fixnum_tag': '0.10.5',
  'dart_glob_tag': '1.1.5',
  'dart_html_tag': '0.13.3',
  'dart_http_multi_server_tag': '2.0.4',
  'dart_http_parser_tag': '3.1.1',
  'dart_http_retry_tag': '0.1.0',
  'dart_http_tag': '0.11.3+16',
  'dart_http_throttle_tag': '1.0.1',
  'dart_intl_tag': '0.15.2',
  'dart_isolate_tag': '1.1.0',
  'dart_json_rpc_2_tag': '2.0.6',
  'dart_linter_tag': '0.1.45',
  'dart_logging_tag': '0.11.3+1',
  'dart_markdown_tag': '1.1.1',
  'dart_matcher_tag': '0.12.1+4',
  'dart_mime_tag': '0.9.6',
  'dart_mockito_tag': 'a92db054fba18bc2d605be7670aee74b7cadc00a',
  'dart_mustache4dart_tag': 'v2.1.0',
  'dart_oauth2_tag': '1.1.0',
  'dart_observatory_pub_packages_rev': '4c282bb240b68f407c8c7779a65c68eeb0139dc6',
  'dart_package_config_tag': '1.0.3',
  'dart_package_resolver_tag': '1.0.2+1',
  'dart_path_tag': '1.5.1',
  'dart_plugin_tag': '0.2.0+2',
  'dart_pool_tag': '1.3.4',
  'dart_protobuf_tag': '0.7.1',
  'dart_pub_rev': '875d35005a7d33f367d70a3e31e9d3bad5d1ebd8',
  'dart_pub_semver_tag': '1.3.2',
  'dart_quiver_tag': '5aaa3f58c48608af5b027444d561270b53f15dbf',
  'dart_resource_rev': 'af5a5bf65511943398146cf146e466e5f0b95cb9',
  'dart_root_certificates_rev': '16ef64be64c7dfdff2b9f4b910726e635ccc519e',
  'dart_shelf_packages_handler_tag': '1.0.3',
  'dart_shelf_static_rev': 'v0.2.7',
  'dart_shelf_tag': '0.7.2',
  'dart_shelf_web_socket_tag': '0.2.2',
  'dart_source_map_stack_trace_tag': '1.1.4',
  'dart_source_maps_tag': '0.10.4',
  'dart_source_span_tag': '1.4.0',
  'dart_stack_trace_tag': '1.9.2',
  'dart_stream_channel_tag': '1.6.4',
  'dart_string_scanner_tag': '1.0.2',
  'dart_test_tag': '0.12.30+1',
  'dart_tuple_tag': 'v1.0.1',
  'dart_typed_data_tag': '1.1.3',
  'dart_usage_tag': '3.3.0',
  'dart_utf_tag': '0.9.0+4',
  'dart_watcher_tag': '0.9.7+7',
  'dart_web_socket_channel_tag': '1.0.7',
  'dart_yaml_tag': '2.1.13',

  # Build bot tooling for iOS
  'ios_tools_revision': '69b7c1b160e7107a6a98d948363772dc9caea46f',

  'buildtools_revision': 'ae85410691b10aa2469695c2421b1fe751843e64',
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
  'src': 'https://github.com/flutter/buildroot.git' + '@' + '35d44f8c4e20043de7615adf2f1203acb12ad236',

   # Fuchsia compatibility
   #
   # The dependencies in this section should match the layout in the Fuchsia gn
   # build. Eventually, we'll manage these dependencies together with Fuchsia
   # and not have to specific specific hashes.

  'src/garnet':
   Var('fuchsia_git') + '/garnet' + '@' + 'b7492b5f34e32248b164eb48ae8e67995aebda67',

  'src/topaz':
   Var('fuchsia_git') + '/topaz' + '@' + 'e331f910c1003d154a4de6e1b5356f8d785fd6ec',

  'src/third_party/benchmark':
   Var('fuchsia_git') + '/third_party/benchmark' + '@' + '296537bc48d380adf21567c5d736ab79f5363d22',

  'src/third_party/googletest':
   Var('fuchsia_git') + '/third_party/googletest' + '@' + '2072b0053d3537fa5e8d222e34c759987aae1320',

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
   Var('dart_git') + '/observatory_pub_packages.git' + '@' + Var('dart_observatory_pub_packages_rev'),

  'src/third_party/dart/third_party/pkg/oauth2':
   Var('dart_git') + '/oauth2.git' + '@' + Var('dart_oauth2_tag'),

  'src/third_party/dart/third_party/pkg/args':
   Var('dart_git') + '/args.git' + '@' + Var('dart_args_tag'),

  'src/third_party/dart/third_party/pkg/async':
   Var('dart_git') + '/async.git' + '@' +   Var('dart_async_tag'),

  'src/third_party/dart/third_party/pkg/barback':
   Var('dart_git') + '/barback.git' + '@' +   Var('dart_barback_tag'),

  'src/third_party/dart/third_party/pkg/bazel_worker':
   Var('dart_git') + '/bazel_worker.git' + '@' +   Var('dart_bazel_worker_tag'),

  'src/third_party/dart/third_party/pkg/boolean_selector':
   Var('dart_git') + '/boolean_selector.git' + '@' +   Var('dart_boolean_selector_tag'),

  'src/third_party/dart/third_party/pkg/charcode':
   Var('dart_git') + '/charcode.git' + '@' + Var('dart_charcode_tag'),

  'src/third_party/dart/third_party/pkg/cli_util':
   Var('dart_git') + '/cli_util.git' + '@' + Var('dart_cli_util_tag'),

  'src/third_party/dart/third_party/pkg/collection':
   Var('dart_git') + '/collection.git' + '@' + Var('dart_collection_tag'),

  'src/third_party/dart/third_party/pkg/convert':
   Var('dart_git') + '/convert.git' + '@' + Var('dart_convert_tag'),

  'src/third_party/dart/third_party/pkg/crypto':
   Var('dart_git') + '/crypto.git' + '@' + Var('dart_crypto_tag'),

  'src/third_party/dart/third_party/pkg/csslib':
   Var('dart_git') + '/csslib.git' + '@' + Var('dart_csslib_tag'),

  'src/third_party/dart/third_party/pkg/dart2js_info':
   Var('dart_git') + '/dart2js_info.git' + '@' + Var('dart_dart2js_info_tag'),

  'src/third_party/dart/third_party/pkg/dartdoc':
   Var('dart_git') + '/dartdoc.git' + '@' + Var('dart_dartdoc_tag'),

  'src/third_party/dart/third_party/pkg/isolate':
   Var('dart_git') + '/isolate.git' + '@' + Var('dart_isolate_tag'),

  'src/third_party/dart/third_party/pkg/json_rpc_2':
   Var('dart_git') + '/json_rpc_2.git' + '@' + Var('dart_json_rpc_2_tag'),

  'src/third_party/dart/third_party/pkg/intl':
   Var('dart_git') + '/intl.git' + '@' + Var('dart_intl_tag'),

  'src/third_party/dart/third_party/pkg/fixnum':
   Var('dart_git') + '/fixnum.git' + '@' + Var('dart_fixnum_tag'),

  'src/third_party/dart/third_party/pkg/glob':
   Var('dart_git') + '/glob.git' + '@' + Var('dart_glob_tag'),

  'src/third_party/dart/third_party/pkg/html':
   Var('dart_git') + '/html.git' + '@' + Var('dart_html_tag'),

  'src/third_party/dart/third_party/pkg/http':
   Var('dart_git') + '/http.git' + '@' + Var('dart_http_tag'),

  'src/third_party/dart/third_party/pkg/http_parser':
   Var('dart_git') + '/http_parser.git' + '@' + Var('dart_http_parser_tag'),

  'src/third_party/dart/third_party/pkg/http_retry':
   Var('dart_git') + '/http_retry.git' + '@' + Var('dart_http_retry_tag'),

  'src/third_party/dart/third_party/pkg/http_throttle':
   Var('dart_git') + '/http_throttle.git' + '@' + Var('dart_http_throttle_tag'),

  'src/third_party/dart/third_party/pkg/http_multi_server':
   Var('dart_git') + '/http_multi_server.git' + '@' + Var('dart_http_multi_server_tag'),

  'src/third_party/dart/third_party/pkg/logging':
   Var('dart_git') + '/logging.git' + '@' + Var('dart_logging_tag'),

  'src/third_party/dart/third_party/pkg/linter':
   Var('dart_git') + '/linter.git' + '@' + Var('dart_linter_tag'),

  'src/third_party/dart/third_party/pkg/markdown':
   Var('dart_git') + '/markdown.git' + '@' + Var('dart_markdown_tag'),

  'src/third_party/dart/third_party/pkg/matcher':
   Var('dart_git') + '/matcher.git' + '@' + Var('dart_matcher_tag'),

  'src/third_party/dart/third_party/pkg/mime':
   Var('dart_git') + '/mime.git' + '@' + Var('dart_mime_tag'),

  'src/third_party/dart/third_party/pkg/mockito':
   Var('dart_git') + '/mockito.git' + '@' + Var('dart_mockito_tag'),

  'src/third_party/dart/third_party/pkg/mustache4dart':
   Var('chromium_git') + '/external/github.com/valotas/mustache4dart' + '@' + Var('dart_mustache4dart_tag'),

  'src/third_party/dart/third_party/pkg_tested/package_config':
   Var('dart_git') + '/package_config.git' + '@' + Var('dart_package_config_tag'),

  'src/third_party/dart/third_party/pkg_tested/package_resolver':
   Var('dart_git') + '/package_resolver.git' + '@' + Var('dart_package_resolver_tag'),

  'src/third_party/dart/third_party/pkg/path':
   Var('dart_git') + '/path.git' + '@' + Var('dart_path_tag'),

  'src/third_party/dart/third_party/pkg/pool':
   Var('dart_git') + '/pool.git' + '@' + Var('dart_pool_tag'),

  'src/third_party/dart/third_party/pkg/plugin':
   Var('dart_git') + '/plugin.git' + '@' + Var('dart_plugin_tag'),

  'src/third_party/dart/third_party/pkg/protobuf':
   Var('dart_git') + '/protobuf.git' + '@' + Var('dart_protobuf_tag'),

  'src/third_party/dart/third_party/pkg/pub_semver':
   Var('dart_git') + '/pub_semver.git' + '@' + Var('dart_pub_semver_tag'),

  'src/third_party/dart/third_party/pkg/pub':
   Var('dart_git') + '/pub.git' + '@' + Var('dart_pub_rev'),

  'src/third_party/dart/third_party/pkg/quiver':
   Var('chromium_git') + '/external/github.com/google/quiver-dart' + '@' + Var('dart_quiver_tag'),

  'src/third_party/dart/third_party/pkg/resource':
   Var('dart_git') + '/resource.git' + '@' + Var('dart_resource_rev'),

  'src/third_party/dart/third_party/pkg/shelf':
   Var('dart_git') + '/shelf.git' + '@' + Var('dart_shelf_tag'),

  'src/third_party/dart/third_party/pkg/shelf_packages_handler':
   Var('dart_git') + '/shelf_packages_handler.git' + '@' + Var('dart_shelf_packages_handler_tag'),

  'src/third_party/dart/third_party/pkg/shelf_static':
   Var('dart_git') + '/shelf_static.git' + '@' + Var('dart_shelf_static_rev'),

  'src/third_party/dart/third_party/pkg/shelf_web_socket':
   Var('dart_git') + '/shelf_web_socket.git' + '@' + Var('dart_shelf_web_socket_tag'),

  'src/third_party/dart/third_party/pkg/source_span':
   Var('dart_git') + '/source_span.git' + '@' + Var('dart_source_span_tag'),

  'src/third_party/dart/third_party/pkg/source_map_stack_trace':
   Var('dart_git') + '/source_map_stack_trace.git' + '@' + Var('dart_source_map_stack_trace_tag'),

  'src/third_party/dart/third_party/pkg/source_maps':
   Var('dart_git') + '/source_maps.git' + '@' + Var('dart_source_maps_tag'),

  'src/third_party/dart/third_party/pkg/string_scanner':
   Var('dart_git') + '/string_scanner.git' + '@' + Var('dart_string_scanner_tag'),

  'src/third_party/dart/third_party/pkg/stream_channel':
   Var('dart_git') + '/stream_channel.git' + '@' + Var('dart_stream_channel_tag'),

  'src/third_party/dart/third_party/pkg/stack_trace':
   Var('dart_git') + '/stack_trace.git' + '@' + Var('dart_stack_trace_tag'),

  'src/third_party/dart/third_party/pkg_tested/dart_style':
   Var('dart_git') + '/dart_style.git' + '@' + Var('dart_dart_style_tag'),

  'src/third_party/dart/third_party/pkg/typed_data':
   Var('dart_git') + '/typed_data.git' + '@' + Var('dart_typed_data_tag'),

  'src/third_party/dart/third_party/pkg/test':
   Var('dart_git') + '/test.git' + '@' + Var('dart_test_tag'),

  'src/third_party/dart/third_party/pkg/tuple':
   Var('dart_git') + '/tuple.git' + '@' + Var('dart_tuple_tag'),

  'src/third_party/dart/third_party/pkg/utf':
   Var('dart_git') + '/utf.git' + '@' + Var('dart_utf_tag'),

  'src/third_party/dart/third_party/pkg/usage':
   Var('dart_git') + '/usage.git' + '@' + Var('dart_usage_tag'),

  'src/third_party/dart/third_party/pkg/watcher':
   Var('dart_git') + '/watcher.git' + '@' + Var('dart_watcher_tag'),

  'src/third_party/dart/third_party/pkg/web_socket_channel':
   Var('dart_git') + '/web_socket_channel.git' + '@' + Var('dart_web_socket_channel_tag'),

  'src/third_party/dart/third_party/pkg/yaml':
   Var('dart_git') + '/yaml.git' + '@' + Var('dart_yaml_tag'),

  'src/third_party/colorama/src':
   Var('chromium_git') + '/external/colorama.git' + '@' + '799604a1041e9b3bc5d2789ecbd7e8db2e18e6b8',

  'src/third_party/freetype2':
   Var('fuchsia_git') + '/third_party/freetype2' + '@' + 'e23a030e9b43c648249477fdf7bf5305d2cc8f59',

  'src/third_party/root_certificates':
   Var('dart_git') + '/root_certificates.git' + '@' + Var('dart_root_certificates_rev'),

  'src/third_party/skia':
   Var('skia_git') + '/skia.git' + '@' +  Var('skia_revision'),

  'src/third_party/libjpeg-turbo':
   Var('fuchsia_git') + '/third_party/libjpeg-turbo' + '@' + '9587e51cf946f1a1d19bb596bc31ba4e6c9d8893',

  'src/third_party/libwebp':
   Var('chromium_git') + '/webm/libwebp.git' + '@' + '0.6.0',

  'src/third_party/gyp':
   Var('chromium_git') + '/external/gyp.git' + '@' + '4801a5331ae62da9769a327f11c4213d32fb0dad',

   # Headers for Vulkan 1.0
   'src/third_party/vulkan':
   Var('github_git') + '/KhronosGroup/Vulkan-Docs.git' + '@' + 'e29c2489e238509c41aeb8c7bce9d669a496344b',

  'src/third_party/pkg/when':
   Var('dart_git') + '/when.git' + '@' + '0.2.0',
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
    'name': 'frontend_server_packages',
    'pattern': '.',
    'condition': 'host_os == "linux"',
    'cwd': 'src/flutter/frontend_server/',
    'action': [
      '../../../src/third_party/dart/tools/sdks/linux/dart-sdk/bin/pub', 'get',
    ],
  },
  {
    'name': 'frontend_server_packages',
    'pattern': '.',
    'condition': 'host_os == "mac"',
    'cwd': 'src/flutter/frontend_server/',
    'action': [
      '../../../src/third_party/dart/tools/sdks/mac/dart-sdk/bin/pub', 'get',
    ],
  },
  {
    'name': 'frontend_server_packages',
    'pattern': '.',
    'condition': 'host_os == "win"',
    'cwd': 'src/flutter/frontend_server/',
    'action': [
      '..\\..\\..\\src\\third_party\\dart\\tools\\sdks\\win\\dart-sdk\\bin\\pub.bat', 'get',
    ],
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
