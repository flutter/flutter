// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Evaluation of a GN build file into the converter's intermediate form.
///
/// GN build files are programs; what Bazel needs is data. This library runs
/// the program symbolically: assignments are recorded together with the
/// condition under which they happen (`if (is_linux) { sources += [...] }`
/// becomes "under `is_linux`, append these to `sources`"), and conditions
/// are kept as formulas over GN's variables except where [Assumptions] fix a
/// variable's value, in which case the dead branches are skipped exactly as
/// GN would skip them.
///
/// The subset of GN understood here is the one the engine's first-party
/// build files use. Anything else is a [GnError] naming the file and line
/// (strict mode): the converter must never guess.
library;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'gn_ast.dart';

// ---------------------------------------------------------------------------
// Conditions
// ---------------------------------------------------------------------------

/// The platform predicates `//build/config/BUILDCONFIG.gn` sets in one
/// `if/else if` chain over `current_os`, so that exactly one of them holds in
/// any toolchain. `is_apple` and `is_posix` are derived from them and not
/// alternatives of the family.
const Set<String> exclusiveOsPredicates = <String>{
  'is_android',
  'is_fuchsia',
  'is_ios',
  'is_linux',
  'is_mac',
  'is_qnx',
  'is_wasm',
  'is_win',
};

/// A boolean formula over GN variables.
///
/// [and] and [or] simplify as they combine: constants, repeated terms, a term
/// beside its negation, and the families of mutually exclusive alternatives
/// (the OS predicates; the values one variable is compared with), so that the
/// path of `else if (is_mac)` after `if (is_ios)` is `is_mac`, not
/// `!is_ios && is_mac`. Nothing else is rewritten: the formulas stay in the
/// shape the GN source gave them.
@immutable
sealed class Condition {
  const Condition();

  static const Condition always = ConditionConstant(true);
  static const Condition never = ConditionConstant(false);

  Condition and(Condition other) => conjunction(<Condition>[this, other]);

  Condition or(Condition other) => disjunction(<Condition>[this, other]);

  /// The conjunction of [operands], simplified.
  static Condition conjunction(List<Condition> operands) {
    final terms = <Condition>[];
    for (final operand in operands) {
      if (operand == never) {
        return never;
      }
      for (final Condition term in operand is ConditionAnd ? operand.terms : <Condition>[operand]) {
        if (term == always || terms.contains(term)) {
          continue;
        }
        if (terms.contains(term.negated)) {
          return never;
        }
        terms.add(term);
      }
    }
    // Asserting one alternative of a family denies the others: `is_mac`
    // beside `is_ios` never holds, beside `!is_ios` it says it all.
    final asserted = <String, String>{};
    for (final term in terms) {
      final _Alternative? alternative = term._alternative;
      if (alternative == null || !alternative.asserted) {
        continue;
      }
      final String? other = asserted[alternative.family];
      if (other != null && other != alternative.member) {
        return never;
      }
      asserted[alternative.family] = alternative.member;
    }
    terms.removeWhere((Condition term) {
      final _Alternative? alternative = term._alternative;
      return alternative != null &&
          !alternative.asserted &&
          asserted[alternative.family] != null &&
          asserted[alternative.family] != alternative.member;
    });
    return switch (terms.length) {
      0 => always,
      1 => terms.single,
      _ => ConditionAnd(terms),
    };
  }

  /// The disjunction of [operands], simplified (the dual of [conjunction]:
  /// denying two alternatives of a family always holds, and denying one
  /// subsumes asserting another).
  static Condition disjunction(List<Condition> operands) {
    final terms = <Condition>[];
    for (final operand in operands) {
      if (operand == always) {
        return always;
      }
      for (final Condition term in operand is ConditionOr ? operand.terms : <Condition>[operand]) {
        if (term == never || terms.contains(term)) {
          continue;
        }
        if (terms.contains(term.negated)) {
          return always;
        }
        terms.add(term);
      }
    }
    final denied = <String, String>{};
    for (final term in terms) {
      final _Alternative? alternative = term._alternative;
      if (alternative == null || alternative.asserted) {
        continue;
      }
      final String? other = denied[alternative.family];
      if (other != null && other != alternative.member) {
        return always;
      }
      denied[alternative.family] = alternative.member;
    }
    terms.removeWhere((Condition term) {
      final _Alternative? alternative = term._alternative;
      return alternative != null &&
          alternative.asserted &&
          denied[alternative.family] != null &&
          denied[alternative.family] != alternative.member;
    });
    return switch (terms.length) {
      0 => never,
      1 => terms.single,
      _ => ConditionOr(terms),
    };
  }

  /// This formula as the assertion or denial of one alternative of a family
  /// of mutually exclusive ones, if it is one.
  _Alternative? get _alternative => switch (this) {
    ConditionVariable(:final String name) when exclusiveOsPredicates.contains(name) => _Alternative(
      'current_os',
      name,
      asserted: true,
    ),
    ConditionNot(operand: ConditionVariable(:final String name))
        when exclusiveOsPredicates.contains(name) =>
      _Alternative('current_os', name, asserted: false),
    ConditionComparison(:final String name, :final bool equals, :final String value) =>
      _Alternative(name, value, asserted: equals),
    _ => null,
  };

  Condition get negated => switch (this) {
    ConditionConstant(:final bool value) => ConditionConstant(!value),
    ConditionNot(:final Condition operand) => operand,
    ConditionComparison(:final String name, :final bool equals, :final String value) =>
      ConditionComparison(name, !equals, value),
    ConditionAnd(:final List<Condition> terms) => disjunction(<Condition>[
      for (final Condition t in terms) t.negated,
    ]),
    ConditionOr(:final List<Condition> terms) => conjunction(<Condition>[
      for (final Condition t in terms) t.negated,
    ]),
    _ => ConditionNot(this),
  };

  /// The formula as GN would write it, for comments and messages.
  String get gnSource;

  @override
  String toString() => gnSource;
}

final class ConditionConstant extends Condition {
  const ConditionConstant(this.value);

  final bool value;

  @override
  String get gnSource => value ? 'true' : 'false';

  @override
  bool operator ==(Object other) => other is ConditionConstant && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// A boolean GN variable, such as `is_linux` or `enable_unittests`.
final class ConditionVariable extends Condition {
  const ConditionVariable(this.name);

  final String name;

  @override
  String get gnSource => name;

  @override
  bool operator ==(Object other) => other is ConditionVariable && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// `variable == "literal"` or `variable != "literal"`.
final class ConditionComparison extends Condition {
  const ConditionComparison(this.name, this.equals, this.value);

  final String name;
  final bool equals;
  final String value;

  @override
  String get gnSource => '$name ${equals ? '==' : '!='} "$value"';

  @override
  bool operator ==(Object other) =>
      other is ConditionComparison &&
      other.name == name &&
      other.equals == equals &&
      other.value == value;

  @override
  int get hashCode => Object.hash(name, equals, value);
}

final class ConditionNot extends Condition {
  const ConditionNot(this.operand);

  final Condition operand;

  @override
  String get gnSource =>
      '!${operand is ConditionVariable ? operand.gnSource : '(${operand.gnSource})'}';

  @override
  bool operator ==(Object other) => other is ConditionNot && other.operand == operand;

  @override
  int get hashCode => Object.hash('not', operand);
}

final class ConditionAnd extends Condition {
  const ConditionAnd(this.terms);

  final List<Condition> terms;

  @override
  String get gnSource =>
      terms.map((Condition t) => t is ConditionOr ? '(${t.gnSource})' : t.gnSource).join(' && ');

  @override
  bool operator ==(Object other) => other is ConditionAnd && _sameTerms(terms, other.terms);

  @override
  int get hashCode => Object.hashAll(<Object>['and', ...terms]);
}

final class ConditionOr extends Condition {
  const ConditionOr(this.terms);

  final List<Condition> terms;

  @override
  String get gnSource => terms.map((Condition t) => t.gnSource).join(' || ');

  @override
  bool operator ==(Object other) => other is ConditionOr && _sameTerms(terms, other.terms);

  @override
  int get hashCode => Object.hashAll(<Object>['or', ...terms]);
}

bool _sameTerms(List<Condition> a, List<Condition> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// One alternative of a family of mutually exclusive ones (`is_mac` of the
/// OS predicates; `"wasm"` of `target_os`), asserted or denied.
final class _Alternative {
  const _Alternative(this.family, this.member, {required this.asserted});

  final String family;
  final String member;
  final bool asserted;
}

// ---------------------------------------------------------------------------
// Values
// ---------------------------------------------------------------------------

/// A GN value, as far as the converter follows them.
@immutable
sealed class GnValue {
  const GnValue();
}

final class GnStringValue extends GnValue {
  const GnStringValue(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is GnStringValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '"$value"';
}

final class GnBoolValue extends GnValue {
  const GnBoolValue(this.value);

  final bool value;

  @override
  bool operator ==(Object other) => other is GnBoolValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

final class GnIntValue extends GnValue {
  const GnIntValue(this.value);

  final int value;

  @override
  bool operator ==(Object other) => other is GnIntValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// A reference to a variable the converter does not evaluate (one that an
/// imported `.gni` defines, such as `flutter_cflags_objc`). The Bazel side
/// maps these by name.
final class GnReference extends GnValue {
  const GnReference(this.name);

  final String name;

  @override
  bool operator ==(Object other) => other is GnReference && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// A GN scope held in a variable: `x = { a = [...] }`, or a template's
/// `invoker`. Members are read as `x.a`.
final class GnScopeValue extends GnValue {
  const GnScopeValue(this.variables);

  final Map<String, GnVariable> variables;

  @override
  String toString() => '{${variables.keys.join(', ')}}';
}

/// The root under which the evaluator places GN's build directory
/// (`root_build_dir`, `root_out_dir`; `target_out_dir` is `//@out/obj/<dir>`).
const String buildDirRoot = '//@out';

/// The root under which the evaluator places GN's generated-file tree
/// (`root_gen_dir`; `target_gen_dir` is `//@gen/<dir>`).
const String genDirRoot = '//@gen';

/// Brackets a `rebase_path(x, root_build_dir)` result inside a string: the
/// absolute GN path of x, for the emitter to turn into a Bazel path.
const String rebasedPathMarker = '\u0001';

/// A value the converter cannot know: the result of `rebase_path()` to a
/// directory other than the build directory, or of `exec_script()`. It may
/// be stored (a `.gni` may compute arguments the engine never uses) but is
/// an error wherever it would reach the output.
final class GnOpaqueValue extends GnValue {
  const GnOpaqueValue(this.description);

  /// What produced it, for the error message.
  final String description;

  @override
  String toString() => '<$description>';
}

/// A boolean whose value the assumptions did not decide: the result of
/// `use_x = enable_unittests && shell_enable_gl`, kept as a formula so that
/// `if (use_x)` can be followed.
final class GnConditionValue extends GnValue {
  const GnConditionValue(this.condition);

  final Condition condition;

  @override
  bool operator ==(Object other) => other is GnConditionValue && other.condition == condition;

  @override
  int get hashCode => condition.hashCode;

  @override
  String toString() => '($condition)';
}

/// The comments around one list item in the GN source.
@immutable
final class GnItemComments {
  const GnItemComments({this.before = const <String>[], this.suffix = const <String>[]});

  static const GnItemComments none = GnItemComments();

  /// Comment lines before the item.
  final List<String> before;

  /// Comments on the item's own line, after it.
  final List<String> suffix;

  bool get isEmpty => before.isEmpty && suffix.isEmpty;
}

/// One assignment to a variable: `op` is `=`, `+=` or `-=`; `items` are the
/// elements for lists and the single value for scalars.
@immutable
final class GnAssignment {
  const GnAssignment(
    this.location,
    this.condition,
    this.op,
    this.items, {
    this.sourceConditions = const <String>[],
    this.comments = const <String>[],
    this.itemComments = const <GnItemComments>[],
  });

  final GnLocation location;

  /// The condition under which the assignment happens, with the
  /// [Assumptions] applied.
  final Condition condition;

  /// The enclosing `if` conditions as written in GN, outermost first, before
  /// any assumption was applied (for comments in the generated files).
  final List<String> sourceConditions;

  final String op;
  final List<GnValue> items;

  /// The comment lines before the assignment.
  final List<String> comments;

  /// The comments of each item, parallel to [items] (or empty when no item
  /// has any).
  final List<GnItemComments> itemComments;

  bool get isUnconditional => condition == Condition.always;

  /// The comments of `items[index]`.
  GnItemComments commentsOf(int index) =>
      index < itemComments.length ? itemComments[index] : GnItemComments.none;

  @override
  String toString() => '[$condition] $op $items';
}

/// Everything that was assigned to one variable, in program order.
final class GnVariable {
  GnVariable(this.name, {required this.isList, this.forwarded = false});

  final String name;

  /// Whether the variable holds a list (as opposed to a string, boolean or
  /// integer), decided by its first assignment.
  final bool isList;

  /// Whether the variable arrived through `forward_variables_from()` rather
  /// than being written where it is: a template forwards its invoker's
  /// bookkeeping (`enabled`, ...) along with the real target variables.
  final bool forwarded;
  final List<GnAssignment> assignments = <GnAssignment>[];

  /// The items of a list variable when every assignment is unconditional
  /// (the common case), or null if any is conditional.
  List<GnValue>? get unconditionalItems {
    final items = <GnValue>[];
    for (final GnAssignment a in assignments) {
      if (!a.isUnconditional) {
        return null;
      }
      switch (a.op) {
        case '=':
          items
            ..clear()
            ..addAll(a.items);
        case '+=':
          items.addAll(a.items);
        case '-=':
          items.removeWhere(a.items.contains);
      }
    }
    return items;
  }

  /// The values a scalar variable may hold and when: its `=` assignments in
  /// program order, each in force where its own condition holds and no later
  /// assignment's does (GN's last write wins). One case under
  /// [Condition.always] is the plain variable; several are what a
  /// `select()` renders.
  List<GnScalarCase> cases(GnLocation use) {
    if (isList) {
      throw GnError(use, '$name is a list');
    }
    final cases = <GnScalarCase>[];
    for (var i = 0; i < assignments.length; i++) {
      final GnAssignment assignment = assignments[i];
      if (assignment.op != '=' || assignment.items.length != 1) {
        throw GnError(assignment.location, '${assignment.op} on the scalar $name is not supported');
      }
      Condition when = assignment.condition;
      for (final GnAssignment later in assignments.skip(i + 1)) {
        // A later write that cannot happen together with this one (the other
        // branch of the `if`, another OS) cannot override it.
        if (when.and(later.condition) != Condition.never) {
          when = when.and(later.condition.negated);
        }
      }
      if (when != Condition.never) {
        cases.add(GnScalarCase(when, assignment.items.single, assignment));
      }
    }
    return cases;
  }
}

/// One value a scalar variable holds, and the condition under which it is
/// the one in force.
@immutable
final class GnScalarCase {
  const GnScalarCase(this.condition, this.value, this.assignment);

  final Condition condition;
  final GnValue value;

  /// The assignment the value came from (for its comments and location).
  final GnAssignment assignment;

  @override
  String toString() => '[$condition] $value';
}

/// A target: a call of a GN rule or template with a block.
final class GnTarget {
  GnTarget(this.location, this.rule, this.name, this.condition);

  final GnLocation location;

  /// `source_set`, `executable`, `config`, `test_fixtures`, ...
  final String rule;
  final String name;

  /// The condition under which the target exists at all.
  final Condition condition;

  /// The target's variables (`sources`, `deps`, ...), in first-assignment
  /// order.
  final Map<String, GnVariable> variables = <String, GnVariable>{};

  /// Comments that preceded the target in the GN file.
  List<String> comments = const <String>[];
}

/// The result of evaluating one GN file.
final class GnFileEvaluation {
  GnFileEvaluation(this.file);

  final String file;
  final List<String> imports = <String>[];
  final List<GnTarget> targets = <GnTarget>[];

  /// Targets that were asked to be skipped and were found, in file order.
  final List<String> skipped = <String>[];

  /// The configs GN applies to each target of this file through
  /// `all_dependent_configs`: a target's own, and those of every target it
  /// depends on, directly or indirectly, through `deps` or `public_deps` —
  /// private dependencies do not stop them, unlike `public_configs`. Only
  /// dependencies within this file are followed (`:name`), and only
  /// unconditional ones (see [conditionalAllDependentConfigs]); the result
  /// maps target names to config labels as written (`:name_public`).
  Map<String, Set<String>> get allDependentConfigs => _propagation().$1;

  /// The targets whose propagated configs depend on a condition the
  /// assumptions did not decide (a conditional dep or a conditional
  /// `all_dependent_configs`), which [allDependentConfigs] leaves out.
  Set<String> get conditionalAllDependentConfigs => _propagation().$2;

  (Map<String, Set<String>>, Set<String>) _propagation() {
    final byName = <String, GnTarget>{for (final GnTarget t in targets) t.name: t};
    final result = <String, Set<String>>{};
    final conditional = <String>{};
    Set<String> visit(GnTarget target, Set<String> visiting) {
      final Set<String>? done = result[target.name];
      if (done != null) {
        return done;
      }
      final configs = <String>{};
      if (visiting.add(target.name)) {
        for (final GnAssignment a
            in target.variables['all_dependent_configs']?.assignments ?? const <GnAssignment>[]) {
          if (!a.isUnconditional) {
            conditional.add(target.name);
            continue;
          }
          for (final GnValue v in a.items) {
            if (v is GnStringValue && a.op != '-=') {
              configs.add(v.value);
            }
          }
        }
        for (final name in <String>['deps', 'public_deps']) {
          for (final GnAssignment a
              in target.variables[name]?.assignments ?? const <GnAssignment>[]) {
            for (final GnValue v in a.items) {
              final GnTarget? dep = v is GnStringValue && v.value.startsWith(':')
                  ? byName[v.value.substring(1)]
                  : null;
              if (dep == null || a.op == '-=') {
                continue;
              }
              final Set<String> theirs = visit(dep, visiting);
              if (a.isUnconditional) {
                configs.addAll(theirs);
                if (conditional.contains(dep.name)) {
                  conditional.add(target.name);
                }
              } else if (theirs.isNotEmpty || conditional.contains(dep.name)) {
                conditional.add(target.name);
              }
            }
          }
        }
        visiting.remove(target.name);
      }
      result[target.name] = configs;
      return configs;
    }

    for (final GnTarget target in targets) {
      visit(target, <String>{});
    }
    return (result, conditional);
  }
}

// ---------------------------------------------------------------------------
// Assumptions
// ---------------------------------------------------------------------------

/// What holds in every configuration the engine builds, beneath whatever the
/// [Assumptions] say (`--assume=none` included): `tools/gn` passes
/// `is_clang=true` to every configuration it writes (`--no-clang` is a
/// developer escape hatch no builder uses), and the Bazel toolchains are
/// clang only, so a Bazel build never has a `!is_clang` branch to take;
/// `dart_src` (dart.gni) is where DEPS puts the Dart SDK and where the Bazel
/// wrap builds it from, and no builder overrides it.
const Map<String, GnValue> buildInvariants = <String, GnValue>{
  'is_clang': GnBoolValue(true),
  'dart_src': GnStringValue('//flutter/third_party/dart'),
};

/// Values the converter may take as given for GN variables (build arguments
/// and platform predicates), so that the branches they rule out are skipped
/// and the ones they imply are unconditional.
final class Assumptions {
  Assumptions(Map<String, GnValue> values)
    : _values = Map<String, GnValue>.unmodifiable(<String, GnValue>{...buildInvariants, ...values});

  final Map<String, GnValue> _values;

  GnValue? operator [](String name) => _values[name];

  /// These assumptions with [overrides] added or replaced.
  Assumptions withValues(Map<String, GnValue> overrides) =>
      Assumptions(<String, GnValue>{..._values, ...overrides});

  /// Parses `name=value` where value is `true`, `false`, an integer or a
  /// string (quoted or not).
  static GnValue parseValue(String text) {
    switch (text) {
      case 'true':
        return const GnBoolValue(true);
      case 'false':
        return const GnBoolValue(false);
    }
    final int? number = int.tryParse(text);
    if (number != null) {
      return GnIntValue(number);
    }
    if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
      return GnStringValue(text.substring(1, text.length - 1));
    }
    return GnStringValue(text);
  }
}

// ---------------------------------------------------------------------------
// Evaluator
// ---------------------------------------------------------------------------

/// The GN functions that define targets, with blocks.
const Set<String> gnTargetRules = <String>{
  'action',
  'action_foreach',
  'config',
  'copy',
  'executable',
  'group',
  'shared_library',
  'source_set',
  'static_library',
};

/// Target types that BUILDCONFIG.gn defines as templates over the built-in
/// ones, with what they amount to in the engine's build: `component` is a
/// source_set, since `is_component_build` is false (every object of Skia is
/// linked into whatever depends on it, which Bazel's alwayslink keeps).
const Map<String, String> gnRuleAliases = <String, String>{'component': 'source_set'};

/// Which imported files the evaluator runs, and which it takes as known.
///
/// A `.gni` under one of [evaluatedPrefixes] (GN paths) is loaded and
/// evaluated like GN would, so that its lists, arguments and templates are
/// available. Files in [known] are not evaluated: the mapping tables describe
/// what they define (variables through the known external variables and the
/// assumptions, templates through the template mappings). Importing any
/// other file is an error.
final class ImportPolicy {
  const ImportPolicy({this.evaluatedPrefixes = const <String>{}, this.known = const <String>{}});

  final Set<String> evaluatedPrefixes;
  final Set<String> known;

  bool evaluates(String gnPath) => evaluatedPrefixes.any(gnPath.startsWith);
}

/// Evaluates [file] (the tree of one `BUILD.gn`).
///
/// [templates] are the names of the `.gni` templates that may be invoked like
/// rules; [externalVariables] the names that imported files define and that
/// may be read (they become [GnReference]s) or tested (they stay symbolic).
/// Targets named in [skipTargets] are not evaluated at all (so that what is
/// inside them need not be understood); they are listed in the result.
/// Imports are resolved and loaded through [tree] according to
/// [importPolicy]; without a tree, imports are only recorded.
GnFileEvaluation evaluateGnFile(
  GnBlock file, {
  required Assumptions assumptions,
  Set<String> templates = const <String>{},
  Set<String> externalVariables = const <String>{},
  Set<String> skipTargets = const <String>{},
  GnSourceTree? tree,
  ImportPolicy importPolicy = const ImportPolicy(),
}) {
  final settings = _Settings(
    assumptions: assumptions,
    templates: templates,
    externalVariables: externalVariables,
    skipTargets: skipTargets,
    tree: tree,
    importPolicy: importPolicy,
    importCache: <String, _ImportedFile>{},
  );
  final evaluator = _Evaluator(settings, file.location.file);
  evaluator.evaluateFile(file);
  return evaluator.result;
}

/// Target variables that BUILDCONFIG.gn's set_defaults() initializes, so
/// that a target may `+=` to them without assigning them first.
const Set<String> _predefinedTargetVariables = <String>{'configs'};

/// Functions whose calls have no effect on the data the converter extracts.
const Set<String> _ignoredFunctions = <String>{'assert', 'not_needed', 'print', 'set_defaults'};

final class _Scope {
  _Scope(this.parent, {this.isTarget = false});

  final _Scope? parent;

  /// Whether this is the scope of a target's block.
  final bool isTarget;
  final Map<String, GnVariable> variables = <String, GnVariable>{};
  final Map<String, _Template> templates = <String, _Template>{};

  GnVariable? lookup(String name) => variables[name] ?? parent?.lookup(name);

  _Template? lookupTemplate(String name) => templates[name] ?? parent?.lookupTemplate(name);
}

/// A `template("name") { body }`: a closure over the scope it was defined in.
final class _Template {
  const _Template(this.name, this.body, this.scope, this.location);

  final String name;
  final GnBlock body;
  final _Scope scope;
  final GnLocation location;
}

/// What an evaluated `.gni` contributes to its importers.
final class _ImportedFile {
  const _ImportedFile(this.variables, this.templates);

  final Map<String, GnVariable> variables;
  final Map<String, _Template> templates;
}

/// One element of an expression's value: the GN value, the comments around
/// it, and the condition it holds under (always, unless it came from a
/// variable with conditional appends).
final class _Value {
  const _Value(
    this.value,
    this.comments, {
    this.condition = Condition.always,
    this.sourceConditions = const <String>[],
  });

  final GnValue value;
  final GnItemComments comments;
  final Condition condition;
  final List<String> sourceConditions;
}

/// The value of an expression while it is evaluated.
final class _Expression {
  const _Expression(this.items, {required this.isList});

  _Expression.scalar(GnValue value)
    : this(<_Value>[_Value(value, GnItemComments.none)], isList: false);

  final List<_Value> items;
  final bool isList;

  /// The value of a scalar expression that holds unconditionally.
  GnValue? get scalar => isList || items.length != 1 || items.single.condition != Condition.always
      ? null
      : items.single.value;

  @override
  String toString() => isList
      ? '[${items.map((_Value i) => i.value).join(', ')}]'
      : items
            .map(
              (_Value i) =>
                  i.condition == Condition.always ? '${i.value}' : '[${i.condition}] ${i.value}',
            )
            .join(' | ');
}

/// What every evaluator of one conversion shares.
final class _Settings {
  const _Settings({
    required this.assumptions,
    required this.templates,
    required this.externalVariables,
    required this.skipTargets,
    required this.tree,
    required this.importPolicy,
    required this.importCache,
  });

  final Assumptions assumptions;
  final Set<String> templates;
  final Set<String> externalVariables;
  final Set<String> skipTargets;
  final GnSourceTree? tree;
  final ImportPolicy importPolicy;
  final Map<String, _ImportedFile> importCache;
}

/// A template invocation in progress: the primary target it defines (the one
/// named `target_name`) takes the invocation's comments.
final class _Invocation {
  const _Invocation(this.targetName, this.comments);

  final String targetName;
  final List<String> comments;
}

final class _Evaluator {
  _Evaluator(this.settings, String file) : result = GnFileEvaluation(file);

  final _Settings settings;
  final GnFileEvaluation result;

  /// The root scope of the file, where imports merge.
  late final _Scope fileScope;

  final List<_Invocation> _invocations = <_Invocation>[];

  /// Whether a `declare_args()` block is being evaluated, in which the
  /// assumptions override the defaults.
  bool _declaringArgs = false;

  Assumptions get assumptions => settings.assumptions;

  void evaluateFile(GnBlock file) {
    fileScope = _Scope(null);
    _evaluateBlock(file, fileScope, Condition.always, const <String>[], target: null);
  }

  // -------------------------------------------------------------------------
  // Statements
  // -------------------------------------------------------------------------

  /// [path] is the condition of the enclosing `if`s with the assumptions
  /// applied; [source] their text as written.
  void _evaluateBlock(
    GnBlock block,
    _Scope scope,
    Condition path,
    List<String> source, {
    required GnTarget? target,
  }) {
    for (final GnNode statement in block.statements) {
      switch (statement) {
        case GnComment():
          // A comment block that stands on its own (a blank line separates it
          // from the next statement); GN attaches the others to their
          // statements as beforeComments.
          break;
        case GnBinary() when statement.isAssignment:
          _evaluateAssignment(statement, scope, path, source, comments: statement.beforeComments);
        case GnCondition():
          _evaluateCondition(statement, scope, path, source, target: target);
        case GnFunctionCall():
          _evaluateCall(
            statement,
            scope,
            path,
            source,
            target: target,
            comments: statement.beforeComments,
          );
        default:
          throw GnError(statement.location, 'unsupported statement (${statement.runtimeType})');
      }
    }
  }

  void _evaluateCondition(
    GnCondition node,
    _Scope scope,
    Condition path,
    List<String> source, {
    required GnTarget? target,
  }) {
    final Condition test = _condition(node.condition, scope);
    final String text = _gnText(node.condition);
    final Condition thenPath = path.and(test);
    if (thenPath != Condition.never) {
      _evaluateBlock(node.thenBlock, scope, thenPath, <String>[...source, text], target: target);
    }
    final GnNode? orElse = node.orElse;
    if (orElse == null) {
      return;
    }
    final Condition elsePath = path.and(test.negated);
    if (elsePath == Condition.never) {
      return;
    }
    final elseSource = <String>[...source, '!($text)'];
    switch (orElse) {
      case GnBlock():
        _evaluateBlock(orElse, scope, elsePath, elseSource, target: target);
      case GnCondition():
        _evaluateCondition(orElse, scope, elsePath, elseSource, target: target);
      default:
        throw GnError(orElse.location, 'unsupported else branch');
    }
  }

  /// The GN source of an expression, reconstructed from the tree.
  static String _gnText(GnNode node) {
    return switch (node) {
      GnIdentifier(:final String name) => name,
      GnLiteral(:final String raw) => raw,
      GnUnary(:final String op, :final GnNode operand) =>
        '$op${operand is GnBinary ? '(${_gnText(operand)})' : _gnText(operand)}',
      GnBinary(:final String op, :final GnNode left, :final GnNode right) =>
        '${_gnText(left)} $op ${right is GnBinary && right.op != op ? '(${_gnText(right)})' : _gnText(right)}',
      GnAccessor(:final String base, :final GnNode index) =>
        index is GnIdentifier ? '$base.${index.name}' : '$base[${_gnText(index)}]',
      GnFunctionCall(:final String name, :final List<GnNode> args) =>
        '$name(${args.map(_gnText).join(', ')})',
      _ => '<${node.runtimeType}>',
    };
  }

  void _evaluateCall(
    GnFunctionCall call,
    _Scope scope,
    Condition condition,
    List<String> source, {
    required GnTarget? target,
    required List<String> comments,
  }) {
    if (_ignoredFunctions.contains(call.name)) {
      return;
    }
    switch (call.name) {
      case 'import':
        if (target != null) {
          // The .gni's variables enter the block's scope; when the file was
          // imported at file level already (skunicode, skparagraph) they
          // are visible through the enclosing scope and nothing changes.
          // Any other file would make the target's variables depend on an
          // import the converter never evaluated.
          final String gnPath = _importPath(call, scope);
          if (!result.imports.contains(gnPath)) {
            throw GnError(call.location, 'import of $gnPath inside a target');
          }
          return;
        }
        _import(call, scope);
        return;
      case 'declare_args':
        _declareArgs(call, scope, condition, source);
        return;
      case 'template':
        _defineTemplate(call, scope);
        return;
      case 'forward_variables_from':
        _forwardVariablesFrom(call, scope);
        return;
      case 'foreach':
      case 'exec_script':
        throw GnError(call.location, '${call.name}() is not supported by the converter');
    }
    if (target != null) {
      throw GnError(call.location, 'target ${call.name}() nested inside target ${target.name}');
    }
    // A skipped target is left alone before anything about it is checked,
    // so that a template the converter does not know can be skipped.
    if (call.args.length == 1) {
      final GnNode arg = call.args.single;
      if (arg is GnLiteral && arg.isString && settings.skipTargets.contains(arg.stringValue)) {
        result.skipped.add(arg.stringValue);
        return;
      }
    }
    final _Template? template = scope.lookupTemplate(call.name);
    if (template != null) {
      _invokeTemplate(template, call, scope, condition, source, comments: comments);
      return;
    }
    final String rule;
    final String name;
    if (call.name == 'target') {
      // target(type, name): the type is an expression.
      if (call.args.length != 2) {
        throw GnError(call.location, 'target() takes a type and a name');
      }
      rule = _stringExpression(call.args[0], scope);
      name = _stringExpression(call.args[1], scope);
    } else {
      rule = call.name;
      name = _stringArgument(call, scope);
    }
    final String resolvedRule = gnRuleAliases[rule] ?? rule;
    if (!gnTargetRules.contains(resolvedRule) && !settings.templates.contains(resolvedRule)) {
      throw GnError(call.location, 'unknown function or template $rule()');
    }
    final GnBlock? block = call.block;
    if (block == null) {
      throw GnError(call.location, '${call.name}() without a block');
    }
    final _Invocation? invocation = _invocations.isEmpty ? null : _invocations.last;
    final newTarget = GnTarget(call.location, resolvedRule, name, condition)
      ..comments = invocation != null && invocation.targetName == name
          ? invocation.comments
          : comments;
    final targetScope = _Scope(scope, isTarget: true);
    _evaluateBlock(block, targetScope, Condition.always, const <String>[], target: newTarget);
    newTarget.variables.addAll(targetScope.variables);
    result.targets.add(newTarget);
  }

  String _stringArgument(GnFunctionCall call, _Scope scope) {
    if (call.args.length != 1) {
      throw GnError(call.location, '${call.name}() takes one argument');
    }
    return _stringExpression(call.args.single, scope);
  }

  /// The value of an expression that must be a string.
  String _stringExpression(GnNode node, _Scope scope) {
    final _Expression expression = _expression(node, scope);
    final String? value = _agreedString(expression);
    if (value == null) {
      final got = expression.isList
          ? 'a list'
          : expression.scalar == null
          ? 'a value that depends on a condition ($expression)'
          : '$expression';
      throw GnError(node.location, 'expected one string, got $got');
    }
    return value;
  }

  // -------------------------------------------------------------------------
  // Imports, arguments, templates
  // -------------------------------------------------------------------------

  void _import(GnFunctionCall call, _Scope scope) {
    final String gnPath = _importPath(call, scope);
    result.imports.add(gnPath);
    final GnSourceTree? tree = settings.tree;
    if (tree == null) {
      // Imports are only recorded; what they define must be known.
      return;
    }
    if (settings.importPolicy.known.contains(gnPath)) {
      return;
    }
    if (!settings.importPolicy.evaluates(gnPath)) {
      throw GnError(
        call.location,
        'import of $gnPath is neither evaluated nor known to the converter',
      );
    }
    final _ImportedFile imported = settings.importCache.putIfAbsent(gnPath, () {
      final String file = tree.resolve(gnPath);
      final evaluator = _Evaluator(settings, file)..evaluateFile(tree.load(file));
      if (evaluator.result.targets.isNotEmpty) {
        throw GnError(
          evaluator.result.targets.first.location,
          'target defined in an imported file',
        );
      }
      // Underscore names are private to the file.
      return _ImportedFile(
        <String, GnVariable>{
          for (final MapEntry<String, GnVariable> e in evaluator.fileScope.variables.entries)
            if (!e.key.startsWith('_')) e.key: e.value,
        },
        <String, _Template>{
          for (final MapEntry<String, _Template> e in evaluator.fileScope.templates.entries)
            if (!e.key.startsWith('_')) e.key: e.value,
        },
      );
    });
    // Merge; a conflict with a different value is GN's "import clobbers" error.
    for (final MapEntry<String, GnVariable> e in imported.variables.entries) {
      final GnVariable? existing = scope.variables[e.key];
      if (existing != null && existing != e.value && !_sameValue(existing, e.value)) {
        throw GnError(call.location, 'import of $gnPath would clobber ${e.key}');
      }
      scope.variables[e.key] = e.value;
    }
    for (final MapEntry<String, _Template> e in imported.templates.entries) {
      final _Template? existing = scope.templates[e.key];
      if (existing != null && existing != e.value) {
        throw GnError(call.location, 'import of $gnPath would clobber template ${e.key}()');
      }
      scope.templates[e.key] = e.value;
    }
  }

  static bool _sameValue(GnVariable a, GnVariable b) {
    final List<GnValue>? x = a.unconditionalItems;
    final List<GnValue>? y = b.unconditionalItems;
    if (x == null || y == null || x.length != y.length) {
      return false;
    }
    for (var i = 0; i < x.length; i++) {
      if (x[i] != y[i]) {
        return false;
      }
    }
    return true;
  }

  /// The GN path (`//a/b.gni`) of an import, resolved against the importing
  /// file's directory when relative.
  String _importPath(GnFunctionCall call, _Scope scope) {
    final String path = _stringArgument(call, scope);
    if (path.startsWith('//')) {
      return path;
    }
    final GnSourceTree? tree = settings.tree;
    if (tree == null) {
      return path;
    }
    return tree.gnPath(p.join(p.dirname(call.location.file), path));
  }

  /// `declare_args() { x = default }`: the assumptions play the role of
  /// args.gn and override the defaults; an argument the Bazel side defines
  /// (one of the external variables, with no assumption) keeps its name --
  /// the default's formula is how GN picks a value per platform, which Bazel
  /// does in configuration instead.
  void _declareArgs(GnFunctionCall call, _Scope scope, Condition condition, List<String> source) {
    final GnBlock? block = call.block;
    if (block == null) {
      throw GnError(call.location, 'declare_args() without a block');
    }
    final bool outer = _declaringArgs;
    _declaringArgs = true;
    try {
      _evaluateBlock(block, scope, condition, source, target: null);
    } finally {
      _declaringArgs = outer;
    }
  }

  void _defineTemplate(GnFunctionCall call, _Scope scope) {
    final String name = _stringArgument(call, scope);
    final GnBlock? body = call.block;
    if (body == null) {
      throw GnError(call.location, 'template() without a block');
    }
    scope.templates[name] = _Template(name, body, scope, call.location);
  }

  /// Runs a template: the invoking block becomes the `invoker` scope, the
  /// body runs as a closure over the defining scope with `target_name` set.
  void _invokeTemplate(
    _Template template,
    GnFunctionCall call,
    _Scope scope,
    Condition condition,
    List<String> source, {
    required List<String> comments,
  }) {
    final String name = _stringArgument(call, scope);
    final GnBlock? block = call.block;
    if (block == null) {
      throw GnError(call.location, '${call.name}() without a block');
    }
    final invokerScope = _Scope(scope);
    _evaluateBlock(block, invokerScope, Condition.always, const <String>[], target: null);
    final bodyScope = _Scope(template.scope);
    bodyScope.variables['invoker'] = GnVariable('invoker', isList: false)
      ..assignments.add(
        GnAssignment(call.location, Condition.always, '=', <GnValue>[
          GnScopeValue(invokerScope.variables),
        ]),
      );
    bodyScope.variables['target_name'] = GnVariable('target_name', isList: false)
      ..assignments.add(
        GnAssignment(call.location, Condition.always, '=', <GnValue>[GnStringValue(name)]),
      );
    _invocations.add(_Invocation(name, comments));
    try {
      _evaluateBlock(template.body, bodyScope, condition, source, target: null);
    } finally {
      _invocations.removeLast();
    }
  }

  /// `forward_variables_from(scope, "*" | [names], [excluded])`.
  void _forwardVariablesFrom(GnFunctionCall call, _Scope scope) {
    if (call.args.length < 2 || call.args.length > 3) {
      throw GnError(call.location, 'forward_variables_from() takes two or three arguments');
    }
    final GnNode fromNode = call.args[0];
    if (fromNode is! GnIdentifier) {
      throw GnError(fromNode.location, 'forward_variables_from() needs a scope variable');
    }
    final Map<String, GnVariable> from = _scopeVariables(fromNode.name, fromNode.location, scope);
    final Set<String> excluded = call.args.length == 3
        ? _stringList(call.args[2], scope).toSet()
        : const <String>{};
    final GnNode what = call.args[1];
    if (what is GnLiteral && what.isString && what.stringValue == '*') {
      // "*": everything set directly on the scope, clobbering.
      for (final MapEntry<String, GnVariable> e in from.entries) {
        if (!excluded.contains(e.key)) {
          scope.variables[e.key] = _copy(e.value, forwarded: true);
        }
      }
      return;
    }
    for (final String name in _stringList(what, scope)) {
      if (excluded.contains(name)) {
        continue;
      }
      final GnVariable? variable = from[name];
      if (variable == null) {
        continue;
      }
      if (scope.variables.containsKey(name)) {
        throw GnError(call.location, 'forward_variables_from() would clobber $name');
      }
      scope.variables[name] = _copy(variable, forwarded: true);
    }
  }

  static GnVariable _copy(GnVariable variable, {required bool forwarded}) {
    return GnVariable(variable.name, isList: variable.isList, forwarded: forwarded)
      ..assignments.addAll(variable.assignments);
  }

  List<String> _stringList(GnNode node, _Scope scope) {
    final _Expression value = _expression(node, scope);
    if (!value.isList) {
      throw GnError(node.location, 'expected a list of strings');
    }
    return <String>[
      for (final _Value item in value.items)
        if (item.value is GnStringValue && item.condition == Condition.always)
          (item.value as GnStringValue).value
        else
          throw GnError(node.location, 'expected a list of plain strings, got ${item.value}'),
    ];
  }

  /// The variables of the scope held by [name] (`invoker`, or a variable
  /// assigned a `{ ... }` block).
  Map<String, GnVariable> _scopeVariables(String name, GnLocation location, _Scope scope) {
    final GnVariable? variable = scope.lookup(name);
    final List<GnValue>? items = variable?.unconditionalItems;
    if (items == null || items.length != 1 || items.single is! GnScopeValue) {
      throw GnError(location, '$name is not a scope');
    }
    return (items.single as GnScopeValue).variables;
  }

  // -------------------------------------------------------------------------
  // Assignments and expressions
  // -------------------------------------------------------------------------

  void _evaluateAssignment(
    GnBinary node,
    _Scope scope,
    Condition condition,
    List<String> source, {
    required List<String> comments,
  }) {
    final GnNode left = node.left;
    if (left is! GnIdentifier) {
      throw GnError(left.location, 'assignment to something other than a variable');
    }
    final String name = left.name;
    final GnVariable? existing = scope.lookup(name);
    final GnValue? assumed = !_declaringArgs || node.op != '='
        ? null
        : assumptions[name] ??
              (settings.externalVariables.contains(name)
                  ? GnConditionValue(ConditionVariable(name))
                  : null);
    final _Expression value = assumed != null
        ? _Expression.scalar(assumed)
        : _isBooleanExpression(node.right)
        ? _booleanExpression(node.right, scope)
        : _expression(node.right, scope);
    final GnVariable variable;
    if (node.op == '=') {
      // `=` defines a variable in the current scope (GN forbids shadowing an
      // enclosing scope's variable, which is left to GN to diagnose). A
      // scalar may be reassigned under a condition: its cases are read back
      // with the last write winning. A list may not: that would be a whole
      // list under a select(), which no GN file of the engine needs.
      variable = scope.variables.putIfAbsent(name, () => GnVariable(name, isList: value.isList));
      if (variable.isList && variable.assignments.isNotEmpty && condition != Condition.always) {
        throw GnError(
          node.location,
          'conditional reassignment of $name is not supported; use += in the branch',
        );
      }
    } else if (existing == null) {
      if (!_predefinedTargetVariables.contains(name) || !scope.isTarget) {
        throw GnError(node.location, '${node.op} on undefined variable $name');
      }
      // GN's set_defaults() gives targets an initial value for these.
      variable = scope.variables.putIfAbsent(name, () => GnVariable(name, isList: true));
    } else {
      if (!scope.variables.containsKey(name)) {
        throw GnError(node.location, '${node.op} on $name, which belongs to an enclosing scope');
      }
      variable = existing;
    }
    if (variable.isList != value.isList) {
      throw GnError(
        node.location,
        '${node.op} of a ${value.isList ? 'list' : 'scalar'} to the '
        '${variable.isList ? 'list' : 'scalar'} $name',
      );
    }
    // Elements that hold under a condition of their own (read from a
    // variable with conditional appends) become appends under that
    // condition, in order of first appearance.
    final groups = <Condition, List<_Value>>{};
    for (final _Value item in value.items) {
      groups.putIfAbsent(item.condition, () => <_Value>[]).add(item);
    }
    if (groups.isEmpty) {
      groups[Condition.always] = <_Value>[];
    }
    String op = node.op;
    var first = true;
    for (final MapEntry<Condition, List<_Value>> group in groups.entries) {
      final Condition when = condition.and(group.key);
      if (when == Condition.never) {
        continue;
      }
      if (op == '-=' && group.key != Condition.always) {
        throw GnError(node.location, '-= of conditional elements is not supported');
      }
      final List<_Value> items = group.value;
      final bool anyItemComments = items.any((_Value i) => !i.comments.isEmpty);
      variable.assignments.add(
        GnAssignment(
          node.location,
          when,
          op,
          <GnValue>[for (final _Value item in items) item.value],
          sourceConditions: <String>[...source, ...?items.firstOrNull?.sourceConditions],
          comments: first ? comments : const <String>[],
          itemComments: anyItemComments
              ? <GnItemComments>[for (final _Value item in items) item.comments]
              : const <GnItemComments>[],
        ),
      );
      first = false;
      if (op == '=' && variable.isList) {
        op = '+=';
      }
    }
  }

  /// The value of an expression: the items of a list, or the single value
  /// of a scalar, each with the comments written around it.
  _Expression _expression(GnNode node, _Scope scope) {
    switch (node) {
      case GnList(:final List<GnNode> items):
        return _Expression(<_Value>[
          for (final GnNode item in items) ..._expression(item, scope).items,
        ], isList: true);
      case GnBinary(op: '+', :final GnNode left, :final GnNode right):
        final _Expression l = _expression(left, scope);
        final _Expression r = _expression(right, scope);
        if (l.isList && r.isList) {
          return _Expression(<_Value>[...l.items, ...r.items], isList: true);
        }
        final GnValue? a = l.scalar;
        final GnValue? b = r.scalar;
        if (a is GnStringValue && b is GnStringValue) {
          return _Expression.scalar(GnStringValue(a.value + b.value));
        }
        throw GnError(node.location, 'unsupported operands of +: $l and $r');
      case GnIdentifier(:final String name):
        return _variableValue(name, node, scope);
      case GnAccessor(:final String base, :final GnNode index):
        if (index is! GnIdentifier) {
          throw GnError(node.location, 'only scope.member access is supported');
        }
        final GnVariable? member = _scopeVariables(base, node.location, scope)[index.name];
        if (member == null) {
          throw GnError(node.location, '$base has no member ${index.name}');
        }
        return _variableItems(member, node);
      case GnBlock():
        // `x = { ... }`: a scope value.
        final blockScope = _Scope(scope);
        _evaluateBlock(node, blockScope, Condition.always, const <String>[], target: null);
        return _Expression.scalar(GnScopeValue(blockScope.variables));
      case GnLiteral():
        return _Expression(<_Value>[
          _Value(_literal(node, scope: scope), _comments(node)),
        ], isList: false);
      case GnFunctionCall(name: 'get_path_info', :final List<GnNode> args):
        if (args.length != 2 || _stringExpression(args[1], scope) != 'abspath') {
          throw GnError(node.location, 'only get_path_info(path, "abspath") is supported');
        }
        return _Expression.scalar(
          GnStringValue(_absolutePath(_stringExpression(args[0], scope), node)),
        );
      case GnFunctionCall(name: 'rebase_path', :final List<GnNode> args):
        // rebase_path(x, root_build_dir): the path of x as the build runs
        // it. Kept as a marked absolute path inside the string, which the
        // emitter turns into the action rule's path tokens; any other
        // destination is unknowable here.
        if (args.isNotEmpty &&
            args.length <= 2 &&
            (args.length == 1 ||
                (args[1] is GnIdentifier && (args[1] as GnIdentifier).name == 'root_build_dir'))) {
          final String path = _absolutePath(_stringExpression(args[0], scope), node);
          return _Expression.scalar(GnStringValue('$rebasedPathMarker$path$rebasedPathMarker'));
        }
        return _Expression.scalar(GnOpaqueValue(_gnText(node)));
      case GnFunctionCall(name: 'get_label_info', :final List<GnNode> args):
        if (args.length != 2) {
          throw GnError(node.location, 'get_label_info() takes a label and a property');
        }
        return _Expression.scalar(
          GnStringValue(
            _labelInfo(_stringExpression(args[0], scope), _stringExpression(args[1], scope), node),
          ),
        );
      case GnFunctionCall(name: 'exec_script'):
        // Unknowable here; an error if it ever reaches the output.
        return _Expression.scalar(GnOpaqueValue(_gnText(node)));
      case GnFunctionCall(:final String name):
        throw GnError(node.location, '$name() in an expression is not supported by the converter');
      default:
        throw GnError(node.location, 'unsupported expression (${node.runtimeType})');
    }
  }

  /// The GN path of [path] as seen from the file containing [node].
  String _absolutePath(String path, GnNode node) {
    if (path.startsWith('//')) {
      return path;
    }
    final GnSourceTree? tree = settings.tree;
    if (tree == null) {
      throw GnError(node.location, 'get_path_info() needs the source tree');
    }
    return tree.gnPath(p.normalize(p.join(p.dirname(node.location.file), path)));
  }

  /// The GN directory of the file containing [node] (`//flutter/fml`).
  String _directoryOf(GnNode node) {
    final GnSourceTree? tree = settings.tree;
    if (tree == null) {
      throw GnError(node.location, 'build directory variables need the source tree');
    }
    return tree.gnDirectory(node.location.file);
  }

  /// GN's build directory variables, as paths under roots that stand for
  /// the build directory ([buildDirRoot]) and the generated-file tree
  /// ([genDirRoot]); the emitter maps them to Bazel's output tree.
  String? _buildDirVariable(String name, GnNode node) {
    return switch (name) {
      'root_build_dir' || 'root_out_dir' => buildDirRoot,
      'root_gen_dir' => genDirRoot,
      'target_gen_dir' => '$genDirRoot${_directoryOf(node).substring(1)}',
      'target_out_dir' => '$buildDirRoot/obj${_directoryOf(node).substring(1)}',
      _ => null,
    };
  }

  /// get_label_info(label, what) for the properties that are paths or
  /// names; a toolchain suffix (`($default_toolchain)`) is ignored.
  String _labelInfo(String label, String what, GnNode node) {
    var bare = label;
    final int paren = bare.indexOf('(');
    if (paren >= 0) {
      bare = bare.substring(0, paren);
    }
    final int colon = bare.indexOf(':');
    final String directory = colon < 0 ? bare : bare.substring(0, colon);
    final String dir = directory.isEmpty ? _directoryOf(node) : _absolutePath(directory, node);
    final String name = colon < 0
        ? dir.substring(dir.lastIndexOf('/') + 1)
        : bare.substring(colon + 1);
    return switch (what) {
      'dir' => dir,
      'name' => name,
      'target_gen_dir' => '$genDirRoot${dir.substring(1)}',
      'target_out_dir' => '$buildDirRoot/obj${dir.substring(1)}',
      'root_gen_dir' => genDirRoot,
      'root_out_dir' => buildDirRoot,
      _ => throw GnError(node.location, 'get_label_info(..., "$what") is not supported'),
    };
  }

  _Expression _variableValue(String name, GnNode node, _Scope scope) {
    final GnVariable? variable = scope.lookup(name);
    if (variable != null) {
      return _variableItems(variable, node);
    }
    final GnValue? assumed = assumptions[name];
    if (assumed != null) {
      return _Expression.scalar(assumed);
    }
    if (settings.externalVariables.contains(name)) {
      // The engine's `.gni` variables that build files read are all lists of
      // flags.
      return _Expression(<_Value>[_Value(GnReference(name), _comments(node))], isList: true);
    }
    final String? buildDir = _buildDirVariable(name, node);
    if (buildDir != null) {
      return _Expression.scalar(GnStringValue(buildDir));
    }
    throw GnError(node.location, 'unknown variable $name');
  }

  /// The elements of a variable, each under the condition of the append
  /// that produced it; for a scalar, its [GnVariable.cases].
  static _Expression _variableItems(GnVariable variable, GnNode node) {
    if (!variable.isList) {
      return _scalarItems(variable, node.location);
    }
    final items = <_Value>[];
    for (final GnAssignment a in variable.assignments) {
      if (a.op == '-=') {
        if (!a.isUnconditional) {
          throw GnError(node.location, 'use of ${variable.name}, which has a conditional -=');
        }
        items.removeWhere((_Value item) => a.items.contains(item.value));
        continue;
      }
      if (a.op == '=') {
        if (!a.isUnconditional && items.isNotEmpty) {
          throw GnError(
            node.location,
            'use of ${variable.name}, which is reassigned conditionally',
          );
        }
        items.clear();
      }
      for (var i = 0; i < a.items.length; i++) {
        items.add(
          _Value(
            a.items[i],
            a.commentsOf(i),
            condition: a.condition,
            sourceConditions: a.sourceConditions,
          ),
        );
      }
    }
    return _Expression(items, isList: true);
  }

  /// The value of a scalar: its one case, or its several cases each under
  /// the condition where it is the value in force. Several boolean cases
  /// fold into one formula — "some case holds and its value is true" — which
  /// is exact wherever GN would let the variable be read (where no case
  /// holds, GN has no value to give either).
  static _Expression _scalarItems(GnVariable variable, GnLocation use) {
    final List<GnScalarCase> cases = variable.cases(use);
    if (cases.isEmpty) {
      throw GnError(use, 'use of ${variable.name}, which has no value');
    }
    if (cases.length == 1 && cases.single.condition == Condition.always) {
      final GnScalarCase only = cases.single;
      return _Expression(<_Value>[
        _Value(only.value, only.assignment.commentsOf(0)),
      ], isList: false);
    }
    if (cases.every((GnScalarCase c) => c.value is GnBoolValue || c.value is GnConditionValue)) {
      final Condition holds = Condition.disjunction(<Condition>[
        for (final GnScalarCase c in cases)
          _valueCondition(c.value, use, variable.name).and(c.condition),
      ]);
      return _Expression.scalar(switch (holds) {
        ConditionConstant(:final bool value) => GnBoolValue(value),
        _ => GnConditionValue(holds),
      });
    }
    return _Expression(<_Value>[
      for (final GnScalarCase c in cases)
        _Value(
          c.value,
          c.assignment.commentsOf(0),
          condition: c.condition,
          sourceConditions: c.assignment.sourceConditions,
        ),
    ], isList: false);
  }

  /// Whether [node] is a formula (`a && b`, `!a`, `x == "y"`) rather than a
  /// value.
  static bool _isBooleanExpression(GnNode node) {
    return switch (node) {
      GnBinary(:final String op) => op == '&&' || op == '||' || op == '==' || op == '!=',
      GnUnary(op: '!') => true,
      _ => false,
    };
  }

  /// The value of a formula: a boolean when the assumptions decide it, else
  /// the formula itself.
  _Expression _booleanExpression(GnNode node, _Scope scope) {
    final Condition condition = _condition(node, scope);
    final GnValue value = switch (condition) {
      ConditionConstant(:final bool value) => GnBoolValue(value),
      _ => GnConditionValue(condition),
    };
    return _Expression.scalar(value);
  }

  static GnItemComments _comments(GnNode node) {
    if (node.beforeComments.isEmpty && node.suffixComments.isEmpty) {
      return GnItemComments.none;
    }
    return GnItemComments(before: node.beforeComments, suffix: node.suffixComments);
  }

  GnValue _literal(GnLiteral node, {_Scope? scope}) {
    if (node.isBool) {
      return GnBoolValue(node.boolValue);
    }
    if (node.isInteger) {
      return GnIntValue(node.intValue);
    }
    if (node.hasExpansion) {
      return GnStringValue(_expand(node, scope));
    }
    return GnStringValue(node.stringValue);
  }

  static final RegExp _expansion = RegExp(
    r'\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))',
  );

  /// Resolves `$name` and `${name}` in a string from the known strings
  /// (assumptions and local scalar variables); anything else is an error.
  String _expand(GnLiteral node, _Scope? scope) {
    final String text = node.stringValue;
    var last = 0;
    final out = StringBuffer();
    for (final Match match in _expansion.allMatches(text)) {
      final String name = match.group(1) ?? match.group(2)!;
      final String? value = _knownString(name, scope, node);
      if (value == null) {
        throw GnError(node.location, 'string expansion of \$$name is not supported: ${node.raw}');
      }
      out
        ..write(text.substring(last, match.start))
        ..write(value);
      last = match.end;
    }
    if (last < text.length) {
      final String rest = text.substring(last);
      if (rest.contains(r'$')) {
        throw GnError(node.location, 'string expansion is not supported: ${node.raw}');
      }
      out.write(rest);
    }
    return out.toString();
  }

  /// The value of [name] when it is a string the converter knows: an
  /// assumption, or a local variable holding one unconditional string.
  String? _knownString(String name, _Scope? scope, [GnNode? node]) {
    final GnVariable? variable = scope?.lookup(name);
    if (variable != null) {
      return variable.isList
          ? null
          : _agreedString(
              _scalarItems(variable, node?.location ?? variable.assignments.first.location),
            );
    }
    final GnValue? assumed = assumptions[name];
    if (assumed is GnStringValue) {
      return assumed.value;
    }
    return node == null ? null : _buildDirVariable(name, node);
  }

  /// The string a scalar expression is wherever it has a value: its one
  /// unconditional value, or the value all of its cases agree on (a variable
  /// written once in the branch that reads it has a single case under that
  /// branch's condition; where no case holds, GN has no value either).
  static String? _agreedString(_Expression expression) {
    if (expression.isList || expression.items.isEmpty) {
      return null;
    }
    final GnValue first = expression.items.first.value;
    if (first is! GnStringValue || expression.items.any((_Value i) => i.value != first)) {
      return null;
    }
    return first.value;
  }

  // -------------------------------------------------------------------------
  // Conditions
  // -------------------------------------------------------------------------

  Condition _condition(GnNode node, _Scope scope) {
    switch (node) {
      case GnLiteral() when node.isBool:
        return ConditionConstant(node.boolValue);
      case GnIdentifier(:final String name):
        return _variableCondition(name, node.location, scope);
      case GnAccessor():
        return _valueCondition(_expression(node, scope).scalar, node.location, _gnText(node));
      case GnUnary(op: '!', :final GnNode operand):
        return _condition(operand, scope).negated;
      case GnBinary(op: '&&', :final GnNode left, :final GnNode right):
        // GN short-circuits: the right side may be meaningless when the left
        // is false (`is_android && ndk_api >= 30`).
        final Condition l = _condition(left, scope);
        return l == Condition.never ? l : l.and(_condition(right, scope));
      case GnBinary(op: '||', :final GnNode left, :final GnNode right):
        final Condition l = _condition(left, scope);
        return l == Condition.always ? l : l.or(_condition(right, scope));
      case GnBinary(:final String op, :final GnNode left, :final GnNode right)
          when op == '==' || op == '!=':
        return _comparison(node, op == '==', left, right, scope);
      case GnBinary(:final String op, :final GnNode left, :final GnNode right)
          when op == '<' || op == '<=' || op == '>' || op == '>=':
        final GnValue? a = _expression(left, scope).scalar;
        final GnValue? b = _expression(right, scope).scalar;
        if (a is! GnIntValue || b is! GnIntValue) {
          throw GnError(node.location, '$op needs two known integers');
        }
        return ConditionConstant(switch (op) {
          '<' => a.value < b.value,
          '<=' => a.value <= b.value,
          '>' => a.value > b.value,
          _ => a.value >= b.value,
        });
      case GnFunctionCall(name: 'defined', :final List<GnNode> args):
        if (args.length != 1) {
          throw GnError(node.location, 'defined() takes one argument');
        }
        return ConditionConstant(_isDefined(args.single, scope));
      default:
        throw GnError(node.location, 'unsupported condition (${node.runtimeType})');
    }
  }

  bool _isDefined(GnNode what, _Scope scope) {
    switch (what) {
      case GnIdentifier(:final String name):
        return scope.lookup(name) != null ||
            assumptions[name] != null ||
            settings.externalVariables.contains(name);
      case GnAccessor(:final String base, :final GnNode index):
        if (index is! GnIdentifier) {
          throw GnError(what.location, 'only defined(scope.member) is supported');
        }
        return _scopeVariables(base, what.location, scope).containsKey(index.name);
      default:
        throw GnError(what.location, 'only defined(variable) is supported');
    }
  }

  Condition _variableCondition(String name, GnLocation location, _Scope scope) {
    final GnVariable? variable = scope.lookup(name);
    if (variable != null) {
      if (variable.isList) {
        throw GnError(location, 'condition on $name, which is not a plain boolean');
      }
      return _valueCondition(_scalarItems(variable, location).scalar, location, name);
    }
    final GnValue? assumed = assumptions[name];
    if (assumed != null) {
      return _valueCondition(assumed, location, name);
    }
    if (settings.externalVariables.contains(name)) {
      return ConditionVariable(name);
    }
    throw GnError(location, 'unknown variable $name in condition');
  }

  static Condition _valueCondition(GnValue? value, GnLocation location, String what) {
    return switch (value) {
      GnBoolValue(:final bool value) => ConditionConstant(value),
      GnConditionValue(:final Condition condition) => condition,
      _ => throw GnError(location, 'condition on $what, which is not a plain boolean'),
    };
  }

  Condition _comparison(GnNode node, bool equals, GnNode left, GnNode right, _Scope scope) {
    if (left is! GnIdentifier) {
      throw GnError(node.location, 'only `variable == "string"` comparisons are supported');
    }
    final String? leftValue = _knownString(left.name, scope);
    if (right is GnIdentifier) {
      // `current_toolchain == host_toolchain`: both sides must be known.
      final String? rightValue = _knownString(right.name, scope);
      if (leftValue == null || rightValue == null) {
        throw GnError(
          node.location,
          'comparison of ${left.name} with ${right.name} needs both values to be known',
        );
      }
      return ConditionConstant((leftValue == rightValue) == equals);
    }
    if (right is! GnLiteral || !right.isString) {
      throw GnError(node.location, 'only `variable == "string"` comparisons are supported');
    }
    final String value = right.stringValue;
    if (leftValue != null) {
      return ConditionConstant((leftValue == value) == equals);
    }
    if (assumptions[left.name] != null || scope.lookup(left.name) != null) {
      throw GnError(node.location, 'comparison with ${left.name}, which is not a known string');
    }
    if (!settings.externalVariables.contains(left.name)) {
      throw GnError(node.location, 'unknown variable ${left.name} in condition');
    }
    return ConditionComparison(left.name, equals, value);
  }
}
