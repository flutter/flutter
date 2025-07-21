// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';
import '../base/logger.dart';
import '../globals.dart' as globals;

abstract class ProxyRule {
  ProxyRule({required this.target});

  final String target;
  String replace(String path);
  bool matches(String path);

  static ProxyRule? fromYaml(YamlMap yaml, {Logger? logger}) {
    final target = yaml['target'] as String?;
    final source = yaml['source'] as String?;
    final regex = yaml['regex'] as String?;
    final replace = yaml['replace'] as String?;
    final Logger effectiveLogger = logger ?? globals.logger;

    RegExp? proxyPattern;
    if (source != null && source.isNotEmpty) {
      if (target == null) {
        effectiveLogger.printError(
          "Invalid 'target' for 'source': $source. 'target' cannot be null",
        );
        return null;
      }
      return SourceProxyRule(source: source, target: target, replacement: replace?.trim());
    } else if (regex != null && regex.isNotEmpty) {
      if (target == null) {
        effectiveLogger.printError("Invalid 'target' for 'regex': $regex. 'target' cannot be null");
        return null;
      }
      try {
        proxyPattern = RegExp(regex.trim());
      } on FormatException catch (e) {
        proxyPattern = RegExp(RegExp.escape(regex));
        effectiveLogger.printWarning(
          "Invalid regex pattern in replace 'regex': '$regex'. Treating $regex as string. Error: $e",
        );
      }
      return RegexProxyRule(pattern: proxyPattern, target: target, replacement: replace?.trim());
    } else {
      effectiveLogger.printError("'source' or 'regex' field must be provided");
      return null;
    }
  }
}

class RegexProxyRule extends ProxyRule {
  RegexProxyRule({required this.pattern, required super.target, this.replacement});

  final RegExp pattern;
  final String? replacement;

  @override
  bool matches(String path) {
    return pattern.hasMatch(path);
  }

  @override
  String replace(String path) {
    if (replacement == null) {
      return path;
    }
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
    return '{pattern: ${pattern.pattern}, target: $target, replacement: ${replacement ?? 'null'}}';
  }
}

class SourceProxyRule extends ProxyRule {
  SourceProxyRule({required this.source, required super.target, this.replacement});
  final String source;
  final String? replacement;

  @override
  bool matches(String path) {
    return path.startsWith(source);
  }

  @override
  String replace(String path) {
    if (replacement == null) {
      return path;
    }
    return path.replaceFirst(source, replacement!);
  }

  @override
  String toString() {
    return '{source: $source, target: $target, replacement: ${replacement ?? 'null'}}';
  }
}
