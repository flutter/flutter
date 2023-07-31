// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

/// Parse the given map into a lint config.
/// Return `null` if [optionsMap] is `null` or does not have `linter` map.
LintConfig? parseConfig(YamlMap? optionsMap) {
  if (optionsMap != null) {
    var options = optionsMap.valueAt('linter');
    // Quick check of basic contract.
    if (options is YamlMap) {
      return LintConfig.parseMap(options);
    }
  }
  return null;
}

/// Process the given option [fileContents] and produce a corresponding
/// [LintConfig]. Return `null` if [fileContents] is not a YAML map, or
/// does not have the `linter` child map.
LintConfig? processAnalysisOptionsFile(String fileContents, {String? fileUrl}) {
  var yaml = loadYamlNode(fileContents,
      sourceUrl: fileUrl != null ? Uri.parse(fileUrl) : null);
  if (yaml is YamlMap) {
    return parseConfig(yaml);
  }
  return null;
}

/// The configuration of lint rules within an analysis options file.
abstract class LintConfig {
  factory LintConfig.parse(String source, {String? sourceUrl}) =>
      _LintConfig().._parse(source, sourceUrl: sourceUrl);

  factory LintConfig.parseMap(YamlMap map) => _LintConfig().._parseYaml(map);

  List<String> get fileExcludes;
  List<String> get fileIncludes;
  List<RuleConfig> get ruleConfigs;
}

/// The configuration of a single lint rule within an analysis options file.
abstract class RuleConfig {
  Map<String, dynamic> args = <String, dynamic>{};
  String? get group;
  String? get name;

  // Provisional
  bool disables(String ruleName) =>
      ruleName == name && args['enabled'] == false;

  bool enables(String ruleName) => ruleName == name && args['enabled'] == true;
}

class _LintConfig implements LintConfig {
  @override
  final fileIncludes = <String>[];
  @override
  final fileExcludes = <String>[];
  @override
  final ruleConfigs = <RuleConfig>[];

  void addAsListOrString(Object? value, List<String> list) {
    if (value is List) {
      for (var entry in value) {
        list.add(entry);
      }
    } else if (value is String) {
      list.add(value);
    }
  }

  bool? asBool(Object scalar) {
    Object value = scalar is YamlScalar ? scalar.value : scalar;
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value == 'true') {
        return true;
      }
      if (value == 'false') {
        return false;
      }
    }
    return null;
  }

  String? asString(Object scalar) {
    Object value = scalar is YamlScalar ? scalar.value : scalar;
    if (value is String) {
      return value;
    }
    return null;
  }

  Map<String, dynamic>? parseArgs(Object args) {
    var enabled = asBool(args);
    if (enabled != null) {
      return {'enabled': enabled};
    }
    return null;
  }

  void _parse(String src, {String? sourceUrl}) {
    var yaml = loadYamlNode(src,
        sourceUrl: sourceUrl != null ? Uri.parse(sourceUrl) : null);
    if (yaml is YamlMap) {
      _parseYaml(yaml);
    }
  }

  void _parseYaml(YamlMap yaml) {
    yaml.nodes.forEach((k, v) {
      if (k is! YamlScalar) {
        return;
      }
      YamlScalar key = k;
      switch (key.toString()) {
        case 'files':
          if (v is YamlMap) {
            addAsListOrString(v['include'], fileIncludes);
            addAsListOrString(v['exclude'], fileExcludes);
          }
          break;

        case 'rules':

          // - unnecessary_getters
          // - camel_case_types
          if (v is YamlList) {
            for (var rule in v.nodes) {
              var config = _RuleConfig();
              config.name = asString(rule);
              config.args = {'enabled': true};
              ruleConfigs.add(config);
            }
          }

          // style_guide: {unnecessary_getters: false, camel_case_types: true}
          if (v is YamlMap) {
            v.nodes.forEach((key, value) {
              //{unnecessary_getters: false}
              if (asBool(value) != null) {
                var config = _RuleConfig();
                config.name = asString(key);
                config.args = {'enabled': asBool(value)};
                ruleConfigs.add(config);
              }

              // style_guide: {unnecessary_getters: false, camel_case_types: true}
              if (value is YamlMap) {
                value.nodes.forEach((rule, args) {
                  // TODO: verify format
                  // unnecessary_getters: false
                  var config = _RuleConfig();
                  config.group = asString(key);
                  config.name = asString(rule);
                  config.args = parseArgs(args)!;
                  ruleConfigs.add(config);
                });
              }
            });
          }
          break;
      }
    });
  }
}

class _RuleConfig extends RuleConfig {
  @override
  String? group;
  @override
  String? name;
}
