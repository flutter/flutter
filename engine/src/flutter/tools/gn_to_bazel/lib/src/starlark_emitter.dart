// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Starlark generation: from the evaluated GN targets to a `BUILD.bazel`.
library;

import 'bazel_mapping.dart';
import 'gn_ast.dart';
import 'gn_eval.dart';

const String _licenseHeader = '''
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
''';

/// One item of a Bazel list attribute: a string or a Starlark identifier.
final class _Item {
  const _Item(this.text, {this.quoted = true, this.comment, this.before = const <String>[]});

  final String text;
  final bool quoted;

  /// A comment on the item's line (without `#`).
  final String? comment;

  /// Comment lines before the item (with their `#`).
  final List<String> before;

  String get starlark => quoted ? '"${text.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"' : text;
}

/// One element of a GN list variable as it reached the emitter.
final class _Element {
  const _Element(this.condition, this.value, this.assignment, this.comments);

  /// The condition the element is appended under.
  final Condition condition;
  final GnValue value;
  final GnAssignment assignment;

  /// The comments GN had around the element, with the assignment's own
  /// comments folded into the first element's `before`.
  final GnItemComments comments;

  /// A comment for the item's line: GN's suffix comment, and the condition
  /// the assumptions resolved.
  String? get note {
    final parts = <String>[
      for (final String suffix in comments.suffix) _uncomment(suffix),
      if (assignment.sourceConditions.isNotEmpty) assignment.sourceConditions.join(' && '),
    ];
    return parts.isEmpty ? null : parts.join('; ');
  }

  static String _uncomment(String comment) => comment.replaceFirst(RegExp(r'^#\s?'), '');
}

/// A list attribute: unconditional items, plus items per condition in the
/// order the conditions first appeared.
final class _ListAttribute {
  final List<_Item> always = <_Item>[];
  final Map<Condition, List<_Item>> conditional = <Condition, List<_Item>>{};

  /// Comment lines above the attribute (GN's comments on the `=` that
  /// defined the variable).
  final List<String> comments = <String>[];

  bool get isEmpty => always.isEmpty && conditional.isEmpty;

  void add(Condition condition, _Item item) {
    if (condition == Condition.always) {
      always.add(item);
    } else {
      conditional.putIfAbsent(condition, () => <_Item>[]).add(item);
    }
  }
}

/// A generated rule.
final class _Rule {
  _Rule(this.kind, this.name, this.comments);

  final String kind;
  final String name;
  final List<String> comments;
  final Map<String, _ListAttribute> lists = <String, _ListAttribute>{};
  final Map<String, String> scalars = <String, String>{};

  _ListAttribute list(String attribute) => lists.putIfAbsent(attribute, _ListAttribute.new);
}

/// Converts the targets of one GN file into the text of a `BUILD.bazel`.
///
/// [gnPackage] is the GN directory of the file (`//flutter/fml`). Targets
/// named in [skipTargets] are left out (with a note).
String emitBuildFile(
  GnFileEvaluation evaluation, {
  required String gnPackage,
  Set<String> skipTargets = const <String>{},
}) {
  final emitter = _Emitter(gnPackage);
  final skipped = <String>[];
  for (final GnTarget target in evaluation.targets) {
    if (skipTargets.contains(target.name)) {
      skipped.add(target.name);
      continue;
    }
    emitter.convert(target);
  }
  return emitter.render(evaluation.file, skipped);
}

final class _Emitter {
  _Emitter(this.gnPackage) : bazelPackage = bazelLabel(gnPackage, package: gnPackage);

  final String gnPackage;

  /// The Bazel package of the generated file (`//engine/src/flutter/fml`).
  final String bazelPackage;
  final List<_Rule> rules = <_Rule>[];

  /// `load()` statements: file label to the symbols used from it.
  final Map<String, Set<String>> loads = <String, Set<String>>{};

  void _use(String bzl, String symbol) {
    loads.putIfAbsent(bzl, () => <String>{}).add(symbol);
  }

  // -------------------------------------------------------------------------
  // Targets
  // -------------------------------------------------------------------------

  void convert(GnTarget target) {
    if (target.condition != Condition.always) {
      throw GnError(
        target.location,
        'target ${target.name} is defined under `${target.condition}`, which Bazel cannot express',
      );
    }
    final TemplateMapping? template = templateMappings[target.rule];
    if (template != null) {
      _convertTemplate(target, template);
      return;
    }
    switch (target.rule) {
      case 'source_set':
      case 'static_library':
        _convertCcTarget(target, 'cc_library', library: true);
      case 'executable':
        _convertCcTarget(target, _isTest(target) ? 'cc_test' : 'cc_binary', library: false);
      case 'config':
        _convertConfig(target);
      default:
        throw GnError(target.location, '${target.rule}() is not converted yet');
    }
  }

  static bool _isTest(GnTarget target) {
    final List<GnValue>? testonly = target.variables['testonly']?.unconditionalItems;
    final bool isTestonly =
        testonly != null && testonly.length == 1 && testonly.single == const GnBoolValue(true);
    return isTestonly && (target.name.endsWith('_unittests') || target.name.endsWith('_tests'));
  }

  void _convertTemplate(GnTarget target, TemplateMapping template) {
    _use(template.bzl, template.symbol);
    final rule = _Rule(template.symbol, target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'fixtures':
          _labelsInto(rule.list('fixtures'), variable, target);
        case 'testonly':
          _scalar(rule, 'testonly', variable);
        default:
          throw GnError(
            variable.assignments.first.location,
            '${target.rule}() argument ${variable.name} is not handled by the ${template.symbol} macro mapping',
          );
      }
    }
    rules.add(rule);
  }

  void _convertCcTarget(GnTarget target, String kind, {required bool library}) {
    _use('@rules_cc//cc:defs.bzl', kind);
    final rule = _Rule(kind, target.name, target.comments);
    if (kind == 'cc_test') {
      rule.scalars['size'] = '"${testSizes[target.name] ?? defaultTestSize}"';
    }
    var chromiumCode = true;
    final extraCopts = <_Item>[];
    final conditionalCopts = <Condition, List<_Item>>{};

    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'sources':
          _sourcesInto(rule, variable, target, library: library);
        case 'public':
          throw GnError(
            variable.assignments.first.location,
            '`public` header lists are not supported yet',
          );
        case 'deps':
          _labelsInto(rule.list(library ? 'implementation_deps' : 'deps'), variable, target);
        case 'public_deps':
          _labelsInto(rule.list('deps'), variable, target);
        case 'defines':
          _stringsInto(rule.list('local_defines'), variable);
        case 'include_dirs':
          _stringsInto(rule.list('includes'), variable);
        case 'configs':
        case 'public_configs':
          chromiumCode = _configsInto(rule, variable, target, chromiumCode: chromiumCode);
        case 'libs':
          _forEachItem(variable, into: rule.list('linkopts'), (_Element e) {
            final String lib = _string(e);
            if (lib.contains('/')) {
              throw GnError(e.assignment.location, 'library path $lib in libs is not supported');
            }
            rule.list('linkopts').add(e.condition, _item('-l$lib', e));
          });
        case 'frameworks':
          _forEachItem(variable, into: rule.list('linkopts'), (_Element e) {
            final String framework = _string(e).replaceFirst(RegExp(r'\.framework$'), '');
            rule.list('linkopts')
              ..add(e.condition, _item('-framework', e, note: false))
              ..add(e.condition, _Item(framework, comment: e.note));
          });
        case 'cflags':
        case 'cflags_c':
        case 'cflags_cc':
        case 'cflags_objc':
        case 'cflags_objcc':
          _forEachItem(variable, into: rule.list('copts'), (_Element e) {
            final _Item item = _flagItem(e);
            if (e.condition == Condition.always) {
              extraCopts.add(item);
            } else {
              conditionalCopts.putIfAbsent(e.condition, () => <_Item>[]).add(item);
            }
          });
        case 'ldflags':
          _stringsInto(rule.list('linkopts'), variable);
        case 'testonly':
          // cc_test is testonly by definition.
          if (kind != 'cc_test') {
            _scalar(rule, 'testonly', variable);
          }
        default:
          throw GnError(
            variable.assignments.first.location,
            'variable ${variable.name} is not converted yet',
          );
      }
    }

    // A header-only library compiles nothing, so its flags would only be
    // noise (GN ignores them just the same).
    final bool compiles = !(rule.lists['srcs']?.isEmpty ?? true);
    final bool hasFlags =
        extraCopts.isNotEmpty ||
        conditionalCopts.isNotEmpty ||
        !(rule.lists['local_defines']?.isEmpty ?? true);
    if (!compiles && hasFlags) {
      throw GnError(
        target.location,
        '${target.name} has flags or defines but no sources to apply them to',
      );
    }
    if (compiles) {
      // GN applies chromium_code (or no_chromium_code) to every target; the
      // Bazel toolchain carries the rest.
      final _ListAttribute copts = rule.list('copts');
      _use(
        '//engine/src/flutter/build/bazel:copts.bzl',
        chromiumCode ? 'FLUTTER_COPTS' : 'FLUTTER_THIRD_PARTY_COPTS',
      );
      copts.always.insert(
        0,
        _Item(chromiumCode ? 'FLUTTER_COPTS' : 'FLUTTER_THIRD_PARTY_COPTS', quoted: false),
      );
      copts.always.addAll(extraCopts);
      for (final MapEntry<Condition, List<_Item>> entry in conditionalCopts.entries) {
        copts.conditional.putIfAbsent(entry.key, () => <_Item>[]).addAll(entry.value);
      }
      if (chromiumCode) {
        _use('//engine/src/flutter/build/bazel:copts.bzl', 'FLUTTER_LOCAL_DEFINES');
        rule
            .list('local_defines')
            .always
            .insert(0, const _Item('FLUTTER_LOCAL_DEFINES', quoted: false));
      }
    } else if (!library) {
      throw GnError(target.location, '${target.name} has no sources');
    }
    rules.add(rule);
  }

  /// config("x") becomes a header-only library carrying the defines and
  /// include directories, which dependents list in deps.
  void _convertConfig(GnTarget target) {
    _use('@rules_cc//cc:defs.bzl', 'cc_library');
    final rule = _Rule('cc_library', target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'defines':
          _stringsInto(rule.list('defines'), variable);
        case 'include_dirs':
          _stringsInto(rule.list('includes'), variable);
        case 'visibility':
          // Local configs are only ever used by their own package.
          break;
        default:
          throw GnError(
            variable.assignments.first.location,
            'config variable ${variable.name} cannot be propagated by Bazel; convert it by hand',
          );
      }
    }
    rules.add(rule);
  }

  // -------------------------------------------------------------------------
  // Variables
  // -------------------------------------------------------------------------

  /// Calls [visit] for every item of a list variable with the condition it
  /// is appended under. Removals (`-=`) are only supported unconditionally.
  ///
  /// The comments on the `=` that defined the variable describe the whole
  /// list and go above [into], the attribute the items end up in; comments on
  /// a `+=` describe the addition and go with its first item.
  void _forEachItem(
    GnVariable variable,
    void Function(_Element) visit, {
    required _ListAttribute into,
  }) {
    final elements = <_Element>[];
    for (final GnAssignment assignment in variable.assignments) {
      switch (assignment.op) {
        case '=':
          if (assignment.isUnconditional) {
            elements.clear();
          }
          into.comments.addAll(assignment.comments);
          elements.addAll(_elements(assignment, withComments: false));
        case '+=':
          elements.addAll(_elements(assignment, withComments: true));
        case '-=':
          if (!assignment.isUnconditional) {
            throw GnError(assignment.location, 'conditional -= is not supported');
          }
          for (final GnValue value in assignment.items) {
            final int before = elements.length;
            elements.removeWhere((_Element e) => e.value == value);
            if (elements.length == before) {
              throw GnError(assignment.location, '-= of $value, which is not in ${variable.name}');
            }
          }
      }
    }
    elements.forEach(visit);
  }

  /// The elements of one assignment; with [withComments], the comment lines
  /// before the assignment itself go with its first element.
  static List<_Element> _elements(GnAssignment assignment, {required bool withComments}) {
    return <_Element>[
      for (var i = 0; i < assignment.items.length; i++)
        _Element(
          assignment.condition,
          assignment.items[i],
          assignment,
          i == 0 && withComments && assignment.comments.isNotEmpty
              ? GnItemComments(
                  before: <String>[...assignment.comments, ...assignment.commentsOf(i).before],
                  suffix: assignment.commentsOf(i).suffix,
                )
              : assignment.commentsOf(i),
        ),
    ];
  }

  static String _string(_Element element) {
    final GnValue value = element.value;
    if (value is! GnStringValue) {
      throw GnError(element.assignment.location, 'expected a string, got $value');
    }
    return value.value;
  }

  /// An item for [element] with its comments; [note] false leaves the line
  /// comment for a following item.
  static _Item _item(String text, _Element element, {bool quoted = true, bool note = true}) {
    return _Item(
      text,
      quoted: quoted,
      comment: note ? element.note : null,
      before: element.comments.before,
    );
  }

  _Item _flagItem(_Element element) {
    switch (element.value) {
      case GnStringValue(:final String value):
        return _item(value, element);
      case GnReference(:final String name):
        final String? constant = referenceConstants[name];
        if (constant == null) {
          throw GnError(element.assignment.location, 'no Bazel constant for $name');
        }
        _use('//engine/src/flutter/build/bazel:copts.bzl', constant);
        return _item(constant, element, quoted: false);
      default:
        throw GnError(element.assignment.location, 'unexpected flag value ${element.value}');
    }
  }

  void _stringsInto(_ListAttribute attribute, GnVariable variable) {
    _forEachItem(variable, into: attribute, (_Element e) {
      attribute.add(e.condition, _item(_string(e), e));
    });
  }

  void _labelsInto(_ListAttribute attribute, GnVariable variable, GnTarget target) {
    _forEachItem(variable, into: attribute, (_Element e) {
      final String label = bazelLabel(
        _string(e),
        package: gnPackage,
        location: e.assignment.location,
      );
      attribute.add(e.condition, _item(_localLabel(label), e));
    });
  }

  /// `//engine/src/flutter/fml:x` is `:x` from within its own package.
  String _localLabel(String label) {
    if (label == bazelPackage) {
      return ':${bazelPackage.substring(bazelPackage.lastIndexOf('/') + 1)}';
    }
    if (label.startsWith('$bazelPackage:')) {
      return label.substring(bazelPackage.length);
    }
    return label;
  }

  static const Set<String> _headerExtensions = <String>{'.h', '.hh', '.hpp', '.inc'};

  /// Libraries get their headers in `hdrs` (GN's default `public` is all
  /// of them); binaries and tests have no such attribute.
  void _sourcesInto(_Rule rule, GnVariable variable, GnTarget target, {required bool library}) {
    _forEachItem(variable, into: rule.list('srcs'), (_Element e) {
      final String path = _string(e);
      final int dot = path.lastIndexOf('.');
      final String extension = dot < 0 ? '' : path.substring(dot);
      final bool header = library && _headerExtensions.contains(extension);
      rule.list(header ? 'hdrs' : 'srcs').add(e.condition, _item(path, e));
    });
  }

  /// Applies `configs`/`public_configs`; returns whether the target is still
  /// chromium_code.
  bool _configsInto(
    _Rule rule,
    GnVariable variable,
    GnTarget target, {
    required bool chromiumCode,
  }) {
    var result = chromiumCode;
    for (final GnAssignment assignment in variable.assignments) {
      for (final _Element element in _elements(assignment, withComments: true)) {
        final String config = _string(element);
        final ConfigEffect? effect = config.startsWith(':')
            ? ConfigDependency(config)
            : configEffects[config] ?? configEffects['$gnPackage$config'];
        if (effect == null) {
          throw GnError(assignment.location, 'config $config has no Bazel mapping');
        }
        switch (effect) {
          case ConfigWarningSet(:final bool chromiumCode):
            if (!assignment.isUnconditional) {
              throw GnError(assignment.location, 'conditional warning set is not supported');
            }
            // `configs -= [chromium_code]` and `configs += [no_chromium_code]`
            // both mean the same thing.
            result = assignment.op == '-=' ? !chromiumCode : chromiumCode;
          case ConfigDependency(:final String label):
            if (assignment.op == '-=') {
              throw GnError(assignment.location, 'removing config $config is not supported');
            }
            rule.list('deps').add(assignment.condition, _item(label, element));
          case ConfigImplied():
            break;
        }
      }
    }
    return result;
  }

  void _scalar(_Rule rule, String attribute, GnVariable variable) {
    final List<GnValue>? items = variable.unconditionalItems;
    if (items == null || items.length != 1) {
      throw GnError(
        variable.assignments.first.location,
        '${variable.name} must be a single unconditional value',
      );
    }
    rule.scalars[attribute] = switch (items.single) {
      GnBoolValue(:final bool value) => value ? 'True' : 'False',
      GnIntValue(:final int value) => '$value',
      GnStringValue(:final String value) => '"$value"',
      final GnValue other => throw GnError(
        variable.assignments.first.location,
        'unsupported value $other',
      ),
    };
  }

  // -------------------------------------------------------------------------
  // Rendering
  // -------------------------------------------------------------------------

  String render(String gnFile, List<String> skipped) {
    final out = StringBuffer()
      ..write(_licenseHeader)
      ..writeln()
      ..writeln('# Generated from $gnPackage/BUILD.gn by gn_to_bazel; do not edit.');
    if (skipped.isNotEmpty) {
      out.writeln('# Not converted: ${skipped.join(', ')}.');
    }
    out.writeln();
    final List<String> loadFiles = loads.keys.toList()..sort(_compareLoads);
    for (final bzl in loadFiles) {
      final List<String> symbols = loads[bzl]!.toList()..sort();
      out.writeln('load("$bzl", ${symbols.map((String s) => '"$s"').join(', ')})');
    }
    out
      ..writeln()
      ..writeln('package(default_visibility = ["//visibility:public"])');
    for (final _Rule rule in rules) {
      out.writeln();
      _renderRule(out, rule);
    }
    return out.toString();
  }

  /// `@` loads first, as buildifier orders them.
  static int _compareLoads(String a, String b) {
    final bool externalA = a.startsWith('@');
    final bool externalB = b.startsWith('@');
    if (externalA != externalB) {
      return externalA ? -1 : 1;
    }
    return a.compareTo(b);
  }

  static const List<String> _leadingAttributes = <String>['name', 'size', 'srcs', 'hdrs'];

  void _renderRule(StringBuffer out, _Rule rule) {
    rule.comments.forEach(out.writeln);
    out.writeln('${rule.kind}(');
    out.writeln('    name = "${rule.name}",');
    final List<String> attributes = <String>{...rule.lists.keys, ...rule.scalars.keys}.toList()
      ..sort((String a, String b) {
        final int ia = _leadingAttributes.indexOf(a);
        final int ib = _leadingAttributes.indexOf(b);
        if (ia >= 0 || ib >= 0) {
          return (ia < 0 ? _leadingAttributes.length : ia).compareTo(
            ib < 0 ? _leadingAttributes.length : ib,
          );
        }
        if ((a == 'deps') != (b == 'deps')) {
          return a == 'deps' ? 1 : -1;
        }
        return a.compareTo(b);
      });
    for (final attribute in attributes) {
      final String? scalar = rule.scalars[attribute];
      if (scalar != null) {
        out.writeln('    $attribute = $scalar,');
        continue;
      }
      final _ListAttribute list = rule.lists[attribute]!;
      if (list.isEmpty) {
        continue;
      }
      for (final String comment in list.comments) {
        out.writeln('    $comment');
      }
      out.write('    $attribute = ');
      _renderList(out, list, rule, attribute);
      out.writeln(',');
    }
    out.writeln(')');
  }

  /// Attributes whose order carries no meaning; the emitter sorts them the
  /// way buildifier would, so that GN's order and comments (which buildifier
  /// does not sort across) do not leak into the result.
  static const Set<String> _sortedAttributes = <String>{
    'srcs',
    'hdrs',
    'deps',
    'implementation_deps',
    'fixtures',
  };

  void _renderList(StringBuffer out, _ListAttribute list, _Rule rule, String attribute) {
    final bool sorted = _sortedAttributes.contains(attribute);
    final parts = <String>[];
    // A bare constant (FLUTTER_COPTS, FLUTTER_LOCAL_DEFINES) leads as itself.
    final always = List<_Item>.of(list.always);
    if (always.isNotEmpty && !always.first.quoted && always.first.comment == null) {
      parts.add(always.removeAt(0).text);
    }
    if (always.isNotEmpty || parts.isEmpty && list.conditional.isEmpty) {
      parts.add(_renderItems(sorted ? _sortItems(always) : always, indent: 4));
    }
    for (final MapEntry<Condition, List<_Item>> entry in list.conditional.entries) {
      parts.add(_renderSelect(entry.key, sorted ? _sortItems(entry.value) : entry.value, rule));
    }
    out.write(parts.join(' + '));
  }

  /// buildifier's order for string lists: plain names, then `:local`, then
  /// `//absolute`, then `@external`; within a group, the strings compared
  /// piecewise after splitting on `.` and `:`.
  static List<_Item> _sortItems(List<_Item> items) {
    int phase(_Item item) {
      if (!item.quoted) {
        return -1;
      }
      if (item.text.startsWith(':')) {
        return 1;
      }
      if (item.text.startsWith('//')) {
        return 2;
      }
      if (item.text.startsWith('@')) {
        return 3;
      }
      return 0;
    }

    List<String> split(_Item item) => item.text.replaceAll(':', '.').split('.');

    return List<_Item>.of(items)..sort((_Item a, _Item b) {
      final int byPhase = phase(a).compareTo(phase(b));
      if (byPhase != 0) {
        return byPhase;
      }
      final List<String> sa = split(a);
      final List<String> sb = split(b);
      for (var i = 0; i < sa.length && i < sb.length; i++) {
        final int c = sa[i].compareTo(sb[i]);
        if (c != 0) {
          return c;
        }
      }
      if (sa.length != sb.length) {
        return sa.length.compareTo(sb.length);
      }
      return a.text.compareTo(b.text);
    });
  }

  static String _renderItems(List<_Item> items, {required int indent}) {
    if (items.isEmpty) {
      return '[]';
    }
    if (items.length == 1 && items.single.comment == null && items.single.before.isEmpty) {
      return '[${items.single.starlark}]';
    }
    final String pad = ' ' * (indent + 4);
    final out = StringBuffer('[\n');
    for (final item in items) {
      for (final String comment in item.before) {
        out.writeln('$pad$comment');
      }
      out.write('$pad${item.starlark},');
      if (item.comment != null) {
        out.write('  # ${item.comment}');
      }
      out.writeln();
    }
    out.write('${' ' * indent}]');
    return out.toString();
  }

  /// `select()` for the items appended under [condition].
  String _renderSelect(Condition condition, List<_Item> items, _Rule rule) {
    final settings = <String>[];
    var negated = false;
    switch (condition) {
      case ConditionVariable():
        settings.add(_setting(condition, rule));
      case ConditionNot(operand: final ConditionVariable operand):
        settings.add(_setting(operand, rule));
        negated = true;
      case ConditionOr(:final List<Condition> terms)
          when terms.every((Condition t) => t is ConditionVariable):
        settings.addAll(terms.map((Condition t) => _setting(t as ConditionVariable, rule)));
      default:
        throw GnError(
          GnLocation('$gnPackage/BUILD.gn', 0, 0),
          'condition `$condition` on ${rule.kind} ${rule.name} cannot be expressed as a select()',
        );
    }
    final String branch = _renderItems(items, indent: 8);
    final out = StringBuffer('select({\n');
    for (final setting in settings) {
      out.writeln('        "$setting": ${negated ? '[]' : branch},');
    }
    out.writeln('        "//conditions:default": ${negated ? branch : '[]'},');
    out.write('    })');
    return out.toString();
  }

  String _setting(ConditionVariable variable, _Rule rule) {
    final String? setting = conditionSettings[variable.name];
    if (setting == null) {
      throw GnError(
        GnLocation('$gnPackage/BUILD.gn', 0, 0),
        'no config_setting for `${variable.name}` (used by ${rule.kind} ${rule.name})',
      );
    }
    return setting;
  }
}
