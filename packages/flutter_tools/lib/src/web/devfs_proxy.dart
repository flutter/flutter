// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';
import '../base/logger.dart';

/// Represents a rule for proxying requests based on a specific pattern.
/// Subclasses must implement the [matches], [replace], and [getTargetUri] methods.
sealed class ProxyRule {
  static const _kLogEntryPrefix = '[ProxyRule]';
  static const _kTarget = 'target';
  static const _kRegex = 'regex';
  static const _kPrefix = 'prefix';
  static const _kReplace = 'replace';
  static const _kHeaders = 'headers';
  static const _kName = 'name';
  static const _kValue = 'value';

  /// Checks if the given [path] matches the rule's pattern.
  bool matches(String path);

  /// Replaces the matched part of the [path] according to the rule's logic.
  /// If no replacement is needed, it returns the original path.
  String replace(String path);

  /// Returns the target URI to which the request should be proxied.
  Uri getTargetUri();

  /// Returns additional headers to inject into the outgoing proxied request.
  /// Implementations should return an immutable map. May be empty.
  Map<String, String> get headers;

  /// If both or neither 'prefix' and 'regex' are defined, it logs an error and returns null.
  /// Otherwise, it tries to create a [PrefixProxyRule] or [RegexProxyRule] based on the [yaml] keys.
  static ProxyRule? fromYaml(YamlMap yaml, Logger logger) {
    if (PrefixProxyRule.canHandle(yaml) && RegexProxyRule.canHandle(yaml)) {
      logger.printError(
        '$_kLogEntryPrefix Both $_kPrefix and $_kRegex are defined in the proxy rule YAML.'
        ' Only one should be used.',
      );
      return null;
    } else if (PrefixProxyRule.canHandle(yaml)) {
      return PrefixProxyRule.fromYaml(yaml, logger);
    } else if (RegexProxyRule.canHandle(yaml)) {
      return RegexProxyRule.fromYaml(yaml, logger);
    } else {
      logger.printError('$_kLogEntryPrefix Invalid proxy rule in YAML: $yaml');
      return null;
    }
  }

  /// Parses a list of headers from YAML in the shape:
  /// headers:
  ///   - name: <String>
  ///     value: <String>
  static Map<String, String> _parseHeadersFromYaml(YamlMap yaml, Logger logger) {
    final result = <String, String>{};
    if (!yaml.containsKey(_kHeaders)) {
      return result;
    }
    final Object? headersValue = yaml[_kHeaders];
    if (headersValue is! YamlList) {
      logger.printError('$_kLogEntryPrefix $_kHeaders must be a list of maps with $_kName/$_kValue');
      return result;
    }
    for (final Object? item in headersValue) {
      if (item is! YamlMap) {
        logger.printError('$_kLogEntryPrefix Each header entry must be a map. Found ${item.runtimeType}');
        continue;
      }
      final Object? name = item[_kName];
      final Object? value = item[_kValue];
      if (name is! String || name.isEmpty) {
        logger.printError('$_kLogEntryPrefix Header "$_kName" must be a non-empty String. Found ${name.runtimeType}');
        continue;
      }
      if (value is! String) {
        logger.printError('$_kLogEntryPrefix Header "$_kValue" must be a String. Found ${value.runtimeType}');
        continue;
      }
      }
      result[name] = value;
    }
    return result;
  }
}

/// A [ProxyRule] implementation that uses regular expressions for matching and
/// replacement.
///
/// This rule matches paths against a provided regular expression [_pattern].
/// If a [_replacement] string is provided, it replaces parts of the matched
/// path based on regex group capturing.
class RegexProxyRule implements ProxyRule {
  /// Creates a [RegexProxyRule] with the given regular expression [pattern],
  /// [target] URI base, and optional [replacement] string.
  RegexProxyRule({
    required RegExp pattern,
    required String target,
    String? replacement,
    Map<String, String> headers = const <String, String>{},
  })
    : _pattern = pattern,
      _target = target,
      _replacement = replacement,
      _headers = headers;

  final RegExp _pattern;
  final String _target;
  final String? _replacement;
  final Map<String, String> _headers;

  @override
  bool matches(String path) {
    return _pattern.hasMatch(path);
  }

  @override
  String replace(String path) {
    if (_replacement == null) {
      return path;
    }
    return path.replaceAllMapped(_pattern, (Match match) {
      String result = _replacement;
      for (var i = 0; i <= match.groupCount; i++) {
        result = result.replaceAll('\$$i', match.group(i) ?? '');
      }
      return result;
    });
  }

  @override
  Uri getTargetUri() {
    final Uri targetBaseUri = Uri.parse(_target);
    return targetBaseUri;
  }

  @override
  Map<String, String> get headers => _headers;

  @override
  String toString() {
    final base = '{${ProxyRule._kRegex}: ${_pattern.pattern}, ${ProxyRule._kTarget}: $_target, ${ProxyRule._kReplace}: ${_replacement ?? 'null'}';
    if (_headers.isEmpty) {
      return '$base}';
    }
    return '$base, ${ProxyRule._kHeaders}: $_headers}';
  }

  /// Checks if the given [yaml] can be handled by this rule.
  /// It requires the 'regex' key to be present and non-empty.
  static bool canHandle(YamlMap yaml) {
    return yaml.containsKey(ProxyRule._kRegex) &&
        yaml[ProxyRule._kRegex] is String &&
        (yaml[ProxyRule._kRegex] as String).isNotEmpty;
  }

  /// Attempts to create a [RegexProxyRule] from the provided [yaml] map.
  /// If the 'regex' or 'target' keys are missing or invalid, it logs an error
  /// and returns null.
  /// If the 'regex' is invalid, it logs a warning and treats it as a string.
  static RegexProxyRule? fromYaml(YamlMap yaml, Logger effectiveLogger) {
    final regex = yaml[ProxyRule._kRegex] as String?;
    final target = yaml[ProxyRule._kTarget] as String?;
    final replacement = yaml[ProxyRule._kReplace] as String?;
    if (regex == null || regex.isEmpty) {
      return null;
    } else if (target == null || target.isEmpty) {
      effectiveLogger.printError(
        '${ProxyRule._kLogEntryPrefix} Invalid ${ProxyRule._kTarget} for '
        '${ProxyRule._kRegex}: $regex. ${ProxyRule._kTarget} cannot be null',
      );
      return null;
    }
    RegExp? pattern;
    try {
      pattern = RegExp(regex.trim());
    } on FormatException catch (e) {
      pattern = RegExp(RegExp.escape(regex));
      effectiveLogger.printWarning(
        '${ProxyRule._kLogEntryPrefix} Invalid regex pattern in ${ProxyRule._kRegex}: $regex. '
        'Treating $regex as string. Error: $e',
      );
    }
    final headers = ProxyRule._parseHeadersFromYaml(yaml, effectiveLogger);
    return RegexProxyRule(
      pattern: pattern,
      target: target,
      replacement: replacement?.trim(),
      headers: headers,
    );
  }
}

/// A [ProxyRule] implementation that matches paths starting with a specific prefix.
///
/// If a [_replacement] string is provided, it replaces the prefix in the matched path.
class PrefixProxyRule extends RegexProxyRule {
  /// Creates a [PrefixProxyRule] with the given [prefix] prefix, [target] URI base,
  /// and optional [replacement] string.
  PrefixProxyRule({
    required String prefix,
    required super.target,
    super.replacement,
    super.headers,
  }) : super(pattern: RegExp('^${RegExp.escape(prefix)}'));

  @override
  String toString() {
    final base = '{${ProxyRule._kPrefix}: ${_pattern.pattern}, ${ProxyRule._kTarget}: $_target, ${ProxyRule._kReplace}: ${_replacement ?? 'null'}';
    if (headers.isEmpty) {
      return '$base}';
    }
    return '$base, ${ProxyRule._kHeaders}: $headers}';
  }

  /// Checks if the given [yaml] can be handled by this rule.
  /// It requires the 'prefix' key to be present and non-empty.
  static bool canHandle(YamlMap yaml) {
    return yaml.containsKey(ProxyRule._kPrefix) &&
        yaml[ProxyRule._kPrefix] is String &&
        (yaml[ProxyRule._kPrefix] as String).isNotEmpty;
  }

  /// Attempts to create a [PrefixProxyRule] from the provided [yaml] map.
  /// If the 'prefix' or 'target' keys are missing or invalid, it logs an error
  /// and returns null.
  static PrefixProxyRule? fromYaml(YamlMap yaml, Logger effectiveLogger) {
    final prefix = yaml[ProxyRule._kPrefix] as String?;
    final target = yaml[ProxyRule._kTarget] as String?;
    final replacement = yaml[ProxyRule._kReplace] as String?;
    if (prefix == null || prefix.isEmpty) {
      return null;
    } else if (target == null || target.isEmpty) {
      effectiveLogger.printError(
        '${ProxyRule._kLogEntryPrefix} Invalid ${ProxyRule._kTarget} for '
        '${ProxyRule._kPrefix}: $prefix. ${ProxyRule._kTarget} cannot be null',
      );
      return null;
    }
    final headers = ProxyRule._parseHeadersFromYaml(yaml, effectiveLogger);
    return PrefixProxyRule(
      prefix: prefix,
      target: target,
      replacement: replacement?.trim(),
      headers: headers,
    );
  }
}
