// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';
import '../base/logger.dart';
import '../globals.dart' as globals;

abstract class ProxyRule {
  ProxyRule({required this.target, this.replacement});

  final String target;
  final String? replacement;
  String replace(String path);
  bool matches(String path);

  static ProxyRule? fromYaml(YamlMap yaml, {Logger? logger}) {
    final target = yaml['target'] as String?;
    final prefix = yaml['prefix'] as String?;
    final regex = yaml['regex'] as String?;
    final replacement = yaml['replace'] as String?;
    final Logger effectiveLogger = logger ?? globals.logger;

    if (target == null) {
      final String? path = prefix ?? regex;
      effectiveLogger.printError("Invalid 'target' for path: $path. 'target' cannot be null");
      return null;
    }
    if (prefix != null && prefix.isNotEmpty) {
      return PrefixProxyRule(prefix: prefix, target: target, replacement: replace?.trim());
    } else if (regex != null && regex.isNotEmpty) {
      RegExp? regexPattern;
      try {
        regexPattern = RegExp(regex.trim());
      } on FormatException catch (e) {
        regexPattern = RegExp(RegExp.escape(regex));
        effectiveLogger.printWarning(
          "Invalid regex pattern in replace 'regex': '$regex'. Treating $regex as string. Error: $e",
        );
      }
      return RegexProxyRule(pattern: regexPattern, target: target, replacement: replace?.trim());
    } else {
      effectiveLogger.printError("'prefix' or 'regex' field must be provided");
      return null;
    }
  }
}

class RegexProxyRule extends ProxyRule {
  RegexProxyRule({required this.pattern, required super.target, super.replacement});

  final RegExp pattern;

  @override
  bool matches(String path) {
    return pattern.hasMatch(path);
  }

  @override
  String replace(String path) {
    return path.replaceAllMapped(pattern, (Match match) {
      String result = replacement!;

      for (var i = 0; i <= match.groupCount; i++) {
        result = result.replaceAll('\$$i', match.group(i) ?? '');
      }
      return result;
    });
  }

  @override
  String toString() {
    return '{pattern: ${pattern.pattern}, target: $target, replace: ${replacement ?? 'null'}}';
  }
}

class PrefixProxyRule extends ProxyRule {
  PrefixProxyRule({required this.prefix, required super.target, super.replacement});
  final String prefix;

  @override
  bool matches(String path) {
    return path.startsWith(prefix);
  }

  @override
  String replace(String path) {
    return path.replaceFirst(prefix, replacement!);
  }

  @override
  String toString() {
    return '{prefix: $prefix, target: $target, replacement: ${replacement ?? 'null'}}';
  }
}
