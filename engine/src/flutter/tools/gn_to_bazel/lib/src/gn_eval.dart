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

/// BUILDCONFIG.gn's OS names, as `target_os` and `current_os` spell them, to
/// the OS predicate each one sets: comparing the name asserts the predicate.
const Map<String, String> osNamePredicates = <String, String>{
  'android': 'is_android',
  'fuchsia': 'is_fuchsia',
  'ios': 'is_ios',
  'linux': 'is_linux',
  'mac': 'is_mac',
  'qnx': 'is_qnx',
  'wasm': 'is_wasm',
  'win': 'is_win',
};

/// What a value of config.gni's `full_target_platform_name`
/// (`<target_platform_name>-<target_cpu>`, with mac spelled `darwin` and win
/// `windows`) asserts: its OS predicate and its CPU. Null for a string that
/// is not one.
({String osPredicate, String cpu})? targetPlatformParts(String value) {
  final int dash = value.lastIndexOf('-');
  if (dash <= 0 || dash == value.length - 1) {
    return null;
  }
  final String name = value.substring(0, dash);
  final String? predicate = switch (name) {
    'darwin' => 'is_mac',
    'windows' => 'is_win',
    _ => osNamePredicates[name],
  };
  if (predicate == null) {
    return null;
  }
  return (osPredicate: predicate, cpu: value.substring(dash + 1));
}

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
    // beside `is_ios` never holds, beside `!is_ios` it says it all. A
    // comparison may assert in several families at once (`target_os ==
    // "wasm"` is `is_wasm`; `full_target_platform_name == "linux-x64"` is
    // `is_linux` and `target_cpu == "x64"`).
    final asserted = <String, String>{};
    for (final term in terms) {
      for (final _Alternative alternative in term._alternatives) {
        if (!alternative.asserted) {
          continue;
        }
        final String? other = asserted[alternative.family];
        if (other != null && other != alternative.member) {
          return never;
        }
        asserted[alternative.family] = alternative.member;
      }
    }
    // A denial of the very member another term asserts (`!is_mac` beside
    // `full_target_platform_name == "darwin-arm64"`, which asserts is_mac)
    // never holds; a denial of another member is said already.
    for (final term in terms) {
      final _Alternative? alternative = term._alternative;
      if (alternative != null &&
          !alternative.asserted &&
          asserted[alternative.family] == alternative.member) {
        return never;
      }
    }
    terms.removeWhere((Condition term) {
      final _Alternative? alternative = term._alternative;
      return alternative != null &&
          !alternative.asserted &&
          asserted[alternative.family] != null &&
          asserted[alternative.family] != alternative.member;
    });
    // A disjunction beside the negation of one of its own terms loses that
    // term (`a && (!a || b)` is `a && b`), and beside one of its terms goes
    // altogether (`a && (a || b)` is `a`): the shape a scalar's cases take
    // when a later conditional write overrides an earlier one. A reduced
    // disjunction may be a term the rules above apply to (`x != "b" &&
    // (x == "b" || x == "a")` reduces to `x == "a"`, which then subsumes
    // `x != "b"`), so a reduction starts the simplification over.
    var reduced = false;
    for (var i = 0; i < terms.length; i++) {
      final Condition term = terms[i];
      if (term is! ConditionOr) {
        continue;
      }
      final others = <Condition>[...terms.sublist(0, i), ...terms.sublist(i + 1)];
      if (term.terms.any(others.contains)) {
        terms.removeAt(i--);
        continue;
      }
      // A disjunct the others deny -- its literal negation, or another
      // member of its family asserted (`x == "a"` beside `(x == "b" || !f)`
      // leaves `!f`) -- drops out.
      bool denied(Condition t) {
        if (others.contains(t.negated)) {
          return true;
        }
        final _Alternative? alternative = t._alternative;
        return alternative != null &&
            alternative.asserted &&
            asserted[alternative.family] != null &&
            asserted[alternative.family] != alternative.member;
      }

      final List<Condition> remaining = term.terms.where((Condition t) => !denied(t)).toList();
      if (remaining.length != term.terms.length) {
        if (remaining.isEmpty) {
          return never;
        }
        final Condition replacement = disjunction(remaining);
        if (others.contains(replacement.negated)) {
          return never;
        }
        if (others.contains(replacement)) {
          terms.removeAt(i--);
          continue;
        }
        terms[i] = replacement;
        reduced = true;
      }
    }
    if (reduced) {
      return conjunction(terms);
    }
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
    // The dual of the conjunction's last step: a conjunction beside the
    // negation of one of its own terms loses that term (`a || (!a && b)` is
    // `a || b`), beside one of its terms goes altogether (`a || (a && b)` is
    // `a`), and one with every term denied beside it holds always (`(a &&
    // b) || !a || !b`: a target defined in both branches of an `if` on a
    // conjunction, skcms's arch() template).
    for (var i = 0; i < terms.length; i++) {
      final Condition term = terms[i];
      if (term is! ConditionAnd) {
        continue;
      }
      final others = <Condition>[...terms.sublist(0, i), ...terms.sublist(i + 1)];
      if (term.terms.any(others.contains)) {
        terms.removeAt(i--);
        continue;
      }
      final List<Condition> remaining = term.terms
          .where((Condition t) => !others.contains(t.negated))
          .toList();
      if (remaining.length != term.terms.length) {
        if (remaining.isEmpty) {
          return always;
        }
        final Condition reduced = conjunction(remaining);
        if (others.contains(reduced.negated)) {
          return always;
        }
        if (others.contains(reduced)) {
          terms.removeAt(i--);
          continue;
        }
        terms[i] = reduced;
      }
    }
    return switch (terms.length) {
      0 => never,
      1 => terms.single,
      _ => ConditionOr(terms),
    };
  }

  /// Every alternative this formula asserts or denies ([_alternative] first):
  /// an asserted comparison of an OS name or a platform name asserts the OS
  /// predicate (and the CPU) it names too.
  List<_Alternative> get _alternatives {
    final _Alternative? primary = _alternative;
    if (primary == null) {
      return const <_Alternative>[];
    }
    if (this case ConditionComparison(:final String name, equals: true, :final String value)) {
      if (name == 'target_os' || name == 'current_os') {
        final String? predicate = osNamePredicates[value];
        if (predicate != null) {
          return <_Alternative>[primary, _Alternative('current_os', predicate, asserted: true)];
        }
      }
      // The wasm CPU is the wasm OS's alone: `target_cpu == "wasm"` beside
      // `is_android` never holds (the Android archives' directory names,
      // expanded over the CPUs under is_android).
      if ((name == 'target_cpu' || name == 'current_cpu') && value == 'wasm') {
        return <_Alternative>[primary, const _Alternative('current_os', 'is_wasm', asserted: true)];
      }
      if (name == 'full_target_platform_name') {
        final ({String osPredicate, String cpu})? parts = targetPlatformParts(value);
        if (parts != null) {
          return <_Alternative>[
            primary,
            _Alternative('current_os', parts.osPredicate, asserted: true),
            _Alternative('target_cpu', parts.cpu, asserted: true),
          ];
        }
      }
    }
    return <_Alternative>[primary];
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

/// A list held as one value: an element of a list that is itself a list
/// (the validation layers' `layers = [ [ "khronos_validation", vvl_sources,
/// [ ":glslang" ], [] ] ]`, which a `foreach` takes apart with
/// `layer_info[0]`). Read by index, a list element is the list again.
final class GnListValue extends GnValue {
  const GnListValue(this.items);

  final List<GnValue> items;

  @override
  bool operator ==(Object other) =>
      other is GnListValue &&
      other.items.length == items.length &&
      Iterable<int>.generate(items.length).every((int i) => other.items[i] == items[i]);

  @override
  int get hashCode => Object.hashAll(items);

  @override
  String toString() => '[${items.join(', ')}]';
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

/// A string with a `$name` expansion of a variable the converter does not
/// evaluate (`"FLUTTER_ENGINE_VERSION=\"$engine_version\""`): its literal
/// parts and its references, in order. The Bazel side holds each reference
/// as a constant; where such a string may go is the emitter's decision.
final class GnExpandedString extends GnValue {
  const GnExpandedString(this.parts);

  /// [GnStringValue] and [GnReference] parts.
  final List<GnValue> parts;

  @override
  bool operator ==(Object other) =>
      other is GnExpandedString &&
      other.parts.length == parts.length &&
      Iterable<int>.generate(parts.length).every((int i) => other.parts[i] == parts[i]);

  @override
  int get hashCode => Object.hashAll(parts);

  @override
  String toString() =>
      '"${parts.map((GnValue p) => p is GnReference ? '\$${p.name}' : (p as GnStringValue).value).join()}"';
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
/// An assumption with one string per case of another variable's value:
/// build/config/android/config.gni's android_app_abi by `current_cpu`
/// (`arm64-v8a` under `current_cpu == "arm64"`). Read, it is those cases,
/// each under its comparison, as a variable the evaluator defined under
/// `if (current_cpu == ...)` branches would be.
final class GnCasedValue extends GnValue {
  const GnCasedValue(this.variable, this.values);

  /// The variable the cases compare (`current_cpu`).
  final String variable;

  /// The value under each of [variable]'s values.
  final Map<String, String> values;

  @override
  String toString() => '{$variable: $values}';
}

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

/// The outputs of another target, as `get_target_outputs(label)` returns
/// them (optionally through `filter_include`): the converter does not know
/// what a template's targets produce, so the value names the target (an
/// absolute GN label) and the file patterns kept, and the Bazel side takes
/// the target's files.
final class GnTargetOutputsValue extends GnValue {
  const GnTargetOutputsValue(this.label, this.patterns);

  /// The target, as `//dir:name`.
  final String label;

  /// `filter_include` patterns (`*.iplr`); empty for every output.
  final List<String> patterns;

  @override
  bool operator ==(Object other) =>
      other is GnTargetOutputsValue &&
      other.label == label &&
      other.patterns.length == patterns.length &&
      Iterable<int>.generate(patterns.length).every((int i) => other.patterns[i] == patterns[i]);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(patterns));

  @override
  String toString() => patterns.isEmpty
      ? 'get_target_outputs("$label")'
      : 'filter_include(get_target_outputs("$label"), $patterns)';
}

/// The outputs of a target as paths relative to the build directory:
/// `rebase_path(get_target_outputs(":copy"), root_build_dir)` -- the GTK
/// bundle's idiom for "every output of the copy at its build-directory
/// path", which the emitter reads together with the outputs themselves --
/// or relative to a directory under it ([base]: the web SDK's archive,
/// `rebase_path(source, "$root_build_dir/flutter_web_sdk")`).
final class GnTargetOutputPathsValue extends GnValue {
  const GnTargetOutputPathsValue(this.label, {this.base = ''});

  /// The target, as `//dir:name`.
  final String label;

  /// The directory the paths are relative to, under the build directory;
  /// empty for the build directory itself.
  final String base;

  @override
  bool operator ==(Object other) =>
      other is GnTargetOutputPathsValue && other.label == label && other.base == base;

  @override
  int get hashCode => Object.hash(label, base);

  @override
  String toString() => base.isEmpty
      ? 'rebase_path(get_target_outputs("$label"), root_build_dir)'
      : 'rebase_path(get_target_outputs("$label"), "\$root_build_dir/$base")';
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

/// One item of a list variable and the assignment that put it there
/// ([GnVariable.liveItems]).
@immutable
final class GnListItem {
  const GnListItem(this.assignment, this.index);

  final GnAssignment assignment;

  /// The item's position in [assignment]'s items.
  final int index;

  GnValue get value => assignment.items[index];

  /// The condition the item is in the list under.
  Condition get condition => assignment.condition;

  GnItemComments get comments => assignment.commentsOf(index);
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

  /// The items of a list variable with the assignment each came in, in
  /// order, each in the list under its assignment's condition: an
  /// unconditional `=` starts the list over, a conditional one appends like
  /// `+=` (both branches of an `if`/`else` stay, each under its own
  /// condition), and `-=` -- unconditional only -- removes every item equal
  /// to one of its own, which must be there.
  List<GnListItem> get liveItems {
    final items = <GnListItem>[];
    for (final GnAssignment a in assignments) {
      switch (a.op) {
        case '=' || '+=':
          if (a.op == '=' && a.isUnconditional) {
            items.clear();
          }
          for (var i = 0; i < a.items.length; i++) {
            items.add(GnListItem(a, i));
          }
        case '-=':
          if (!a.isUnconditional) {
            throw GnError(a.location, 'conditional -= is not supported');
          }
          for (final GnValue value in a.items) {
            final int before = items.length;
            items.removeWhere((GnListItem item) => item.value == value);
            if (items.length == before) {
              throw GnError(a.location, '-= of $value, which is not in $name');
            }
          }
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
    // In order of writing: a `=` is the value from its condition on, which
    // restricts every earlier case to where the write does not happen (a
    // write that cannot happen together with an earlier one -- the other
    // branch of the `if`, another OS -- leaves it alone); a `+=` on a string
    // (zip_bundle.gni's android_zip_archive_dir, grown by the runtime mode
    // and the Dart flags) splits every case into the one that takes the
    // suffix and the one that does not.
    var cases = <GnScalarCase>[];
    for (final GnAssignment assignment in assignments) {
      if (assignment.items.length != 1) {
        throw GnError(assignment.location, '${assignment.op} on the scalar $name is not supported');
      }
      final GnValue value = assignment.items.single;
      switch (assignment.op) {
        case '=':
          final next = <GnScalarCase>[];
          for (final earlier in cases) {
            final Condition when = earlier.condition.and(assignment.condition) == Condition.never
                ? earlier.condition
                : earlier.condition.and(assignment.condition.negated);
            if (when != Condition.never) {
              next.add(GnScalarCase(when, earlier.value, earlier.assignment));
            }
          }
          if (assignment.condition != Condition.never) {
            next.add(GnScalarCase(assignment.condition, value, assignment));
          }
          cases = next;
        case '+=':
          if (cases.isEmpty) {
            throw GnError(assignment.location, '+= on the scalar $name before any value');
          }
          final next = <GnScalarCase>[];
          for (final earlier in cases) {
            final Condition both = earlier.condition.and(assignment.condition);
            if (both != Condition.never) {
              next.add(
                GnScalarCase(
                  both,
                  concatenated(earlier.value, value, assignment.location),
                  assignment,
                ),
              );
            }
            final Condition other = both == Condition.never
                ? earlier.condition
                : earlier.condition.and(assignment.condition.negated);
            if (other != Condition.never) {
              next.add(GnScalarCase(other, earlier.value, earlier.assignment));
            }
          }
          cases = next;
        default:
          throw GnError(
            assignment.location,
            '${assignment.op} on the scalar $name is not supported',
          );
      }
    }
    return cases;
  }

  /// `a + b` for two strings, either of which may hold references
  /// (GnExpandedString): the parts in sequence, adjacent literals joined.
  static GnValue concatenated(GnValue a, GnValue b, GnLocation location) {
    List<GnValue> parts(GnValue v) => switch (v) {
      GnStringValue() => <GnValue>[v],
      GnExpandedString(:final List<GnValue> parts) => parts,
      // A bare variable the converter does not evaluate (`"_" +
      // flutter_runtime_mode`): its expansion, as in a string.
      GnReference() => <GnValue>[v],
      _ => throw GnError(location, '+ of $v to a string'),
    };
    final joined = <GnValue>[];
    for (final part in <GnValue>[...parts(a), ...parts(b)]) {
      if (part is GnStringValue && joined.isNotEmpty && joined.last is GnStringValue) {
        joined[joined.length - 1] = GnStringValue(
          (joined.last as GnStringValue).value + part.value,
        );
      } else {
        joined.add(part);
      }
    }
    if (joined.length == 1 && joined.single is GnStringValue) {
      return joined.single;
    }
    return GnExpandedString(List<GnValue>.unmodifiable(joined));
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

  /// The names of [variables] the block itself read -- in a condition, a
  /// string expansion, another variable's value. A variable that is not one
  /// of GN's target variables or a template's arguments, and that the block
  /// read, is a helper of the block (`font_subset_bin = "font-subset"`,
  /// then `"$root_build_dir/$font_subset_bin"`): GN rejects an assignment
  /// nothing reads, so such a variable's effect is already in the values
  /// it fed, and the conversion ignores it.
  final Set<String> readVariables = <String>{};

  /// Comments that preceded the target in the GN file.
  List<String> comments = const <String>[];
}

/// The result of evaluating one GN file.
final class GnFileEvaluation {
  GnFileEvaluation(this.file, this.assumptions);

  final String file;

  /// The assumptions the file was evaluated under.
  final Assumptions assumptions;
  final List<String> imports = <String>[];
  final List<GnTarget> targets = <GnTarget>[];

  /// Targets that were asked to be skipped and were found, in file order.
  final List<String> skipped = <String>[];

  /// The configs GN applies to each target of this file through
  /// `all_dependent_configs`: a target's own, and those of every target it
  /// depends on, directly or indirectly, through `deps` or `public_deps` —
  /// private dependencies do not stop them, unlike `public_configs`. Only
  /// dependencies within this file are followed (`:name`). The result maps
  /// target names to config labels as written (`:name_public`), each under
  /// the condition it reaches the target: [Condition.always] for one named
  /// and depended on unconditionally, else the disjunction over the paths
  /// of each path's conditions (a conditional `all_dependent_configs`, as
  /// of a merged optional() target, or a conditional dep).
  Map<String, Map<String, Condition>> get inheritedConfigs {
    final byName = <String, GnTarget>{for (final GnTarget t in targets) t.name: t};
    final result = <String, Map<String, Condition>>{};
    Map<String, Condition> visit(GnTarget target, Set<String> visiting) {
      final Map<String, Condition>? done = result[target.name];
      if (done != null) {
        return done;
      }
      final configs = <String, Condition>{};
      void add(String config, Condition when) {
        if (when == Condition.never) {
          return;
        }
        final Condition? already = configs[config];
        configs[config] = already == null ? when : already.or(when);
      }

      if (visiting.add(target.name)) {
        for (final GnAssignment a
            in target.variables['all_dependent_configs']?.assignments ?? const <GnAssignment>[]) {
          if (a.op == '-=') {
            continue;
          }
          for (final GnValue v in a.items) {
            if (v is GnStringValue) {
              add(v.value, a.condition);
            }
          }
        }
        for (final name in <String>['deps', 'public_deps']) {
          for (final GnAssignment a
              in target.variables[name]?.assignments ?? const <GnAssignment>[]) {
            if (a.op == '-=') {
              continue;
            }
            for (final GnValue v in a.items) {
              final GnTarget? dep = v is GnStringValue && v.value.startsWith(':')
                  ? byName[v.value.substring(1)]
                  : null;
              if (dep == null) {
                continue;
              }
              for (final MapEntry<String, Condition> theirs in visit(dep, visiting).entries) {
                add(theirs.key, a.condition.and(theirs.value));
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
    return result;
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

  /// The variables these assumptions fix (the build invariants among them).
  Iterable<String> get names => _values.keys;

  /// These assumptions with [overrides] added or replaced.
  Assumptions withValues(Map<String, GnValue> overrides) =>
      Assumptions(<String, GnValue>{..._values, ...overrides});

  /// [condition], a formula built outside an evaluation (the mapping
  /// tables'), with the variables these assumptions fix replaced by their
  /// values and the result simplified -- what evaluating the same formula
  /// from GN source would have produced.
  Condition apply(Condition condition) {
    switch (condition) {
      case ConditionConstant():
        return condition;
      case ConditionVariable(:final String name):
        final GnValue? assumed = _values[name];
        return assumed is GnBoolValue ? ConditionConstant(assumed.value) : condition;
      case ConditionComparison(:final String name, :final bool equals, :final String value):
        final GnValue? assumed = _values[name];
        return assumed is GnStringValue
            ? ConditionConstant((assumed.value == value) == equals)
            : condition;
      case ConditionNot(:final Condition operand):
        return apply(operand).negated;
      case ConditionAnd(:final List<Condition> terms):
        return Condition.conjunction(<Condition>[for (final Condition t in terms) apply(t)]);
      case ConditionOr(:final List<Condition> terms):
        return Condition.disjunction(<Condition>[for (final Condition t in terms) apply(t)]);
    }
  }

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
  'generated_file',
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
/// may be read (they become [GnReference]s -- or, for the [booleanVariables]
/// among them, the predicate itself) or tested (they stay symbolic).
/// Targets named in [skipTargets] are not evaluated at all (so that what is
/// inside them need not be understood); they are listed in the result. A
/// target named in [targetConditions] exists under that condition besides
/// its block's, as if its definition sat inside `if (condition)`: a target
/// GN defines outright but reaches on some platforms alone (the desktop
/// embeddings' accessibility bridge, which only the macOS and Windows
/// shells name and only they compile).
/// Imports are resolved and loaded through [tree] according to
/// [importPolicy]; without a tree, imports are only recorded.
GnFileEvaluation evaluateGnFile(
  GnBlock file, {
  required Assumptions assumptions,
  Set<String> templates = const <String>{},
  Set<String> externalVariables = const <String>{},
  Set<String> booleanVariables = const <String>{},
  Set<String> skipTargets = const <String>{},
  GnSourceTree? tree,
  ImportPolicy importPolicy = const ImportPolicy(),
  Condition condition = Condition.always,
  Map<String, Condition> targetConditions = const <String, Condition>{},
}) {
  final settings = _Settings(
    assumptions: assumptions,
    templates: templates,
    externalVariables: externalVariables,
    booleanVariables: booleanVariables,
    skipTargets: skipTargets,
    tree: tree,
    importPolicy: importPolicy,
    importCache: <String, _ImportedFile>{},
    targetConditions: targetConditions,
  );
  final evaluator = _Evaluator(settings, file.location.file);
  evaluator.evaluateFile(file, condition);
  final GnFileEvaluation result = evaluator.result;
  final List<GnTarget> resolved = _resolveDefinitions(List<GnTarget>.of(result.targets));
  result.targets
    ..clear()
    ..addAll(resolved);
  return result;
}

/// One name, one target. GN lets a file define a name in branches that
/// cannot both run (`if (c) { source_set("x") { … } } else { source_set("x")
/// { … } }`; Skia's optional() template, which is the feature's sources when
/// it is enabled and an empty source set otherwise), since only one branch
/// runs. Under a condition the assumptions leave open both branches are
/// evaluated, and Bazel has one rule per name, so the two definitions become
/// one target: defined wherever either was, with each branch's variables
/// under that branch's condition (the emitter's select()s), and a variable
/// both branches set the same way unconditional. GN's placeholder idiom --
/// an empty group standing in for a real target of another rule
/// (impeller_component's testonly components when unit tests are off), so
/// that dependents can name it unconditionally -- keeps the real target
/// alone, under its own condition: Bazel says what the group said with
/// `target_compatible_with`. Two definitions that could both run, or of
/// different rules otherwise, are an error, as the first is in GN.
List<GnTarget> _resolveDefinitions(List<GnTarget> targets) {
  final byName = <String, List<GnTarget>>{};
  for (final target in targets) {
    byName.putIfAbsent(target.name, () => <GnTarget>[]).add(target);
  }
  if (byName.length == targets.length) {
    return targets;
  }
  // Each target of a duplicated name, and what stands for it: a merged
  // target, or null for one that another stands for.
  final replacements = <GnTarget, GnTarget?>{};
  for (final List<GnTarget> group in byName.values) {
    if (group.length == 1) {
      continue;
    }
    final GnTarget first = group[0];
    final GnTarget second = group[1];
    GnError duplicate() => GnError(
      second.location,
      'target ${first.name} is defined more than once (under `${first.condition}` and '
      '`${second.condition}`)',
    );
    if (group.length != 2) {
      throw duplicate();
    }
    final (Condition common, Condition a, Condition b) = _branches(
      first.condition,
      second.condition,
    );
    final complementary = a.negated == b;
    if (!complementary && a.and(b) != Condition.never) {
      throw duplicate();
    }
    final List<GnTarget> placeholders = group.where(_isPlaceholder).toList();
    if (placeholders.length == 1 && complementary) {
      replacements[placeholders.single] = null;
      continue;
    }
    if (first.rule != second.rule) {
      throw duplicate();
    }
    replacements[first] = _merged(first, second, common.and(a.or(b)), a, b);
    replacements[second] = null;
  }
  return <GnTarget>[
    for (final GnTarget target in targets)
      if (!replacements.containsKey(target))
        target
      else if (replacements[target] case final GnTarget merged)
        merged,
  ];
}

/// An empty group: the placeholder of GN's idiom (`group(name) {
/// not_needed(invoker, "*") }`), with nothing but a template's forwarded
/// bookkeeping, `testonly` or `visibility` in it.
bool _isPlaceholder(GnTarget target) =>
    target.rule == 'group' &&
    target.variables.keys.every(
      (String v) => v == 'testonly' || v == 'visibility' || target.variables[v]!.forwarded,
    );

/// The conditions of two definitions of one name taken apart: the terms
/// they share (the enclosing conditions, `P` of `P && c` and `P && !c`) and
/// what each adds to them.
(Condition, Condition, Condition) _branches(Condition first, Condition second) {
  List<Condition> terms(Condition c) => c is ConditionAnd ? c.terms : <Condition>[c];
  final List<Condition> x = terms(first);
  final List<Condition> y = terms(second);
  final List<Condition> common = x.where(y.contains).toList();
  return (
    Condition.conjunction(common),
    Condition.conjunction(x.where((Condition t) => !common.contains(t)).toList()),
    Condition.conjunction(y.where((Condition t) => !common.contains(t)).toList()),
  );
}

/// The one target two definitions of a name amount to (see
/// [_resolveDefinitions]): [first]'s variables under [a], [second]'s under
/// [b], a variable both set the same way as it was.
GnTarget _merged(GnTarget first, GnTarget second, Condition condition, Condition a, Condition b) {
  final merged = GnTarget(first.location, first.rule, first.name, condition)
    ..comments = first.comments
    ..readVariables.addAll(first.readVariables)
    ..readVariables.addAll(second.readVariables);
  for (final name in <String>{...first.variables.keys, ...second.variables.keys}) {
    final GnVariable? x = first.variables[name];
    final GnVariable? y = second.variables[name];
    if (x != null && y != null && x.isList != y.isList) {
      throw GnError(
        y.assignments.first.location,
        '$name is a ${y.isList ? 'list' : 'scalar'} in one definition of ${first.name} '
        'and a ${x.isList ? 'list' : 'scalar'} in the other',
      );
    }
    if (x != null && y != null && _sameValue(x, y)) {
      merged.variables[name] = x;
      continue;
    }
    final GnVariable either = (x ?? y)!;
    final variable = GnVariable(
      name,
      isList: either.isList,
      forwarded: (x?.forwarded ?? true) && (y?.forwarded ?? true),
    );
    if (x != null && y != null && either.isList) {
      // An item both branches append the same way (the raw_ptr dependency
      // skia_source_set adds in whichever branch of optional() runs) is in
      // the list wherever either branch is: once, under their disjunction.
      bool same(GnListItem p, GnListItem q) =>
          p.value == q.value && p.assignment.condition == q.assignment.condition;
      final List<GnListItem> xs = x.liveItems;
      final List<GnListItem> ys = y.liveItems;
      variable.assignments.addAll(
        _under(
          x,
          a,
          branchOf: (GnListItem p) => ys.any((GnListItem q) => same(p, q)) ? a.or(b) : a,
        ),
      );
      variable.assignments.addAll(
        _under(y, b, skip: (GnListItem q) => xs.any((GnListItem p) => same(p, q))),
      );
      merged.variables[name] = variable;
      continue;
    }
    if (x != null) {
      variable.assignments.addAll(_under(x, a));
    }
    if (y != null) {
      variable.assignments.addAll(_under(y, b));
    }
    merged.variables[name] = variable;
  }
  return merged;
}

/// Whether two variables hold the same unconditional value.
bool _sameValue(GnVariable a, GnVariable b) {
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

/// [variable]'s effective assignments, each under its own condition and
/// [branch]: a list's live items (an unconditional `=` having started it
/// over), grouped as they were assigned, as `+=`; a scalar's cases as `=`.
/// A list item [skip] accepts is left out; [branchOf] names the branch of a
/// list item that is not under [branch] (see [_merged]).
List<GnAssignment> _under(
  GnVariable variable,
  Condition branch, {
  Condition Function(GnListItem)? branchOf,
  bool Function(GnListItem)? skip,
}) {
  final result = <GnAssignment>[];
  if (variable.isList) {
    final groups = <(GnAssignment, Condition), List<int>>{};
    for (final GnListItem item in variable.liveItems) {
      if (skip != null && skip(item)) {
        continue;
      }
      groups
          .putIfAbsent((item.assignment, branchOf?.call(item) ?? branch), () => <int>[])
          .add(item.index);
    }
    for (final MapEntry<(GnAssignment, Condition), List<int>> entry in groups.entries) {
      final (GnAssignment a, Condition under) = entry.key;
      result.add(
        GnAssignment(
          a.location,
          under.and(a.condition),
          '+=',
          <GnValue>[for (final int i in entry.value) a.items[i]],
          sourceConditions: <String>[
            if (under != Condition.always) under.gnSource,
            ...a.sourceConditions,
          ],
          comments: a.comments,
          itemComments: a.itemComments.isEmpty
              ? const <GnItemComments>[]
              : <GnItemComments>[for (final int i in entry.value) a.commentsOf(i)],
        ),
      );
    }
    return result;
  }
  for (final GnScalarCase c in variable.cases(variable.assignments.first.location)) {
    result.add(
      GnAssignment(
        c.assignment.location,
        branch.and(c.condition),
        '=',
        <GnValue>[c.value],
        sourceConditions: <String>[branch.gnSource, ...c.assignment.sourceConditions],
        comments: c.assignment.comments,
      ),
    );
  }
  return result;
}

/// Target variables that BUILDCONFIG.gn's set_defaults() initializes, so
/// that a target may `+=` to them without assigning them first.
const Set<String> _predefinedTargetVariables = <String>{'configs'};

/// Functions whose calls have no effect on the data the converter extracts.
const Set<String> _ignoredFunctions = <String>{'assert', 'not_needed', 'print', 'set_defaults'};

final class _Scope {
  _Scope(this.parent, {this.isTarget = false, this.isPass = false});

  final _Scope? parent;

  /// Whether this is the scope of a target's block.
  final bool isTarget;

  /// Whether this is one pass of a `foreach` body: GN runs the body in the
  /// enclosing scope itself, and so do assignments here to variables of
  /// an enclosing scope (`outputs += [...]`); only a variable the pass
  /// defines afresh is its own, so that passes under different conditions
  /// (elements of a list that hold under conditions) do not read each
  /// other's values as cases.
  final bool isPass;

  /// The scope GN would run this one's statements in: the nearest
  /// enclosing scope that is not a pass.
  _Scope get owner {
    var scope = this;
    while (scope.isPass) {
      scope = scope.parent!;
    }
    return scope;
  }

  final Map<String, GnVariable> variables = <String, GnVariable>{};
  final Map<String, _Template> templates = <String, _Template>{};

  /// The names of [variables] something read (see [GnTarget.readVariables]).
  final Set<String> readNames = <String>{};

  /// The variable [name] names in this scope or an enclosing one, noting
  /// the read in the scope that holds it.
  GnVariable? lookup(String name) {
    final GnVariable? own = variables[name];
    if (own != null) {
      readNames.add(name);
      return own;
    }
    return parent?.lookup(name);
  }

  /// [lookup] without noting a read: for an assignment, which finds the
  /// variable to append to.
  GnVariable? find(String name) => variables[name] ?? parent?.find(name);

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
    required this.booleanVariables,
    required this.skipTargets,
    required this.tree,
    required this.importPolicy,
    required this.importCache,
    this.targetConditions = const <String, Condition>{},
  });

  final Assumptions assumptions;

  /// Conditions targets exist under besides their blocks' (see
  /// [evaluateGnFile]), by target name.
  final Map<String, Condition> targetConditions;
  final Set<String> templates;
  final Set<String> externalVariables;

  /// The external variables that are predicates (the OS predicates, the
  /// arguments with a config_setting): read as values they are the
  /// predicate, where the other external variables are lists of flags.
  final Set<String> booleanVariables;
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
  _Evaluator(this.settings, String file) : result = GnFileEvaluation(file, settings.assumptions);

  final _Settings settings;
  final GnFileEvaluation result;

  /// The root scope of the file, where imports merge.
  late final _Scope fileScope;

  /// The condition the file is evaluated under (a manifest condition such
  /// as `is_android`, or always).
  Condition fileCondition = Condition.always;

  final List<_Invocation> _invocations = <_Invocation>[];

  /// Whether a `declare_args()` block is being evaluated, in which the
  /// assumptions override the defaults.
  bool _declaringArgs = false;

  Assumptions get assumptions => settings.assumptions;

  /// Evaluates the file under [condition]: the condition GN reaches the
  /// file under, for a file no `if` of its own guards but which only an
  /// `if (is_android)` dependency of another file names (impeller's
  /// Android toolkit) -- its targets exist under it, as if the file were
  /// one such block.
  void evaluateFile(GnBlock file, [Condition condition = Condition.always]) {
    fileScope = _Scope(null);
    fileCondition = condition;
    _evaluateBlock(file, fileScope, condition, const <String>[], target: null);
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
    if (call.name == 'error') {
      // GN stops at error(). Reached unconditionally, the file does not
      // generate and neither does the conversion; under a condition the
      // converter leaves open (cpu_features' `else` over current_cpu: "Missing
      // definition for architecture"), it is the branch no supported
      // configuration takes, which contributes nothing.
      if (condition == Condition.always) {
        throw GnError(call.location, 'error() reached: ${_errorMessage(call)}');
      }
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
        _foreach(call, scope, condition, source, target: target);
        return;
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
    // A template the converter maps to a rule (settings.templates) is a
    // target here even where the file defines it itself (web_sdk's
    // _compile_platform): the mapping is the conversion of its body.
    final _Template? template = settings.templates.contains(call.name)
        ? null
        : scope.lookupTemplate(call.name);
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
    final Condition? own = settings.targetConditions[name];
    final newTarget =
        GnTarget(call.location, resolvedRule, name, own == null ? condition : condition.and(own))
          ..comments = invocation != null && invocation.targetName == name
              ? invocation.comments
              : comments;
    final targetScope = _Scope(scope, isTarget: true);
    // GN defines target_name in every target's block (an action's depfile
    // named after it); it is the block's, not a variable of the target.
    targetScope.variables['target_name'] = GnVariable('target_name', isList: false)
      ..assignments.add(
        GnAssignment(call.location, Condition.always, '=', <GnValue>[GnStringValue(name)]),
      );
    _evaluateBlock(block, targetScope, Condition.always, const <String>[], target: newTarget);
    targetScope.variables.remove('target_name');
    newTarget.variables.addAll(targetScope.variables);
    newTarget.readVariables.addAll(targetScope.readNames..remove('target_name'));
    result.targets.add(newTarget);
  }

  /// `foreach(x, list) { ... }`: the body once per element of the list,
  /// with `x` bound to the element in the enclosing scope (GN's foreach
  /// opens no scope; the variable is restored afterwards). A list the
  /// converter cannot enumerate (`get_target_outputs()` of a target) is
  /// one symbolic element, the outputs themselves, which the body's
  /// expressions carry along (`rebase_path(x, root_build_dir)` becomes
  /// [GnTargetOutputPathsValue]) for the emitter to read as a tree.
  void _foreach(
    GnFunctionCall call,
    _Scope scope,
    Condition condition,
    List<String> source, {
    required GnTarget? target,
  }) {
    final GnBlock? body = call.block;
    if (call.args.length != 2 || call.args[0] is! GnIdentifier || body == null) {
      throw GnError(call.location, 'foreach() takes a variable, a list and a block');
    }
    final String name = (call.args[0] as GnIdentifier).name;
    final _Expression list = _expression(call.args[1], scope);
    if (!list.isList) {
      throw GnError(call.location, 'foreach() over something other than a list');
    }
    for (final _Value item in list.items) {
      final Condition when = condition.and(item.condition);
      if (when == Condition.never) {
        continue;
      }
      // Each pass runs in a scope of its own, holding the loop variable and
      // what the body defines (`extension = get_path_info(source, ...)`),
      // which the next pass defines afresh: one pass's values are not
      // cases of another's, as they would be in the enclosing scope when
      // the elements hold under conditions (the ABI jars' names by CPU).
      // Appends reach the enclosing variables through the parent, as GN's
      // `outputs += [...]` in a foreach body does.
      final pass = _Scope(scope, isPass: true);
      pass.variables[name] = GnVariable(
        name,
        isList: false,
      )..assignments.add(GnAssignment(call.location, Condition.always, '=', <GnValue>[item.value]));
      _evaluateBlock(body, pass, when, source, target: target);
      scope.readNames.addAll(pass.readNames);
    }
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
      throw GnError.unreadImport(
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

  /// The GN path (`//a/b.gni`) of an import, resolved against the importing
  /// file's directory when relative.
  /// The message of an error() call, as far as it is a literal.
  String _errorMessage(GnFunctionCall call) {
    final GnNode? arg = call.args.firstOrNull;
    return arg is GnLiteral && arg.isString
        ? arg.stringValue
        : (arg == null ? '' : arg.location.toString());
  }

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
    // GN fills the invocation block's scope as a target's (FillTargetBlockScope):
    // `target_name` is defined there too, so `invoker.target_name` reads.
    final invokerScope = _Scope(scope);
    invokerScope.variables['target_name'] = GnVariable('target_name', isList: false)
      ..assignments.add(
        GnAssignment(call.location, Condition.always, '=', <GnValue>[GnStringValue(name)]),
      );
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
      // "*": everything set directly on the scope, clobbering -- except the
      // invocation's `target_name`, which the body defines itself.
      for (final MapEntry<String, GnVariable> e in from.entries) {
        if (!excluded.contains(e.key) && e.key != 'target_name') {
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
    _Scope assignedIn,
    Condition condition,
    List<String> source, {
    required List<String> comments,
  }) {
    var scope = assignedIn;
    final GnNode left = node.left;
    if (left is! GnIdentifier) {
      throw GnError(left.location, 'assignment to something other than a variable');
    }
    final String name = left.name;
    GnVariable? existing = scope.find(name);
    // In a pass of a foreach body, a variable of an enclosing scope is
    // written where GN writes it: that scope (see _Scope.isPass).
    if (scope.isPass && existing != null && !scope.variables.containsKey(name)) {
      scope = scope.owner;
      existing = scope.find(name);
    }
    final GnValue? assumed = !_declaringArgs || node.op != '='
        ? null
        : assumptions[name] ??
              (settings.externalVariables.contains(name)
                  ? GnConditionValue(ConditionVariable(name))
                  : null);
    // The value is read in the scope of the statement itself (a pass's own
    // variables are visible there), whatever scope the write goes to.
    final _Expression value = assumed != null
        ? _Expression.scalar(assumed)
        : _isBooleanExpression(node.right)
        ? _booleanExpression(node.right, assignedIn)
        : _expression(node.right, assignedIn);
    final GnVariable variable;
    var reassignedEmpty = false;
    if (node.op == '=') {
      // `=` defines a variable in the current scope (GN forbids shadowing an
      // enclosing scope's variable, which is left to GN to diagnose). A
      // scalar may be reassigned under a condition: its cases are read back
      // with the last write winning. A list may not: that would be a whole
      // list under a select(), which no GN file of the engine needs.
      variable = scope.variables.putIfAbsent(name, () => GnVariable(name, isList: value.isList));
      if (variable.isList && variable.assignments.isNotEmpty && condition != Condition.always) {
        // Two shapes are an append in disguise: `public_configs = []` and
        // then, in a branch, `public_configs = [ ":gles_config" ]`
        // (impeller's GLES backend outside Android and Fuchsia) -- with
        // nothing assigned so far, the branch's `=` is its `+=` -- and one
        // `=` per branch of an if/else chain (the platform shells' group:
        // `deps = [ "android" ]` under is_android, `deps = []` under
        // is_linux), where no two assignments can both happen.
        if (variable.assignments.every((GnAssignment a) => a.items.isEmpty) ||
            variable.assignments.every(
              (GnAssignment a) => a.condition.and(condition) == Condition.never,
            )) {
          reassignedEmpty = true;
        } else {
          throw GnError(
            node.location,
            'conditional reassignment of $name is not supported; use += in the branch',
          );
        }
      }
    } else if (existing == null) {
      if (!_predefinedTargetVariables.contains(name) || !scope.isTarget) {
        throw GnError(node.location, '${node.op} on undefined variable $name');
      }
      // GN's set_defaults() gives targets an initial value for these.
      variable = scope.variables.putIfAbsent(name, () => GnVariable(name, isList: true));
    } else {
      if (!scope.variables.containsKey(name)) {
        // GN copies the enclosing scope's value into the current scope
        // first (Scope::GetValueForcedToCurrentScope) and modifies the copy;
        // the enclosing variable is untouched. The embedder's template
        // forwards `public_configs` to its own scope and the target block
        // appends to it.
        variable = GnVariable(name, isList: existing.isList)
          ..assignments.addAll(existing.assignments);
        scope.variables[name] = variable;
      } else {
        variable = existing;
      }
    }
    if (variable.isList != value.isList) {
      throw GnError(
        node.location,
        '${node.op} of a ${value.isList ? 'list' : 'scalar'} to the '
        '${variable.isList ? 'list' : 'scalar'} $name',
      );
    }
    // Elements that hold under a condition of their own (read from a
    // variable with conditional appends, or a cased string among them)
    // become appends under that condition: one per run of elements under
    // one condition, in the elements' order, so that an argument list
    // keeps its order (`[ "--platform", _platform, dir ]` with _platform
    // cased by OS) where the attribute is read in order.
    final groups = <(Condition, List<_Value>)>[];
    for (final _Value item in value.items) {
      if (groups.isEmpty || groups.last.$1 != item.condition) {
        groups.add((item.condition, <_Value>[]));
      }
      groups.last.$2.add(item);
    }
    if (groups.isEmpty) {
      groups.add((Condition.always, <_Value>[]));
    }
    String op = reassignedEmpty ? '+=' : node.op;
    var first = true;
    for (final (Condition groupCondition, List<_Value> groupItems) in groups) {
      final Condition when = condition.and(groupCondition);
      if (when == Condition.never) {
        continue;
      }
      if (op == '-=' && groupCondition != Condition.always) {
        throw GnError(node.location, '-= of conditional elements is not supported');
      }
      final items = groupItems;
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
        // An element that is itself a list (a list literal, or a variable
        // holding one) is one element, as in GN: a nested list, held as a
        // value (GnListValue) for an index to take apart. A bare variable
        // the converter does not evaluate (`[ "--mode", flutter_runtime_mode
        // ]`) is read as a list of flags for want of knowing better; as an
        // element it is the one string it must be.
        return _Expression(<_Value>[
          for (final GnNode item in items)
            if (_expression(item, scope) case final _Expression e when e.isList)
              if (e.items.length == 1 && e.items.single.value is GnReference)
                e.items.single
              else
                _Value(_nestedList(e, item), _comments(item))
            else
              ..._expression(item, scope).items,
        ], isList: true);
      case GnBinary(op: '+', :final GnNode left, :final GnNode right):
        _Expression l = _expression(left, scope);
        _Expression r = _expression(right, scope);
        if (l.isList && r.isList) {
          return _Expression(<_Value>[...l.items, ...r.items], isList: true);
        }
        // A string and a bare variable the converter does not evaluate
        // (`"_" + flutter_runtime_mode`): such a variable is read as a list
        // of flags for want of knowing better, but GN adds a string to a
        // string only, so here it is a string.
        _Expression asString(_Expression e) =>
            e.isList && e.items.length == 1 && e.items.single.value is GnReference
            ? _Expression(e.items, isList: false)
            : e;
        if (l.isList != r.isList) {
          l = asString(l);
          r = asString(r);
        }
        final GnValue? a = l.scalar;
        final GnValue? b = r.scalar;
        if (a is GnStringValue && b is GnStringValue) {
          return _Expression.scalar(GnStringValue(a.value + b.value));
        }
        // Two string scalars, either with cases (a file-level variable of a
        // file evaluated under a condition, a string around a reference):
        // the concatenation case by case (`jar_path + ".md5.stamp"`).
        if (!l.isList && !r.isList && l.items.isNotEmpty && r.items.isNotEmpty) {
          final out = <_Value>[];
          for (final _Value x in l.items) {
            for (final _Value y in r.items) {
              final Condition when = x.condition.and(y.condition);
              if (when == Condition.never) {
                continue;
              }
              out.add(
                _Value(
                  GnVariable.concatenated(x.value, y.value, node.location),
                  x.comments,
                  condition: when,
                  sourceConditions: x.sourceConditions,
                ),
              );
            }
          }
          return _Expression(out, isList: false);
        }
        throw GnError(node.location, 'unsupported operands of +: $l and $r');
      case GnIdentifier(:final String name):
        return _variableValue(name, node, scope);
      case GnAccessor(:final String base, :final GnNode index):
        if (index is GnLiteral && index.isInteger) {
          return _indexed(base, int.parse(index.raw), node, scope);
        }
        if (index is! GnIdentifier) {
          throw GnError(node.location, 'only scope.member and list[index] access is supported');
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
        if (node.hasExpansion) {
          return _expandExpression(node, scope);
        }
        return _Expression(<_Value>[
          _Value(_literal(node, scope: scope), _comments(node)),
        ], isList: false);
      case GnFunctionCall(name: 'get_path_info', :final List<GnNode> args)
          when args.length == 2 &&
              const <String>{
                'extension',
                'name',
                'file',
              }.contains(_stringExpression(args[1], scope)):
        // The file name's parts, of each case of the path (the Android
        // embedding's `get_path_info(source, "extension")` over the jar and
        // pom names around the runtime mode): a string around a reference
        // keeps the reference where the part spans it.
        final String what = _stringExpression(args[1], scope);
        final _Expression input = _expression(args[0], scope);
        if (input.isList) {
          throw GnError(node.location, 'get_path_info() of a list for $what');
        }
        return _Expression(<_Value>[
          for (final _Value item in input.items)
            _Value(
              _pathInfo(item.value, what, node),
              item.comments,
              condition: item.condition,
              sourceConditions: item.sourceConditions,
            ),
        ], isList: false);
      case GnFunctionCall(name: 'get_path_info', :final List<GnNode> args):
        if (args.length != 2 || _stringExpression(args[1], scope) != 'abspath') {
          throw GnError(node.location, 'only get_path_info(path, "abspath") is supported');
        }
        // A list of paths gives the list of their results, as in GN.
        final _Expression input = _expression(args[0], scope);
        if (input.isList) {
          return _Expression(<_Value>[
            for (final _Value item in input.items)
              if (item.value case GnStringValue(:final String value))
                _Value(
                  GnStringValue(_absolutePath(value, node)),
                  item.comments,
                  condition: item.condition,
                  sourceConditions: item.sourceConditions,
                )
              else
                throw GnError(node.location, 'get_path_info() of a list of ${item.value}'),
          ], isList: true);
        }
        return _Expression.scalar(
          GnStringValue(_absolutePath(_stringExpression(args[0], scope), node)),
        );
      case GnFunctionCall(name: 'string_replace', :final List<GnNode> args):
        // string_replace(str, old, new): each case of the string, replaced
        // (the Android embedding's `string_replace(android_app_abi, "-",
        // "_")`, where the ABI has one case per CPU). A string around a
        // reference the converter does not evaluate cannot be replaced in.
        if (args.length != 3) {
          throw GnError(node.location, 'string_replace() takes a string, the old and the new text');
        }
        final String from = _stringExpression(args[1], scope);
        final String to = _stringExpression(args[2], scope);
        final _Expression input = _expression(args[0], scope);
        if (input.isList) {
          throw GnError(node.location, 'string_replace() of a list');
        }
        return _Expression(<_Value>[
          for (final _Value item in input.items)
            if (item.value case GnStringValue(:final String value))
              _Value(
                GnStringValue(value.replaceAll(from, to)),
                item.comments,
                condition: item.condition,
                sourceConditions: item.sourceConditions,
              )
            else
              throw GnError(node.location, 'string_replace() of ${item.value}'),
        ], isList: false);
      case GnFunctionCall(name: 'rebase_path', :final List<GnNode> args):
        // rebase_path(x, root_build_dir): the path of x as the build runs
        // it. Kept as a marked absolute path inside the string, which the
        // emitter turns into the action rule's path tokens; any other
        // destination is unknowable here.
        if (args.isNotEmpty &&
            args.length <= 2 &&
            (args.length == 1 ||
                (args[1] is GnIdentifier && (args[1] as GnIdentifier).name == 'root_build_dir') ||
                (args[1] is GnLiteral &&
                    (args[1] as GnLiteral).stringValue == r'$root_build_dir'))) {
          final _Expression what = _expression(args[0], scope);
          final GnValue? single = what.isList ? null : what.scalar;
          if (single is GnTargetOutputsValue) {
            // The outputs of a target, as their build-directory paths.
            return _Expression.scalar(GnTargetOutputPathsValue(single.label));
          }
          if (what.isList) {
            // A list of paths (an action's sources as arguments): each one;
            // a target's outputs among them (`sources +=
            // get_target_outputs(":gen_android_build_config_java")`), as
            // their build-directory paths.
            return _Expression(<_Value>[
              for (final _Value item in what.items)
                if (item.value case GnStringValue(:final String value))
                  _Value(
                    GnStringValue(
                      '$rebasedPathMarker${_absolutePath(_unmarkedPath(value), node)}$rebasedPathMarker',
                    ),
                    item.comments,
                    condition: item.condition,
                    sourceConditions: item.sourceConditions,
                  )
                else if (item.value case GnTargetOutputsValue(:final String label))
                  _Value(
                    GnTargetOutputPathsValue(label),
                    item.comments,
                    condition: item.condition,
                    sourceConditions: item.sourceConditions,
                  )
                else
                  throw GnError(node.location, 'rebase_path() of a list of ${item.value}'),
            ], isList: true);
          }
          // A string, with its cases (a file-level variable of a file
          // evaluated under a condition) and around a reference (the
          // embedding jar's path, `flutter_embedding_$flutter_runtime_mode.jar`,
          // which the emitter enumerates): each case marked.
          return _Expression(<_Value>[
            for (final _Value item in what.items)
              _Value(
                _markedRebased(item.value, node),
                item.comments,
                condition: item.condition,
                sourceConditions: item.sourceConditions,
              ),
          ], isList: false);
        }
        // rebase_path(x, "$root_build_dir/<dir>"): x, under that directory
        // of the build directory, relative to it -- the web SDK's archive
        // placing the tree under flutter_web_sdk at its paths below it. A
        // target's outputs keep their symbol with the base; a literal path
        // loses the prefix.
        if (args.length == 2 && args[1] is! GnIdentifier) {
          final String destination = _unmarkedPath(_stringExpression(args[1], scope));
          if (destination.startsWith('$buildDirRoot/')) {
            final String base = destination.substring(buildDirRoot.length + 1);
            GnValue rebased(GnValue value) {
              switch (value) {
                // The outputs, or their absolute paths (`source =
                // rebase_path(source)` in the same scope, read back by the
                // destination's line): the same outputs.
                case GnTargetOutputsValue(:final String label):
                case GnTargetOutputPathsValue(:final String label, base: ''):
                  return GnTargetOutputPathsValue(label, base: base);
                case GnStringValue(value: final String path)
                    when _unmarkedPath(path).startsWith('$buildDirRoot/$base/'):
                  return GnStringValue(
                    _unmarkedPath(path).substring(buildDirRoot.length + base.length + 2),
                  );
                default:
                  throw GnError(
                    node.location,
                    'rebase_path() of $value against $destination is not supported',
                  );
              }
            }

            final _Expression input = _expression(args[0], scope);
            if (input.isList) {
              return _Expression(<_Value>[
                for (final _Value item in input.items)
                  _Value(
                    rebased(item.value),
                    item.comments,
                    condition: item.condition,
                    sourceConditions: item.sourceConditions,
                  ),
              ], isList: true);
            }
            final GnValue? single = input.scalar;
            if (single == null) {
              throw GnError(node.location, 'rebase_path() of nothing');
            }
            return _Expression.scalar(rebased(single));
          }
        }
        // rebase_path(x, root_build_dir, root_build_dir): x, a path relative
        // to the build directory, as the build runs it -- the same path
        // (the Android embedding's `rebase_path("flutter.jar",
        // root_build_dir, root_build_dir)`): the marked build-directory path,
        // as rebase_path("$root_build_dir/x", root_build_dir) gives.
        if (args.length == 3 &&
            args[1] is GnIdentifier &&
            (args[1] as GnIdentifier).name == 'root_build_dir' &&
            args[2] is GnIdentifier &&
            (args[2] as GnIdentifier).name == 'root_build_dir') {
          final _Expression input = _expression(args[0], scope);
          if (input.isList) {
            throw GnError(node.location, 'rebase_path() of a list against the build directory');
          }
          GnValue rebased(GnValue value) {
            switch (value) {
              case GnStringValue(value: final String path):
                final String absolute = path.startsWith('//')
                    ? path
                    : _normalizedPath('$buildDirRoot/$path', node);
                return GnStringValue('$rebasedPathMarker$absolute$rebasedPathMarker');
              case GnExpandedString(:final List<GnValue> parts):
                // A name around a reference (`"$engine_artifact_id.jar"`
                // with the runtime mode in it): the marked path around it.
                final GnValue first = parts.first;
                final String head = first is GnStringValue ? first.value : '';
                final List<GnValue> rest = first is GnStringValue ? parts.sublist(1) : parts;
                final start = head.startsWith('//') ? head : '$buildDirRoot/$head';
                final out = <GnValue>[GnStringValue('$rebasedPathMarker$start'), ...rest];
                final GnValue last = out.last;
                if (last is GnStringValue) {
                  out[out.length - 1] = GnStringValue(last.value + rebasedPathMarker);
                } else {
                  out.add(const GnStringValue(rebasedPathMarker));
                }
                return GnExpandedString(List<GnValue>.unmodifiable(out));
              default:
                throw GnError(node.location, 'rebase_path() of $value');
            }
          }

          return _Expression(<_Value>[
            for (final _Value item in input.items)
              _Value(
                rebased(item.value),
                item.comments,
                condition: item.condition,
                sourceConditions: item.sourceConditions,
              ),
          ], isList: false);
        }
        // rebase_path(x, "", base): x, relative to base, as an absolute
        // path -- sky_engine's way of naming the Dart SDK's library sources
        // (`rebase_path(async_sdk_sources, "", lib_path)`, lib_path itself
        // `rebase_path("async", "", rebase_path("$dart_src/sdk/lib"))`).
        // Each result is the marked absolute path again, for a file list to
        // read; the base must be one such, or a source-absolute path.
        // rebase_path(x, ".", base): the same path relative to the current
        // directory, which a source-absolute path serves as wherever GN
        // takes a relative one (`script = rebase_path(script, ".", "//")`),
        // so the result is that path, unmarked.
        if (args.length == 3 &&
            args[1] is GnLiteral &&
            ((args[1] as GnLiteral).stringValue == '' ||
                (args[1] as GnLiteral).stringValue == '.')) {
          final marked = (args[1] as GnLiteral).stringValue == '';
          final String base = _rebasedPath(_stringExpression(args[2], scope), node);
          String rebased(String path) {
            final String absolute = path.startsWith('//') || path.startsWith(rebasedPathMarker)
                ? _rebasedPath(path, node)
                : _normalizedPath(base == '//' ? '//$path' : '$base/$path', node);
            return marked ? '$rebasedPathMarker$absolute$rebasedPathMarker' : absolute;
          }

          final _Expression input = _expression(args[0], scope);
          if (input.isList) {
            return _Expression(<_Value>[
              for (final _Value item in input.items)
                if (item.value case GnStringValue(:final String value))
                  _Value(
                    GnStringValue(rebased(value)),
                    item.comments,
                    condition: item.condition,
                    sourceConditions: item.sourceConditions,
                  )
                else
                  throw GnError(node.location, 'rebase_path() of a list of ${item.value}'),
            ], isList: true);
          }
          return _Expression.scalar(GnStringValue(rebased(_stringExpression(args[0], scope))));
        }
        return _Expression.scalar(GnOpaqueValue(_gnText(node)));
      case GnFunctionCall(name: 'get_label_info', :final List<GnNode> args):
        if (args.length != 2) {
          throw GnError(node.location, 'get_label_info() takes a label and a property');
        }
        return _Expression.scalar(
          GnStringValue(
            _labelInfo(_labelArgument(args[0], scope), _stringExpression(args[1], scope), node),
          ),
        );
      case GnFunctionCall(name: 'exec_script'):
        // Unknowable here; an error if it ever reaches the output.
        return _Expression.scalar(GnOpaqueValue(_gnText(node)));
      case GnFunctionCall(name: 'get_target_outputs', :final List<GnNode> args):
        if (args.length != 1) {
          throw GnError(node.location, 'get_target_outputs() takes one label');
        }
        final String label = _stringExpression(args.single, scope);
        return _Expression(<_Value>[
          _Value(
            GnTargetOutputsValue(
              '${_labelInfo(label, 'dir', node)}:${_labelInfo(label, 'name', node)}',
              const <String>[],
            ),
            GnItemComments.none,
          ),
        ], isList: true);
      case GnFunctionCall(name: 'filter_include', :final List<GnNode> args):
        if (args.length != 2) {
          throw GnError(node.location, 'filter_include() takes a list and the patterns');
        }
        final _Expression list = _expression(args[0], scope);
        final patterns = <String>[
          for (final _Value v in _expression(args[1], scope).items)
            if (v.value case GnStringValue(:final String value))
              value
            else
              throw GnError(node.location, 'filter_include() patterns must be strings'),
        ];
        final kept = <_Value>[];
        for (final _Value item in list.items) {
          switch (item.value) {
            case GnTargetOutputsValue(:final String label, patterns: final List<String> existing):
              if (existing.isNotEmpty) {
                throw GnError(
                  node.location,
                  'filter_include() over a filtered get_target_outputs()',
                );
              }
              kept.add(
                _Value(
                  GnTargetOutputsValue(label, patterns),
                  item.comments,
                  condition: item.condition,
                  sourceConditions: item.sourceConditions,
                ),
              );
            case GnStringValue(:final String value):
              if (patterns.any((String p) => _matchesFilePattern(value, p))) {
                kept.add(item);
              }
            default:
              throw GnError(node.location, 'filter_include() over ${item.value} is not supported');
          }
        }
        return _Expression(kept, isList: true);
      case GnFunctionCall(:final String name):
        throw GnError(node.location, '$name() in an expression is not supported by the converter');
      default:
        throw GnError(node.location, 'unsupported expression (${node.runtimeType})');
    }
  }

  /// GN's file pattern match (`filter_include`): `*` matches any run of
  /// characters, the rest is literal; the pattern covers the whole string.
  static bool _matchesFilePattern(String value, String pattern) {
    final String regex = pattern.split('*').map(RegExp.escape).join('.*');
    return RegExp('^$regex\$').hasMatch(value);
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

  /// The source-absolute path a `rebase_path()` result holds (the marked
  /// path), or [path] itself when it is already one (`//flutter/...`).
  String _rebasedPath(String path, GnNode node) {
    final String unmarked = _unmarkedPath(path);
    if (unmarked.startsWith('//')) {
      return unmarked;
    }
    throw GnError(node.location, '$path is not a path rebase_path() can rebase from');
  }

  /// [path] without the marks of a `rebase_path()` result, if it is one.
  static String _unmarkedPath(String path) {
    if (path.length >= 2 &&
        path.startsWith(rebasedPathMarker) &&
        path.endsWith(rebasedPathMarker) &&
        !path.substring(1, path.length - 1).contains(rebasedPathMarker)) {
      return path.substring(1, path.length - 1);
    }
    return path;
  }

  /// A source-absolute path with `.` and `..` resolved (`//a/b/../c` is
  /// `//a/c`).
  String _normalizedPath(String path, GnNode node) {
    if (!path.startsWith('//')) {
      throw GnError(node.location, '$path is not source-absolute');
    }
    final String normalized = p.posix.normalize(path.substring(2));
    return normalized == '.' ? '//' : '//$normalized';
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

  /// A label argument (get_label_info's): one string, or one whose only
  /// expansion is a toolchain variable in parentheses
  /// (`"$dart_src/runtime/bin:gen_snapshot($host_toolchain)"`), kept as
  /// written for [_labelInfo] to read the toolchain off.
  String _labelArgument(GnNode node, _Scope scope) {
    final _Expression expression = _expression(node, scope);
    final GnValue? value = expression.scalar;
    if (value is GnExpandedString) {
      final List<GnValue> parts = value.parts;
      if (parts.length == 3 &&
          parts[0] is GnStringValue &&
          parts[1] is GnReference &&
          parts[2] == const GnStringValue(')') &&
          (parts[0] as GnStringValue).value.endsWith('(')) {
        return '${(parts[0] as GnStringValue).value}\$${(parts[1] as GnReference).name})';
      }
    }
    return _stringExpression(node, scope);
  }

  /// `rebase_path(value, root_build_dir)` of one string: the absolute path,
  /// marked; a string around a reference keeps the reference, the marks on
  /// its literal ends.
  GnValue _markedRebased(GnValue value, GnNode node) {
    switch (value) {
      case GnStringValue(value: final String path):
        return GnStringValue(
          '$rebasedPathMarker${_absolutePath(_unmarkedPath(path), node)}$rebasedPathMarker',
        );
      case GnExpandedString(:final List<GnValue> parts):
        final GnValue first = parts.first;
        final String head = first is GnStringValue ? first.value : '';
        final List<GnValue> rest = first is GnStringValue ? parts.sublist(1) : parts;
        final out = <GnValue>[
          GnStringValue('$rebasedPathMarker${_absolutePath(_unmarkedPath(head), node)}'),
          ...rest,
        ];
        final GnValue last = out.last;
        if (last is GnStringValue) {
          out[out.length - 1] = GnStringValue(last.value + rebasedPathMarker);
        } else {
          out.add(const GnStringValue(rebasedPathMarker));
        }
        return GnExpandedString(List<GnValue>.unmodifiable(out));
      default:
        throw GnError(node.location, 'rebase_path() of $value');
    }
  }

  /// get_label_info(label, what) for the properties that are paths or
  /// names. A toolchain suffix (`($default_toolchain)`) is ignored, except
  /// that the host toolchain's `root_out_dir` in a cross build is its
  /// subdirectory of the build directory (`clang_x64` on the Linux x64
  /// host: the Android shell's archives of the host's gen_snapshot and
  /// analyze_snapshot), which the file's condition decides: a file
  /// evaluated under an OS the host does not run is a cross build, one
  /// under a host OS is not; a file under neither cannot say.
  String _labelInfo(String label, String what, GnNode node) {
    var bare = label;
    var toolchain = '';
    final int paren = bare.indexOf('(');
    if (paren >= 0) {
      toolchain = bare.substring(paren + 1, bare.length - 1);
      bare = bare.substring(0, paren);
    }
    if (what == 'root_out_dir' && toolchain == r'$host_toolchain') {
      final bool? host = _isHostBuild();
      if (host == null) {
        throw GnError(
          node.location,
          'get_label_info(..., "root_out_dir") of a host-toolchain label depends on whether the '
          "build is a cross build, which the file's condition does not say",
        );
      }
      return host ? buildDirRoot : '$buildDirRoot/$hostToolchainDirectory';
    }
    if (what == 'root_out_dir' && toolchainDirectories.containsKey(toolchain)) {
      return '$buildDirRoot/${toolchainDirectories[toolchain]}';
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

  /// `get_path_info(path, what)` for "file" (the last component), "name"
  /// (without the extension) and "extension": of a string, or of a string
  /// around a reference, whose literal ends give the parts (the reference
  /// stays inside the name).
  GnValue _pathInfo(GnValue value, String what, GnNode node) {
    final List<GnValue> parts = switch (value) {
      GnStringValue() => <GnValue>[value],
      GnExpandedString(:final List<GnValue> parts) => parts,
      _ => throw GnError(node.location, 'get_path_info() of $value'),
    };
    // The last component: from the last '/' of a literal part on.
    var start = 0;
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] case GnStringValue(value: final String text)) {
        if (text.contains('/')) {
          start = i;
        }
      }
    }
    final file = <GnValue>[];
    for (var i = start; i < parts.length; i++) {
      final GnValue part = parts[i];
      if (i == start && part is GnStringValue) {
        file.add(GnStringValue(part.value.substring(part.value.lastIndexOf('/') + 1)));
      } else {
        file.add(part);
      }
    }
    GnValue joined(List<GnValue> p) => p.length == 1 && p.single is GnStringValue
        ? p.single
        : GnExpandedString(List<GnValue>.unmodifiable(p));
    if (what == 'file') {
      return joined(file);
    }
    final GnValue last = file.last;
    final int dot = last is GnStringValue ? last.value.lastIndexOf('.') : -1;
    if (dot < 0) {
      // No extension in the literal tail: GN's "" for the extension, the
      // file for the name.
      return what == 'extension' ? const GnStringValue('') : joined(file);
    }
    final String tail = (last as GnStringValue).value;
    if (what == 'extension') {
      return GnStringValue(tail.substring(dot + 1));
    }
    final name = <GnValue>[
      ...file.sublist(0, file.length - 1),
      GnStringValue(tail.substring(0, dot)),
    ];
    if (name.last case GnStringValue(value: '')) {
      name.removeLast();
    }
    return joined(name);
  }

  /// A list expression as one value, for an element of a list that is a
  /// list: its elements must be unconditional (a select() has no place
  /// inside a value).
  GnListValue _nestedList(_Expression list, GnNode node) {
    return GnListValue(
      List<GnValue>.unmodifiable(<GnValue>[
        for (final _Value item in list.items)
          if (item.condition == Condition.always)
            item.value
          else
            throw GnError(node.location, 'an element of a nested list under a condition'),
      ]),
    );
  }

  /// `name[i]`: the element of a list variable, or of a variable holding a
  /// list (a `foreach` variable over nested lists). An element that is a
  /// list is the list again.
  _Expression _indexed(String name, int i, GnNode node, _Scope scope) {
    final GnVariable? variable = scope.lookup(name);
    if (variable == null) {
      throw GnError(node.location, 'unknown variable $name');
    }
    final _Expression value = _variableItems(variable, node);
    final List<GnValue> items;
    if (value.isList) {
      if (value.items.any((_Value v) => v.condition != Condition.always)) {
        throw GnError(node.location, 'an element of $name, which has conditional elements');
      }
      items = <GnValue>[for (final _Value v in value.items) v.value];
    } else if (value.scalar case GnListValue(items: final List<GnValue> held)) {
      items = held;
    } else {
      throw GnError(node.location, '$name[$i] of ${value.scalar}, which is not a list');
    }
    if (i < 0 || i >= items.length) {
      throw GnError(node.location, '$name[$i] is out of range (${items.length} elements)');
    }
    final GnValue element = items[i];
    if (element is GnListValue) {
      return _Expression(<_Value>[
        for (final GnValue v in element.items) _Value(v, _comments(node)),
      ], isList: true);
    }
    return _Expression.scalar(element);
  }

  _Expression _variableValue(String name, GnNode node, _Scope scope) {
    final GnVariable? variable = scope.lookup(name);
    if (variable != null) {
      return _variableItems(variable, node);
    }
    final GnValue? assumed = assumptions[name];
    if (assumed is GnCasedValue) {
      return _Expression(<_Value>[
        for (final MapEntry<String, String> c in assumed.values.entries)
          _Value(
            GnStringValue(c.value),
            _comments(node),
            condition: ConditionComparison(assumed.variable, true, c.key),
          ),
      ], isList: false);
    }
    if (assumed != null) {
      return _Expression.scalar(assumed);
    }
    if (settings.booleanVariables.contains(name)) {
      // A predicate read as a value (gpu.gni's invocations: `enable_software
      // = test_enable_software`, tested in the template as
      // `invoker.enable_software`).
      return _Expression.scalar(GnConditionValue(ConditionVariable(name)));
    }
    if (settings.externalVariables.contains(name)) {
      // The engine's other `.gni` variables that build files read are lists
      // of flags.
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
  _Expression _variableItems(GnVariable variable, GnNode node) {
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
  _Expression _scalarItems(GnVariable variable, GnLocation use) {
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
      return _expand(node, scope);
    }
    return GnStringValue(node.stringValue);
  }

  static final RegExp _expansion = RegExp(
    r'\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))',
  );

  static final RegExp _defaultToolchainSuffix = RegExp(
    r'\(\$(?:default_toolchain|\{default_toolchain\})\)$',
  );

  /// Resolves `$name` and `${name}` in a string from the known strings
  /// (assumptions and local scalar variables). An external variable with no
  /// assumed value stays a reference inside a [GnExpandedString]; anything
  /// else is an error.
  GnValue _expand(
    GnLiteral node,
    _Scope? scope, {
    Map<String, GnValue> bound = const <String, GnValue>{},
  }) {
    // `:x($default_toolchain)` names the default toolchain's instance of a
    // target; a Bazel package is loaded once for every configuration, so
    // the suffix is dropped (as bazelLabel and _labelInfo drop it from a
    // plain string) rather than expanded into a label.
    final String text = node.stringValue.replaceFirst(_defaultToolchainSuffix, '');
    var last = 0;
    final parts = <GnValue>[];
    final literal = StringBuffer();
    for (final Match match in _expansion.allMatches(text)) {
      final String name = match.group(1) ?? match.group(2)!;
      literal.write(text.substring(last, match.start));
      last = match.end;
      // A variable bound to one of its cases ([_expandExpression]): its
      // string, or the parts of a string around a reference.
      final GnValue? boundValue = bound[name];
      if (boundValue is GnStringValue) {
        literal.write(boundValue.value);
        continue;
      }
      if (boundValue is GnExpandedString) {
        for (final GnValue part in boundValue.parts) {
          if (part is GnStringValue) {
            literal.write(part.value);
          } else {
            if (literal.isNotEmpty) {
              parts.add(GnStringValue(literal.toString()));
              literal.clear();
            }
            parts.add(part);
          }
        }
        continue;
      }
      final String? value = _knownString(name, scope, node);
      // A local variable holding a string around a reference (`prefix =
      // "linux-x64-$flutter_runtime_mode/"`): its parts, spliced in.
      final GnValue? held = value == null ? _heldExpandedString(name, scope, node) : null;
      // A list expands as GN serializes one -- `["a", "b"]` -- which the
      // scripts that take such arguments parse back (build_utils.ParseGnList:
      // javac.py's --classpath); its strings and the marks of rebased paths
      // among them stay as they are.
      final List<String>? listed = value == null && held == null
          ? _heldStringList(name, scope)
          : null;
      // A local holding an external variable by name: the reference.
      final GnReference? reference = value == null && held == null && listed == null
          ? _heldReference(name, scope)
          : null;
      if (value != null) {
        literal.write(value);
      } else if (listed != null) {
        literal.write('[${listed.map((String s) => '"$s"').join(', ')}]');
      } else if (held is GnExpandedString) {
        for (final GnValue part in held.parts) {
          if (part is GnStringValue) {
            literal.write(part.value);
          } else {
            if (literal.isNotEmpty) {
              parts.add(GnStringValue(literal.toString()));
              literal.clear();
            }
            parts.add(part);
          }
        }
      } else if (reference != null || settings.externalVariables.contains(name)) {
        if (literal.isNotEmpty) {
          parts.add(GnStringValue(literal.toString()));
          literal.clear();
        }
        parts.add(reference ?? GnReference(name));
      } else {
        throw GnError(node.location, 'string expansion of \$$name is not supported: ${node.raw}');
      }
    }
    if (last < text.length) {
      final String rest = text.substring(last);
      if (rest.contains(r'$')) {
        throw GnError(node.location, 'string expansion is not supported: ${node.raw}');
      }
      literal.write(rest);
    }
    if (parts.isEmpty) {
      return GnStringValue(literal.toString());
    }
    if (literal.isNotEmpty) {
      parts.add(GnStringValue(literal.toString()));
    }
    return GnExpandedString(List<GnValue>.unmodifiable(parts));
  }

  /// A string with expansions as an expression: one value per case when a
  /// variable it expands takes different values under different conditions
  /// (`path_prefix` set under `flutter_runtime_mode == "release"`, then
  /// `"${path_prefix}platform_strong.dill"`), each under the conjunction of
  /// its variables' conditions; the single value otherwise ([_expand]).
  _Expression _expandExpression(GnLiteral node, _Scope? scope) {
    final String text = node.stringValue;
    // Each variable with more than one case, by its place in the text.
    final conditional = <String, List<_Value>>{};
    for (final Match match in _expansion.allMatches(text)) {
      final String name = match.group(1) ?? match.group(2)!;
      if (conditional.containsKey(name)) {
        continue;
      }
      final GnVariable? variable = scope?.lookup(name);
      if (variable == null) {
        // A cased assumption (`"$android_app_abi"`: config.gni's ABI by
        // CPU) has its cases too.
        if (assumptions[name] case final GnCasedValue cased) {
          conditional[name] = <_Value>[
            for (final MapEntry<String, String> c in cased.values.entries)
              _Value(
                GnStringValue(c.value),
                _comments(node),
                condition: ConditionComparison(cased.variable, true, c.key),
              ),
          ];
        }
        continue;
      }
      if (variable.isList) {
        continue;
      }
      final _Expression items = _scalarItems(variable, node.location);
      if (items.items.length > 1) {
        conditional[name] = items.items;
      }
    }
    if (conditional.isEmpty) {
      return _Expression(<_Value>[_Value(_expand(node, scope), _comments(node))], isList: false);
    }
    if (conditional.length > 1) {
      throw GnError(
        node.location,
        'more than one variable with conditional values in one string: ${node.raw}',
      );
    }
    final MapEntry<String, List<_Value>> only = conditional.entries.single;
    final values = <_Value>[];
    for (final _Value item in only.value) {
      if (item.value is! GnStringValue && item.value is! GnExpandedString) {
        throw GnError(node.location, 'expansion of ${only.key}, which is ${item.value}');
      }
      values.add(
        _Value(
          _expand(node, scope, bound: <String, GnValue>{only.key: item.value}),
          _comments(node),
          condition: item.condition,
          sourceConditions: item.sourceConditions,
        ),
      );
    }
    return _Expression(values, isList: false);
  }

  /// The [GnExpandedString] a local scalar [name] holds unconditionally,
  /// or null.
  GnValue? _heldExpandedString(String name, _Scope? scope, GnNode node) {
    final GnVariable? variable = scope?.lookup(name);
    if (variable == null || variable.isList) {
      return null;
    }
    final _Expression items = _scalarItems(variable, node.location);
    // One value, or one value under every case (a file evaluated under a
    // condition of its own -- the Android shell's under is_android -- gives
    // every file-level variable that condition).
    final GnValue? single = items.scalar;
    if (single is GnExpandedString) {
      return single;
    }
    if (items.items.isEmpty) {
      return null;
    }
    final GnValue first = items.items.first.value;
    if (first is GnExpandedString && items.items.every((_Value i) => i.value == first)) {
      return first;
    }
    return null;
  }

  /// The external variable a local [name] holds as a bare reference
  /// (darwin/common's `_platform_path = mac_platform_path`, read as
  /// `"$_platform_path/..."`), or null. An external variable is read as a
  /// list of one reference ([_identifier]: the `.gni` flag lists), so the
  /// local is a list here; a string expansion of it is the reference itself,
  /// which the Bazel side holds as a constant -- a string one, where the
  /// expression the emitter writes around it (`"-F" + CONSTANT + "/..."`)
  /// makes sense; a list constant would fail there, loudly.
  GnReference? _heldReference(String name, _Scope? scope) {
    final GnVariable? variable = scope?.lookup(name);
    if (variable == null || !variable.isList) {
      return null;
    }
    GnReference? held;
    for (final GnAssignment a in variable.assignments) {
      if (a.op != '=' || a.items.length != 1) {
        return null;
      }
      final GnValue item = a.items.single;
      if (item is! GnReference || (held != null && item != held)) {
        return null;
      }
      held = item;
    }
    return held;
  }

  /// The strings of [name] when it is a local list variable of plain
  /// strings holding unconditionally (GN serializes such a list into a
  /// string expansion); null for anything else.
  List<String>? _heldStringList(String name, _Scope? scope) {
    final GnVariable? variable = scope?.lookup(name);
    if (variable == null || !variable.isList) {
      return null;
    }
    // Assignments unconditional or under one condition (a file evaluated
    // under a condition of its own gives its variables that condition; a
    // list of literals and rebased paths splits into the two) count as
    // unconditional here.
    final conditions = <Condition>{
      for (final GnAssignment a in variable.assignments)
        if (!a.isUnconditional) a.condition,
    };
    if (conditions.length > 1) {
      return null;
    }
    final items = <GnValue>[];
    for (final GnAssignment a in variable.assignments) {
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
    if (items.any((GnValue v) => v is! GnStringValue)) {
      return null;
    }
    return <String>[for (final GnValue v in items) (v as GnStringValue).value];
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
    if (left case GnAccessor(:final String base, index: final GnLiteral index)
        when index.isInteger && right is GnLiteral && right.isString) {
      // `layer_info[2] != ""`: an element of a nested list against a
      // string. A list is never equal to a string; a string compares.
      final _Expression element = _indexed(base, int.parse(index.raw), node, scope);
      if (element.isList) {
        return ConditionConstant(!equals);
      }
      if (element.scalar case GnStringValue(:final String value)) {
        return ConditionConstant((value == right.stringValue) == equals);
      }
      throw GnError(node.location, 'comparison of ${element.scalar} with a string');
    }
    if (left is! GnIdentifier) {
      throw GnError(node.location, 'only `variable == "string"` comparisons are supported');
    }
    final String? leftValue = _knownString(left.name, scope);
    if (right is GnIdentifier) {
      // `current_toolchain == host_toolchain`: both sides must be known -- or
      // neither, when the comparison is GN's "is this the host's own build"
      // (testing.gni's enable_unittests, the shell's tester, glfw's shell),
      // which the converter keeps as the predicate hostToolchainPredicate:
      // in Bazel's terms the target OS is one a host runs
      // (build/bazel/BUILD.bazel's host_toolchain group).
      final String? rightValue = _knownString(right.name, scope);
      if (leftValue == null && rightValue == null && _isHostToolchainTest(left.name, right.name)) {
        const condition = ConditionVariable(hostToolchainPredicate);
        return equals ? condition : condition.negated;
      }
      if (leftValue == null &&
          rightValue == null &&
          _isDefaultToolchainTest(left.name, right.name)) {
        // `current_toolchain == default_toolchain` (glslang's build_info
        // action): GN defines the target once, in the default toolchain, and
        // the other toolchains' targets name it as `:x($default_toolchain)`.
        // A Bazel package is loaded once for every configuration, so the
        // test holds.
        return ConditionConstant(equals);
      }
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
    final Condition? byCases = _casesComparison(left.name, equals, value, scope, node);
    if (byCases != null) {
      return byCases;
    }
    if (assumptions[left.name] != null || scope.lookup(left.name) != null) {
      throw GnError(node.location, 'comparison with ${left.name}, which is not a known string');
    }
    if (!settings.externalVariables.contains(left.name)) {
      throw GnError(node.location, 'unknown variable ${left.name} in condition');
    }
    // An OS name's comparison asserts that OS's predicate (_alternatives);
    // where the assumptions deny the predicate (`target_os != "android"` in
    // the generation scope, is_android being false there) the comparison is
    // decided too.
    final String? predicate = switch (left.name) {
      'target_os' || 'current_os' => osNamePredicates[value],
      'full_target_platform_name' => targetPlatformParts(value)?.osPredicate,
      _ => null,
    };
    if (predicate != null && assumptions[predicate] == const GnBoolValue(false)) {
      return ConditionConstant(!equals);
    }
    return ConditionComparison(left.name, equals, value);
  }

  /// `name == "value"` for a string variable written under conditions
  /// (skia.gni's skia_gl_standard: "webgl" where `is_wasm`, "" otherwise):
  /// the comparison holds where a case with that string (for `!=`, another
  /// string) is the one in force. Null for anything but such a variable.
  Condition? _casesComparison(String name, bool equals, String value, _Scope scope, GnNode node) {
    final GnVariable? variable = scope.lookup(name);
    if (variable == null) {
      final GnValue? assumed = assumptions[name];
      return assumed is GnCasedValue ? _casedComparison(assumed, equals, value) : null;
    }
    if (variable.isList) {
      return null;
    }
    final _Expression cases = _scalarItems(variable, node.location);
    // A declared argument an assumption with cases stands in for
    // (declare_args() assigns the assumption under each of its branches):
    // the cases are the assumption's.
    final cased = <GnCasedValue>{
      for (final _Value i in cases.items)
        if (i.value is GnCasedValue) i.value as GnCasedValue,
    };
    if (cased.isNotEmpty) {
      if (cased.length != 1 || cases.items.any((_Value i) => i.value is! GnCasedValue)) {
        throw GnError(node.location, '$name mixes an assumption with cases and other values');
      }
      return _casedComparison(cased.single, equals, value);
    }
    if (cases.items.any((_Value i) => i.value is! GnStringValue)) {
      return null;
    }
    return Condition.disjunction(<Condition>[
      for (final _Value i in cases.items)
        if (((i.value as GnStringValue).value == value) == equals) i.condition,
    ]);
  }

  /// `name == "value"` for an assumption with a case per value of another
  /// variable (skia_gl_standard by target_os: "gles" on Android, "webgl" on
  /// the web, "" on the host): the comparison holds under the cases whose
  /// string matches (for `!=`, does not), each the comparison of that
  /// variable -- `target_os == "android"`, which the emitter renders as the
  /// OS's setting.
  Condition _casedComparison(GnCasedValue cased, bool equals, String value) {
    return Condition.disjunction(<Condition>[
      for (final MapEntry<String, String> c in cased.values.entries)
        if ((c.value == value) == equals) ConditionComparison(cased.variable, true, c.key),
    ]);
  }

  /// Whether the build the file is evaluated for is the host's own (its
  /// condition, or the assumed target OS, names an OS a host runs), a cross
  /// build (any other OS), or neither is known (null).
  bool? _isHostBuild() {
    const hostOses = <String>{'is_linux', 'is_mac', 'is_win'};
    final Condition condition = fileCondition;
    if (condition is ConditionVariable && exclusiveOsPredicates.contains(condition.name)) {
      return hostOses.contains(condition.name);
    }
    for (final String os in exclusiveOsPredicates) {
      if (settings.assumptions[os] == const GnBoolValue(true)) {
        return hostOses.contains(os);
      }
    }
    return null;
  }

  static bool _isHostToolchainTest(String a, String b) {
    return (a == 'current_toolchain' && b == 'host_toolchain') ||
        (a == 'host_toolchain' && b == 'current_toolchain');
  }

  static bool _isDefaultToolchainTest(String a, String b) {
    return (a == 'current_toolchain' && b == 'default_toolchain') ||
        (a == 'default_toolchain' && b == 'current_toolchain');
  }
}

/// The converter's name for GN's `current_toolchain == host_toolchain` when
/// neither toolchain is assumed: the build is the host's own. Its
/// config_setting (bazel_mapping's conditionSettings) is the group of the
/// OSes a host runs with the host's CPU (build/bazel's host_toolchain),
/// which //flutter/testing's unittests_enabled reads too, with testing.gni's
/// other two cases.
const String hostToolchainPredicate = 'is_host_toolchain';

/// The subdirectory of the build directory that holds the host toolchain's
/// outputs in a cross build (BUILDCONFIG.gn names the Linux x64 host's
/// toolchain clang_x64; GN puts every non-default toolchain's outputs under
/// its name).
const String hostToolchainDirectory = 'clang_x64';

/// The other non-default toolchains a label may name, each with the
/// subdirectory of the build directory that holds its outputs:
/// build/toolchain/android's clang_arm64_apilevel26 (the Vulkan validation
/// layer's), under `clang_arm64_apilevel26/`.
const Map<String, String> toolchainDirectories = <String, String>{
  '//build/toolchain/android:clang_arm64_apilevel26': 'clang_arm64_apilevel26',
};
