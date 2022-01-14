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
/// or jakemac53@. For other packages please contact hixie@ or zanderso@.
///
/// You may remove entries from this list at any time, but once removed they must stay removed
/// unless the additions are cleared as described above.
const Set<String> kCorePackageAllowList = <String>{
  // Please keep this list in alphabetical order.
  '_fe_analyzer_shared',
  'analyzer',
  'archive',
  'args',
  'async',
  'boolean_selector',
  'characters',
  'charcode',
  'cli_util',
  'clock',
  'collection',
  'convert',
  'coverage',
  'crypto',
  'fake_async',
  'file',
  'flutter',
  'flutter_driver',
  'flutter_localizations',
  'flutter_test',
  'frontend_server_client',
  'glob',
  'http_multi_server',
  'http_parser',
  'integration_test',
  'intl',
  'io',
  'js',
  'logging',
  'matcher',
  'material_color_utilities',
  'meta',
  'mime',
  'node_preamble',
  'package_config',
  'path',
  'pool',
  'pub_semver',
  'shelf',
  'shelf_packages_handler',
  'shelf_static',
  'shelf_web_socket',
  'source_map_stack_trace',
  'source_maps',
  'source_span',
  'stack_trace',
  'stream_channel',
  'string_scanner',
  'sync_http',
  'term_glyph',
  'test',
  'test_api',
  'test_core',
  'typed_data',
  'vector_math',
  'vm_service',
  'watcher',
  'web_socket_channel',
  'webdriver',
  'webkit_inspection_protocol',
  'yaml',
};
