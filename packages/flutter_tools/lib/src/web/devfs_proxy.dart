// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';
import '../base/logger.dart';
import '../globals.dart' as globals;

/// Represents a rule for proxying requests based on a specific pattern.
/// Subclasses must implement the [matches], [replace], and [getTargetUri] methods.
sealed class ProxyRule {
  /// Checks if the given [path] matches the rule's pattern.
  bool matches(String path);

  /// Replaces the matched part of the [path] according to the rule's logic.
  /// If no replacement is needed, it returns the original path.
  String replace(String path);

  /// Returns the target URI to which the request should be proxied.
  Uri getTargetUri();

  /// If both or neither 'prefix' and 'regex' are defined, it logs an error and returns null.
  /// Otherwise, it tries to create a [PrefixProxyRule] or [RegexProxyRule] based on the [yaml] keys.
  static ProxyRule? fromYaml(YamlMap yaml, {Logger? logger}) {
    final Logger effectiveLogger = logger ?? globals.logger;
    if (PrefixProxyRule.canHandle(yaml) && RegexProxyRule.canHandle(yaml)) {
      effectiveLogger.printError(
        '[PROXY] Both "prefix" and "regex" are defined in the proxy rule YAML. Only one should be used.',
      );
      return null;
    } else if (PrefixProxyRule.canHandle(yaml)) {
      return PrefixProxyRule.fromYaml(yaml, effectiveLogger);
    } else if (RegexProxyRule.canHandle(yaml)) {
      return RegexProxyRule.fromYaml(yaml, effectiveLogger);
    } else {
      effectiveLogger.printError('[PROXY] Invalid proxy rule in YAML: $yaml');
      return null;
    }
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
  RegexProxyRule({required RegExp pattern, required String target, String? replacement})
    : _pattern = pattern,
      _target = target,
      _replacement = replacement;

  final RegExp _pattern;
  final String _target;
  final String? _replacement;

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
  String toString() {
    return '{pattern: ${_pattern.pattern}, target: $_target, replace: ${_replacement ?? 'null'}}';
  }

  /// Checks if the given [yaml] can be handled by this rule.
  /// It requires the 'regex' key to be present and non-empty.
  static bool canHandle(YamlMap yaml) {
    return yaml.containsKey('regex') &&
        yaml['regex'] is String &&
        (yaml['regex'] as String).isNotEmpty;
  }

  /// Attempts to create a [RegexProxyRule] from the provided [yaml] map.
  /// If the 'regex' or 'target' keys are missing or invalid, it logs an error
  /// and returns null.
  /// If the 'regex' is invalid, it logs a warning and treats it as a string.
  static RegexProxyRule? fromYaml(YamlMap yaml, Logger effectiveLogger) {
    final regex = yaml['regex'] as String?;
    final target = yaml['target'] as String?;
    final replacement = yaml['replace'] as String?;
    if (regex == null || regex.isEmpty) {
      return null;
    } else if (target == null || target.isEmpty) {
      effectiveLogger.printError(
        "[PROXY] Invalid 'target' for 'regex': $regex. 'target' cannot be null",
      );
      return null;
    }
    RegExp? pattern;
    try {
      pattern = RegExp(regex.trim());
    } on FormatException catch (e) {
      pattern = RegExp(RegExp.escape(regex));
      effectiveLogger.printWarning(
        "[PROXY] Invalid regex pattern in 'regex': '$regex'. Treating $regex as string. Error: $e",
      );
    }
    return RegexProxyRule(pattern: pattern, target: target, replacement: replacement?.trim());
  }
}

/// A [ProxyRule] implementation that matches paths starting with a specific prefix.
/// If a [_replacement] string is provided, it replaces the prefix in the matched path.
class PrefixProxyRule implements ProxyRule {
  /// Creates a [PrefixProxyRule] with the given [pattern] prefix, [target] URI base,
  /// and optional [replacement] string.
  PrefixProxyRule({required String pattern, required String target, String? replacement})
    : _pattern = pattern,
      _target = target,
      _replacement = replacement;

  final String _pattern;
  final String _target;
  final String? _replacement;

  @override
  bool matches(String path) {
    return path.startsWith(_pattern);
  }

  @override
  String replace(String path) {
    if (_replacement == null) {
      return path;
    }
    return path.replaceFirst(_pattern, _replacement);
  }

  @override
  Uri getTargetUri() {
    final Uri targetBaseUri = Uri.parse(_target);
    return targetBaseUri;
  }

  @override
  String toString() {
    return '{prefix: $_pattern, target: $_target, replace: ${_replacement ?? 'null'}}';
  }

  /// Checks if the given [yaml] can be handled by this rule.
  /// It requires the 'prefix' key to be present and non-empty.
  static bool canHandle(YamlMap yaml) {
    return yaml.containsKey('prefix') &&
        yaml['prefix'] is String &&
        (yaml['prefix'] as String).isNotEmpty;
  }

  /// Attempts to create a [PrefixProxyRule] from the provided [yaml] map.
  /// If the 'prefix' or 'target' keys are missing or invalid, it logs an error
  /// and returns null.
  static PrefixProxyRule? fromYaml(YamlMap yaml, Logger effectiveLogger) {
    final pattern = yaml['prefix'] as String?;
    final target = yaml['target'] as String?;
    final replacement = yaml['replace'] as String?;
    if (pattern == null || pattern.isEmpty) {
      return null;
    } else if (target == null || target.isEmpty) {
      effectiveLogger.printError(
        "[PROXY] Invalid 'target' for 'prefix': $pattern. 'target' cannot be null",
      );
      return null;
    }
    return PrefixProxyRule(pattern: pattern, target: target, replacement: replacement?.trim());
  }
}
