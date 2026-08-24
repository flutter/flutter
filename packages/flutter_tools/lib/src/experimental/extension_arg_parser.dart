// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Dynamic argument parser mixin for tool extensions.
///
/// This library provides a mixin to allow commands to dynamically rebuild
/// their argument parsers when extension-provided options change.
library experimental.extension_arg_parser;

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

  /// Hook called by the command runner before parsing arguments,
  /// allowing the command to perform asynchronous initialization
  /// (e.g. querying extensions) to populate its dynamic options.
  Future<void> initializeDynamicOptions() async {}

  /// Creates and configures the static base `ArgParser` for this command.
  ///
  /// Subclasses should override this method to register their static options
  /// and flags rather than adding options in the constructor, allowing the
  /// base parser to be cloned and dynamically rebuilt when extension options change.
  @protected
  ArgParser createBaseArgParser() => ArgParser(allowTrailingOptions: false);

  /// Returns a cache key representing the current set of dynamic extension options
  /// (for example, a comma-separated list of template names).
  ///
  /// This key is used to determine if the dynamic parser needs to be rebuilt.
  /// If this returns null or an empty string, the base parser is returned directly.
  @protected
  String? get extensionArgParserCacheKey;

  /// Injects dynamic extension options or allowed help entries into [dynamicParser].
  ///
  /// [dynamicParser] is a pre-cloned copy of [baseArgParser]. Subclasses should
  /// mutate and return [dynamicParser] with extension options added.
  @protected
  ArgParser buildDynamicArgParser(ArgParser dynamicParser);

  /// Clones all options from [source] into a new [ArgParser] instance.
  @protected
  static ArgParser cloneParser(ArgParser source) {
    final newParser = ArgParser(
      allowTrailingOptions: source.allowTrailingOptions,
      usageLineLength: source.usageLineLength,
    );
    for (final Option opt in source.options.values) {
      switch (opt.type) {
        case OptionType.flag:
          newParser.addFlag(
            opt.name,
            abbr: opt.abbr,
            help: opt.help,
            defaultsTo: opt.defaultsTo as bool?,
            negatable: opt.negatable ?? true,
            hide: opt.hide,
            hideNegatedUsage: opt.hideNegatedUsage ?? false,
            aliases: opt.aliases,
          );
        case OptionType.single:
          newParser.addOption(
            opt.name,
            abbr: opt.abbr,
            help: opt.help,
            valueHelp: opt.valueHelp,
            allowed: opt.allowed,
            allowedHelp: opt.allowedHelp,
            defaultsTo: opt.defaultsTo as String?,
            mandatory: opt.mandatory,
            hide: opt.hide,
            aliases: opt.aliases,
          );
        case OptionType.multiple:
          newParser.addMultiOption(
            opt.name,
            abbr: opt.abbr,
            help: opt.help,
            valueHelp: opt.valueHelp,
            allowed: opt.allowed,
            allowedHelp: opt.allowedHelp,
            defaultsTo: (opt.defaultsTo as Iterable<Object?>?)?.cast<String>(),
            splitCommas: opt.splitCommas,
            hide: opt.hide,
            aliases: opt.aliases,
          );
      }
    }
    return newParser;
  }

  /// Returns the base static `ArgParser` for this command, initializing it if needed.
  ArgParser get baseArgParser {
    if (_baseArgParser != null) {
      return _baseArgParser!;
    }
    _buildingBaseParser = true;
    try {
      final ArgParser parser = createBaseArgParser();
      _baseArgParser = parser;
      return parser;
    } finally {
      _buildingBaseParser = false;
    }
  }

  /// Returns either the base parser or a dynamically rebuilt parser if the
  /// cache key has changed.
  @override
  ArgParser get argParser {
    assert(
      !_buildingBaseParser,
      'argParser was accessed re-entrantly while createBaseArgParser was executing. '
      'Subclasses should add options directly to the ArgParser created in createBaseArgParser.',
    );
    final String? cacheKey = extensionArgParserCacheKey;
    if (cacheKey == null || cacheKey.isEmpty) {
      return baseArgParser;
    }
    if (_customArgParser == null || cacheKey != _lastDynamicCacheKey) {
      _lastDynamicCacheKey = cacheKey;
      final ArgParser clonedParser = cloneParser(baseArgParser);
      _customArgParser = buildDynamicArgParser(clonedParser);
      // Re-add subcommands to the custom parser to ensure they are not lost.
      for (final MapEntry(:key, :value) in subcommands.entries) {
        if (!_customArgParser!.commands.containsKey(key)) {
          _customArgParser!.addCommand(key, value.argParser);
        }
      }
    }
    return _customArgParser!;
  }
}
