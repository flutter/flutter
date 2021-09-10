// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The SDK package allowlist for the flutter, flutter_test, flutter_driver, flutter_localizations,
/// and integration_test packages.
///
/// The goal of the allowlist is to make it more difficult to accidentally add new dependencies
/// to the core SDK packages that users depend on. Any dependencies added to this set can have a
/// large impact on the allowed version solving of a given flutter application because of how
/// the SDK pins to an exact version.
///
/// Before adding a new Dart Team owned dependency to this set, please clear with natebosch@
/// or jakemac53@. For other packages please contact hixie@ or zanderso@ .
const Set<String> kCorePackageAllowList = <String>{
  'characters',
  'clock',
  'collection',
  'fake_async',
  'file',
  'frontend_server_client',
  'intl',
  'meta',
  'path',
  'stack_trace',
  'test',
  'test_api',
  'typed_data',
  'vector_math',
  'vm_service',
  'webdriver',
  '_fe_analyzer_shared',
  'analyzer',
  'archive',
  'args',
  'async',
  'boolean_selector',
  'charcode',
  'cli_util',
  'convert',
  'coverage',
  'crypto',
  'glob',
  'http_multi_server',
  'http_parser',
  'io',
  'js',
  'logging',
  'matcher',
  'mime',
  'node_preamble',
  'package_config',
  'pedantic',
  'pool',
  'pub_semver',
  'shelf',
  'shelf_packages_handler',
  'shelf_static',
  'shelf_web_socket',
  'source_map_stack_trace',
  'source_maps',
  'source_span',
  'stream_channel',
  'string_scanner',
  'sync_http',
  'term_glyph',
  'test_core',
  'watcher',
  'web_socket_channel',
  'webkit_inspection_protocol',
  'yaml',
  'flutter',
  'flutter_driver',
  'flutter_localizations',
  'flutter_test',
  'integration_test'
};
