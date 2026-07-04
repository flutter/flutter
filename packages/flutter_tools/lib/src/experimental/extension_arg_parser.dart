// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:meta/meta.dart';

import '../runner/flutter_command.dart';

/// A mixin on `FlutterCommand` that supports lazy, dynamic rebuilding of `argParser`
/// when extension-provided options or templates change at runtime.
///
/// Because `ArgParser` instances in `package:args` cannot be mutated once options
/// or commands are registered, dynamic commands must reconstruct their `argParser`
/// when new extension capabilities (such as project templates) are discovered.
mixin ExtensionArgParserMixin on FlutterCommand {
  ArgParser? _baseArgParser;
  ArgParser? _customArgParser;
  String? _lastDynamicCacheKey;
  bool _buildingBaseParser = false;

  /// Creates the initial empty `ArgParser` instance for this command.
  ///
  /// Override this to provide custom `ArgParser` parameters such as `usageLineLength`.
  @protected
  ArgParser createBaseArgParser() => ArgParser(allowTrailingOptions: false);

  /// Populates options and flags on `parser` (which is also accessible via `argParser`).
  @protected
  void populateBaseArgParser(ArgParser parser);

  /// Returns a cache key representing the current set of dynamic extension options
  /// (for example, a comma-separated list of template names).
  ///
  /// If this returns null or an empty string, the base parser is returned directly.
  @protected
  String? get extensionArgParserCacheKey;

  /// Builds a new dynamic `ArgParser` by cloning `baseParser` and injecting
  /// any dynamic extension options or allowed help entries.
  @protected
  ArgParser buildDynamicArgParser(ArgParser baseParser);

  /// Returns the base static `ArgParser` for this command, initializing it if needed.
  ArgParser get baseArgParser {
    if (_baseArgParser != null) {
      return _baseArgParser!;
    }
    _buildingBaseParser = true;
    try {
      final ArgParser parser = createBaseArgParser();
      _baseArgParser = parser;
      populateBaseArgParser(parser);
      return parser;
    } finally {
      _buildingBaseParser = false;
    }
  }

  @override
  ArgParser get argParser {
    if (_buildingBaseParser) {
      return baseArgParser;
    }
    final String? cacheKey = extensionArgParserCacheKey;
    if (cacheKey == null || cacheKey.isEmpty) {
      return baseArgParser;
    }
    if (_customArgParser == null || cacheKey != _lastDynamicCacheKey) {
      _lastDynamicCacheKey = cacheKey;
      _customArgParser = buildDynamicArgParser(baseArgParser);
    }
    return _customArgParser!;
  }
}
