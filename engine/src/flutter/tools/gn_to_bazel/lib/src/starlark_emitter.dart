// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Starlark generation: from the evaluated GN targets to a `BUILD.bazel`.
library;

import 'dart:io';

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

/// The config_settings a condition keys a `select()` with, and whether the
/// branch goes under them (`is_win`, `is_mac || is_ios`) or under the default
/// with those keys empty (`!is_win`, `!is_win && !is_mac`).
final class _SelectKeys {
  const _SelectKeys(this.settings, {required this.negated});

  final List<String> settings;
  final bool negated;
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
  _Rule(this.kind, this.name, List<String> comments) : comments = List<String>.of(comments);

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
  GnSourceTree? tree,
}) {
  final emitter = _Emitter(gnPackage, layout, implicitDeps, tree)
    ..inheritedConfigs.addAll(evaluation.allDependentConfigs)
    ..conditionalInheritance.addAll(evaluation.conditionalAllDependentConfigs);
  for (final GnTarget target in evaluation.targets) {
    emitter.localTargets[target.name] = target;
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
const Set<String> _ignoredVariables = <String>{'check_includes', 'metadata', 'visibility'};

final class _Emitter {
  _Emitter(this.gnPackage, this.layout, this.implicitDeps, this.tree)
    : package = BazelLabel.parse(bazelLabel(gnPackage, package: gnPackage));

  final String gnPackage;
  final OutputLayout layout;

  /// The source tree, when available: tells a rebased directory from a
  /// rebased file in an action's arguments.
  final GnSourceTree? tree;

  /// Labels every compiled target depends on (the manifest's implicitDeps).
  final List<String> implicitDeps;

  /// The Bazel package of the generated file (`//engine/src/flutter/fml`,
  /// or `@skia//` for a repository root).
  final BazelLabel package;
  final List<_Rule> rules = <_Rule>[];

  /// The `config()` targets of the file, by name, for inlining.
  final Map<String, GnTarget> localConfigs = <String, GnTarget>{};

  /// Every target of the file, by name.
  final Map<String, GnTarget> localTargets = <String, GnTarget>{};

  /// The local configs some target of the file lists (whose compiler flags
  /// are therefore inlined there).
  final Set<String> locallyUsedConfigs = <String>{};

  /// Per target, the configs it inherits through `all_dependent_configs`
  /// (its own and its dependencies', see
  /// [GnFileEvaluation.allDependentConfigs]), and the targets whose
  /// inheritance is conditional, which the emitter refuses.
  final Map<String, Set<String>> inheritedConfigs = <String, Set<String>>{};
  final Set<String> conditionalInheritance = <String>{};

  /// `load()` statements: file label to the symbols used from it.
  final Map<String, Set<String>> loads = <String, Set<String>>{};

  void _use(String bzl, String symbol) {
    loads.putIfAbsent(_absoluteLabel(bzl), () => <String>{}).add(symbol);
  }

  /// The `lib<name>.so` files the file's shared libraries produce.
  final Set<String> _sharedLibraryOutputs = <String>{};

  /// Registers the `load("file", "symbol", ...)` lines at the top of
  /// [appendix] as the file's own and returns the appendix without them.
  String _takeLoads(String appendix) {
    final List<String> lines = appendix.trim().split('\n');
    var first = 0;
    while (first < lines.length) {
      final String line = lines[first].trim();
      if (line.isEmpty) {
        first++;
        continue;
      }
      final RegExpMatch? load = _loadStatement.firstMatch(line);
      if (load == null) {
        break;
      }
      for (final RegExpMatch symbol in _quotedString.allMatches(load.group(2)!)) {
        _use(load.group(1)!, symbol.group(1)!);
      }
      first++;
    }
    return lines.sublist(first).join('\n');
  }

  static final RegExp _loadStatement = RegExp(r'^load\("([^"]+)"((?:,\s*"[^"]+")+)\)$');
  static final RegExp _quotedString = RegExp(r'"([^"]+)"');

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
      case 'shared_library':
        _convertCcTarget(target, 'cc_binary', library: false, shared: true);
      case 'config':
        _convertConfig(target);
      case 'group':
        _convertGroup(target);
      case 'action':
        _convertAction(target);
      case 'copy':
        _convertCopy(target);
      default:
        throw GnError(target.location, '${target.rule}() is not converted yet');
    }
  }

  /// group("x") forwards its dependencies: a `cc_library` with only `deps`.
  /// With nothing to compile it cannot keep a private dependency private
  /// (Bazel's implementation_deps need sources), so `deps` and
  /// `public_deps` both become `deps`, which is what GN does for linking.
  void _convertGroup(GnTarget target) {
    _use('@rules_cc//cc:defs.bzl', 'cc_library');
    final rule = _Rule('cc_library', target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'deps':
        case 'public_deps':
          _depsInto(rule, variable, target);
        case 'testonly':
          _scalar(rule, 'testonly', variable);
        case 'public_configs':
        case 'all_dependent_configs':
          _configsInto(
            rule,
            variable,
            target,
            chromiumCode: true,
            publicConfigs: const <String>{},
            propagatedFlags: <String>[],
          );
        default:
          if (_ignoredVariables.contains(variable.name) || variable.forwarded) {
            break;
          }
          throw GnError(
            variable.assignments.first.location,
            'variable ${variable.name} of group ${target.name} is not converted yet',
          );
      }
    }
    for (final String config in inheritedConfigs[target.name] ?? const <String>{}) {
      rule.list('deps').addUnique(Condition.always, _Item(_localLabel(config)));
    }
    rules.add(rule);
  }

  /// action("x") becomes a `gn_action` (build/bazel/gn_action): the script
  /// runs once with GN's arguments, in which `rebase_path(f, root_build_dir)`
  /// results become the rule's path tokens -- `$(execpath label)` for a
  /// source file, `$(src dir)` for a source directory, `$(gen path)` for
  /// anything under `$target_gen_dir`. Outputs are declared relative to the
  /// package, which is where GN's `$target_gen_dir` puts them. A file the
  /// arguments name that GN never declared as an input is declared here:
  /// the sandbox holds declared inputs only.
  void _convertAction(GnTarget target) {
    _use('//engine/src/flutter/build/bazel/gn_action:gn_action.bzl', 'gn_action');
    final rule = _Rule('gn_action', target.name, target.comments);
    final GnVariable? args = target.variables['args'];
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'script':
          final List<GnValue>? items = variable.unconditionalItems;
          if (items == null || items.length != 1 || items.single is! GnStringValue) {
            throw GnError(variable.assignments.first.location, 'script must be one plain string');
          }
          rule.scalars['script'] =
              '"${_filePath((items.single as GnStringValue).value, variable.assignments.first.location)}"';
        case 'sources':
          _filesInto(rule.list('srcs'), variable);
        case 'inputs':
          _filesInto(rule.list('inputs'), variable);
        case 'outputs':
          _outputsInto(rule.list('outputs'), variable, target);
        case 'args':
          break; // After the inputs, which it may add to.
        case 'deps':
        case 'public_deps':
          _labelsInto(rule.list('deps'), variable, target);
        case 'testonly':
          _scalar(rule, 'testonly', variable);
        case 'depfile':
        case 'pool':
          // The sandbox declares every input; pools are a scheduling matter.
          break;
        case 'data' || 'data_deps' || 'response_file_contents' || 'metadata' || 'assert_no_deps':
          throw GnError(
            variable.assignments.first.location,
            'action variable ${variable.name} is not converted yet',
          );
        default:
          // GN refuses an assignment that has no effect, so any other
          // variable of the block is a helper whose value reached the
          // attributes above.
          break;
      }
    }
    if (args != null) {
      _argsInto(rule, args, target);
    }
    rules.add(rule);
  }

  /// An action's outputs, as paths relative to the package: GN requires them
  /// under the build directory, and the rule declares them under the
  /// package's output directory, so they must be under `$target_gen_dir`.
  void _outputsInto(_ListAttribute attribute, GnVariable variable, GnTarget target) {
    final genDir = '$genDirRoot${gnPackage.substring(1)}/';
    _forEachItem(variable, into: attribute, (_Element e) {
      final String path = _string(e);
      if (!path.startsWith(genDir)) {
        throw GnError(
          e.assignment.location,
          'output $path of ${target.name} is not under its target_gen_dir; only such outputs are supported',
        );
      }
      attribute.addUnique(e.condition, _item(path.substring(genDir.length), e));
    });
  }

  /// An action's `args`, with each rebased path replaced by the rule's token
  /// for it.
  void _argsInto(_Rule rule, GnVariable variable, GnTarget target) {
    final _ListAttribute attribute = rule.list('args');
    final declared = <String>{
      for (final String list in <String>['srcs', 'inputs'])
        for (final _Item item in rule.list(list).always) item.text,
    };
    _forEachItem(variable, into: attribute, (_Element e) {
      final String text = _rawString(e);
      final List<String> parts = text.split(rebasedPathMarker);
      if (parts.length.isEven) {
        throw GnError(e.assignment.location, 'unbalanced rebased path in argument $text');
      }
      final out = StringBuffer();
      for (var i = 0; i < parts.length; i++) {
        if (i.isEven) {
          out.write(parts[i]);
          continue;
        }
        out.write(_pathToken(parts[i], e.assignment.location, rule, declared, target));
      }
      attribute.add(e.condition, _item(out.toString(), e));
    });
  }

  /// The rule's token for the absolute GN path [path] named by a
  /// `rebase_path(..., root_build_dir)`.
  String _pathToken(
    String path,
    GnLocation location,
    _Rule rule,
    Set<String> declared,
    GnTarget target,
  ) {
    if (path.startsWith('$genDirRoot/')) {
      final String? relative = layout.relativePath('//${path.substring(genDirRoot.length + 1)}');
      if (relative == null) {
        throw GnError(location, 'generated path $path is outside the output repository');
      }
      return '\$(gen $relative)';
    }
    if (path.startsWith(buildDirRoot)) {
      throw GnError(
        location,
        'a path in the build directory ($path) cannot be expressed; convert by hand',
      );
    }
    final String file = _filePath(path, location);
    final bool isDirectory = switch (tree) {
      final GnSourceTree t => FileSystemEntity.isDirectorySync(t.resolve(path)),
      null => !declared.contains(file),
    };
    if (isDirectory) {
      final String? relative = layout.relativePath(path);
      if (relative == null) {
        throw GnError(location, 'directory $path is outside the output repository');
      }
      return '\$(src $relative)';
    }
    if (!declared.contains(file)) {
      rule.list('inputs').addUnique(Condition.always, _Item(file));
      declared.add(file);
    }
    final label = file.startsWith('//') || file.startsWith('@') ? file : ':$file';
    return '\$(execpath $label)';
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

  /// A known template becomes a call of its Bazel macro, with the arguments
  /// the mapping names translated by kind (see [TemplateMapping.arguments]).
  void _convertTemplate(GnTarget target, TemplateMapping template) {
    _use(template.bzl, template.symbol);
    final rule = _Rule(template.symbol, target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      final TemplateArgument? argument = template.arguments[variable.name];
      if (argument == null) {
        if (_ignoredVariables.contains(variable.name)) {
          continue;
        }
        throw GnError(
          variable.assignments.first.location,
          '${target.rule}() argument ${variable.name} is not handled by the ${template.symbol} macro mapping',
        );
      }
      switch (argument.kind) {
        case TemplateArgumentKind.files:
          _filesInto(rule.list(argument.attribute), variable);
        case TemplateArgumentKind.labels:
          _labelsInto(rule.list(argument.attribute), variable, target);
        case TemplateArgumentKind.configs:
          _forEachItem(variable, into: rule.list(argument.attribute), (_Element e) {
            final String config = _string(e);
            final String label;
            if (config.startsWith(':')) {
              if (!localConfigs.containsKey(config.substring(1))) {
                throw GnError(e.assignment.location, 'unknown local config $config');
              }
              label = config;
            } else {
              final ConfigEffect? effect = configEffects[_gnLabel(config)];
              if (effect is! ConfigDependency) {
                throw GnError(
                  e.assignment.location,
                  'config $config has no Bazel dependency mapping for a ${template.symbol} macro',
                );
              }
              label = _localLabel(effect.label);
            }
            rule.list(argument.attribute).addUnique(e.condition, _item(label, e));
          });
        case TemplateArgumentKind.scalar:
          _scalar(rule, argument.attribute, variable);
      }
    }
    rules.add(rule);
  }

  /// copy("x") becomes a `gn_copy`: its sources as they are, GN's
  /// destination recorded (see build/bazel/gn_action).
  void _convertCopy(GnTarget target) {
    _use('//engine/src/flutter/build/bazel/gn_action:gn_action.bzl', 'gn_copy');
    final rule = _Rule('gn_copy', target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'sources':
          _filesInto(rule.list('srcs'), variable);
        case 'outputs':
          // As GN wrote them, for the record.
          _forEachItem(variable, into: rule.list('outputs'), (_Element e) {
            final String text = _string(e)
                .replaceFirst('$genDirRoot/', r'$root_gen_dir/')
                .replaceFirst('$buildDirRoot/', r'$root_out_dir/');
            rule.list('outputs').add(e.condition, _item(text, e));
          });
        case 'deps':
        case 'public_deps':
          _labelsInto(rule.list('deps'), variable, target);
        case 'testonly':
          _scalar(rule, 'testonly', variable);
        default:
          if (_ignoredVariables.contains(variable.name) || variable.forwarded) {
            break;
          }
          throw GnError(
            variable.assignments.first.location,
            'variable ${variable.name} of copy ${target.name} is not converted yet',
          );
      }
    }
    rules.add(rule);
  }

  /// A `source_set`/`static_library` ([library]), an `executable`, or a
  /// `shared_library` ([shared]: a `cc_binary` with `linkshared`, named
  /// after the file GN produces -- `lib<output_name>.so`, as Bazel requires
  /// of a shared binary -- with an `alias` under the GN target's name).
  void _convertCcTarget(
    GnTarget target,
    String kind, {
    required bool library,
    bool shared = false,
  }) {
    _use('@rules_cc//cc:defs.bzl', kind);
    final String name = shared
        ? 'lib${_singleString(target.variables['output_name']) ?? target.name}.so'
        : target.name;
    final rule = _Rule(kind, name, target.comments);
    if (kind == 'cc_test') {
      rule.scalars['size'] = '"${testSizes[target.name] ?? defaultTestSize}"';
    }
    if (shared) {
      rule.scalars['linkshared'] = 'True';
      _sharedLibraryOutputs.add(name);
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
        case 'public_deps':
          // Both are Bazel deps: GN's include paths make every header of
          // every transitive dependency visible, private or not, and its
          // check follows only the first edge; a sandboxed compile sees
          // declared inputs alone. What a private GN dep keeps from
          // dependents is the propagation of its public configs, which
          // Bazel's implementation_deps would model at the price of
          // compiles that cannot find the headers their dependencies'
          // headers include. The defines dependents gain this way are what
          // the parity check against GN measures.
          _depsInto(rule, variable, target);
          _propagatedFlagsInto(rule, variable);
        case 'defines':
          _stringsInto(rule.list('local_defines'), variable);
        case 'include_dirs':
          _includeDirsInto(rule, variable, Condition.always);
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
        case 'output_name' when target.rule == 'source_set' || shared:
          // A source_set produces no file, so GN ignores the name (harfbuzz's
          // GN sets one); a shared library's is in the rule's name already;
          // on anything else it would rename the output.
          break;
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

    // GN applies a dependency's all_dependent_configs to this target and to
    // everything that depends on it, through private dependencies too;
    // Bazel's implementation_deps would stop them, so the configs become
    // public deps of their own.
    if (conditionalInheritance.contains(target.name)) {
      throw GnError(
        target.location,
        '${target.name} inherits all_dependent_configs under a condition, which is not supported',
      );
    }
    for (final String config in inheritedConfigs[target.name] ?? const <String>{}) {
      rule.list('deps').addUnique(Condition.always, _Item(_localLabel(config)));
    }

    // A header-only library compiles nothing: GN ignores its flags and
    // defines (they apply to no compile and propagate to no one), and so
    // does the generated rule; its private configs likewise.
    final bool compiles = !(rule.lists['srcs']?.isEmpty ?? true);
    if (!compiles) {
      const <String>[
        'copts',
        'conlyopts',
        'cxxopts',
        'local_defines',
        'implementation_deps',
      ].forEach(rule.lists.remove);
    }
    if (compiles) {
      // GN applies chromium_code (or no_chromium_code) to every target, and
      // //flutter:config (-Wunreachable-code) to engine code: targets that
      // list it, their direct dependents, and dependents through public_deps.
      // The Bazel toolchain carries the rest.
      final constant = !chromiumCode
          ? 'FLUTTER_THIRD_PARTY_COPTS'
          : _isEngineCode(target)
          ? 'FLUTTER_COPTS'
          : 'CHROMIUM_CODE_COPTS';
      _use('//engine/src/flutter/build/bazel:copts.bzl', constant);
      // gmock's public config (-Wno-inconsistent-missing-override) reaches
      // every test target through testing_core's public_deps; see copts.bzl.
      final bool testonly = kind == 'cc_test' || rule.scalars['testonly'] == 'True';
      if (testonly) {
        _use('//engine/src/flutter/build/bazel:copts.bzl', 'FLUTTER_TESTONLY_COPTS');
        rule.list('copts').always.insert(0, const _Item('FLUTTER_TESTONLY_COPTS', quoted: false));
      }
      rule.list('copts').always.insert(0, _Item(constant, quoted: false));
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
      // GN's default include dirs, applied to every target by BUILDCONFIG.gn.
      if (layout.isMain) {
        rule.list('deps').addUnique(Condition.always, _Item(_localLabel(defaultIncludeDirsLabel)));
      }
    }
    // What GN leaves implicit (the headers of the tree, say) is a public
    // dependency, so that dependents outside the file see it too -- of a
    // header-only library as well, whose headers include the tree's.
    for (final String dep in implicitDeps) {
      rule.list('deps').addUnique(Condition.always, _Item(_localLabel(dep)));
    }
    // cc_binary and cc_test have no `includes`; a target's own include_dirs
    // ride a header-only library it depends on, which puts the same -I on
    // the same compiles.
    final _ListAttribute? includes = rule.lists['includes'];
    if (includes != null) {
      _dropForeignIncludeDirs(rule, includes, target);
    }
    if (kind != 'cc_library' && includes != null && !includes.isEmpty) {
      rule.lists.remove('includes');
      final helper = _Rule('cc_library', '${target.name}_include_dirs', const <String>[]);
      helper.lists['includes'] = includes;
      rules.add(helper);
      rule.list('deps').addUnique(Condition.always, _Item(':${helper.name}'));
    }
    if (shared) {
      // GN's default deps link the C++ runtime into every shared library;
      // Bazel's link_extra_libs reaches executables only.
      rule.list('deps').addUnique(Condition.always, _Item(_localLabel(cxxRuntimeLabel)));
    }
    rules.add(rule);
    if (shared) {
      // GN's name for the library, for dependents and the command line.
      rules.add(_Rule('alias', target.name, const <String>[])..scalars['actual'] = '":$name"');
    }
  }

  /// An include directory in another repository (`include_dirs =
  /// [ "${spirv_headers}/include" ]`) has no `includes` form, which is
  /// package-relative. When the target depends on that repository, the
  /// directory is the one its dependency's public config carries (the GN
  /// pattern: a dependency plus its include dir), so it is dropped with a
  /// note; otherwise it is an error.
  void _dropForeignIncludeDirs(_Rule rule, _ListAttribute includes, GnTarget target) {
    // The repositories the target depends on, through targets of this file
    // too.
    final depRepositories = <String>{};
    final visited = <String>{};
    void visit(GnTarget t) {
      if (!visited.add(t.name)) {
        return;
      }
      for (final name in <String>['deps', 'public_deps']) {
        for (final GnAssignment a in t.variables[name]?.assignments ?? const <GnAssignment>[]) {
          for (final GnValue v in a.items) {
            if (v is! GnStringValue) {
              continue;
            }
            final String label = bazelLabel(v.value, package: gnPackage, location: a.location);
            if (label.startsWith('@')) {
              final int slashes = label.indexOf('//');
              depRepositories.add(slashes < 0 ? label : label.substring(0, slashes));
            } else if (label.startsWith(':')) {
              final GnTarget? local = localTargets[label.substring(1)];
              if (local != null) {
                visit(local);
              }
            }
          }
        }
      }
    }

    visit(target);
    bool foreign(_Item item) => item.text.startsWith('@');
    for (final item in <_Item>[
      ...includes.always.where(foreign),
      for (final List<_Item> items in includes.conditional.values) ...items.where(foreign),
    ]) {
      final String repository = item.text.substring(0, item.text.indexOf('//'));
      // Without a dependency on the repository the directory cannot be
      // expressed, and the target cannot need it beyond what its own
      // dependencies carry: a file-wide GN config applied where nothing
      // includes from that tree. The sandboxed compile is the check.
      rule.comments.add(
        depRepositories.contains(repository)
            ? '# include_dirs: ${item.text} comes with the dependency on $repository.'
            : '# include_dirs: ${item.text} dropped; no dependency on $repository carries it.',
      );
    }
    includes.always.removeWhere(foreign);
    for (final List<_Item> items in includes.conditional.values) {
      items.removeWhere(foreign);
    }
    includes.conditional.removeWhere((Condition c, List<_Item> items) => items.isEmpty);
  }

  /// Whether GN compiles [target] with //flutter:config: it lists the
  /// config itself, or depends (directly, or through public_deps) on a
  /// target of this file that exports it, or depends on another engine
  /// package — engine libraries all export //flutter:config, which is the
  /// convention the Bazel copts constants rest on.
  bool _isEngineCode(GnTarget target, [Set<String>? visiting]) {
    bool lists(GnTarget t, List<String> variables) {
      for (final name in variables) {
        for (final GnAssignment a in t.variables[name]?.assignments ?? const <GnAssignment>[]) {
          for (final GnValue v in a.items) {
            if (v is GnStringValue && v.value == flutterConfigLabel && a.op != '-=') {
              return true;
            }
          }
        }
      }
      return false;
    }

    if (lists(target, const <String>['configs', 'public_configs', 'all_dependent_configs'])) {
      return true;
    }
    final Set<String> seen = visiting ?? <String>{};
    if (!seen.add(target.name)) {
      return false;
    }
    for (final name in const <String>['deps', 'public_deps']) {
      for (final GnAssignment a in target.variables[name]?.assignments ?? const <GnAssignment>[]) {
        for (final GnValue v in a.items) {
          if (v is! GnStringValue || a.op == '-=') {
            continue;
          }
          final GnTarget? local = v.value.startsWith(':')
              ? localTargets[v.value.substring(1)]
              : null;
          if (local != null) {
            if (lists(local, const <String>['public_configs', 'all_dependent_configs'])) {
              return true;
            }
            // Public configs travel further only through public_deps.
            if (name == 'public_deps' && _isEngineCode(local, seen)) {
              return true;
            }
            continue;
          }
          final String label = bazelLabel(v.value, package: gnPackage, location: a.location);
          if (label.startsWith('$bazelRootPackage/flutter')) {
            return true;
          }
        }
      }
    }
    return false;
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
  String _gnLabel(String value) => absoluteGnLabel(value, package: gnPackage, implicitName: true);

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
          _includeDirsInto(rule, variable, Condition.always);
        case 'libs':
        case 'frameworks':
        case 'ldflags':
          _linkFlagsInto(rule, variable);
        case 'visibility':
          // Local configs are only ever used by their own package.
          break;
        case 'configs':
          // A config's own configs apply wherever it applies: dependencies.
          _labelsInto(rule.list('deps'), variable, target);
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
          _includeDirsInto(rule, variable, use.condition);
          continue;
        case 'ldflags':
          attribute = 'linkopts';
        case 'visibility':
          continue;
        case 'configs':
          // The config's own configs apply to the target along with it.
          if (!flagsOnly) {
            _forEachItem(variable, into: rule.list('deps'), (_Element e) {
              final String label = bazelLabel(
                _string(e),
                package: gnPackage,
                location: e.assignment.location,
              );
              rule
                  .list('deps')
                  .addUnique(use.condition.and(e.condition), _Item(_localLabel(label)));
            });
          }
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
    final String value = _rawString(element);
    if (value.contains(rebasedPathMarker)) {
      throw GnError(
        element.assignment.location,
        'a rebase_path(..., root_build_dir) result is only usable in the args of an action()',
      );
    }
    return value;
  }

  /// [_string] for an action's args, where a rebased path belongs.
  static String _rawString(_Element element) {
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

  /// GN's `action()` targets of this file, whose outputs a dependent takes
  /// as sources: in GN a dependency on an action only orders it before the
  /// compile, the files being on disk; in Bazel the compile's inputs must
  /// name them.
  bool _isLocalAction(String gnLabel) {
    if (!gnLabel.startsWith(':')) {
      return false;
    }
    String name = gnLabel.substring(1);
    final int paren = name.indexOf('(');
    if (paren >= 0) {
      name = name.substring(0, paren);
    }
    return localTargets[name]?.rule == 'action';
  }

  /// Like [_labelsInto] for a compiled target's dependencies: those on
  /// actions of this file go to [sources] instead.
  void _depsInto(_Rule rule, GnVariable variable, GnTarget target) {
    _forEachItem(variable, into: rule.list('deps'), (_Element e) {
      final String gnLabel = _string(e);
      final String label = bazelLabel(gnLabel, package: gnPackage, location: e.assignment.location);
      final list = _isLocalAction(gnLabel) ? 'srcs' : 'deps';
      rule.list(list).addUnique(e.condition, _item(_localLabel(label), e));
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
    String absolute = gnFilePath.startsWith('//')
        ? gnFilePath
        : gnFilePath == '.'
        ? gnPackage
        : '$gnPackage/$gnFilePath';
    // A generated directory (`$target_gen_dir`, `get_label_info(...,
    // "target_gen_dir")`) as an include directory: Bazel's `includes`
    // names the source directory and its twin in the output tree at once,
    // so the path is the source path's.
    if (absolute == genDirRoot) {
      absolute = '//';
    } else if (absolute.startsWith('$genDirRoot/')) {
      absolute = '//${absolute.substring(genDirRoot.length + 1)}';
    }
    if (absolute.length > 2 && absolute.endsWith('/')) {
      absolute = absolute.substring(0, absolute.length - 1);
    }
    final String? relative = layout.relativePath(absolute);
    if (relative == null || layout.isMain) {
      // A file of another repository (a synced tree, which the main
      // repository ignores), which is a single package here.
      for (final MapEntry<String, String> entry in labelRepositoryPrefixes.entries) {
        if (entry.value.endsWith('//') &&
            (absolute.startsWith(entry.key) || '$absolute/' == entry.key)) {
          final String rest = '$absolute/' == entry.key ? '' : absolute.substring(entry.key.length);
          return rest.isEmpty ? entry.value : '${entry.value}:$rest';
        }
      }
    }
    if (relative == null) {
      throw GnError(
        location,
        '$gnFilePath is outside the output repository '
        '${layout.repository.isEmpty ? '' : layout.repository} (root ${layout.repositoryGnRoot})',
      );
    }
    // The deepest package owns a file: the one being generated (which the
    // layout need not list) or another the layout knows.
    final String current = package.package;
    final bool underCurrent = relative == current || relative.startsWith('$current/');
    String? owner = layout.owningPackage(relative);
    if (underCurrent && (owner == null || owner.length < current.length)) {
      owner = current;
    }
    if (owner == null) {
      throw GnError(location, '$gnFilePath is outside the package of the generated file');
    }
    final ownerPrefix = owner.isEmpty ? '' : '$owner/';
    if (owner == current) {
      return relative == owner ? '.' : relative.substring(ownerPrefix.length);
    }
    final String rest = relative == owner ? '' : relative.substring(ownerPrefix.length);
    return '//$owner:$rest';
  }

  void _filesInto(_ListAttribute attribute, GnVariable variable) {
    _forEachItem(variable, into: attribute, (_Element e) {
      attribute.addUnique(e.condition, _item(_filePath(_string(e), e.assignment.location), e));
    });
  }

  /// `include_dirs`: `includes` entries, except that a generated directory
  /// of an ancestor package (`$root_gen_dir/flutter`) is a dependency on
  /// the target whose `includes` already spans it (see
  /// [genDirIncludeTargets]); [under] is the condition of the config that
  /// carries them, when they are inlined.
  void _includeDirsInto(_Rule rule, GnVariable variable, Condition under) {
    _forEachItem(variable, into: rule.list('includes'), (_Element e) {
      final String path = _string(e);
      final String? ancestor = _genDirIncludeTarget(path);
      if (ancestor != null) {
        rule.list('deps').addUnique(under.and(e.condition), _Item(_localLabel(ancestor)));
        return;
      }
      rule
          .list('includes')
          .addUnique(under.and(e.condition), _item(_filePath(path, e.assignment.location), e));
    });
  }

  /// The dependency standing for a generated include directory of an
  /// ancestor package, or null when the directory is this package's or a
  /// plain source directory.
  String? _genDirIncludeTarget(String path) {
    final absolute = path.startsWith('//') ? path : '$gnPackage/$path';
    if (!absolute.startsWith(genDirRoot)) {
      return null;
    }
    final directory = absolute == genDirRoot
        ? '//'
        : '//${absolute.substring(genDirRoot.length + 1)}';
    if (directory == gnPackage || directory.startsWith('$gnPackage/')) {
      return null;
    }
    return genDirIncludeTargets[directory];
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
      final String list;
      if (splitHeaders && _headerExtensions.contains(extension)) {
        list = 'hdrs';
      } else if (_headerExtensions.contains(extension) || _sourceExtensions.contains(extension)) {
        list = 'srcs';
      } else {
        // A file Bazel's C++ rules would refuse in srcs (glslang's
        // spirv.hpp11): GN compiles nothing from it either, so it is a
        // textual header, which takes any file.
        list = 'textual_hdrs';
      }
      rule.list(list).addUnique(e.condition, _item(_filePath(path, e.assignment.location), e));
    });
  }

  /// What Bazel compiles from `srcs`.
  static const Set<String> _sourceExtensions = <String>{
    '.c',
    '.cc',
    '.cpp',
    '.cxx',
    '.c++',
    '.C',
    '.m',
    '.mm',
    '.S',
    '.s',
    '.asm',
    '.o',
    '.a',
    '.lo',
    '.so',
    '.def',
  };

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
  /// `copts`. A private config of another file is an `implementation_deps`
  /// entry, which Bazel applies to this target's compiles alone -- GN's
  /// private semantics -- except on a binary, which has no such attribute
  /// and no dependents.
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
            : configEffects[config] ?? configEffects[_gnLabel(config)];
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
            final attribute = private && local == null && rule.kind == 'cc_library'
                ? 'implementation_deps'
                : 'deps';
            rule.list(attribute).addUnique(assignment.condition, _item(label, element));
          case ConfigImplied():
            break;
        }
      }
    }
    return result;
  }

  /// The value of a variable that must be one unconditional string, or null
  /// when the variable is not set.
  String? _singleString(GnVariable? variable) {
    if (variable == null) {
      return null;
    }
    final List<GnValue>? items = variable.unconditionalItems;
    if (items == null || items.length != 1 || items.single is! GnStringValue) {
      throw GnError(
        variable.assignments.first.location,
        '${variable.name} must be a single unconditional string',
      );
    }
    return (items.single as GnStringValue).value;
  }

  void _scalar(_Rule rule, String attribute, GnVariable variable) {
    final List<GnScalarCase> cases = variable.cases(variable.assignments.first.location);
    if (cases.isEmpty) {
      throw GnError(variable.assignments.first.location, '${variable.name} has no value');
    }
    if (cases.length == 1 && cases.single.condition == Condition.always) {
      rule.scalars[attribute] = _scalarText(cases.single);
      return;
    }
    rule.scalars[attribute] = _renderScalarSelect(cases, rule, variable);
  }

  static String _scalarText(GnScalarCase scalarCase) {
    return switch (scalarCase.value) {
      GnBoolValue(:final bool value) => value ? 'True' : 'False',
      GnIntValue(:final int value) => '$value',
      GnStringValue(:final String value) => '"$value"',
      final GnValue other => throw GnError(
        scalarCase.assignment.location,
        'unsupported value $other',
      ),
    };
  }

  /// `select()` over the cases of a scalar: a case under a config_setting
  /// (or several, `is_mac || is_ios`) keys its value; the one case under a
  /// negation, if any, is the default; where no case holds the attribute is
  /// unset (`None`), as GN leaves the variable undefined there.
  String _renderScalarSelect(List<GnScalarCase> cases, _Rule rule, GnVariable variable) {
    final branches = <String, String>{};
    String? fallback;
    for (final scalarCase in cases) {
      final String value = _scalarText(scalarCase);
      final _SelectKeys keys = _selectKeys(
        scalarCase.condition,
        rule,
        scalarCase.assignment.location,
        () => 'of the value of ${variable.name} (${rule.kind} ${rule.name})',
      );
      if (!keys.negated) {
        for (final String setting in keys.settings) {
          branches[setting] = value;
        }
        continue;
      }
      if (fallback != null) {
        throw GnError(
          scalarCase.assignment.location,
          'two values of ${variable.name} hold under negations; a select() has one default',
        );
      }
      fallback = value;
      for (final String setting in keys.settings) {
        branches.putIfAbsent(setting, () => 'None');
      }
    }
    final out = StringBuffer('select({\n');
    for (final MapEntry<String, String> branch in branches.entries) {
      out.writeln('        "${branch.key}": ${branch.value},');
    }
    out
      ..writeln('        "//conditions:default": ${fallback ?? 'None'},')
      ..write('    })');
    return out.toString();
  }

  // -------------------------------------------------------------------------
  // Rendering
  // -------------------------------------------------------------------------

  String render(String gnFile, List<String> skipped, {String? appendix}) {
    // An appendix's own `load()`s (a rule or macro the generated part does
    // not use) belong with the file's; buildifier would move them there.
    if (appendix != null) {
      appendix = _takeLoads(appendix);
    }
    // A cc_library declares lib<name>.so as an implicit output; when a
    // shared library of the file produces that very file (GN's
    // `tessellator` source_set, which makes no file, next to
    // `tessellator_shared` with output_name "tessellator"), the library
    // gives it up. Dependents link it statically either way.
    for (final _Rule rule in rules) {
      if (rule.kind == 'cc_library' && _sharedLibraryOutputs.contains('lib${rule.name}.so')) {
        rule.scalars['linkstatic'] = 'True';
      }
    }
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

  /// buildifier's order: `@` loads first, then by the package's path
  /// components and the file name, so that a package precedes its
  /// subpackages (`//a/b:x.bzl` before `//a/b/c:y.bzl`, where a plain string
  /// comparison would put `/` before `:`).
  static int _compareLoads(String a, String b) {
    final bool externalA = a.startsWith('@');
    final bool externalB = b.startsWith('@');
    if (externalA != externalB) {
      return externalA ? -1 : 1;
    }
    List<String> key(String label) {
      final int colon = label.indexOf(':');
      final String package = colon < 0 ? label : label.substring(0, colon);
      final String file = colon < 0 ? '' : label.substring(colon + 1);
      return <String>[...package.split('/'), ':$file'];
    }

    final List<String> ka = key(a);
    final List<String> kb = key(b);
    for (var i = 0; i < ka.length && i < kb.length; i++) {
      final int c = ka[i].compareTo(kb[i]);
      if (c != 0) {
        return c;
      }
    }
    return ka.length.compareTo(kb.length);
  }

  static const List<String> _leadingAttributes = <String>[
    'name',
    'size',
    'testonly',
    'srcs',
    'hdrs',
  ];
  static const List<String> _trailingAttributes = <String>[
    'deps',
    'implementation_deps',
    'alwayslink',
  ];

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
    // Bare constants (FLUTTER_COPTS, FLUTTER_TESTONLY_COPTS,
    // FLUTTER_LOCAL_DEFINES) lead as themselves.
    final always = List<_Item>.of(list.always);
    while (always.isNotEmpty && !always.first.quoted && always.first.comment == null) {
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
    final _SelectKeys keys = _selectKeys(
      condition,
      rule,
      GnLocation('$gnPackage/BUILD.gn', 0, 0),
      () => 'on ${rule.kind} ${rule.name}',
    );
    final String branch = _renderItems(items, indent: 8);
    final out = StringBuffer('select({\n');
    for (final String setting in keys.settings) {
      out.writeln('        "$setting": ${keys.negated ? '[]' : branch},');
    }
    out.writeln('        "//conditions:default": ${keys.negated ? branch : '[]'},');
    out.write('    })');
    return out.toString();
  }

  /// How [condition] maps onto the keys of a `select()`: the settings of
  /// its variables, and whether the branch belongs under them or, for a
  /// negation (`!is_win`; `!is_win && !is_mac`, the `else` of a chain),
  /// under the default with those keys empty.
  _SelectKeys _selectKeys(
    Condition condition,
    _Rule rule,
    GnLocation location,
    String Function() where,
  ) {
    switch (condition) {
      case ConditionVariable():
      case ConditionComparison(equals: true):
        return _SelectKeys(<String>[_setting(condition, rule)], negated: false);
      case ConditionComparison(equals: false):
        return _SelectKeys(<String>[_setting(condition.negated, rule)], negated: true);
      case ConditionNot(:final Condition operand):
        return _SelectKeys(<String>[_setting(operand, rule)], negated: true);
      case ConditionOr(:final List<Condition> terms):
        return _SelectKeys(<String>[
          for (final Condition t in terms) _setting(t, rule),
        ], negated: false);
      case ConditionAnd(:final List<Condition> terms)
          when terms.every(
            (Condition t) => t is ConditionNot || t is ConditionComparison && !t.equals,
          ):
        return _SelectKeys(<String>[
          for (final Condition t in terms) _setting(t.negated, rule),
        ], negated: true);
      default:
        throw GnError(
          location,
          'condition `$condition` ${where()} cannot be expressed as a select()',
        );
    }
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
