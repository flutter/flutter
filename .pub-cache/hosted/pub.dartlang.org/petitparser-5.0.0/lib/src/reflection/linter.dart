import 'package:meta/meta.dart';

import '../core/parser.dart';
import 'analyzer.dart';
import 'internal/linter_rules.dart';

/// The type of a linter issue.
enum LinterType {
  info,
  warning,
  error,
}

/// Encapsulates a single linter rule.
@immutable
abstract class LinterRule {
  /// Constructs a new linter rule.
  const LinterRule(this.type, this.title);

  /// Severity of issues detected by this rule.
  final LinterType type;

  /// Human readable title of this rule.
  final String title;

  /// Executes this rule using a provided [analyzer] on a [parser]. Expected
  /// to call [callback] zero or more times as issues are detected.
  void run(Analyzer analyzer, Parser parser, LinterCallback callback);

  @override
  String toString() => 'LinterRule(type: $type, title: $title)';
}

/// Encapsulates a single linter issue.
@immutable
class LinterIssue {
  /// Constructs a new linter rule.
  const LinterIssue(this.rule, this.parser, this.description, [this.fixer]);

  /// Rule that identified the issue.
  final LinterRule rule;

  /// Severity of the issue.
  LinterType get type => rule.type;

  /// Title of the issue.
  String get title => rule.title;

  /// Parser object with the issue.
  final Parser parser;

  /// Detailed explanation of the issue.
  final String description;

  /// Optional function to fix the issue in-place.
  final void Function()? fixer;

  @override
  String toString() => 'LinterIssue(type: $type, title: $title, '
      'parser: $parser, description: $description)';
}

/// Function signature of a linter callback that is called whenever a linter
/// rule identifies an issue.
typedef LinterCallback = void Function(LinterIssue issue);

/// All default linter rules to be run.
const allLinterRules = [
  UnresolvedSettable(),
  UnnecessaryResolvable(),
  RepeatedChoice(),
  UnreachableChoice(),
  NullableRepeater(),
  LeftRecursion(),
  NestedChoice(),
  OverlappingChoice(),
  UnusedResult(),
];

/// Returns a list of linter issues found when analyzing the parser graph
/// reachable from [parser].
///
/// The optional [callback] is triggered during the search for each issue
/// discovered.
///
/// A custom list of [rules] can be provided, otherwise [allLinterRules] are
/// used and filtered by the set of [excludedRules] and [excludedTypes] (rules
/// of `LinterType.info` are ignored by default).
List<LinterIssue> linter(Parser parser,
    {LinterCallback? callback,
    List<LinterRule>? rules,
    Set<String> excludedRules = const {},
    Set<LinterType> excludedTypes = const {LinterType.info}}) {
  final issues = <LinterIssue>[];
  final analyzer = Analyzer(parser);
  final selectedRules = rules ??
      allLinterRules
          .where((rule) =>
              !excludedRules.contains(rule.title) &&
              !excludedTypes.contains(rule.type))
          .toList(growable: false);
  for (final parser in analyzer.parsers) {
    for (final rule in selectedRules) {
      rule.run(analyzer, parser, (issue) {
        if (callback != null) {
          callback(issue);
        }
        issues.add(issue);
      });
    }
  }
  return issues;
}
