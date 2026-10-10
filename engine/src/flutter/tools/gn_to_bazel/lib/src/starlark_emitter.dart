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
  /// the assumptions resolved (`defined()` tests, which templates use to
  /// forward optional variables, say nothing and are left out).
  String? get note {
    final List<String> conditions = assignment.sourceConditions
        .where((String c) => !c.startsWith('defined(') && !c.startsWith('!(defined('))
        .toList();
    final parts = <String>[
      for (final String suffix in comments.suffix) _uncomment(suffix),
      if (conditions.isNotEmpty) conditions.join(' && '),
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

  /// Adds [item] unless the same text is already there under [condition]
  /// (two GN labels can translate to one Bazel label, which Bazel rejects as
  /// a duplicate).
  void addUnique(Condition condition, _Item item) {
    final List<_Item> bucket = condition == Condition.always
        ? always
        : conditional.putIfAbsent(condition, () => <_Item>[]);
    if (bucket.any((_Item existing) => existing.text == item.text)) {
      return;
    }
    bucket.add(item);
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
/// named in [skipTargets] are left out (with a note), as are the ones the
/// evaluation already skipped. [appendix] is Starlark to append verbatim:
/// what the GN file has no way to say (an `exports_files`, say). [layout]
/// says where the file lives, which decides how file paths are written.
/// [implicitDeps] are labels every target that compiles depends on (see
/// the manifest).
String emitBuildFile(
  GnFileEvaluation evaluation, {
  required String gnPackage,
  Set<String> skipTargets = const <String>{},
  String? appendix,
  OutputLayout layout = const OutputLayout.main(),
  List<String> implicitDeps = const <String>[],
}) {
  final emitter = _Emitter(gnPackage, layout, implicitDeps);
  for (final GnTarget target in evaluation.targets) {
    if (target.rule == 'config') {
      emitter.localConfigs[target.name] = target;
      continue;
    }
    for (final name in <String>['configs', 'public_configs', 'all_dependent_configs']) {
      for (final GnAssignment a in target.variables[name]?.assignments ?? const <GnAssignment>[]) {
        for (final GnValue v in a.items) {
          if (v is GnStringValue && v.value.startsWith(':')) {
            emitter.locallyUsedConfigs.add(v.value.substring(1));
          }
        }
      }
    }
  }
  final skipped = <String>[...evaluation.skipped];
  for (final GnTarget target in evaluation.targets) {
    if (skipTargets.contains(target.name)) {
      skipped.add(target.name);
      continue;
    }
    emitter.convert(target);
  }
  return emitter.render(evaluation.file, skipped, appendix: appendix);
}

/// Target variables that say nothing Bazel needs.
const Set<String> _ignoredVariables = <String>{'check_includes', 'visibility'};

final class _Emitter {
  _Emitter(this.gnPackage, this.layout, this.implicitDeps)
    : package = BazelLabel.parse(bazelLabel(gnPackage, package: gnPackage));

  final String gnPackage;
  final OutputLayout layout;

  /// Labels every compiled target depends on (the manifest's implicitDeps).
  final List<String> implicitDeps;

  /// The Bazel package of the generated file (`//engine/src/flutter/fml`,
  /// or `@skia//` for a repository root).
  final BazelLabel package;
  final List<_Rule> rules = <_Rule>[];

  /// The `config()` targets of the file, by name, for inlining.
  final Map<String, GnTarget> localConfigs = <String, GnTarget>{};

  /// The local configs some target of the file lists (whose compiler flags
  /// are therefore inlined there).
  final Set<String> locallyUsedConfigs = <String>{};

  /// `load()` statements: file label to the symbols used from it.
  final Map<String, Set<String>> loads = <String, Set<String>>{};

  void _use(String bzl, String symbol) {
    loads.putIfAbsent(_absoluteLabel(bzl), () => <String>{}).add(symbol);
  }

  /// [label] as written from the generated file without shortening: a
  /// main-repository label (`//engine/src/...`) is qualified with the main
  /// repository's name when the file lives in an external repository.
  String _absoluteLabel(String label) {
    if (layout.isMain || !label.startsWith('//')) {
      return label;
    }
    return '$mainRepositoryName$label';
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

  /// The engine's test executables are testonly and named `*tests`
  /// (`fml_unittests`, `display_list_rendertests`); testonly benchmarks and
  /// tools stay binaries.
  static bool _isTest(GnTarget target) {
    final List<GnValue>? testonly = target.variables['testonly']?.unconditionalItems;
    final bool isTestonly =
        testonly != null && testonly.length == 1 && testonly.single == const GnBoolValue(true);
    return isTestonly && target.name.endsWith('tests');
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
    // With an explicit `public` list the headers in `sources` are private.
    final bool explicitPublic = target.variables.containsKey('public');
    // Configs that reach dependents anyway are not inlined privately as well.
    final publicConfigs = <String>{
      for (final String name in <String>['public_configs', 'all_dependent_configs'])
        for (final GnAssignment a in target.variables[name]?.assignments ?? const <GnAssignment>[])
          for (final GnValue v in a.items)
            if (v is GnStringValue) v.value,
    };

    // Two passes: the target's own variables, then its configs, so that a
    // config's flags follow the target's own as they do in GN.
    final configVariables = <GnVariable>[];
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'sources':
          _sourcesInto(rule, variable, target, splitHeaders: library && !explicitPublic);
        case 'public':
          _filesInto(rule.list('hdrs'), variable);
        case 'deps':
          _labelsInto(rule.list(library ? 'implementation_deps' : 'deps'), variable, target);
          _propagatedFlagsInto(rule, variable);
        case 'public_deps':
          _labelsInto(rule.list('deps'), variable, target);
          _propagatedFlagsInto(rule, variable);
        case 'defines':
          _stringsInto(rule.list('local_defines'), variable);
        case 'include_dirs':
          _filesInto(rule.list('includes'), variable);
        case 'configs':
        case 'public_configs':
        case 'all_dependent_configs':
          configVariables.add(variable);
        case 'libs':
        case 'frameworks':
        case 'ldflags':
          _linkFlagsInto(rule, variable);
        case 'cflags':
        case 'cflags_c':
        case 'cflags_cc':
        case 'cflags_objc':
        case 'cflags_objcc':
          _compilerFlagsInto(rule, variable, Condition.always);
        case 'testonly':
          // cc_test is testonly by definition.
          if (kind != 'cc_test') {
            _scalar(rule, 'testonly', variable);
          }
        case 'lib_dirs':
          _requireEmpty(variable);
        default:
          if (_ignoredVariables.contains(variable.name) || variable.forwarded) {
            // A template forwards its invoker's bookkeeping (`enabled`, ...)
            // along with the real variables; GN ignores it just the same.
            break;
          }
          throw GnError(
            variable.assignments.first.location,
            'variable ${variable.name} is not converted yet',
          );
      }
    }
    final propagated = <String>[];
    for (final variable in configVariables) {
      chromiumCode = _configsInto(
        rule,
        variable,
        target,
        chromiumCode: chromiumCode,
        publicConfigs: publicConfigs,
        propagatedFlags: propagated,
      );
    }
    _checkPropagatedFlags(target, propagated);

    // A header-only library compiles nothing, so its flags would only be
    // noise (GN ignores them just the same).
    final bool compiles = !(rule.lists['srcs']?.isEmpty ?? true);
    final bool hasFlags =
        !(rule.lists['copts']?.isEmpty ?? true) ||
        !(rule.lists['conlyopts']?.isEmpty ?? true) ||
        !(rule.lists['cxxopts']?.isEmpty ?? true) ||
        target.variables.containsKey('defines') &&
            !(target.variables['defines']!.unconditionalItems?.isEmpty ?? false);
    if (!compiles && hasFlags) {
      throw GnError(
        target.location,
        '${target.name} has flags or defines but no sources to apply them to',
      );
    }
    if (!compiles) {
      // What private configs brought has nothing to apply to.
      rule.lists.remove('local_defines');
    }
    if (compiles) {
      // GN applies chromium_code (or no_chromium_code) to every target; the
      // Bazel toolchain carries the rest.
      _use(
        '//engine/src/flutter/build/bazel:copts.bzl',
        chromiumCode ? 'FLUTTER_COPTS' : 'FLUTTER_THIRD_PARTY_COPTS',
      );
      rule
          .list('copts')
          .always
          .insert(
            0,
            _Item(chromiumCode ? 'FLUTTER_COPTS' : 'FLUTTER_THIRD_PARTY_COPTS', quoted: false),
          );
      if (chromiumCode) {
        _use('//engine/src/flutter/build/bazel:copts.bzl', 'FLUTTER_LOCAL_DEFINES');
        rule
            .list('local_defines')
            .always
            .insert(0, const _Item('FLUTTER_LOCAL_DEFINES', quoted: false));
      }
      // GN links every object of a source_set into the dependent binary,
      // whereas a static_library is an archive the linker picks from. Code
      // that registers itself from static initializers (gtest suites in a
      // helper source_set, for one) relies on the former.
      if (target.rule == 'source_set') {
        rule.scalars['alwayslink'] = 'True';
      }
      // What GN leaves implicit (the headers of the tree, say) is a public
      // dependency, so that dependents outside the file see it too.
      for (final String dep in implicitDeps) {
        rule.list('deps').addUnique(Condition.always, _Item(_localLabel(dep)));
      }
    }
    rules.add(rule);
  }

  /// `cflags*` of a target or a config into the rule's flag attributes,
  /// under [condition] on top of each item's own.
  void _compilerFlagsInto(_Rule rule, GnVariable variable, Condition condition) {
    final String attribute = switch (variable.name) {
      'cflags_c' => 'conlyopts',
      'cflags_cc' => 'cxxopts',
      _ => 'copts',
    };
    _forEachItem(variable, into: rule.list(attribute), (_Element e) {
      final _Item item = _flagItem(e);
      // GN's compiler config fixes the language standard in its own
      // cflags_c/cflags_cc, which follow every target's flags, so a
      // target's -std= never takes effect there (skcms asks for C11 and
      // compiles C++20). Bazel's copts come last and would win.
      if (item.quoted && item.text.startsWith('-std=')) {
        return;
      }
      rule.list(attribute).add(condition.and(e.condition), item);
    });
  }

  /// The flags a dependency hands its dependents through a public config
  /// ([propagatedCopts]), added to the rule that lists the dependency.
  void _propagatedFlagsInto(_Rule rule, GnVariable variable) {
    _forEachItem(variable, into: _ListAttribute(), (_Element e) {
      final List<String>? flags = propagatedCopts[_gnLabel(_string(e))];
      if (flags == null) {
        return;
      }
      for (final String flag in flags) {
        rule.list('copts').addUnique(e.condition, _Item(flag, comment: 'from ${_string(e)}'));
      }
    });
  }

  /// A target whose public configs carry compiler flags must be listed in
  /// [propagatedCopts] with exactly those flags, since that table is how
  /// its dependents get them.
  void _checkPropagatedFlags(GnTarget target, List<String> propagated) {
    final label = '$gnPackage:${target.name}';
    final Set<String> expected = propagatedCopts[label]?.toSet() ?? const <String>{};
    final Set<String> actual = propagated.toSet();
    if (expected.length != actual.length || !expected.containsAll(actual)) {
      throw GnError(
        target.location,
        actual.isEmpty
            ? '$label is in propagatedCopts but its public configs carry no compiler flags'
            : 'the public configs of $label carry compiler flags ${actual.toList()}, which Bazel '
                  'cannot hand to its dependents; list them under $label in propagatedCopts '
                  '(bazel_mapping.dart)${expected.isEmpty ? '' : ', which has ${expected.toList()}'}',
      );
    }
  }

  /// A GN label as written in this file, as `//dir:name`.
  String _gnLabel(String value) {
    var label = value.startsWith(':')
        ? '$gnPackage$value'
        : value.startsWith('//')
        ? value
        : '$gnPackage/$value';
    if (!label.contains(':')) {
      label = '$label:${label.substring(label.lastIndexOf('/') + 1)}';
    }
    return label;
  }

  /// config("x") becomes a header-only library carrying the defines, include
  /// directories and link flags, which dependents list in deps; Bazel
  /// propagates those the way GN propagates a config. Compiler flags cannot
  /// travel that way: a target of this file that lists the config gets them
  /// inlined (and, for a public config, must be in [propagatedCopts] for
  /// its dependents); a config with flags that no target here lists is
  /// refused.
  void _convertConfig(GnTarget target) {
    _use('@rules_cc//cc:defs.bzl', 'cc_library');
    final rule = _Rule('cc_library', target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'defines':
          _stringsInto(rule.list('defines'), variable);
        case 'include_dirs':
          _filesInto(rule.list('includes'), variable);
        case 'libs':
        case 'frameworks':
        case 'ldflags':
          _linkFlagsInto(rule, variable);
        case 'visibility':
          // Local configs are only ever used by their own package.
          break;
        case 'cflags' || 'cflags_c' || 'cflags_cc' || 'cflags_objc' || 'cflags_objcc'
            when locallyUsedConfigs.contains(target.name):
          // Carried by the targets of this file that list the config.
          break;
        default:
          if (variable.forwarded) {
            break;
          }
          // `cflags_objcc = []`, `lib_dirs = []`: nothing to propagate.
          _requireEmpty(
            variable,
            why:
                'config variable ${variable.name} cannot be propagated by Bazel; convert it by hand',
          );
      }
    }
    rules.add(rule);
  }

  static const Set<String> _flagVariables = <String>{
    'cflags',
    'cflags_c',
    'cflags_cc',
    'cflags_objc',
    'cflags_objcc',
  };

  /// Copies a private config of this file into [rule] (see [_configsInto]).
  /// [use] is the assignment that listed the config; its condition applies
  /// on top of the config's own. With [flagsOnly], only the compiler flags
  /// (what a public config cannot carry as a dependency).
  void _inlineConfig(_Rule rule, GnTarget config, GnAssignment use, {bool flagsOnly = false}) {
    for (final GnVariable variable in config.variables.values) {
      if (_flagVariables.contains(variable.name)) {
        _compilerFlagsInto(rule, variable, use.condition);
        continue;
      }
      if (flagsOnly) {
        continue;
      }
      final String attribute;
      switch (variable.name) {
        case 'defines':
          attribute = 'local_defines';
        case 'include_dirs':
          attribute = 'includes';
        case 'ldflags':
          attribute = 'linkopts';
        case 'visibility':
          continue;
        default:
          if (variable.forwarded) {
            continue;
          }
          _requireEmpty(
            variable,
            why:
                'config variable ${variable.name} of ${config.name} cannot be applied to '
                '${rule.name} by Bazel; convert it by hand',
          );
          continue;
      }
      _forEachItem(variable, into: rule.list(attribute), (_Element e) {
        final String text = attribute == 'includes'
            ? _filePath(_string(e), e.assignment.location)
            : _string(e);
        final item = _Item(text, comment: e.note, before: <String>[...e.comments.before]);
        rule.list(attribute).addUnique(use.condition.and(e.condition), item);
      });
    }
  }

  /// Accepts a variable only while it holds nothing.
  void _requireEmpty(GnVariable variable, {String? why}) {
    final List<GnValue>? items = variable.unconditionalItems;
    if (items == null || items.isNotEmpty) {
      throw GnError(
        variable.assignments.first.location,
        why ?? 'variable ${variable.name} is not converted yet',
      );
    }
  }

  /// `libs`, `frameworks` and `ldflags` all become `linkopts`.
  void _linkFlagsInto(_Rule rule, GnVariable variable) {
    final _ListAttribute linkopts = rule.list('linkopts');
    switch (variable.name) {
      case 'libs':
        _forEachItem(variable, into: linkopts, (_Element e) {
          final String lib = _string(e);
          if (lib.contains('/')) {
            throw GnError(e.assignment.location, 'library path $lib in libs is not supported');
          }
          linkopts.add(e.condition, _item('-l$lib', e));
        });
      case 'frameworks':
        _forEachItem(variable, into: linkopts, (_Element e) {
          final String framework = _string(e).replaceFirst(RegExp(r'\.framework$'), '');
          linkopts
            ..add(e.condition, _item('-framework', e, note: false))
            ..add(e.condition, _Item(framework, comment: e.note));
        });
      case 'ldflags':
        _stringsInto(linkopts, variable);
    }
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
      attribute.addUnique(e.condition, _item(_localLabel(label), e));
    });
  }

  /// The shortest way to write [label] from the generated file: `:x` within
  /// its package, `//pkg:x` within its repository. An absolute label's `//`
  /// is the main repository, as everywhere in the mapping tables.
  String _localLabel(String label) {
    final parsed = label.startsWith(':')
        ? BazelLabel(package.repository, package.package, label.substring(1))
        : BazelLabel.parse(label);
    return parsed.relativeTo(repository: package.repository, package: package.package);
  }

  /// How a GN file path (a source, header or include directory) is written
  /// in the generated file: relative to the package when the package owns
  /// it, as a `//pkg:file` label when another package of the repository
  /// does. A path outside the output repository is an error: the GN file
  /// then names something Bazel cannot see from here.
  String _filePath(String gnFilePath, GnLocation location) {
    final String absolute = gnFilePath.startsWith('//')
        ? gnFilePath
        : gnFilePath == '.'
        ? gnPackage
        : '$gnPackage/$gnFilePath';
    final String? relative = layout.relativePath(absolute);
    if (relative == null) {
      throw GnError(
        location,
        '$gnFilePath is outside the output repository '
        '${layout.repository.isEmpty ? '' : layout.repository} (root ${layout.repositoryGnRoot})',
      );
    }
    final String owner = layout.isMain ? package.package : layout.owningPackage(relative);
    final ownerPrefix = owner.isEmpty ? '' : '$owner/';
    if (owner == package.package) {
      if (relative == owner) {
        return '.';
      }
      if (!relative.startsWith(ownerPrefix)) {
        throw GnError(location, '$gnFilePath is outside the package of the generated file');
      }
      return relative.substring(ownerPrefix.length);
    }
    final String rest = relative == owner ? '' : relative.substring(ownerPrefix.length);
    return '//$owner:$rest';
  }

  void _filesInto(_ListAttribute attribute, GnVariable variable) {
    _forEachItem(variable, into: attribute, (_Element e) {
      attribute.addUnique(e.condition, _item(_filePath(_string(e), e.assignment.location), e));
    });
  }

  static const Set<String> _headerExtensions = <String>{'.h', '.hh', '.hpp', '.inc'};

  /// Libraries without an explicit `public` list get their headers in
  /// `hdrs` (GN's default `public` is all of them); otherwise, and for
  /// binaries and tests, everything is a source. A file listed twice (Skia's
  /// generated lists repeat shared headers) is kept once, as Bazel insists.
  void _sourcesInto(
    _Rule rule,
    GnVariable variable,
    GnTarget target, {
    required bool splitHeaders,
  }) {
    _forEachItem(variable, into: rule.list('srcs'), (_Element e) {
      final String path = _string(e);
      final int dot = path.lastIndexOf('.');
      final String extension = dot < 0 ? '' : path.substring(dot);
      final bool header = splitHeaders && _headerExtensions.contains(extension);
      rule
          .list(header ? 'hdrs' : 'srcs')
          .addUnique(e.condition, _item(_filePath(path, e.assignment.location), e));
    });
  }

  /// Applies `configs`, `public_configs` or `all_dependent_configs`;
  /// returns whether the target is still chromium_code.
  ///
  /// A public config becomes a dependency on the header-only library that
  /// stands for it, so that its defines and include directories reach
  /// dependents as GN propagates them; its compiler flags, which cannot,
  /// are inlined into the target itself (GN applies a target's public
  /// configs to it) and noted in [propagatedFlags] for the dependents'
  /// side. A private config of the same file is inlined instead: its
  /// defines become `local_defines` (a dependency's `defines` would leak to
  /// dependents, which GN's private configs never do), its include
  /// directories `includes`, its link flags `linkopts`, its compiler flags
  /// `copts`.
  bool _configsInto(
    _Rule rule,
    GnVariable variable,
    GnTarget target, {
    required bool chromiumCode,
    required Set<String> publicConfigs,
    required List<String> propagatedFlags,
  }) {
    var result = chromiumCode;
    final private = variable.name == 'configs';
    for (final GnAssignment assignment in variable.assignments) {
      for (final _Element element in _elements(assignment, withComments: true)) {
        final String config = _string(element);
        final GnTarget? local = config.startsWith(':') ? localConfigs[config.substring(1)] : null;
        if (local != null && private) {
          if (publicConfigs.contains(config)) {
            // The public listing of the same config does everything.
            continue;
          }
          if (assignment.op == '-=') {
            throw GnError(assignment.location, 'removing config $config is not supported');
          }
          _inlineConfig(rule, local, assignment);
          continue;
        }
        if (local != null) {
          _inlineConfig(rule, local, assignment, flagsOnly: true);
          for (final GnVariable v in local.variables.values) {
            if (_flagVariables.contains(v.name)) {
              for (final GnValue flag in v.unconditionalItems ?? const <GnValue>[]) {
                if (flag is GnStringValue && !flag.value.startsWith('-std=')) {
                  propagatedFlags.add(flag.value);
                }
              }
            }
          }
        }
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
            rule.list('deps').addUnique(assignment.condition, _item(label, element));
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

  String render(String gnFile, List<String> skipped, {String? appendix}) {
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
    if (appendix != null) {
      out
        ..writeln()
        ..writeln("# What GN has no words for; maintained in the converter's manifest")
        ..writeln('# (tools/gn_to_bazel/lib/src/manifest.dart).')
        ..writeln()
        ..write(appendix.trim())
        ..writeln();
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

  static const List<String> _leadingAttributes = <String>[
    'name',
    'size',
    'testonly',
    'srcs',
    'hdrs',
  ];
  static const List<String> _trailingAttributes = <String>['deps', 'alwayslink'];

  static int _attributeRank(String attribute) {
    final int leading = _leadingAttributes.indexOf(attribute);
    if (leading >= 0) {
      return leading;
    }
    final int trailing = _trailingAttributes.indexOf(attribute);
    if (trailing >= 0) {
      return _leadingAttributes.length + 1 + trailing;
    }
    return _leadingAttributes.length;
  }

  void _renderRule(StringBuffer out, _Rule rule) {
    rule.comments.forEach(out.writeln);
    out.writeln('${rule.kind}(');
    out.writeln('    name = "${rule.name}",');
    final List<String> attributes = <String>{...rule.lists.keys, ...rule.scalars.keys}.toList()
      ..sort((String a, String b) {
        final int byRank = _attributeRank(a).compareTo(_attributeRank(b));
        return byRank != 0 ? byRank : a.compareTo(b);
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
      case ConditionComparison(equals: true):
        settings.add(_setting(condition, rule));
      case ConditionComparison(equals: false):
        settings.add(_setting(condition.negated, rule));
        negated = true;
      case ConditionNot(:final Condition operand):
        settings.add(_setting(operand, rule));
        negated = true;
      case ConditionOr(:final List<Condition> terms):
        settings.addAll(terms.map((Condition t) => _setting(t, rule)));
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

  /// The config_setting that is true exactly when [condition] (a variable or
  /// an equality) holds.
  String _setting(Condition condition, _Rule rule) {
    final String? setting = switch (condition) {
      ConditionVariable(:final String name) => conditionSettings[name],
      ConditionComparison(:final String name, equals: true, :final String value) =>
        comparisonSettings[name]?[value],
      _ => null,
    };
    if (setting == null) {
      throw GnError(
        GnLocation('$gnPackage/BUILD.gn', 0, 0),
        'no config_setting for `$condition` (used by ${rule.kind} ${rule.name})',
      );
    }
    return _absoluteLabel(setting);
  }
}
