// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:analyzer/src/plugin/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

// TODO(pq): migrate these codes to `option_codes.dart`?

/// A hint code indicating reference to a deprecated lint.
///
/// Parameters:
/// 0: the rule name
const AnalysisOptionsHintCode DEPRECATED_LINT_HINT = AnalysisOptionsHintCode(
    'DEPRECATED_LINT_HINT',
    "'{0}' is a deprecated lint rule and should not be used");

/// Duplicate rules.
///
/// Parameters:
/// 0: the rule name
const AnalysisOptionsHintCode DUPLICATE_RULE_HINT = AnalysisOptionsHintCode(
    'DUPLICATE_RULE',
    "The rule {0} is already specified and doesn't need to be specified again.",
    correctionMessage: "Try removing all but one specification of the rule.");

/// An error code indicating an incompatible rule.
///
/// Parameters:
/// 0: the rule name
/// 1: the incompatible rule
const AnalysisOptionsWarningCode INCOMPATIBLE_LINT_WARNING =
    AnalysisOptionsWarningCode('INCOMPATIBLE_LINT_WARNING',
        "The rule '{0}' is incompatible with the rule '{1}'",
        correctionMessage: "Try removing one of the incompatible rules.");

/// An error code indicating an undefined lint rule.
///
/// Parameters:
/// 0: the rule name
const AnalysisOptionsWarningCode UNDEFINED_LINT_WARNING =
    AnalysisOptionsWarningCode(
        'UNDEFINED_LINT_WARNING', "'{0}' is not a recognized lint rule");

/// Rule provider.
typedef LintRuleProvider = Iterable<LintRule> Function();

/// Validates `linter` rule configurations.
class LinterRuleOptionsValidator extends OptionsValidator {
  static const linter = 'linter';
  static const rulesKey = 'rules';

  final LintRuleProvider ruleProvider;
  final VersionConstraint? sdkVersionConstraint;
  final bool sourceIsOptionsForContextRoot;

  LinterRuleOptionsValidator({
    LintRuleProvider? provider,
    this.sdkVersionConstraint,
    this.sourceIsOptionsForContextRoot = true,
  }) : ruleProvider = provider ?? (() => Registry.ruleRegistry.rules);

  bool currentSdkAllows(Version? since) {
    if (since == null) return true;
    var sdk = sdkVersionConstraint;
    if (sdk == null) return false;
    return sdk.allows(since);
  }

  LintRule? getRegisteredLint(Object value) =>
      ruleProvider().firstWhereOrNull((rule) => rule.name == value);

  bool isDeprecatedInCurrentSdk(State state) {
    if (state is! DeprecatedState) return false;
    return currentSdkAllows(state.since);
  }

  bool isRemovedInCurrentSdk(State state) {
    if (state is! RemovedState) return false;
    return currentSdkAllows(state.since);
  }

  @override
  List<AnalysisError> validate(ErrorReporter reporter, YamlMap options) {
    List<AnalysisError> errors = <AnalysisError>[];
    var node = options.valueAt(linter);
    if (node is YamlMap) {
      var rules = node.valueAt(rulesKey);
      _validateRules(rules, reporter);
    }
    return errors;
  }

  void _validateRules(YamlNode? rules, ErrorReporter reporter) {
    final seenRules = <String>{};

    String? findIncompatibleRule(LintRule rule) {
      for (var incompatibleRule in rule.incompatibleRules) {
        if (seenRules.contains(incompatibleRule)) {
          return incompatibleRule;
        }
      }
      return null;
    }

    void validateRule(YamlNode node, bool enabled) {
      var value = node.value;
      if (value == null) return;

      final rule = getRegisteredLint(value as Object);
      if (rule == null) {
        reporter.reportErrorForSpan(UNDEFINED_LINT_WARNING, node.span, [value]);
        return;
      }

      if (enabled) {
        final incompatibleRule = findIncompatibleRule(rule);
        if (incompatibleRule != null) {
          reporter.reportErrorForSpan(
              INCOMPATIBLE_LINT_WARNING, node.span, [value, incompatibleRule]);
        } else if (!seenRules.add(rule.name)) {
          reporter.reportErrorForSpan(DUPLICATE_RULE_HINT, node.span, [value]);
        }
      }
      // Report removed or deprecated lint warnings defined directly (and not in
      // includes).
      if (sourceIsOptionsForContextRoot) {
        var state = rule.state;
        if (isDeprecatedInCurrentSdk(state)) {
          reporter.reportErrorForSpan(DEPRECATED_LINT_HINT, node.span, [value]);
        } else if (isRemovedInCurrentSdk(state)) {
          var since = state.since.toString();
          var replacedBy = (state as RemovedState).replacedBy;
          if (replacedBy != null) {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.REPLACED_LINT,
                node.span,
                [value, since, replacedBy]);
          } else {
            reporter.reportErrorForSpan(AnalysisOptionsWarningCode.REMOVED_LINT,
                node.span, [value, since]);
          }
        }
      }
    }

    if (rules is YamlList) {
      for (var ruleNode in rules.nodes) {
        validateRule(ruleNode, true);
      }
    } else if (rules is YamlMap) {
      for (var ruleEntry in rules.nodeMap.entries) {
        validateRule(ruleEntry.key, ruleEntry.value.value as bool);
      }
    }
  }
}
