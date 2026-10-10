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

import 'gn_ast.dart';

// ---------------------------------------------------------------------------
// Conditions
// ---------------------------------------------------------------------------

/// A boolean formula over GN variables.
@immutable
sealed class Condition {
  const Condition();

  static const Condition always = ConditionConstant(true);
  static const Condition never = ConditionConstant(false);

  Condition and(Condition other) {
    if (this == always) {
      return other;
    }
    if (other == always) {
      return this;
    }
    if (this == never || other == never) {
      return never;
    }
    return ConditionAnd(<Condition>[
      if (this is ConditionAnd) ...(this as ConditionAnd).terms else this,
      if (other is ConditionAnd) ...other.terms else other,
    ]);
  }

  Condition or(Condition other) {
    if (this == never) {
      return other;
    }
    if (other == never) {
      return this;
    }
    if (this == always || other == always) {
      return always;
    }
    return ConditionOr(<Condition>[
      if (this is ConditionOr) ...(this as ConditionOr).terms else this,
      if (other is ConditionOr) ...other.terms else other,
    ]);
  }

  Condition get negated => switch (this) {
    ConditionConstant(:final bool value) => ConditionConstant(!value),
    ConditionNot(:final Condition operand) => operand,
    ConditionComparison(:final String name, :final bool equals, :final String value) =>
      ConditionComparison(name, !equals, value),
    ConditionAnd(:final List<Condition> terms) => ConditionOr(<Condition>[
      for (final Condition t in terms) t.negated,
    ]),
    ConditionOr(:final List<Condition> terms) => ConditionAnd(<Condition>[
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
  GnVariable(this.name, {required this.isList});

  final String name;

  /// Whether the variable holds a list (as opposed to a string, boolean or
  /// integer), decided by its first assignment.
  final bool isList;
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
}

// ---------------------------------------------------------------------------
// Assumptions
// ---------------------------------------------------------------------------

/// Values the converter may take as given for GN variables (build arguments
/// and platform predicates), so that the branches they rule out are skipped
/// and the ones they imply are unconditional.
final class Assumptions {
  Assumptions(Map<String, GnValue> values) : _values = Map<String, GnValue>.unmodifiable(values);

  final Map<String, GnValue> _values;

  GnValue? operator [](String name) => _values[name];

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

/// Evaluates [file] (the tree of one `BUILD.gn`).
///
/// [templates] are the names of the `.gni` templates that may be invoked like
/// rules; [externalVariables] the names that imported files define and that
/// may be read (they become [GnReference]s) or tested (they stay symbolic).
/// Targets named in [skipTargets] are not evaluated at all (so that what is
/// inside them need not be understood); they are listed in the result.
GnFileEvaluation evaluateGnFile(
  GnBlock file, {
  required Assumptions assumptions,
  Set<String> templates = const <String>{},
  Set<String> externalVariables = const <String>{},
  Set<String> skipTargets = const <String>{},
}) {
  final evaluator = _Evaluator(
    assumptions,
    templates,
    externalVariables,
    skipTargets,
    file.location.file,
  );
  evaluator.evaluateFile(file);
  return evaluator.result;
}

/// Target variables that BUILDCONFIG.gn's set_defaults() initializes, so
/// that a target may `+=` to them without assigning them first.
const Set<String> _predefinedTargetVariables = <String>{'configs'};

final class _Scope {
  _Scope(this.parent, {this.isTarget = false});

  final _Scope? parent;

  /// Whether this is the scope of a target's block.
  final bool isTarget;
  final Map<String, GnVariable> variables = <String, GnVariable>{};

  GnVariable? lookup(String name) => variables[name] ?? parent?.lookup(name);
}

/// The value of an expression while it is evaluated.
final class _Expression {
  const _Expression(this.items, {required this.isList});

  final List<(GnValue, GnItemComments)> items;
  final bool isList;

  /// The value of a scalar expression.
  GnValue? get scalar => isList ? null : items.single.$1;

  @override
  String toString() =>
      isList ? '[${items.map(((GnValue, GnItemComments) i) => i.$1).join(', ')}]' : '$scalar';
}

final class _Evaluator {
  _Evaluator(
    this.assumptions,
    this.templates,
    this.externalVariables,
    this.skipTargets,
    String file,
  ) : result = GnFileEvaluation(file);

  final Assumptions assumptions;
  final Set<String> templates;
  final Set<String> externalVariables;
  final Set<String> skipTargets;
  final GnFileEvaluation result;

  void evaluateFile(GnBlock file) {
    _evaluateBlock(file, _Scope(null), Condition.always, const <String>[], target: null);
  }

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
          _evaluateCall(statement, scope, path, target: target, comments: statement.beforeComments);
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
      _ => '<${node.runtimeType}>',
    };
  }

  void _evaluateCall(
    GnFunctionCall call,
    _Scope scope,
    Condition condition, {
    required GnTarget? target,
    required List<String> comments,
  }) {
    switch (call.name) {
      case 'import':
        if (target != null) {
          throw GnError(call.location, 'import inside a target');
        }
        result.imports.add(_stringArgument(call));
        return;
      case 'assert':
        return;
      case 'foreach':
      case 'template':
      case 'declare_args':
      case 'set_defaults':
      case 'exec_script':
      case 'forward_variables_from':
        throw GnError(call.location, '${call.name}() is not supported by the converter');
    }
    if (target != null) {
      throw GnError(call.location, 'target ${call.name}() nested inside target ${target.name}');
    }
    // A skipped target is left alone before anything about it is checked,
    // so that a template the converter does not know can be skipped.
    if (call.args.length == 1) {
      final GnNode arg = call.args.single;
      if (arg is GnLiteral && arg.isString && skipTargets.contains(arg.stringValue)) {
        result.skipped.add(arg.stringValue);
        return;
      }
    }
    if (!gnTargetRules.contains(call.name) && !templates.contains(call.name)) {
      throw GnError(call.location, 'unknown function or template ${call.name}()');
    }
    final GnBlock? block = call.block;
    if (block == null) {
      throw GnError(call.location, '${call.name}() without a block');
    }
    final newTarget = GnTarget(call.location, call.name, _stringArgument(call), condition)
      ..comments = comments;
    final targetScope = _Scope(scope, isTarget: true);
    _evaluateBlock(block, targetScope, Condition.always, const <String>[], target: newTarget);
    newTarget.variables.addAll(targetScope.variables);
    result.targets.add(newTarget);
  }

  String _stringArgument(GnFunctionCall call) {
    if (call.args.length != 1) {
      throw GnError(call.location, '${call.name}() takes one argument');
    }
    final GnNode arg = call.args.single;
    if (arg is! GnLiteral || !arg.isString || arg.hasExpansion) {
      throw GnError(arg.location, '${call.name}() argument must be a plain string');
    }
    return arg.stringValue;
  }

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
    final _Expression value = _isBooleanExpression(node.right)
        ? _booleanExpression(node.right, scope)
        : _expression(node.right, scope);
    final GnVariable variable;
    if (node.op == '=') {
      // `=` defines a variable in the current scope (GN forbids shadowing an
      // enclosing scope's variable, which is left to GN to diagnose).
      variable = scope.variables.putIfAbsent(name, () => GnVariable(name, isList: value.isList));
      if (variable.assignments.isNotEmpty && condition != Condition.always) {
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
    final List<(GnValue, GnItemComments)> items = value.items;
    final bool anyItemComments = items.any(((GnValue, GnItemComments) i) => !i.$2.isEmpty);
    variable.assignments.add(
      GnAssignment(
        node.location,
        condition,
        node.op,
        <GnValue>[for (final (GnValue value, _) in items) value],
        sourceConditions: source,
        comments: comments,
        itemComments: anyItemComments
            ? <GnItemComments>[for (final (_, GnItemComments c) in items) c]
            : const <GnItemComments>[],
      ),
    );
  }

  /// The value of an expression: the items of a list, or the single value
  /// of a scalar, each with the comments written around it.
  _Expression _expression(GnNode node, _Scope scope) {
    switch (node) {
      case GnList(:final List<GnNode> items):
        return _Expression(<(GnValue, GnItemComments)>[
          for (final GnNode item in items) ..._expression(item, scope).items,
        ], isList: true);
      case GnBinary(op: '+', :final GnNode left, :final GnNode right):
        final _Expression l = _expression(left, scope);
        final _Expression r = _expression(right, scope);
        if (l.isList && r.isList) {
          return _Expression(<(GnValue, GnItemComments)>[...l.items, ...r.items], isList: true);
        }
        final GnValue? a = l.scalar;
        final GnValue? b = r.scalar;
        if (a is GnStringValue && b is GnStringValue) {
          return _Expression(<(GnValue, GnItemComments)>[
            (GnStringValue(a.value + b.value), GnItemComments.none),
          ], isList: false);
        }
        throw GnError(node.location, 'unsupported operands of +: $l and $r');
      case GnIdentifier(:final String name):
        final GnVariable? variable = scope.lookup(name);
        if (variable != null) {
          final List<GnValue>? items = variable.unconditionalItems;
          if (items == null) {
            throw GnError(
              node.location,
              'use of $name, whose value depends on a condition, is not supported',
            );
          }
          return _Expression(<(GnValue, GnItemComments)>[
            for (final GnValue item in items) (item, GnItemComments.none),
          ], isList: variable.isList);
        }
        final GnValue? assumed = assumptions[name];
        if (assumed != null) {
          return _Expression(<(GnValue, GnItemComments)>[
            (assumed, GnItemComments.none),
          ], isList: false);
        }
        if (externalVariables.contains(name)) {
          // The engine's `.gni` variables that build files read are all
          // lists of flags.
          return _Expression(<(GnValue, GnItemComments)>[
            (GnReference(name), _comments(node)),
          ], isList: true);
        }
        throw GnError(node.location, 'unknown variable $name');
      case GnLiteral():
        return _Expression(<(GnValue, GnItemComments)>[
          (_literal(node, scope: scope), _comments(node)),
        ], isList: false);
      case GnFunctionCall(:final String name):
        throw GnError(node.location, '$name() in an expression is not supported by the converter');
      default:
        throw GnError(node.location, 'unsupported expression (${node.runtimeType})');
    }
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
    return _Expression(<(GnValue, GnItemComments)>[(value, GnItemComments.none)], isList: false);
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
      final String? value = _knownString(name, scope);
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
  String? _knownString(String name, _Scope? scope) {
    final GnVariable? variable = scope?.lookup(name);
    if (variable != null) {
      final List<GnValue>? items = variable.unconditionalItems;
      if (!variable.isList && items != null && items.length == 1 && items.single is GnStringValue) {
        return (items.single as GnStringValue).value;
      }
      return null;
    }
    final GnValue? assumed = assumptions[name];
    return assumed is GnStringValue ? assumed.value : null;
  }

  Condition _condition(GnNode node, _Scope scope) {
    switch (node) {
      case GnLiteral() when node.isBool:
        return ConditionConstant(node.boolValue);
      case GnIdentifier(:final String name):
        return _variableCondition(name, node.location, scope);
      case GnUnary(op: '!', :final GnNode operand):
        return _condition(operand, scope).negated;
      case GnBinary(op: '&&', :final GnNode left, :final GnNode right):
        return _condition(left, scope).and(_condition(right, scope));
      case GnBinary(op: '||', :final GnNode left, :final GnNode right):
        return _condition(left, scope).or(_condition(right, scope));
      case GnBinary(:final String op, :final GnNode left, :final GnNode right)
          when op == '==' || op == '!=':
        return _comparison(node, op == '==', left, right, scope);
      case GnFunctionCall(name: 'defined', :final List<GnNode> args):
        if (args.length != 1 || args.single is! GnIdentifier) {
          throw GnError(node.location, 'only defined(variable) is supported');
        }
        final String name = (args.single as GnIdentifier).name;
        return ConditionConstant(
          scope.lookup(name) != null ||
              assumptions[name] != null ||
              externalVariables.contains(name),
        );
      default:
        throw GnError(node.location, 'unsupported condition (${node.runtimeType})');
    }
  }

  Condition _variableCondition(String name, GnLocation location, _Scope scope) {
    final GnVariable? variable = scope.lookup(name);
    if (variable != null) {
      final List<GnValue>? items = variable.unconditionalItems;
      if (items == null || items.length != 1) {
        throw GnError(location, 'condition on $name, which is not a plain boolean');
      }
      return switch (items.single) {
        GnBoolValue(:final bool value) => ConditionConstant(value),
        GnConditionValue(:final Condition condition) => condition,
        _ => throw GnError(location, 'condition on $name, which is not a plain boolean'),
      };
    }
    final GnValue? assumed = assumptions[name];
    if (assumed != null) {
      if (assumed is! GnBoolValue) {
        throw GnError(location, '$name is assumed to be $assumed, not a boolean');
      }
      return ConditionConstant(assumed.value);
    }
    if (externalVariables.contains(name)) {
      return ConditionVariable(name);
    }
    throw GnError(location, 'unknown variable $name in condition');
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
    if (!externalVariables.contains(left.name)) {
      throw GnError(node.location, 'unknown variable ${left.name} in condition');
    }
    return ConditionComparison(left.name, equals, value);
  }
}
