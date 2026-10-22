// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Starlark generation: from the evaluated GN targets to a `BUILD.bazel`.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'bazel_mapping.dart';
import 'dependency_resolver.dart';
import 'gn_ast.dart';
import 'gn_eval.dart';
import 'manifest.dart';

const String _licenseHeader = '''
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
''';

/// One item of a Bazel list attribute: a string, a Starlark identifier that
/// is itself a list (`FLUTTER_COPTS`, hoisted to lead the attribute), or a
/// Starlark expression that is one element (`"X=\"" + ENGINE_VERSION + "\""`).
final class _Item {
  const _Item(
    this.text, {
    this.quoted = true,
    this.expression = false,
    this.comment,
    this.before = const <String>[],
  });

  final String text;
  final bool quoted;

  /// An unquoted item that is an element of the list rather than a list.
  final bool expression;

  /// A comment on the item's line (without `#`).
  final String? comment;

  /// Comment lines before the item (with their `#`).
  final List<String> before;

  String get starlark => quoted ? '"${text.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"' : text;
}

/// A copy's dependency edge into a wasm toolchain of its file
/// (`"//flutter/skwasm(:skwasm)"`): the dependency and the toolchain, with
/// the Bazel names of both.
final class _ToolchainEdge {
  const _ToolchainEdge({
    required this.gnLabel,
    required this.moduleLabel,
    required this.moduleName,
    required this.toolchainName,
    required this.platform,
  });

  /// The dependency as written, without the toolchain (`//flutter/skwasm`).
  final String gnLabel;

  /// Its Bazel label.
  final String moduleLabel;

  /// Its target name (`skwasm`), which names its outputs.
  final String moduleName;

  /// The toolchain's name (`skwasm`): its directory under the build
  /// directory.
  final String toolchainName;

  /// The platform standing for the toolchain (the wasm_platform this file
  /// declares for it).
  final String platform;
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

/// The archive entries a zip_bundle holds under some settings (`held`) and
/// under none of them (`otherwise`): one `select()` of its `files`.
final class _EntrySelect {
  _EntrySelect(this.settings);

  final List<String> settings;
  final Map<String, String> held = <String, String>{};
  final Map<String, String> otherwise = <String, String>{};
}

/// A list attribute: unconditional items, plus items per condition in the
/// order the conditions first appeared.
final class _ListAttribute {
  _ListAttribute({this.setLike = false});

  /// Whether the attribute is a set of labels Bazel rejects a duplicate in
  /// (deps, srcs, data), where an item under a condition implying another
  /// item's condition is a duplicate wherever it appears; a flag list keeps
  /// GN's repeats in GN's order.
  final bool setLike;

  final List<_Item> always = <_Item>[];
  final Map<Condition, List<_Item>> conditional = <Condition, List<_Item>>{};

  /// Every item with its condition, in the order GN appended them: the
  /// attributes the compiler reads in order (copts, defines, linkopts, the
  /// include directories) are laid out run by run in this order, a select()
  /// per run of one condition, where GN interleaves its conditional appends
  /// with the rest. Items put into [always] directly (a group's members) are
  /// not here, and the layout falls back to the two parts when the counts
  /// disagree.
  final List<(Condition, _Item)> sequence = <(Condition, _Item)>[];

  /// Comment lines above the attribute (GN's comments on the `=` that
  /// defined the variable).
  final List<String> comments = <String>[];

  bool get isEmpty => always.isEmpty && conditional.isEmpty;

  /// Every item, under whatever condition.
  Iterable<_Item> get items =>
      always.followedBy(conditional.values.expand((List<_Item> items) => items));

  int get _count =>
      always.length + conditional.values.fold(0, (int n, List<_Item> items) => n + items.length);

  /// Whether [sequence] has every item, so that the order is known.
  bool get hasOrder => sequence.length == _count;

  void add(Condition condition, _Item item) {
    if (condition == Condition.always) {
      always.add(item);
    } else {
      conditional.putIfAbsent(condition, () => <_Item>[]).add(item);
    }
    sequence.add((condition, item));
  }

  /// Adds [item] under [condition] unless it is there already (two GN labels
  /// can translate to one Bazel label, which Bazel rejects as a duplicate)
  /// -- or in the unconditional part, which holds wherever the condition
  /// does (GN lists impeller_unittests' geometry_unittests outright and
  /// again under a backend; GN's deps are a set, Bazel's reject a duplicate),
  /// or under a condition the new one implies (skshaper lists skunicode
  /// under `skia_enable_skunicode` and again under `skia_use_harfbuzz &&
  /// skia_enable_skunicode`: wherever the second holds, the first does, and
  /// both select() branches would name it). An unconditional item,
  /// likewise, takes the place of its conditional copies (fml's Dart API
  /// headers, listed by GN outside the web build and by the manifest
  /// everywhere), and an item under a weaker condition the place of its
  /// copies under conditions implying it.
  void addUnique(Condition condition, _Item item) {
    bool same(_Item existing) => existing.text == item.text;
    if (always.any(same)) {
      return;
    }
    if (condition == Condition.always) {
      _displace(same, (Condition when) => true);
      always.add(item);
      sequence.add((condition, item));
      return;
    }
    if (setLike) {
      for (final MapEntry<Condition, List<_Item>> entry in conditional.entries) {
        if (entry.value.any(same) && _implies(condition, entry.key)) {
          return;
        }
      }
      _displace(same, (Condition when) => when != condition && _implies(when, condition));
    }
    final List<_Item> bucket = conditional.putIfAbsent(condition, () => <_Item>[]);
    if (bucket.any(same)) {
      return;
    }
    bucket.add(item);
    sequence.add((condition, item));
  }

  /// Removes the items [same] matches from the conditional buckets [where]
  /// selects (and from the sequence), dropping emptied buckets.
  void _displace(bool Function(_Item) same, bool Function(Condition) where) {
    for (final Condition when in conditional.keys.toList()) {
      if (!where(when)) {
        continue;
      }
      final List<_Item> items = conditional[when]!;
      items.removeWhere(same);
      if (items.isEmpty) {
        conditional.remove(when);
      }
    }
    sequence.removeWhere(
      ((Condition, _Item) entry) =>
          entry.$1 != Condition.always && where(entry.$1) && same(entry.$2),
    );
  }

  /// Whether [stronger] holding guarantees [weaker] holds, as far as the
  /// shape says: the same condition, or a conjunction that has [weaker]
  /// among its terms (or all of [weaker]'s terms, when that is a
  /// conjunction too).
  static bool _implies(Condition stronger, Condition weaker) {
    if (stronger == weaker) {
      return true;
    }
    if (stronger is! ConditionAnd) {
      return false;
    }
    if (weaker is ConditionAnd) {
      return weaker.terms.every(stronger.terms.contains);
    }
    return stronger.terms.contains(weaker);
  }

  /// Moves the items under [condition] to the unconditional part, in their
  /// places; one the unconditional part already holds is dropped.
  void makeUnconditional(Condition condition) {
    final List<_Item>? items = conditional.remove(condition);
    if (items == null) {
      return;
    }
    for (final _Item item in items) {
      final bool present = always.any((_Item existing) => existing.text == item.text);
      final int at = sequence.indexWhere(
        ((Condition, _Item) entry) => identical(entry.$2, item) && entry.$1 == condition,
      );
      if (present) {
        if (at >= 0) {
          sequence.removeAt(at);
        }
        continue;
      }
      always.add(item);
      if (at >= 0) {
        sequence[at] = (Condition.always, item);
      }
    }
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

  /// A target's own unconditional compiler flags by attribute (`copts`,
  /// `conlyopts`, `cxxopts`), which lead the attribute as they lead GN's
  /// command line; spliced in once the copts constants are placed.
  final Map<String, List<_Item>> ownFlags = <String, List<_Item>>{};

  _ListAttribute list(String attribute) => lists.putIfAbsent(
    attribute,
    () => _ListAttribute(setLike: _setLikeAttributes.contains(attribute)),
  );

  /// The label-list attributes Bazel rejects a duplicate in.
  static const Set<String> _setLikeAttributes = <String>{
    'srcs',
    'hdrs',
    'deps',
    'implementation_deps',
    'data',
    'tools',
    'fixtures',
    'link_inputs',
    'exports',
  };
}

/// buildifier's order of two strings of a sorted list (labels): compared
/// piecewise after splitting on `.` and `:`, a prefix first.
int compareBuildifierStrings(String a, String b) {
  final List<String> sa = a.replaceAll(':', '.').split('.');
  final List<String> sb = b.replaceAll(':', '.').split('.');
  for (var i = 0; i < sa.length && i < sb.length; i++) {
    final int c = sa[i].compareTo(sb[i]);
    if (c != 0) {
      return c;
    }
  }
  if (sa.length != sb.length) {
    return sa.length.compareTo(sb.length);
  }
  return a.compareTo(b);
}

/// Whether a GN executable is a test: `testonly`, named `*tests`, which is
/// how run_tests.py's executables are declared -- or `*testrunner`, the one
/// gtest executable a builder runs directly (`licenses_cpp_testrunner`,
/// host_release_licenses' test step). The emitter makes such an executable
/// a `cc_test` (or a `flutter_cc_test`); the builder files' generator
/// resolves run_tests.py's names among them.
bool isTestTarget(GnTarget target) {
  if (target.rule != 'executable') {
    return false;
  }
  final List<GnValue>? testonly = target.variables['testonly']?.unconditionalItems;
  final bool isTestonly =
      testonly != null && testonly.length == 1 && testonly.single == const GnBoolValue(true);
  return isTestonly && (target.name.endsWith('tests') || target.name.endsWith('testrunner'));
}

/// Whether the emitter makes a `cc_test` of the executable [target] of
/// [gnPackage]: a test ([isTestTarget]), or a benchmark run_tests.py runs
/// (`benchmarkRuns`).
bool isBazelTest(GnTarget target, String gnPackage) {
  return target.rule == 'executable' &&
      (isTestTarget(target) || benchmarkRuns.containsKey('$gnPackage:${target.name}'));
}

/// Converts the targets of one GN file into the text of a `BUILD.bazel`.
///
/// [gnPackage] is the GN directory of the file (`//flutter/fml`). Targets
/// named in [skipTargets] are left out (with a note), as are the ones the
/// evaluation already skipped. [appendix] is Starlark to append verbatim:
/// what the GN file has no way to say (an `exports_files`, say). [layout]
/// says where the file lives, which decides how file paths are written.
/// [implicitDeps] are labels every target that compiles depends on (see
/// the manifest). [forwardedFlags] resolves the compiler flags a dependency
/// hands this file's targets (dependency_resolver.dart); one resolver serves a
/// whole run, and without one a resolver over [tree] is made -- or, with
/// no tree, one that finds none.
String emitBuildFile(
  GnFileEvaluation evaluation, {
  required String gnPackage,
  Set<String> skipTargets = const <String>{},
  String? appendix,
  OutputLayout layout = const OutputLayout.main(),
  List<String> implicitDeps = const <String>[],
  GnSourceTree? tree,
  DependencyResolver? forwardedFlags,
  List<String> unconvertedDeps = const <String>[],
  Set<String> filesGroups = const <String>{},
}) {
  final DependencyResolver forwarded =
      forwardedFlags ??
      (tree == null
          ? DependencyResolver.none()
          : DependencyResolver(tree: tree, assumptions: evaluation.assumptions));
  final emitter = _Emitter(gnPackage, layout, implicitDeps, tree, evaluation.assumptions, forwarded)
    ..inheritedConfigs.addAll(evaluation.inheritedConfigs);
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
    }
  }
  emitter.skippedTargets.addAll(skipped);
  emitter.unconvertedDeps.addAll(unconvertedDeps);
  emitter.filesGroups.addAll(filesGroups);
  for (final name in filesGroups) {
    if (emitter.localTargets[name]?.rule != 'group') {
      throw GnError(
        GnLocation(evaluation.file, 0, 0),
        'filesGroups names $name, which is not a group of the file',
      );
    }
  }
  for (final GnTarget target in evaluation.targets) {
    if (skipTargets.contains(target.name)) {
      continue;
    }
    emitter.convert(target);
  }
  final List<String> unused = unconvertedDeps
      .where((String label) => !emitter.usedUnconvertedDeps.contains(label))
      .toList();
  if (unused.isNotEmpty) {
    throw GnError(
      GnLocation(evaluation.file, 0, 0),
      'unconvertedDeps lists ${unused.join(', ')}, which no group of the file depends on',
    );
  }
  return emitter.render(evaluation.file, skipped, appendix: appendix);
}

/// Target variables that say nothing Bazel needs.
const Set<String> _ignoredVariables = <String>{'check_includes', 'metadata', 'visibility'};

/// The variables GN's own target types read (`gn help` lists them); any
/// other variable assigned in a target's block is the block's helper, read
/// by its own strings or conditions (`build_embedder_api`), since GN rejects
/// an assignment nothing reads. The converter ignores such a variable: its
/// effect is already in the values it fed.
const Set<String> _gnTargetVariables = <String>{
  'all_dependent_configs',
  'allow_circular_includes_from',
  'arflags',
  'args',
  'asmflags',
  'assert_no_deps',
  'cflags',
  'cflags_c',
  'cflags_cc',
  'cflags_objc',
  'cflags_objcc',
  'check_includes',
  'complete_static_lib',
  'configs',
  'contents',
  'data',
  'data_deps',
  'data_keys',
  'defines',
  'depfile',
  'deps',
  'framework_dirs',
  'frameworks',
  'friend',
  'gen_deps',
  'include_dirs',
  'inputs',
  'ldflags',
  'lib_dirs',
  'libs',
  'metadata',
  'mnemonic',
  'output_conversion',
  'output_dir',
  'output_extension',
  'output_name',
  'output_prefix_override',
  'outputs',
  'pool',
  'precompiled_header',
  'precompiled_header_type',
  'precompiled_source',
  'public',
  'public_configs',
  'public_deps',
  'rebase',
  'response_file_contents',
  'script',
  'sources',
  'swiftflags',
  'testonly',
  'visibility',
  'walk_keys',
  'weak_frameworks',
  'write_runtime_deps',
};

/// Whether [variable] is a helper of its target's block rather than one of
/// GN's target variables (see [_gnTargetVariables]).
bool _isHelperVariable(GnVariable variable) => !_gnTargetVariables.contains(variable.name);

final class _Emitter {
  _Emitter(
    this.gnPackage,
    this.layout,
    this.implicitDeps,
    this.tree,
    this.assumptions,
    this.forwarded,
  ) : package = BazelLabel.parse(bazelLabel(gnPackage, package: gnPackage));

  final String gnPackage;
  final OutputLayout layout;

  /// The source tree, when available: tells a rebased directory from a
  /// rebased file in an action's arguments.
  final GnSourceTree? tree;

  /// The assumptions the file was evaluated under, for the conditions the
  /// mapping tables state (ConfigCopts).
  final Assumptions assumptions;

  /// The compiler flags a dependency hands its dependents, which Bazel
  /// cannot carry along the dependency (dependency_resolver.dart).
  final DependencyResolver forwarded;

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

  /// The condition the target being converted exists under (its items carry
  /// it no longer: _dropImplied), for what the enumeration of a string's
  /// variables can rule out (`target_cpu == "wasm"` under is_android).
  Condition _targetCondition = Condition.always;

  /// The targets of the file that are not converted (the evaluation's
  /// skipped and the run's skipTargets): a template's label list leaves a
  /// dependency on one out, there being no target to name.
  final Set<String> skippedTargets = <String>{};

  /// Dependencies of the file's groups that have no Bazel counterpart yet
  /// (the manifest's unconvertedDeps), by absolute GN label; left out of the
  /// generated groups and listed in the header. [usedUnconvertedDeps] has
  /// the ones met.
  final Set<String> unconvertedDeps = <String>{};
  final Set<String> usedUnconvertedDeps = <String>{};

  /// Groups of the file that are groups of things to build, never linked
  /// against (the manifest's filesGroups): filegroups.
  final Set<String> filesGroups = <String>{};

  /// The local configs some target of the file lists (whose compiler flags
  /// are therefore inlined there).
  final Set<String> locallyUsedConfigs = <String>{};

  /// Per target, the configs it inherits through `all_dependent_configs`
  /// (its own and its dependencies', see
  /// [GnFileEvaluation.inheritedConfigs]), each under the condition it
  /// reaches the target.
  final Map<String, Map<String, Condition>> inheritedConfigs = <String, Map<String, Condition>>{};

  /// `load()` statements: file label to the symbols used from it.
  final Map<String, Set<String>> loads = <String, Set<String>>{};

  void _use(String bzl, String symbol) {
    loads.putIfAbsent(_absoluteLabel(bzl), () => <String>{}).add(symbol);
  }

  /// The `config_setting_group`s this file declares for conjunctions of
  /// mixed settings, by condition (see [_conjunctionSetting]).
  final Map<Condition, String> _conjunctionGroups = <Condition, String>{};

  /// The `lib<name>.so` files the file's shared libraries produce.
  final Set<String> _sharedLibraryOutputs = <String>{};

  /// Whether the file's flutter_gpu_test_backends target has been declared
  /// (once, for all of the file's suites in [gpuBackendTests]).
  bool _declaredGpuBackends = false;

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
    final int first = rules.length;
    _targetCondition = target.condition;
    _convertTarget(target);
    _targetCondition = Condition.always;
    // A target GN defines only under a condition exists in Bazel but is
    // incompatible wherever the condition does not hold: dependents cannot
    // build it there, as in GN they could not name it. The settings the
    // target's select()s add to the file (config_setting_groups of its
    // conditions) are not targets of GN's and take no compatibility: a
    // setting holds or not, wherever it is asked.
    if (target.condition != Condition.always) {
      final int last = rules.length;
      final String compatibility = _compatibility(target);
      for (final _Rule rule in rules.sublist(first, last)) {
        if (rule.kind == 'selects.config_setting_group') {
          continue;
        }
        rule.scalars['target_compatible_with'] = compatibility;
        // Items under a condition the target's own implies (a file-level
        // list defined in the same `if (enable_unittests)` block as the
        // target that reads it) are unconditional within the target, which
        // exists nowhere else: no select() for them -- and a macro that
        // inspects the list in Starlark gets a list.
        for (final _ListAttribute list in rule.lists.values) {
          _dropImplied(list, target.condition);
        }
      }
    }
  }

  /// Moves the items of [list] whose condition [context] implies (context &&
  /// condition is context) to its unconditional part -- those not already
  /// there (impeller_unittests lists geometry_unittests outright and again
  /// under a backend; Bazel rejects a duplicated dependency).
  static void _dropImplied(_ListAttribute list, Condition context) {
    final implied = <Condition>[
      for (final Condition c in list.conditional.keys)
        if (context.and(c) == context) c,
    ];
    implied.forEach(list.makeUnconditional);
  }

  /// `target_compatible_with` for a target defined under its condition:
  /// compatible where the condition's settings hold, `@platforms//:incompatible`
  /// elsewhere.
  String _compatibility(GnTarget target) {
    final _SelectKeys keys = _selectKeys(
      target.condition,
      _Rule(target.rule, target.name, const <String>[]),
      target.location,
      () => 'defining ${target.rule} ${target.name}',
    );
    const incompatible = '["@platforms//:incompatible"]';
    final out = StringBuffer('select({\n');
    for (final String setting in keys.settings) {
      out.writeln('        "$setting": ${keys.negated ? incompatible : '[]'},');
    }
    out
      ..writeln('        "//conditions:default": ${keys.negated ? '[]' : incompatible},')
      ..write('    })');
    return out.toString();
  }

  void _convertTarget(GnTarget target) {
    final TemplateMapping? template = templateMappings[target.rule];
    if (template != null) {
      _convertTemplate(target, template);
      return;
    }
    switch (target.rule) {
      case 'static_library' when _isCompleteStaticLibrary(target):
        _convertCompleteStaticLibrary(target);
      case 'source_set':
      case 'static_library':
        _convertCcTarget(target, 'cc_library', library: true);
      case 'executable' when _isWasmExecutable(target):
        _convertTemplate(target, templateMappings[wasmExecutableRule]!);
      case 'executable':
        _convertCcTarget(
          target,
          _isTest(target) || benchmarkRuns.containsKey('$gnPackage:${target.name}')
              ? 'cc_test'
              : 'cc_binary',
          library: false,
        );
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
      case 'generated_file':
        _convertGeneratedFile(target);
      default:
        throw GnError(target.location, '${target.rule}() is not converted yet');
    }
  }

  /// generated_file("x") with `contents`: a `gn_generated_file`
  /// (build/bazel/gn_action) writing the lines, named after GN's output
  /// path under the build directory (or under the package's own gen dir,
  /// when it is there), with the output on record for install. The
  /// `metadata`-walking form (`data_keys`) is not converted.
  void _convertGeneratedFile(GnTarget target) {
    _use('//engine/src/flutter/build/bazel/gn_action:gn_action.bzl', 'gn_generated_file');
    final rule = _Rule('gn_generated_file', target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'outputs':
          final List<GnValue>? items = variable.unconditionalItems;
          if (items == null || items.length != 1 || items.single is! GnStringValue) {
            throw GnError(
              variable.assignments.first.location,
              'generated_file ${target.name} must name one unconditional output',
            );
          }
          final String output = (items.single as GnStringValue).value;
          final GnLocation location = variable.assignments.first.location;
          final genDir = '$genDirRoot${gnPackage.substring(1)}/';
          final String out = output.startsWith(genDir)
              ? output.substring(genDir.length)
              : _buildDirectoryPath(output, location);
          rule.scalars['out'] = _starlarkString(out);
          rule
              .list('outputs')
              .add(
                Condition.always,
                _Item(
                  output
                      .replaceFirst('$genDirRoot/', r'$root_gen_dir/')
                      .replaceFirst('$buildDirRoot/', r'$root_out_dir/'),
                ),
              );
        case 'contents':
          // Lines of a file, as they are (not flags: no tokenizer escapes).
          _forEachItem(variable, into: rule.list('content'), (_Element e) {
            rule.list('content').add(e.condition, _item(_string(e), e));
          });
        case 'deps':
        case 'public_deps':
          _labelsInto(rule.list('deps'), variable, target);
        case 'testonly':
          _scalar(rule, 'testonly', variable);
        case 'output_conversion' || 'data_keys' || 'walk_keys' || 'rebase':
          throw GnError(
            variable.assignments.first.location,
            'generated_file variable ${variable.name} is not converted yet',
          );
        default:
          if (_ignoredVariables.contains(variable.name) ||
              variable.forwarded ||
              _isHelperVariable(variable)) {
            break;
          }
          throw GnError(
            variable.assignments.first.location,
            'variable ${variable.name} of generated_file ${target.name} is not converted yet',
          );
      }
    }
    if (!rule.scalars.containsKey('out')) {
      throw GnError(target.location, 'generated_file ${target.name} has no outputs');
    }
    rules.add(rule);
  }

  static bool _isCompleteStaticLibrary(GnTarget target) {
    final List<GnValue>? complete = target.variables['complete_static_lib']?.unconditionalItems;
    return complete != null && complete.length == 1 && complete.single == const GnBoolValue(true);
  }

  /// A `static_library` with `complete_static_lib`: an archive of every
  /// object in its dependency closure, which GN writes as an artifact
  /// (`$target_out_dir/lib<output_name>.a`; the Impeller SDK's
  /// `libimpeller.a`). Bazel's `cc_static_library` is the same archive
  /// (`lib<name>.a` in the package, so the rule is named after GN's
  /// `output_name` with an alias under the GN name, like a shared
  /// library's), behind `--experimental_cc_static_library` in Bazel 8
  /// (.bazelrc). Nothing compiles in it, so GN's configs and flags on it
  /// have nothing to apply to and are not written.
  void _convertCompleteStaticLibrary(GnTarget target) {
    _use('@rules_cc//cc:cc_static_library.bzl', 'cc_static_library');
    final List<GnValue>? outputName = target.variables['output_name']?.unconditionalItems;
    final String name =
        outputName != null && outputName.length == 1 && outputName.single is GnStringValue
        ? (outputName.single as GnStringValue).value
        : target.name;
    final rule = _Rule('cc_static_library', name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'deps':
        case 'public_deps':
          _depsInto(rule, variable, target);
        case 'testonly':
          _scalar(rule, 'testonly', variable);
        case 'complete_static_lib':
        case 'output_name':
        // Compile and link settings, with nothing here to compile or link.
        case 'all_dependent_configs':
        case 'asmflags':
        case 'cflags':
        case 'cflags_c':
        case 'cflags_cc':
        case 'cflags_objc':
        case 'cflags_objcc':
        case 'configs':
        case 'defines':
        case 'framework_dirs':
        case 'frameworks':
        case 'include_dirs':
        case 'ldflags':
        case 'lib_dirs':
        case 'libs':
        case 'public_configs':
          break;
        default:
          if (_ignoredVariables.contains(variable.name) ||
              variable.forwarded ||
              _isHelperVariable(variable)) {
            break;
          }
          throw GnError(
            variable.assignments.first.location,
            'variable ${variable.name} of complete static library ${target.name} is not converted yet',
          );
      }
    }
    rules.add(rule);
    if (name != target.name) {
      rules.add(_Rule('alias', target.name, const <String>[])..scalars['actual'] = '":$name"');
    }
  }

  /// group("x") forwards its dependencies: a `cc_library` with only `deps`
  /// (its actions and copies as `srcs` and `data`), which is what a GN group
  /// does for linking -- a `filegroup` when it is a group of things to
  /// build that nothing links against (the manifest's filesGroups: the root
  /// group `flutter` and what it reaches; wasm links). With nothing to
  /// compile it cannot keep a private dependency private (Bazel's
  /// implementation_deps need sources), so `deps` and `public_deps` both
  /// become `deps`.
  void _convertGroup(GnTarget target) {
    if (filesGroups.contains(target.name) || _isWasmGroup(target)) {
      _convertFilesGroup(target);
      return;
    }
    _use('@rules_cc//cc:defs.bzl', 'cc_library');
    final rule = _Rule('cc_library', target.name, target.comments);
    final propagated = <ForwardedFlag>[];
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'deps':
          _depsInto(rule, variable, target);
        case 'public_deps':
          _depsInto(rule, variable, target);
          _forwardedFlagsInto(propagated, variable, target);
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
            propagatedFlags: propagated,
          );
        default:
          if (_ignoredVariables.contains(variable.name) ||
              variable.forwarded ||
              _isHelperVariable(variable)) {
            break;
          }
          throw GnError(
            variable.assignments.first.location,
            'variable ${variable.name} of group ${target.name} is not converted yet',
          );
      }
    }
    _checkPropagatedFlags(target, propagated);
    _inheritedConfigsInto(rule, target);
    rules.add(rule);
  }

  /// Whether a group stands for wasm modules: every dependency is a link in
  /// a wasm toolchain of this file (CanvasKit's `group("canvaskit") {
  /// public_deps = [ ":canvaskit_js" ] }`, which the web SDK's copies name),
  /// a group of files rather than of libraries.
  bool _isWasmGroup(GnTarget target) {
    var any = false;
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'deps' || 'public_deps':
          for (final GnListItem item in variable.liveItems) {
            final GnValue value = item.value;
            if (value is! GnStringValue || !_isLocalWasmLink(_withoutToolchain(value.value))) {
              return false;
            }
            any = true;
          }
        case 'testonly':
          break;
        default:
          if (!_ignoredVariables.contains(variable.name) &&
              !variable.forwarded &&
              !_isHelperVariable(variable)) {
            return false;
          }
      }
    }
    return any;
  }

  /// A group of files as a filegroup: its dependencies' files are its own
  /// (what a copy of the group's outputs takes).
  void _convertFilesGroup(GnTarget target) {
    final rule = _Rule('filegroup', target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        // What the group reaches at run time (data_deps: the validation
        // layers' group over its library) is as much its files.
        case 'deps' || 'public_deps' || 'data_deps':
          _labelsInto(rule.list('srcs'), variable, target, withViews: false);
        case 'testonly':
          _scalar(rule, 'testonly', variable);
        default:
          break;
      }
    }
    rules.add(rule);
  }

  /// The configs [target] inherits through `all_dependent_configs` as
  /// dependencies on their libraries, each under the condition it reaches
  /// the target.
  void _inheritedConfigsInto(_Rule rule, GnTarget target) {
    for (final MapEntry<String, Condition> inherited
        in (inheritedConfigs[target.name] ?? const <String, Condition>{}).entries) {
      rule.list('deps').addUnique(inherited.value, _Item(_localLabel(inherited.key)));
    }
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
    // An action known by its script (dart_pkg.py) is a macro invocation,
    // its variables the macro's arguments.
    final List<GnValue>? scriptItems = target.variables['script']?.unconditionalItems;
    if (scriptItems != null && scriptItems.length == 1 && scriptItems.single is GnStringValue) {
      final String script = (scriptItems.single as GnStringValue).value;
      final TemplateMapping? byScript =
          scriptMappings[script.startsWith('//')
              ? script
              : _normalized('$gnPackage/$script', target.location)];
      if (byScript != null) {
        _convertTemplate(target, byScript);
        return;
      }
    }
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
          final String script = (items.single as GnStringValue).value;
          rule.scalars['script'] = '"${_filePath(script, variable.assignments.first.location)}"';
          // What the script imports beside itself, for the sandbox.
          for (final String label in scriptInputs[_gnPath(script)] ?? const <String>[]) {
            rule.list('inputs').addUnique(Condition.always, _Item(_localLabel(label)));
          }
        case 'sources':
          _actionFilesInto(rule, 'srcs', variable);
        case 'inputs':
          _actionFilesInto(rule, 'inputs', variable);
        case 'outputs':
          _outputsInto(rule, variable, target);
        case 'args':
          break; // After the inputs, which it may add to.
        case 'deps':
        case 'public_deps':
          _actionDepsInto(rule, variable, target);
        case 'testonly':
          _scalar(rule, 'testonly', variable);
        case 'depfile':
        case 'pool':
          // The sandbox declares every input; pools are a scheduling matter.
          break;
        case 'data':
          // `data = outputs` (the validation layers' JSON manifest): the
          // outputs are the action's files already, which a dependent
          // carries; anything else is not converted.
          final List<GnValue>? data = variable.unconditionalItems;
          final List<GnValue>? outputs = target.variables['outputs']?.unconditionalItems;
          if (data == null || outputs == null || !data.every(outputs.contains)) {
            throw GnError(
              variable.assignments.first.location,
              'action variable data is converted only as a subset of the outputs',
            );
          }
        case 'data_deps' || 'response_file_contents' || 'metadata' || 'assert_no_deps':
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

  /// An action's `deps`: labels, except that one with a toolchain the
  /// mapping knows as a platform ([toolchainPlatforms]: the validation
  /// layer's `($apilevel26_toolchain)`) is a `platform_deps` entry, built
  /// for that platform by the rule's transition, with the toolchain's
  /// directory of the build directory on record (`platform_build_dir`),
  /// where its outputs sit; one action builds for one such platform.
  void _actionDepsInto(_Rule rule, GnVariable variable, GnTarget target) {
    _forEachItem(variable, into: rule.list('deps'), (_Element e) {
      final String gnLabel = _string(e);
      final int paren = gnLabel.indexOf('(');
      final String toolchain = paren > 0 && gnLabel.endsWith(')')
          ? gnLabel.substring(paren + 1, gnLabel.length - 1)
          : '';
      final String? platform = toolchainPlatforms[toolchain];
      if (platform == null) {
        final String label = bazelLabel(
          gnLabel,
          package: gnPackage,
          location: e.assignment.location,
        );
        rule.list('deps').addUnique(e.condition, _item(_localLabel(label), e));
        return;
      }
      final platformText = '"${_localLabel(platform)}"';
      final String? before = rule.scalars['platform'];
      if (before != null && before != platformText) {
        throw GnError(
          e.assignment.location,
          'the deps of ${target.name} name two toolchains ($before, $platformText); one platform per action',
        );
      }
      rule.scalars['platform'] = platformText;
      rule.scalars['platform_build_dir'] = '"${toolchainDirectories[toolchain]!}"';
      final String label = bazelLabel(
        _withoutToolchain(gnLabel),
        package: gnPackage,
        location: e.assignment.location,
      );
      rule.list('platform_deps').addUnique(e.condition, _item(_localLabel(label), e));
    });
  }

  /// An action's `sources` or `inputs` into [attribute]: files, the outputs
  /// of another target (`sources += get_target_outputs(":gen")`) as the
  /// target itself, and a file of the build directory (`inputs = [
  /// "$root_build_dir/libflutter.so" ]`) as its path under it in
  /// `build_inputs`, for the rule to find among what the deps place there.
  void _actionFilesInto(_Rule rule, String attribute, GnVariable variable) {
    _forEachItem(variable, into: rule.list(attribute), (_Element e) {
      if (e.value case GnTargetOutputsValue(:final String label, :final List<String> patterns)) {
        if (patterns.isNotEmpty) {
          throw GnError(e.assignment.location, 'filtered outputs of $label in ${variable.name}');
        }
        rule
            .list(attribute)
            .addUnique(
              e.condition,
              _item(
                _localLabel(bazelLabel(label, package: gnPackage, location: e.assignment.location)),
                e,
              ),
            );
        return;
      }
      for (final _Element element in _enumeratedElements(e)) {
        final String raw = _rawString(element);
        final String path = raw.contains(rebasedPathMarker) ? _unmarked(raw) : _string(element);
        if (path.contains(rebasedPathMarker)) {
          throw GnError(e.assignment.location, 'a rebased path inside a file name: $raw');
        }
        if (path.startsWith('$buildDirRoot/')) {
          rule
              .list('build_inputs')
              .addUnique(
                element.condition,
                _item(path.substring(buildDirRoot.length + 1), element),
              );
          continue;
        }
        rule
            .list(attribute)
            .addUnique(element.condition, _item(_filePath(path, e.assignment.location), element));
      }
    });
  }

  /// An action's outputs. GN requires them under the build directory: one
  /// under `$target_gen_dir` is `outputs`, relative to the package, where
  /// the rule declares it; one elsewhere under the build directory (the
  /// embedding's jars at its root) is `build_outputs`, as its path under
  /// the build directory. A name around an enumerated variable
  /// (`flutter_embedding_$flutter_runtime_mode.jar`) is one per value.
  void _outputsInto(
    _Rule rule,
    GnVariable variable,
    GnTarget target, {
    String attribute = 'outputs',
  }) {
    final genDir = '$genDirRoot${gnPackage.substring(1)}/';
    _forEachItem(variable, into: rule.list(attribute), (_Element e) {
      for (final _Element element in _enumeratedElements(e)) {
        // A path around a constant (the Maven tree's, with the engine
        // version in it): an expression, its first literal part placing it.
        if (_isConstantString(element.value)) {
          final expanded = element.value as GnExpandedString;
          final GnValue first = expanded.parts.first;
          final String head = first is GnStringValue ? first.value : '';
          final String? under = head.startsWith(genDir)
              ? genDir
              : head.startsWith('$buildDirRoot/')
              ? '$buildDirRoot/'
              : null;
          if (under == null) {
            throw GnError(
              e.assignment.location,
              'output $expanded of ${target.name} is neither under its target_gen_dir nor under the build directory',
            );
          }
          final stripped = GnExpandedString(<GnValue>[
            GnStringValue(head.substring(under.length)),
            ...expanded.parts.sublist(1),
          ]);
          rule
              .list(under == genDir ? attribute : 'build_outputs')
              .addUnique(
                element.condition,
                _item(
                  _constantExpression(stripped, element),
                  element,
                  quoted: false,
                  expression: true,
                ),
              );
          continue;
        }
        final String path = _string(element);
        if (path.startsWith(genDir)) {
          // A directory output (the javadoc tree) is declared as one.
          final String under = path.substring(genDir.length);
          final bool directory =
              actionDirectoryOutputs['$gnPackage:${target.name}']?.contains(under) ?? false;
          rule
              .list(directory ? 'output_dirs' : attribute)
              .addUnique(element.condition, _item(under, element));
        } else if (path.startsWith('$buildDirRoot/')) {
          rule
              .list('build_outputs')
              .addUnique(
                element.condition,
                _item(path.substring(buildDirRoot.length + 1), element),
              );
        } else {
          throw GnError(
            e.assignment.location,
            'output $path of ${target.name} is neither under its target_gen_dir nor under the build directory',
          );
        }
      }
    });
  }

  /// [element] with a value around an enumerated variable spelled out, one
  /// element per value under that value's condition ([_enumerated]); any
  /// other element is itself.
  List<_Element> _enumeratedElements(_Element element) {
    return <_Element>[
      for (final GnScalarCase scalarCase in _enumerated(<GnScalarCase>[
        GnScalarCase(element.condition, element.value, element.assignment),
      ], element.assignment.location))
        _Element(scalarCase.condition, scalarCase.value, element.assignment, element.comments),
    ];
  }

  /// An action's `args`, with each rebased path replaced by the rule's token
  /// for it, and an argument around an enumerated variable
  /// (`flutter_runtime_mode`, or `"--mode=$flutter_runtime_mode"`) spelled
  /// out as one argument per value under that value's condition
  /// ([_enumeratedElements]).
  void _argsInto(_Rule rule, GnVariable variable, GnTarget target) {
    final _ListAttribute attribute = rule.list('args');
    // The files named already, under any condition (the whole file's
    // condition, which the target's platform carries, goes at the layout).
    final declared = <String>{
      for (final String list in <String>['srcs', 'inputs', 'tools'])
        for (final _Item item in rule.list(list).items) item.text,
    };
    _forEachItem(variable, into: attribute, (_Element e) {
      // The outputs of a target (`args += rebase_path(sources,
      // root_build_dir)` with the generated sources among them): the
      // target's file, which must be one.
      if (e.value case GnTargetOutputPathsValue(:final String label, base: '')) {
        final String local = _localLabel(
          bazelLabel(label, package: gnPackage, location: e.assignment.location),
        );
        attribute.add(e.condition, _item('\$(execpath $local)', e));
        return;
      }
      for (final _Element element in _enumeratedElements(e)) {
        // A bare variable the Bazel side keeps as a constant (version.gni's
        // engine_version, content_hash): the constant, as an expression.
        if (element.value case GnReference(:final String name)
            when referenceConstants.containsKey(name)) {
          attribute.add(
            element.condition,
            _item(_constant(name, element), element, quoted: false, expression: true),
          );
          continue;
        }
        // An argument around a constant (a Maven path with the engine
        // version in it): an expression. A rebased path among its parts
        // must be a build-directory path, whose token wraps the constants.
        if (_isConstantString(element.value)) {
          final expanded = element.value as GnExpandedString;
          final parts = <GnValue>[];
          var inPath = false;
          for (final GnValue part in expanded.parts) {
            if (part is! GnStringValue) {
              parts.add(part);
              continue;
            }
            final out = StringBuffer();
            final List<String> pieces = part.value.split(rebasedPathMarker);
            for (var i = 0; i < pieces.length; i++) {
              if (i > 0) {
                inPath = !inPath;
                if (inPath) {
                  if (pieces[i] == buildDirRoot) {
                    out.write(r'$(built .');
                    continue;
                  }
                  if (!pieces[i].startsWith('$buildDirRoot/')) {
                    throw GnError(
                      e.assignment.location,
                      'a rebased path around a constant must be in the build directory: $expanded',
                    );
                  }
                  out.write('\$(built ${pieces[i].substring(buildDirRoot.length + 1)}');
                  continue;
                }
                out.write(')');
              }
              out.write(pieces[i]);
            }
            parts.add(GnStringValue(out.toString()));
          }
          if (inPath) {
            throw GnError(e.assignment.location, 'unbalanced rebased path in argument $expanded');
          }
          attribute.add(
            element.condition,
            _item(
              _constantExpression(GnExpandedString(parts), element),
              element,
              quoted: false,
              expression: true,
            ),
          );
          continue;
        }
        final String text = _rawString(element);
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
        attribute.add(element.condition, _item(out.toString(), element));
      }
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
    if (path == buildDirRoot) {
      // The build directory itself (`rebase_path(root_build_dir,
      // root_build_dir)`, a script's output directory): where the action's
      // build outputs are declared.
      return r'$(built .)';
    }
    if (path.startsWith('$buildDirRoot/')) {
      // A file of the build directory: one of the action's own build
      // outputs, or one the deps place there, which the rule finds by the
      // path.
      return '\$(built ${path.substring(buildDirRoot.length + 1)})';
    }
    // A directory may be written with a trailing slash (`"$dir/layers/"`).
    final String bare = path.length > 2 && path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    final String file = _filePath(bare, location);
    final bool isDirectory = switch (tree) {
      final GnSourceTree t => FileSystemEntity.isDirectorySync(t.resolve(bare)),
      null => !declared.contains(file),
    };
    if (isDirectory) {
      // A directory of another repository (the embedding's dependency jars
      // in @android_embedding_dependencies): its label, which the rule
      // resolves to the repository's place in the execution root.
      if (file.startsWith('@')) {
        return '\$(src $file)';
      }
      // The directory relative to the output repository's root: as the
      // layout places it, or, for a synced tree's repository whose files
      // the label table names (`@vulkan_validation_layers//:layers`), as
      // the label's path.
      final ownRepository = '${layout.repository}//:';
      final String? relative;
      if (!file.startsWith('@') && !file.startsWith('//')) {
        // Relative to this package.
        relative = file == '.'
            ? package.package
            : package.package.isEmpty
            ? file
            : '${package.package}/$file';
      } else if (file.startsWith(ownRepository) && layout.repository.isNotEmpty) {
        relative = file.substring(ownRepository.length);
      } else {
        relative = layout.relativePath(bare);
      }
      if (relative == null) {
        throw GnError(location, 'directory $path is outside the output repository');
      }
      return '\$(src $relative)';
    }
    if (!declared.contains(file)) {
      // A program the script runs (javac) is a tool, with what it loads.
      final List<String>? runtime = toolRuntimes[file];
      final list = runtime == null ? 'inputs' : 'tools';
      rule.list(list).addUnique(Condition.always, _Item(file));
      for (final String label in runtime ?? const <String>[]) {
        rule.list(list).addUnique(Condition.always, _Item(label));
      }
      declared.add(file);
    }
    final label = file.startsWith('//') || file.startsWith('@') ? file : ':$file';
    return '\$(execpath $label)';
  }

  /// The engine's test executables are testonly and named `*tests`
  /// (`fml_unittests`, `display_list_rendertests`); testonly benchmarks and
  /// tools stay binaries -- but for the benchmarks run_tests.py runs
  /// ([benchmarkRuns]), which are tests tagged `benchmark` and `manual`.
  static bool _isTest(GnTarget target) => isTestTarget(target);

  /// An `executable()` with `output_extension = "js"`: a link in a wasm
  /// toolchain (CanvasKit's), converted through [wasmExecutableRule]'s
  /// mapping.
  static bool _isWasmExecutable(GnTarget target) {
    final List<GnValue>? items = target.variables['output_extension']?.unconditionalItems;
    return items != null &&
        items.length == 1 &&
        items.single is GnStringValue &&
        (items.single as GnStringValue).value == 'js';
  }

  /// A known template becomes a call of its Bazel macro, with the arguments
  /// the mapping names translated by kind (see [TemplateMapping.arguments]).
  void _convertTemplate(GnTarget target, TemplateMapping template) {
    _use(template.bzl, template.symbol);
    final rule = _Rule(template.symbol, target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      final TemplateArgument? argument = template.arguments[variable.name];
      if (argument == null) {
        // A variable the block itself read, and the mapping does not name,
        // is the block's helper (`exe = ""`, then `"gen_snapshot$exe"`); one
        // nothing read must be an argument the mapping lacks.
        if (_ignoredVariables.contains(variable.name) ||
            target.readVariables.contains(variable.name)) {
          continue;
        }
        throw GnError(
          variable.assignments.first.location,
          '${target.rule}() argument ${variable.name} is not handled by the ${template.symbol} macro mapping',
        );
      }
      switch (argument.kind) {
        case TemplateArgumentKind.files:
          _filesInto(rule.list(argument.attribute), _withoutTargetOutputs(variable));
          final Map<String, List<String>> targets = _targetOutputs(variable);
          if (targets.isNotEmpty) {
            rule.scalars['${argument.attribute}_targets'] = _dictText(targets);
          }
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
        case TemplateArgumentKind.file:
          final String? file = _singleString(variable);
          if (file == null) {
            throw GnError(variable.assignments.first.location, '${variable.name} has no value');
          }
          rule.scalars[argument.attribute] =
              '"${_filePath(file, variable.assignments.first.location)}"';
        case TemplateArgumentKind.scalar:
          _scalar(rule, argument.attribute, variable);
        case TemplateArgumentKind.strings:
          _stringsInto(rule.list(argument.attribute), variable);
        case TemplateArgumentKind.pathStrings:
          _pathStringsInto(rule, argument, variable);
        case TemplateArgumentKind.scope:
          rule.scalars[argument.attribute] = _scopeText(variable);
        case TemplateArgumentKind.pathString:
          final String? text = _singleString(variable);
          if (text == null) {
            throw GnError(variable.assignments.first.location, '${variable.name} has no value');
          }
          rule.scalars[argument.attribute] = _starlarkString(
            _withPathTokens(text, variable.assignments.first.location, rule, target),
          );
        case TemplateArgumentKind.ignored:
          break;
        case TemplateArgumentKind.archiveEntries:
          final String entries = _archiveEntriesText(variable, target, rule);
          if (entries.isNotEmpty) {
            rule.scalars[argument.attribute] = entries;
          }
        case TemplateArgumentKind.package:
          final String? directory = _singleString(variable);
          if (directory == null) {
            throw GnError(variable.assignments.first.location, '${variable.name} has no value');
          }
          rule.scalars[argument.attribute] =
              '"${_packageLabel(directory, variable.assignments.first.location)}"';
        case TemplateArgumentKind.sourceDirectory:
          _sourceDirectoryInto(rule, argument, variable);
        case TemplateArgumentKind.buildPath:
          final String? path = _singleString(variable);
          if (path == null) {
            throw GnError(variable.assignments.first.location, '${variable.name} has no value');
          }
          if (!path.startsWith('$buildDirRoot/') && !path.startsWith('$genDirRoot/')) {
            throw GnError(
              variable.assignments.first.location,
              '${variable.name} is not a path under the build directory',
            );
          }
          rule.scalars[argument.attribute] = _starlarkString(
            path
                .replaceFirst('$genDirRoot/', r'$root_gen_dir/')
                .replaceFirst('$buildDirRoot/', r'$root_out_dir/'),
          );
      }
      // An argument the macro applies only under a predicate (the GLES
      // exclusions, under impeller_enable_opengles): items under a condition
      // that predicate implies are unconditional there, which keeps the
      // list a list for the macro to inspect in Starlark.
      final String? appliedUnder = argument.appliedUnder;
      final _ListAttribute? list = rule.lists[argument.attribute];
      if (appliedUnder != null && list != null) {
        _dropImplied(list, ConditionVariable(appliedUnder));
      }
    }
    // What GN discovers after the fact (templateAttributeOverrides).
    templateAttributeOverrides['$gnPackage:${target.name}']?.forEach((
      String attribute,
      String text,
    ) {
      rule.scalars[attribute] = text;
    });
    rules.add(rule);
  }

  /// A zip_bundle's `files` -- `{ source, destination }` scopes -- as the
  /// macro's dictionary of destination to the label of the file placed
  /// there: the unconditional entries as a literal, those under a condition
  /// in a `select()` joined to it with `|` (Bazel merges the dictionaries;
  /// a condition that does not hold adds nothing). A source under the build
  /// directory is the output of a target ([_buildOutputLabel]); any other
  /// is a source file.
  String _archiveEntriesText(GnVariable variable, GnTarget target, _Rule rule) {
    // An archive of one directory of the build directory (the web SDK's:
    // every entry an output under flutter_web_sdk at its path below it,
    // `rebase_path(source, "$root_build_dir/flutter_web_sdk")`) is one
    // build_directory_tree over the bundle's deps, whose closure places the
    // files -- GN's own source of the list.
    final String? under = _archiveDirectory(variable);
    if (under != null) {
      _use(templateMappings['zip_bundle']!.bzl, 'build_directory_tree');
      final name = '${target.name}_tree';
      final tree = _Rule('build_directory_tree', name, <String>[
        '# `${variable.name}`: what the deps place under $under in the build directory, at',
        '# its path below it.',
      ])..scalars['under'] = _starlarkString(under);
      final GnVariable? deps = target.variables['deps'];
      if (deps != null) {
        _labelsInto(tree.list('srcs'), deps, target);
      }
      rules.add(tree);
      rule.list('trees').add(Condition.always, _Item(':$name'));
      return '';
    }
    final always = <String, String>{};
    final conditional = <Condition, Map<String, String>>{};
    // The entries whose source is an output of the build, with its path
    // under the build directory (the rule's `sources`: where ninja's build
    // of the archive leaves the file, and an install lays it).
    final alwaysSources = <String, String>{};
    final conditionalSources = <Condition, Map<String, String>>{};
    for (final GnListItem item in variable.liveItems) {
      final GnLocation location = item.assignment.location;
      final GnValue value = item.value;
      if (value is! GnScopeValue) {
        throw GnError(
          location,
          'an entry of ${variable.name} is $value, not a { source, destination } scope',
        );
      }
      // Every output of a copy at its build-directory path (the GTK bundle:
      // `foreach(source, get_target_outputs(":publish_headers_linux"))` with
      // `destination = rebase_path(source, root_build_dir)`): a zip_tree of
      // the copy's files, rooted so that each lands where the copy's output
      // pattern puts it.
      final GnValue? sourceValue = value.variables['source']?.unconditionalItems?.singleOrNull;
      final GnValue? destinationValue =
          value.variables['destination']?.unconditionalItems?.singleOrNull;
      // The one output of an action of this file at a destination of its
      // own (the javadoc tree at the archive's root: `source =
      // javadoc_dir[0]`, `destination = "/"`): the action, whose file it
      // is; the file's build-directory path from the action's outputs. (A
      // copy's outputs, one per source, are the tree below.)
      if (sourceValue is GnTargetOutputsValue &&
          sourceValue.patterns.isEmpty &&
          destinationValue is GnStringValue &&
          _singleActionOutput(sourceValue.label) != null) {
        final String gnLabel = sourceValue.label;
        final String output = _singleActionOutput(gnLabel)!;
        final String at = destinationValue.value;
        final Map<String, String> entries = item.condition == Condition.always
            ? always
            : conditional.putIfAbsent(item.condition, () => <String, String>{});
        if (entries.containsKey(at)) {
          throw GnError(location, 'two entries of ${variable.name} go to $at');
        }
        entries[at] = _localLabel(bazelLabel(gnLabel, package: gnPackage, location: location));
        final Map<String, String> sources = item.condition == Condition.always
            ? alwaysSources
            : conditionalSources.putIfAbsent(item.condition, () => <String, String>{});
        sources[at] = _buildDirectoryPath(output, location);
        continue;
      }
      if (sourceValue is GnTargetOutputsValue || destinationValue is GnTargetOutputPathsValue) {
        if (sourceValue is! GnTargetOutputsValue ||
            destinationValue is! GnTargetOutputPathsValue ||
            sourceValue.label != destinationValue.label) {
          throw GnError(
            location,
            "an entry over a target's outputs must place each at its build-directory path "
            '(destination = rebase_path(source, root_build_dir))',
          );
        }
        _use(templateMappings['zip_bundle']!.bzl, 'zip_tree');
        final String gnLabel = sourceValue.label;
        final name = '${target.name}_${gnLabel.substring(gnLabel.indexOf(':') + 1)}';
        final tree = _Rule('zip_tree', name, const <String>[])
          ..scalars['root'] = _starlarkString(_copyTreeRoot(gnLabel, location))
          ..scalars['destination'] = '""';
        tree
            .list('srcs')
            .add(
              Condition.always,
              _Item(_localLabel(bazelLabel(gnLabel, package: gnPackage, location: location))),
            );
        rules.add(tree);
        rule.list('trees').add(item.condition, _Item(':$name'));
        continue;
      }
      // A destination (or source) that varies with a condition -- GN's
      // `"${path_prefix}platform_strong.dill"` with the prefix set under the
      // release mode -- is an entry per case, each under its condition.
      for (final GnScalarCase source in _scopeMember(value, 'source', location)) {
        for (final GnScalarCase destination in _scopeMember(value, 'destination', location)) {
          final Condition condition = item.condition
              .and(source.condition)
              .and(destination.condition);
          if (condition == Condition.never) {
            continue;
          }
          // A source written as `rebase_path("$root_out_dir/...")` (the Android
          // shell's archive of the host gen_snapshot) is the path itself.
          final String path = _unmarked((source.value as GnStringValue).value);
          final String at = (destination.value as GnStringValue).value;
          // A directory: a zip_tree of its files, named after the bundle
          // and the destination, in the bundle's `trees`.
          final DirectorySource? directory =
              directorySources[path.startsWith('//')
                  ? path
                  : _normalized('$gnPackage/$path', location)];
          if (directory != null) {
            _use(templateMappings['zip_bundle']!.bzl, 'zip_tree');
            final name = '${target.name}_${at.isEmpty ? 'tree' : at.replaceAll('/', '_')}';
            final tree = _Rule('zip_tree', name, const <String>[])
              ..scalars['root'] = _starlarkString(directory.root)
              ..scalars['destination'] = _starlarkString(at);
            tree.list('srcs').add(Condition.always, _Item(_localLabel(directory.label)));
            rules.add(tree);
            rule.list('trees').add(condition, _Item(':$name'));
            continue;
          }
          final bool built = path.startsWith('$buildDirRoot/') || path.startsWith('$genDirRoot/');
          final String label = built
              ? _buildOutputLabel(path, target, location)
              : _filePath(path, location);
          final Map<String, String> entries = condition == Condition.always
              ? always
              : conditional.putIfAbsent(condition, () => <String, String>{});
          if (entries.containsKey(at)) {
            throw GnError(location, 'two entries of ${variable.name} go to $at');
          }
          entries[at] = label;
          if (built) {
            final Map<String, String> sources = condition == Condition.always
                ? alwaysSources
                : conditionalSources.putIfAbsent(condition, () => <String, String>{});
            sources[at] = _buildDirectoryPath(_unmarked(path), location);
          }
        }
      }
    }
    if (always.isEmpty && conditional.isEmpty) {
      return '';
    }
    if (alwaysSources.isNotEmpty || conditionalSources.isNotEmpty) {
      rule.scalars['sources'] = _entryDictText(alwaysSources, conditionalSources, variable, rule);
    }
    return _entryDictText(always, conditional, variable, rule);
  }

  /// A dictionary attribute of entries by destination: the unconditional
  /// ones as a literal, those under a condition in a `select()` joined to
  /// it with `|` (Bazel merges the dictionaries; a condition that does not
  /// hold adds nothing).
  String _entryDictText(
    Map<String, String> always,
    Map<Condition, Map<String, String>> conditional,
    GnVariable variable,
    _Rule rule,
  ) {
    // One select() per set of settings: entries under a setting and entries
    // under its negation (the patched SDK's two layouts, by the release
    // mode) are the two branches of one.
    final selects = <String, _EntrySelect>{};
    for (final MapEntry<Condition, Map<String, String>> group in conditional.entries) {
      final _SelectKeys keys = _selectKeys(
        group.key,
        rule,
        variable.assignments.first.location,
        () => 'of an entry of ${variable.name}',
      );
      final _EntrySelect entry = selects.putIfAbsent(
        keys.settings.join(' '),
        () => _EntrySelect(keys.settings),
      );
      (keys.negated ? entry.otherwise : entry.held).addAll(group.value);
    }
    final parts = <String>[if (always.isNotEmpty || selects.isEmpty) _stringDictText(always)];
    for (final _EntrySelect select in selects.values) {
      final out = StringBuffer('select({\n');
      for (final String setting in select.settings) {
        out.write(
          '        ${_starlarkString(setting)}: ${_stringDictText(select.held, indent: 8)},\n',
        );
      }
      out.write(
        '        "//conditions:default": ${_stringDictText(select.otherwise, indent: 8)},\n',
      );
      out.write('    })');
      parts.add(out.toString());
    }
    return parts.join(' | ');
  }

  /// The directory of the build directory an archive's entries all come
  /// from, at their paths below it -- each entry's destination being
  /// `rebase_path(source, "$root_build_dir/<dir>")` of a source under it,
  /// a target's outputs (symbolic, with that base) or a literal path -- or
  /// null when the entries are not all of that form.
  String? _archiveDirectory(GnVariable variable) {
    String? under;
    var any = false;
    for (final GnListItem item in variable.liveItems) {
      final GnValue value = item.value;
      if (value is! GnScopeValue) {
        return null;
      }
      final GnValue? source = value.variables['source']?.unconditionalItems?.singleOrNull;
      final GnValue? destination = value.variables['destination']?.unconditionalItems?.singleOrNull;
      String base;
      switch ((source, destination)) {
        case (
              GnTargetOutputsValue(label: final String from) ||
                  GnTargetOutputPathsValue(label: final String from, base: ''),
              GnTargetOutputPathsValue(label: final String to, base: final String b),
            )
            when from == to && b.isNotEmpty:
          base = b;
        case (GnStringValue(value: final String path), GnStringValue(value: final String at)):
          final String absolute = _unmarked(path);
          const int start = buildDirRoot.length + 1;
          final int end = absolute.length - at.length - 1;
          if (!absolute.startsWith('$buildDirRoot/') ||
              at.isEmpty ||
              !absolute.endsWith('/$at') ||
              end <= start ||
              buildOutputLabels.containsKey(absolute)) {
            // Not under a directory of the build directory (a file at its
            // root, artifacts.zip's flutter_tester), or a named output
            // (the host toolchain's gen_snapshot under clang_x64/): an entry
            // of its own.
            return null;
          }
          base = absolute.substring(start, end);
        default:
          return null;
      }
      if (under != null && under != base) {
        return null;
      }
      under = base;
      any = true;
    }
    return any ? under : null;
  }

  /// The zip_tree `root` for the outputs of the copy [gnLabel]: a copy whose
  /// outputs are `$root_out_dir/<dir>/{{source_file_part}}` places each
  /// source at `<dir>/<name>` in the build directory, and its Bazel files
  /// are the sources themselves (gn_copy), so the root is the sources'
  /// directory above `<dir>` -- the same for every source, or the shape is
  /// not one a tree can say.
  String _copyTreeRoot(String gnLabel, GnLocation location) {
    final int colon = gnLabel.indexOf(':');
    final String directory = gnLabel.substring(0, colon);
    final String name = gnLabel.substring(colon + 1);
    final GnTarget? copy = directory == gnPackage
        ? localTargets[name]
        : forwarded.targetOf(gnLabel);
    if (copy == null || copy.rule != 'copy') {
      throw GnError(location, '$gnLabel is not a copy() the converter can read');
    }
    final List<GnValue>? outputs = copy.variables['outputs']?.unconditionalItems;
    final List<GnValue>? sources = copy.variables['sources']?.unconditionalItems;
    const prefix = '$buildDirRoot/';
    const suffix = '/{{source_file_part}}';
    final GnValue? output = outputs?.singleOrNull;
    // `<dir>` between the prefix and the suffix, which share no character:
    // a copy into the build root itself has no directory a tree could stand
    // for.
    final String? under =
        output is GnStringValue &&
            output.value.startsWith(prefix) &&
            output.value.endsWith(suffix) &&
            output.value.length > prefix.length + suffix.length
        ? output.value.substring(prefix.length, output.value.length - suffix.length)
        : null;
    if (under == null || sources == null) {
      throw GnError(
        location,
        'the outputs of $gnLabel are not `\$root_out_dir/<dir>/{{source_file_part}}` over its sources',
      );
    }
    String? root;
    for (final GnValue source in sources) {
      if (source is! GnStringValue) {
        throw GnError(location, 'a source of $gnLabel is not a path');
      }
      final String absolute = source.value.startsWith('//')
          ? source.value
          : _normalized('$directory/${source.value}', location);
      final String? relative = layout.relativePath(absolute);
      final tail = '/$under/${p.basename(absolute)}';
      if (relative == null || !relative.endsWith(tail)) {
        throw GnError(
          location,
          '${source.value} of $gnLabel does not lie under a `$under` directory, as its output does',
        );
      }
      final String candidate = relative.substring(0, relative.length - tail.length);
      if (root != null && root != candidate) {
        throw GnError(
          location,
          'the sources of $gnLabel lie under different roots: $root, $candidate',
        );
      }
      root = candidate;
    }
    return root ?? '';
  }

  /// The string [member] of [scope] (`source`, `destination`): its one
  /// value, or one per condition it takes a value under.
  List<GnScalarCase> _scopeMember(GnScopeValue scope, String member, GnLocation location) {
    final GnVariable? variable = scope.variables[member];
    if (variable == null || variable.isList) {
      throw GnError(location, 'the scope has no $member string');
    }
    final List<GnScalarCase> cases = _enumerated(variable.cases(location), location);
    if (cases.isEmpty || cases.any((GnScalarCase c) => c.value is! GnStringValue)) {
      throw GnError(location, "the scope's $member is not a string");
    }
    return cases;
  }

  /// Whether `name == "value"` can hold under the assumptions: the value
  /// itself is not assumed otherwise, and for an OS name or a platform name
  /// neither is the OS predicate it asserts (nor, for a platform name, the
  /// CPU).
  bool _assumptionsAllow(String name, String value) {
    final GnValue? assumed = assumptions[name];
    if (assumed is GnStringValue) {
      return assumed.value == value;
    }
    String? osPredicate;
    String? cpu;
    if (name == 'target_os' || name == 'current_os') {
      osPredicate = osNamePredicates[value];
    } else if (name == 'full_target_platform_name') {
      final ({String osPredicate, String cpu})? parts = targetPlatformParts(value);
      osPredicate = parts?.osPredicate;
      cpu = parts?.cpu;
    } else if (name == 'target_cpu') {
      cpu = value;
    }
    if (osPredicate != null && assumptions[osPredicate] == const GnBoolValue(false)) {
      return false;
    }
    if (cpu != null) {
      final GnValue? assumedCpu = assumptions['target_cpu'];
      if (assumedCpu is GnStringValue && assumedCpu.value != cpu) {
        return false;
      }
    }
    return true;
  }

  /// [cases] with every string around a reference to a variable whose
  /// values the mapping enumerates (`flutter_runtime_mode`:
  /// [comparisonSettings]) spelled out, one case per value under the
  /// case's condition and that value's -- `"linux-x64-$flutter_runtime_mode"`
  /// under `flutter_runtime_mode != "debug"` is three cases, one per other
  /// mode -- since a `select()` cannot nest one. Other strings stay as they
  /// are.
  List<GnScalarCase> _enumerated(List<GnScalarCase> cases, GnLocation location) {
    final out = <GnScalarCase>[];
    for (final scalarCase in cases) {
      // The bare variable (`flutter_runtime_mode` as an argument) is the
      // string of just its expansion.
      final GnValue value = switch (scalarCase.value) {
        final GnReference reference when comparisonSettings.containsKey(reference.name) =>
          GnExpandedString(<GnValue>[reference]),
        final GnValue other => other,
      };
      if (value is! GnExpandedString) {
        out.add(scalarCase);
        continue;
      }
      // The enumerated variables among the references; a reference the
      // Bazel side keeps as a constant (engine_version in the Maven tree's
      // paths) stays in the string, for an expression to spell out.
      final names = <String>{
        for (final GnValue part in value.parts)
          if (part is GnReference && comparisonSettings.containsKey(part.name)) part.name,
      };
      final bool others = value.parts.any(
        (GnValue part) =>
            part is GnReference &&
            !comparisonSettings.containsKey(part.name) &&
            !referenceConstants.containsKey(part.name),
      );
      if (names.isEmpty || others) {
        out.add(scalarCase);
        continue;
      }
      // One case per combination of the variables' values -- those the
      // assumptions allow: a platform name whose OS or CPU is assumed away
      // (`wasm-wasm` with target_cpu x64) is no case.
      var combinations = <Map<String, String>>[<String, String>{}];
      for (final name in names) {
        combinations = <Map<String, String>>[
          for (final partial in combinations)
            for (final String option in enumeratedValues[name] ?? comparisonSettings[name]!.keys)
              if (_assumptionsAllow(name, option)) <String, String>{...partial, name: option},
        ];
      }
      for (final bound in combinations) {
        Condition condition = scalarCase.condition;
        for (final MapEntry<String, String> b in bound.entries) {
          condition = condition.and(ConditionComparison(b.key, true, b.value));
        }
        if (condition == Condition.never || _targetCondition.and(condition) == Condition.never) {
          continue;
        }
        final parts = <GnValue>[];
        for (final GnValue part in value.parts) {
          final GnValue piece = switch (part) {
            GnReference(:final String name) when bound.containsKey(name) => GnStringValue(
              bound[name]!,
            ),
            _ => part,
          };
          if (piece is GnStringValue && parts.isNotEmpty && parts.last is GnStringValue) {
            parts[parts.length - 1] = GnStringValue(
              (parts.last as GnStringValue).value + piece.value,
            );
          } else {
            parts.add(piece);
          }
        }
        final GnValue text = parts.length == 1 && parts.single is GnStringValue
            ? parts.single
            : GnExpandedString(List<GnValue>.unmodifiable(parts));
        out.add(GnScalarCase(condition, text, scalarCase.assignment));
      }
    }
    return out;
  }

  /// Whether [value] is a string around references the Bazel side keeps as
  /// constants (version.gni's engine_version, content_hash) and nothing
  /// else: the Maven tree's paths, which an expression spells out.
  static bool _isConstantString(GnValue value) =>
      value is GnExpandedString &&
      value.parts.every(
        (GnValue part) =>
            part is GnStringValue ||
            part is GnReference && referenceConstants.containsKey(part.name),
      );

  /// A string around constants as a Starlark expression: its literal parts
  /// quoted, the constants as themselves, joined with `+`; a path token
  /// (`$(built ...)`) opened in one literal part and closed in a later one
  /// wraps the constants between ([_argsInto]'s rebased paths).
  String _constantExpression(GnExpandedString value, _Element element, {bool quoted = true}) {
    final pieces = <String>[];
    for (final GnValue part in value.parts) {
      switch (part) {
        case GnStringValue(value: final String text):
          if (text.isNotEmpty) {
            pieces.add(quoted ? _starlarkString(text) : text);
          }
        case GnReference(:final String name):
          pieces.add(_constant(name, element));
        default:
          throw GnError(element.assignment.location, 'unexpected $part in a string');
      }
    }
    return pieces.join(' + ');
  }

  /// The one plain output of an action of this file (`:gen_android_javadoc`'s
  /// javadoc tree), or null for anything else: a target of another file, a
  /// copy, an action of several outputs or of an output pattern.
  String? _singleActionOutput(String label) {
    final String gnLabel = _gnLabel(label);
    final int colon = gnLabel.lastIndexOf(':');
    if (gnLabel.substring(0, colon) != gnPackage) {
      return null;
    }
    final GnTarget? producer = localTargets[gnLabel.substring(colon + 1)];
    if (producer == null || producer.rule != 'action') {
      return null;
    }
    final List<GnValue> outputs =
        producer.variables['outputs']?.liveItems.map((GnListItem i) => i.value).toList() ??
        const <GnValue>[];
    if (outputs.length != 1) {
      return null;
    }
    return switch (outputs.single) {
      GnStringValue(:final String value) when !value.contains('{{') => value,
      _ => null,
    };
  }

  /// The label of the target that produces the build output [path]
  /// (`//@out/font-subset`, `//@gen/flutter/lib/snapshot/isolate_snapshot.bin`):
  /// a target of this file, or of another file that [bundle]'s `deps` name,
  /// read through the resolver; else the table of outputs the converter
  /// cannot see produced ([buildOutputLabels]: the wrapped and hand-written
  /// trees).
  String _buildOutputLabel(String path, GnTarget bundle, GnLocation location) {
    String? label = _buildOutputs(localTargets.values.toList(), gnPackage)[path];
    if (label == null) {
      // The bundle's deps in other files, and what a group among them
      // forwards (`//flutter/shell/testing` is a group over flutter_tester).
      final pending = <String>[
        for (final GnListItem dep in bundle.variables['deps']?.liveItems ?? const <GnListItem>[])
          if (dep.value is GnStringValue) _gnLabel((dep.value as GnStringValue).value),
      ];
      final seen = <String>{};
      while (pending.isNotEmpty && label == null) {
        final String gnLabel = pending.removeAt(0);
        final int colon = gnLabel.indexOf(':');
        if (colon < 0 || gnLabel.substring(0, colon) == gnPackage || !seen.add(gnLabel)) {
          continue;
        }
        final String directory = gnLabel.substring(0, colon);
        final GnTarget? target = forwarded.targetOf(gnLabel);
        if (target == null) {
          continue;
        }
        if (target.rule == 'group') {
          for (final name in <String>['deps', 'public_deps']) {
            for (final GnListItem dep
                in target.variables[name]?.liveItems ?? const <GnListItem>[]) {
              if (dep.value is GnStringValue) {
                pending.add(
                  absoluteGnLabel(
                    (dep.value as GnStringValue).value,
                    package: directory,
                    implicitName: true,
                  ),
                );
              }
            }
          }
          continue;
        }
        label = _buildOutputs(<GnTarget>[target], directory)[path];
      }
    }
    if (label != null) {
      return _localLabel(bazelLabel(label, package: gnPackage, location: location));
    }
    final String? known = buildOutputLabels[path];
    if (known != null) {
      return _localLabel(known);
    }
    final String spelled = path
        .replaceFirst('$genDirRoot/', r'$root_gen_dir/')
        .replaceFirst('$buildDirRoot/', r'$root_out_dir/');
    throw GnError(
      location,
      'no target of this file or of the deps of ${bundle.name} produces $spelled '
      '(buildOutputLabels in bazel_mapping.dart names the outputs of the wrapped trees)',
    );
  }

  /// The build outputs of [targets] (of the GN directory [directory]), each
  /// as the GN label of what produces it: an executable's file is its
  /// `output_name` or name, a shared library's `lib<name>.so`, a complete
  /// static library's `lib<name>.a` under its `obj/` directory, and a copy's
  /// or an action's its `outputs` -- the source itself for a copy that
  /// keeps the file as it is, the output file for one that renames or an
  /// action that generates. The host's file names: these files are the
  /// Linux host's.
  static Map<String, String> _buildOutputs(List<GnTarget> targets, String directory) {
    final outputs = <String, String>{};
    for (final target in targets) {
      final label = '$directory:${target.name}';
      String name() {
        final List<GnValue>? outputName = target.variables['output_name']?.unconditionalItems;
        return outputName != null && outputName.length == 1 && outputName.single is GnStringValue
            ? (outputName.single as GnStringValue).value
            : target.name;
      }

      switch (target.rule) {
        case 'executable':
          outputs['$buildDirRoot/${name()}'] = label;
        case 'shared_library':
          outputs['$buildDirRoot/lib${name()}.so'] = label;
        case 'static_library':
          final List<GnValue>? complete =
              target.variables['complete_static_lib']?.unconditionalItems;
          if (complete != null &&
              complete.length == 1 &&
              complete.single == const GnBoolValue(true)) {
            outputs['$buildDirRoot/obj${directory.substring(1)}/lib${name()}.a'] = label;
          }
        case 'copy' || 'action':
          // An action's outputs may be partly conditional (android_jar's
          // engine jar, named by the CPU, beside flutter.jar): the live
          // items, of which the plain strings are read below.
          final List<GnValue>? files = target.rule == 'action'
              ? target.variables['outputs']?.liveItems.map((GnListItem i) => i.value).toList()
              : target.variables['outputs']?.unconditionalItems;
          final List<GnValue>? sources = target.variables['sources']?.unconditionalItems;
          if (files == null) {
            break;
          }
          final genDir = '$genDirRoot${directory.substring(1)}/';
          for (var i = 0; i < files.length; i++) {
            final GnValue file = files[i];
            if (file is! GnStringValue || file.value.contains('{{')) {
              continue;
            }
            // A copy that keeps the file as it is (an output outside its own
            // gen dir: the artifact layout's) is the file: the copy itself
            // when it is the one file, else the source of that output. One
            // that renames under its gen dir, and an action, name the output
            // file.
            final String? source =
                sources != null && sources.length == files.length && sources[i] is GnStringValue
                ? (sources[i] as GnStringValue).value
                : null;
            if (file.value.startsWith(genDir)) {
              outputs[file.value] = '$directory:${file.value.substring(genDir.length)}';
            } else if (files.length == 1) {
              outputs[file.value] = label;
            } else if (target.rule == 'action' && file.value.startsWith('$buildDirRoot/')) {
              // One of an action's several build outputs (android_jar's
              // flutter.jar beside the engine's jar): the action, from which
              // an archive takes the file at the output's path
              // (zip_bundle's `sources`; gn_action's build_outputs).
              outputs[file.value] = label;
            } else if (target.rule == 'copy' && source != null) {
              outputs[file.value] = source.startsWith('//')
                  ? source.replaceFirst(RegExp(r'/(?=[^/]*$)'), ':')
                  : '$directory:$source';
            }
          }
      }
    }
    return outputs;
  }

  /// The label of the package at the GN directory [directory] (a source
  /// directory or its generated twin: `$root_gen_dir/flutter/lib/ui` names
  /// the package of `//flutter/lib/ui`), which must be one the layout knows.
  String _packageLabel(String directory, GnLocation location) {
    String absolute = directory.startsWith('//')
        ? directory
        : _normalized('$gnPackage/$directory', location);
    if (absolute == genDirRoot) {
      absolute = '//';
    } else if (absolute.startsWith('$genDirRoot/')) {
      absolute = '//${absolute.substring(genDirRoot.length + 1)}';
    }
    if (absolute.length > 2 && absolute.endsWith('/')) {
      absolute = absolute.substring(0, absolute.length - 1);
    }
    final String? relative = layout.relativePath(absolute);
    final String spelled = directory.replaceFirst(genDirRoot, r'$root_gen_dir');
    if (relative == null) {
      throw GnError(location, '$spelled is outside the output repository');
    }
    if (relative != package.package && layout.owningPackage(relative) != relative) {
      throw GnError(location, '$spelled is not a package the layout knows');
    }
    return '//$relative';
  }

  /// [variable] without the `get_target_outputs()` items of its assignments.
  GnVariable _withoutTargetOutputs(GnVariable variable) {
    if (!variable.assignments.any(
      (GnAssignment a) => a.items.any((GnValue v) => v is GnTargetOutputsValue),
    )) {
      return variable;
    }
    final copy = GnVariable(variable.name, isList: variable.isList, forwarded: variable.forwarded);
    for (final GnAssignment a in variable.assignments) {
      final items = <GnValue>[];
      final comments = <GnItemComments>[];
      for (var i = 0; i < a.items.length; i++) {
        if (a.items[i] is GnTargetOutputsValue) {
          continue;
        }
        items.add(a.items[i]);
        comments.add(a.commentsOf(i));
      }
      copy.assignments.add(
        GnAssignment(
          a.location,
          a.condition,
          a.op,
          items,
          sourceConditions: a.sourceConditions,
          comments: a.comments,
          itemComments: comments,
        ),
      );
    }
    return copy;
  }

  /// The `get_target_outputs()` items of [variable]: Bazel label (as written
  /// from this file) to the `filter_include` patterns kept. Unconditional
  /// only: a conditional one would need a select() over a dictionary.
  Map<String, List<String>> _targetOutputs(GnVariable variable) {
    final targets = <String, List<String>>{};
    for (final GnAssignment a in variable.assignments) {
      for (final GnValue v in a.items) {
        if (v is! GnTargetOutputsValue) {
          continue;
        }
        if (!a.isUnconditional || a.op == '-=') {
          throw GnError(
            a.location,
            'get_target_outputs() under a condition or removed is not supported',
          );
        }
        final String label = _localLabel(
          bazelLabel(v.label, package: gnPackage, location: a.location),
        );
        if (targets.containsKey(label) && targets[label] != v.patterns) {
          throw GnError(
            a.location,
            'get_target_outputs($label) listed twice with different patterns',
          );
        }
        targets[label] = v.patterns;
      }
    }
    return targets;
  }

  /// A Starlark dictionary of label to string list, laid out as buildifier
  /// lays BUILD files out: a dictionary or list of more than one element goes
  /// one element per line (an attribute's text starts after four spaces).
  static String _dictText(Map<String, List<String>> entries) {
    String list(List<String> values, String indent) {
      if (values.length <= 1) {
        return '[${values.map(_starlarkString).join()}]';
      }
      final out = StringBuffer('[\n');
      for (final value in values) {
        out.writeln('$indent    ${_starlarkString(value)},');
      }
      return '$out$indent]';
    }

    if (entries.length == 1) {
      final MapEntry<String, List<String>> e = entries.entries.single;
      return '{${_starlarkString(e.key)}: ${list(e.value, '    ')}}';
    }
    final out = StringBuffer('{\n');
    for (final MapEntry<String, List<String>> e in entries.entries) {
      out.writeln('        ${_starlarkString(e.key)}: ${list(e.value, '        ')},');
    }
    return '$out    }';
  }

  /// A dictionary of strings (a test's `env`) in the same layout.
  /// A dictionary of strings as Starlark text, its lines indented for an
  /// attribute value ([indent] 4) or a `select()` branch (8), as buildifier
  /// lays them out.
  static String _stringDictText(Map<String, String> entries, {int indent = 4}) {
    if (entries.isEmpty) {
      return '{}';
    }
    if (entries.length == 1) {
      final MapEntry<String, String> e = entries.entries.single;
      return '{${_starlarkString(e.key)}: ${_starlarkString(e.value)}}';
    }
    final out = StringBuffer('{\n');
    for (final MapEntry<String, String> e in entries.entries) {
      out.writeln('${' ' * (indent + 4)}${_starlarkString(e.key)}: ${_starlarkString(e.value)},');
    }
    return '$out${' ' * indent}}';
  }

  /// [text] as a Starlark string literal.
  static String _starlarkString(String text) =>
      '"${text.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  /// [text] with each rebased path (see _argsInto) replaced by the rule's
  /// token for it.
  String _withPathTokens(String text, GnLocation location, _Rule rule, GnTarget target) {
    final List<String> parts = text.split(rebasedPathMarker);
    if (parts.length.isEven) {
      throw GnError(location, 'unbalanced rebased path in $text');
    }
    final declared = <String>{
      for (final String list in <String>['srcs', 'inputs', 'shaders'])
        for (final _Item item in rule.list(list).always) item.text,
    };
    final out = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      out.write(i.isEven ? parts[i] : _pathToken(parts[i], location, rule, declared, target));
    }
    return out.toString();
  }

  /// A source directory argument (web_sdk's `input_dir`, `exclude_pattern`):
  /// the directory's path relative to the repository root, and, where the
  /// mapping names an inputs attribute, the filegroup over its files
  /// ([directorySources]) there.
  void _sourceDirectoryInto(_Rule rule, TemplateArgument argument, GnVariable variable) {
    final GnLocation location = variable.assignments.first.location;
    final String? raw = _singleString(variable);
    if (raw == null) {
      throw GnError(location, '${variable.name} has no value');
    }
    String path = _unmarked(raw);
    if (path.contains(rebasedPathMarker)) {
      throw GnError(location, 'a rebased path inside a directory name: $raw');
    }
    if (path.length > 2 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    final String absolute = _gnPath(path);
    final DirectorySource? directory = directorySources[absolute];
    final String? inputs = argument.inputs;
    if (inputs != null) {
      if (directory == null) {
        throw GnError(
          location,
          '${variable.name} names $absolute, a directory directorySources does not list '
          '(a filegroup over its files is needed)',
        );
      }
      rule.list(inputs).addUnique(Condition.always, _Item(_localLabel(directory.label)));
    }
    rule.scalars[argument.attribute] = _starlarkString(
      directory?.root ?? _repositoryPath(absolute, location),
    );
  }

  /// A GN directory as a path relative to the output repository's root.
  String _repositoryPath(String absolute, GnLocation location) {
    final String? relative = layout.relativePath(absolute);
    if (relative == null) {
      throw GnError(location, '$absolute is outside the output repository');
    }
    return relative;
  }

  /// copy("x") becomes a `gn_copy`: its sources as they are, GN's
  /// destination recorded (see build/bazel/gn_action) -- or, when the
  /// outputs are under the target's own gen dir and name the files, either
  /// literally (a renaming copy, which GN allows for one source) or through
  /// `{{source_file_part}}`/`{{source_name_part}}` with more than the bare
  /// name around them (the Linux shell's schemas go to
  /// `assets/{{source_name_part}}/gschemas.compiled`), the copies under
  /// their new names (`outs`), expanded here per source as GN expands them.
  ///
  /// A copy whose dependency edges name a wasm toolchain of this file
  /// (`"//flutter/skwasm(:skwasm)"`: the web SDK's copies of the modules,
  /// third_party/canvaskit) is built for that toolchain's platform
  /// (`platform`, which gn_copy's transition applies to what it names), and
  /// its sources -- the module's outputs under the toolchain's directory of
  /// the build directory, `$root_out_dir/skwasm/skwasm.js` -- are the module
  /// itself, whose files they are.
  void _convertCopy(GnTarget target) {
    _use('//engine/src/flutter/build/bazel/gn_action:gn_action.bzl', 'gn_copy');
    final rule = _Rule('gn_copy', target.name, target.comments);
    final _ToolchainEdge? edge = _toolchainEdge(target);
    if (edge != null) {
      rule.scalars['platform'] = '"${_localLabel(edge.platform)}"';
    }
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case 'sources':
          if (edge != null) {
            _moduleOutputsInto(rule, variable, edge, target);
          } else {
            _filesInto(rule.list('srcs'), variable);
          }
        case 'outputs':
          // As GN wrote them, for the record.
          _forEachItem(variable, into: rule.list('outputs'), (_Element e) {
            final String text = _string(e)
                .replaceFirst('$genDirRoot/', r'$root_gen_dir/')
                .replaceFirst('$buildDirRoot/', r'$root_out_dir/');
            rule.list('outputs').add(e.condition, _item(text, e));
          });
          final List<GnValue>? items = variable.unconditionalItems;
          if (items == null || !items.every((GnValue v) => v is GnStringValue)) {
            break;
          }
          final genDir = '$genDirRoot${gnPackage.substring(1)}/';
          if (!items.every((GnValue v) => (v as GnStringValue).value.startsWith(genDir))) {
            // Outputs elsewhere in the build directory
            // (`$root_out_dir/flutter_embedder.h`,
            // `$root_gen_dir/dart-pkg/sky_engine/lib/async/{{source_file_part}}`)
            // are the layout's, which packaging and install assemble from
            // the files by name (a zip_bundle entry naming the output gets
            // the source; gn_copy places its files by `outputs`): the files
            // travel as they are, the destinations are on record -- except
            // that a copy which renames its file renames it here too, so
            // that the file carries the name the layout has for it.
            _buildDirectoryRenamesInto(rule, items.cast<GnStringValue>(), variable, target);
            break;
          }
          if (items.every((GnValue v) => !(v as GnStringValue).value.contains('{{'))) {
            _outputsInto(rule, variable, target, attribute: 'outs');
          } else {
            _expandedOutputsInto(rule, items.cast<GnStringValue>(), variable, target);
          }
        case 'deps':
        case 'public_deps':
          if (edge != null) {
            // The module is among the sources (its files); any other
            // dependency orders, as ever.
            _forEachItem(variable, into: rule.list('deps'), (_Element e) {
              if (_withoutToolchain(_string(e)) == edge.gnLabel) {
                return;
              }
              final String label = bazelLabel(
                _string(e),
                package: gnPackage,
                location: e.assignment.location,
              );
              rule.list('deps').addUnique(e.condition, _item(_localLabel(label), e));
            });
          } else {
            _labelsInto(rule.list('deps'), variable, target);
          }
        case 'testonly':
          _scalar(rule, 'testonly', variable);
        default:
          if (_ignoredVariables.contains(variable.name) ||
              variable.forwarded ||
              _isHelperVariable(variable)) {
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

  /// The wasm toolchain a copy's dependency edges name
  /// (`"//flutter/skwasm(:skwasm)"`), when they name one of this file's:
  /// GN builds the dependency in that toolchain, a platform here. Null for
  /// a copy whose edges name no toolchain (or `$default_toolchain`, which
  /// is the one configuration a Bazel build has).
  _ToolchainEdge? _toolchainEdge(GnTarget target) {
    _ToolchainEdge? edge;
    for (final name in const <String>['deps', 'public_deps']) {
      final GnVariable? variable = target.variables[name];
      if (variable == null) {
        continue;
      }
      for (final GnListItem item in variable.liveItems) {
        final GnValue value = item.value;
        if (value is! GnStringValue) {
          continue;
        }
        final GnLocation location = item.assignment.location;
        final String label = value.value;
        final int paren = label.indexOf('(');
        if (paren < 0 || !label.endsWith(')')) {
          continue;
        }
        final String toolchain = label.substring(paren + 1, label.length - 1);
        if (toolchain == r'$default_toolchain') {
          continue;
        }
        if (!toolchain.startsWith(':')) {
          throw GnError(
            location,
            "copy ${target.name} names toolchain $toolchain, which is not one of this file's",
          );
        }
        final String toolchainName = toolchain.substring(1);
        if (localTargets[toolchainName]?.rule != 'wasm_toolchain') {
          throw GnError(
            location,
            'copy ${target.name} names toolchain $toolchain, which is not a wasm_toolchain of '
            'this file',
          );
        }
        final String gnLabel = label.substring(0, paren);
        final String absolute = absoluteGnLabel(gnLabel, package: gnPackage, implicitName: true);
        final found = _ToolchainEdge(
          gnLabel: gnLabel,
          moduleLabel: bazelLabel(gnLabel, package: gnPackage, location: location),
          moduleName: absolute.substring(absolute.indexOf(':') + 1),
          toolchainName: toolchainName,
          platform: bazelLabel(toolchain, package: gnPackage, location: location),
        );
        if (edge != null &&
            (edge.gnLabel != found.gnLabel || edge.toolchainName != toolchainName)) {
          throw GnError(
            location,
            'copy ${target.name} names more than one dependency in a toolchain '
            '(${edge.gnLabel}(:${edge.toolchainName}) and $label)',
          );
        }
        edge = found;
      }
    }
    return edge;
  }

  /// [label] without its `(toolchain)` suffix.
  static String _withoutToolchain(String label) {
    final int paren = label.indexOf('(');
    return paren > 0 && label.endsWith(')') ? label.substring(0, paren) : label;
  }

  /// The sources of a copy with a toolchain edge: the module's outputs
  /// under the toolchain's directory of the build directory
  /// (`$root_out_dir/<toolchain>/<module>.js`, `.wasm`, `.js.symbols`, and
  /// `.wasm.map` under is_debug, where the unoptimized link writes one),
  /// which are the module target's files -- the one source here, with the
  /// files GN names as `files`, under their conditions, since a copy may
  /// name fewer than the module writes (CanvasKit's leave the source map).
  void _moduleOutputsInto(_Rule rule, GnVariable variable, _ToolchainEdge edge, GnTarget target) {
    const outputs = <String>['.js', '.wasm', '.js.symbols', '.wasm.map'];
    final directory = '$buildDirRoot/${edge.toolchainName}/';
    final _ListAttribute srcs = rule.list('srcs');
    final _ListAttribute files = rule.list('files');
    _forEachItem(variable, into: srcs, (_Element e) {
      final String path = _string(e);
      final String file = path.startsWith(directory) ? path.substring(directory.length) : '';
      if (!outputs.any((String extension) => file == '${edge.moduleName}$extension')) {
        throw GnError(
          e.assignment.location,
          'source ${_rawString(e)} of copy ${target.name} is not an output of ${edge.gnLabel} '
          'in toolchain :${edge.toolchainName} (${edge.moduleName}.js, .wasm, .js.symbols, '
          '.wasm.map)',
        );
      }
      srcs.addUnique(e.condition, _item(_localLabel(edge.moduleLabel), e, note: false));
      files.addUnique(e.condition, _Item(file));
    });
  }

  /// A copy elsewhere in the build directory whose literal outputs rename
  /// their sources (`embedder.h` to `$root_out_dir/flutter_embedder.h`): the
  /// outputs' paths under the build directory (`flutter_embedder.h`,
  /// `gen/...`) as `outs`, so that the Bazel file bears the layout's name. A
  /// copy keeping its files' names, or one with source expansions in its
  /// outputs, adds nothing: its files travel as they are.
  void _buildDirectoryRenamesInto(
    _Rule rule,
    List<GnStringValue> outputs,
    GnVariable variable,
    GnTarget target,
  ) {
    if (outputs.any((GnStringValue output) => output.value.contains('{{'))) {
      return;
    }
    final GnLocation location = variable.assignments.first.location;
    final List<GnValue>? sources = target.variables['sources']?.unconditionalItems;
    if (sources == null || sources.length != outputs.length) {
      throw GnError(
        location,
        'copy ${target.name} names ${outputs.length} literal output(s) for its sources, '
        'which must be as many and unconditional',
      );
    }
    final names = <String>[
      for (final GnStringValue output in outputs) _buildDirectoryPath(output.value, location),
    ];
    var renames = false;
    for (var i = 0; i < names.length; i++) {
      final GnValue source = sources[i];
      if (source is! GnStringValue) {
        throw GnError(location, 'a source of copy ${target.name} is not a path');
      }
      if (p.basename(_unmarked(source.value)) != p.basename(names[i])) {
        renames = true;
      }
    }
    if (!renames) {
      return;
    }
    for (final name in names) {
      rule.list('outs').addUnique(Condition.always, _Item(name));
    }
  }

  /// GN's path under the build directory for an output under the build
  /// root (`$root_out_dir/x` is `x`) or the generated-file tree
  /// (`$root_gen_dir/x` is `gen/x`).
  static String _buildDirectoryPath(String output, GnLocation location) {
    if (output.startsWith('$buildDirRoot/')) {
      return output.substring(buildDirRoot.length + 1);
    }
    if (output.startsWith('$genDirRoot/')) {
      return 'gen/${output.substring(genDirRoot.length + 1)}';
    }
    throw GnError(location, 'output $output is not under the build directory');
  }

  /// A copy's output pattern with source expansions: under the target's own
  /// gen dir, each source's expansion is an `outs` entry, unless the pattern
  /// is the bare `{{source_file_part}}` (the copy keeps the names, and the
  /// sources travel as they are); anywhere else (`$root_out_dir/...`, the
  /// artifact layout) the destination is recorded alone.
  void _expandedOutputsInto(
    _Rule rule,
    List<GnStringValue> patterns,
    GnVariable variable,
    GnTarget target,
  ) {
    final genDir = '$genDirRoot${gnPackage.substring(1)}/';
    if (patterns.length != 1 || !patterns.single.value.startsWith(genDir)) {
      return;
    }
    final String pattern = patterns.single.value.substring(genDir.length);
    if (pattern == '{{source_file_part}}') {
      return;
    }
    final GnLocation location = variable.assignments.first.location;
    final List<GnValue>? sources = target.variables['sources']?.unconditionalItems;
    if (sources == null) {
      throw GnError(location, 'the sources of copy ${target.name} depend on a condition');
    }
    for (final GnValue source in sources) {
      if (source is! GnStringValue) {
        throw GnError(location, 'a source of copy ${target.name} is not a path');
      }
      final String file = p.basename(source.value);
      final String expanded = pattern
          .replaceAll('{{source_file_part}}', file)
          .replaceAll('{{source_name_part}}', p.basenameWithoutExtension(file));
      if (expanded.contains('{{')) {
        throw GnError(location, 'output pattern $pattern of copy ${target.name} is not supported');
      }
      rule.list('outs').addUnique(Condition.always, _Item(expanded));
    }
  }

  /// A `source_set`/`static_library` ([library]), an `executable`, or a
  /// `shared_library` ([shared]: a `cc_binary` with `linkshared`, named
  /// after the file GN produces -- `lib<output_name>.so`, as Bazel requires
  /// of a shared binary -- with an `alias` under the GN target's name). An
  /// executable with an `output_name` of its own (`_font-subset`, producing
  /// `font-subset`) is named and aliased the same way, since a cc_binary's
  /// file is its name.
  void _convertCcTarget(
    GnTarget target,
    String kind, {
    required bool library,
    bool shared = false,
  }) {
    // A suite that opens a window (displayTests) runs under a display:
    // testing.bzl's macro, with cc_test's attributes. A suite run_tests.py
    // runs through gtest-parallel (gtestParallelSuites) is the macro that
    // does the same, or the display macro told to.
    final gnLabel = '$gnPackage:${target.name}';
    final bool display = kind == 'cc_test' && displayTests.contains(gnLabel);
    final bool gtestParallel = kind == 'cc_test' && gtestParallelSuites.contains(gnLabel);
    final ruleKind = display
        ? 'flutter_display_test'
        : gtestParallel
        ? 'flutter_cc_test'
        : kind;
    if (display || gtestParallel) {
      _use('//engine/src/flutter/testing:testing.bzl', ruleKind);
    } else {
      _use('@rules_cc//cc:defs.bzl', kind);
    }
    // An executable's output_name is the rule's name, GN's name an alias
    // (below): a binary's, and a test's too (the Android suites run by
    // their file names: impeller_toolkit_android_unittests for
    // toolkit/android's `unittests`).
    final String? outputName = _singleString(target.variables['output_name']);
    final String name = shared
        ? 'lib${outputName ?? target.name}.so'
        : (kind == 'cc_binary' || kind == 'cc_test') && outputName != null
        ? outputName
        : target.name;
    final rule = _Rule(ruleKind, name, target.comments);
    if (kind == 'cc_test') {
      rule.scalars['size'] = '"${testSizes[target.name] ?? defaultTestSize}"';
      final int? shards = testShardCounts[target.name];
      if (shards != null) {
        if (!display && !gtestParallel) {
          throw GnError(
            target.location,
            '${target.name} is in testShardCounts but is neither a display test nor '
            'run through gtest-parallel: only testing/xvfb_run.sh and '
            'testing/gtest_parallel_run.sh hand the shard variables on, so a plain '
            'cc_test cannot be sharded',
          );
        }
        rule.scalars['shard_count'] = '$shards';
      }
      // How run_tests.py runs the suite (testRuns), which GN cannot say;
      // a benchmark it runs (benchmarkRuns) the same way, tagged out of
      // wildcard runs.
      final TestRun? benchmark = benchmarkRuns[gnLabel];
      if (benchmark != null) {
        rule.list('tags').addUnique(Condition.always, const _Item('benchmark'));
        rule.list('tags').addUnique(Condition.always, const _Item('manual'));
      }
      final TestRun? run = benchmark ?? testRuns[gnLabel];
      if (run != null) {
        for (final String arg in run.args) {
          rule.list('args').addUnique(Condition.always, _Item(arg));
        }
        if (run.runnerArgs.isNotEmpty) {
          if (!gtestParallel) {
            throw GnError(
              target.location,
              '${target.name} has runnerArgs in testRuns but is not in gtestParallelSuites',
            );
          }
          for (final String arg in run.runnerArgs) {
            rule.list('runner_args').addUnique(Condition.always, _Item(arg));
          }
        }
        for (final String label in run.data) {
          rule.list('data').addUnique(Condition.always, _Item(_localLabel(label)));
        }
        if (run.env.isNotEmpty) {
          rule.scalars['env'] = _stringDictText(run.env);
        }
      }
      if (display && gtestParallel) {
        rule.scalars['gtest_parallel'] = 'True';
      }
      // run_tests.py's Vulkan validation environment goes to the Impeller
      // suites (--type impeller), and names SwiftShader's manifest and the
      // layer next to the binary: a display test without the backends
      // (gpuBackendTests) gets none.
      if (display && !gpuBackendTests.contains('$gnPackage:${target.name}')) {
        rule.scalars['vulkan_validation'] = 'False';
      }
      // A D-Bus session bus of the test's own (sessionBusTests), which the
      // display wrapper starts.
      if (sessionBusTests.contains('$gnPackage:${target.name}')) {
        if (!display) {
          throw GnError(
            target.location,
            '${target.name} is in sessionBusTests but is not a display test: only '
            'testing/xvfb_run.sh starts the bus',
          );
        }
        rule.scalars['session_bus'] = 'True';
      }
    }
    // The GPU test backends next to the binary (gpuBackendTests), which
    // GN's data_deps place in the build directory: one copy per package. An
    // executable that is not a test (flutter_tester_opengles, which the Dart
    // suites run) carries them as runfiles for the tests that run it.
    if (!library && !shared && gpuBackendTests.contains('$gnPackage:${target.name}')) {
      if (!_declaredGpuBackends) {
        _declaredGpuBackends = true;
        _use('//engine/src/flutter/testing:testing.bzl', 'flutter_gpu_test_backends');
        rules.add(
          _Rule('flutter_gpu_test_backends', gpuBackendsTargetName, const <String>[
            '# SwiftShader, its ICD manifest and the Vulkan loader, next to the',
            '# suites below (GN: data_deps of //flutter/third_party/swiftshader and',
            '# ANGLE).',
          ]),
        );
      }
      rule.list('data').addUnique(Condition.always, const _Item(':$gpuBackendsTargetName'));
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
    // The compiler flags this target hands its dependents, for the check
    // against what they will derive from this file.
    final propagated = <ForwardedFlag>[];
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
          if (variable.name == 'public_deps') {
            _forwardedFlagsInto(propagated, variable, target);
          }
        case 'defines':
          _stringsInto(rule.list('local_defines'), variable, defines: true);
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
          _compilerFlagsInto(rule, variable, Condition.always, own: true);
        case 'testonly':
          // cc_test is testonly by definition.
          if (kind != 'cc_test') {
            _scalar(rule, 'testonly', variable);
          }
        case 'lib_dirs':
          _requireEmpty(variable);
        case 'inputs':
          // Files the link reads besides its objects: the version script
          // ldflags names (the Android shell's android_exports.lst), which
          // the ldflags rendering lists as a linker input already; GN's
          // `inputs` declares the same dependency, so the files join
          // additional_linker_inputs (once).
          _forEachItem(variable, into: rule.list('additional_linker_inputs'), (_Element e) {
            final String file = _filePath(_string(e), e.assignment.location);
            final label = file.startsWith('//') || file.startsWith('@') ? file : ':$file';
            rule.list('additional_linker_inputs').addUnique(e.condition, _Item(label));
          });
        case 'output_name' when target.rule == 'source_set' || shared:
          // A source_set produces no file, so GN ignores the name (harfbuzz's
          // GN sets one); a shared library's is in the rule's name already;
          // on anything else it would rename the output.
          break;
        case 'output_name' when target.rule == 'executable':
          // The rule's name, with an alias under the target's (above); a
          // test named after its own target (flutter_tester's template
          // forwards the name) is the file Bazel produces anyway.
          break;
        default:
          if (_ignoredVariables.contains(variable.name) ||
              variable.forwarded ||
              _isHelperVariable(variable)) {
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
    // Nothing depends on a binary: what its public_deps would hand on goes
    // nowhere, and GN's own check only concerns dependents.
    if (kind == 'cc_library' || shared) {
      _checkPropagatedFlags(target, propagated);
    }

    // GN applies a dependency's all_dependent_configs to this target and to
    // everything that depends on it, through private dependencies too;
    // Bazel's implementation_deps would stop them, so the configs become
    // public deps of their own (under the condition each reaches this
    // target: a merged optional() target names its public config only
    // when the feature is on).
    _inheritedConfigsInto(rule, target);

    // A header-only library compiles nothing: GN ignores its flags and
    // defines (they apply to no compile and propagate to no one), and so
    // does the generated rule. Its private configs stay, as
    // implementation_deps: their link flags reach the binaries that link
    // the library, as GN's do (the GTK shell's flutter_linux lists the
    // epoxy config and compiles nothing; libflutter_linux_gtk.so needs
    // -lepoxy), and their defines and include directories reach nothing,
    // which is what a private config of a target without compiles amounts
    // to in GN.
    final bool compiles = !(rule.lists['srcs']?.isEmpty ?? true);
    if (!compiles) {
      const <String>['copts', 'conlyopts', 'cxxopts', 'local_defines'].forEach(rule.lists.remove);
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
      } else if (target.rule == 'static_library' &&
          library &&
          (rule.lists['hdrs']?.isEmpty ?? true)) {
        // An archive of sources whose headers another library carries
        // (icu_bidi over ICU's): buildifier would have it alwayslink,
        // which a static_library is not.
        rule.comments.add('# buildifier: disable=no-hdrs-no-alwayslink');
      }
      // GN's default include dirs, applied to every target by BUILDCONFIG.gn.
      if (layout.isMain) {
        rule.list('deps').addUnique(Condition.always, _Item(_localLabel(defaultIncludeDirsLabel)));
      }
      // The target's own flags lead, as in GN's command line (see
      // _compilerFlagsInto); the constants and the configs' flags follow.
      for (final MapEntry<String, List<_Item>> own in rule.ownFlags.entries) {
        rule.list(own.key).always.insertAll(0, own.value);
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
    if (name != target.name) {
      // GN's name for the library or executable, for dependents and the
      // command line.
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
          // A target of another file: the engine's own (GN's //flutter/...,
          // converted into the main repository) carry //flutter:config as a
          // public config by convention; synced trees do not, nor does the
          // secondary tree's //third_party:fontconfig, whose facade lives in
          // the main repository too.
          final String label = bazelLabel(v.value, package: gnPackage, location: a.location);
          if (label.startsWith('$bazelRootPackage/flutter') &&
              absoluteGnLabel(v.value, package: gnPackage).startsWith('//flutter/')) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// `cflags*` of a target or a config into the rule's flag attributes,
  /// under [condition] on top of each item's own. A target's [own] flags
  /// come before every config's in GN's command line (lib/ui turns
  /// `-Wimplicit-float-conversion` on and `default_warning_flags` then turns
  /// its int-to-float part back off), so they are kept apart and rendered
  /// ahead of the copts constants; a flag under a condition still follows,
  /// in its `select()`.
  void _compilerFlagsInto(
    _Rule rule,
    GnVariable variable,
    Condition condition, {
    bool own = false,
  }) {
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
      final Condition under = condition.and(e.condition);
      if (own && under == Condition.always) {
        rule.ownFlags.putIfAbsent(attribute, () => <_Item>[]).add(item);
        return;
      }
      rule.list(attribute).add(under, item);
    });
  }

  /// The flags a dependency hands its dependents through a public config
  /// ([forwarded]), added to the rule that lists the dependency, under the
  /// dependency's condition and the flag's own.
  void _propagatedFlagsInto(_Rule rule, GnVariable variable) {
    _forEachItem(variable, into: _ListAttribute(), (_Element e) {
      for (final ForwardedFlag flag in forwarded.flagsOf(_gnLabel(_string(e)))) {
        rule
            .list('copts')
            .addUnique(
              e.condition.and(flag.condition),
              _Item(_tokenizerEscaped(flag.flag), comment: 'from ${_string(e)}'),
            );
      }
    });
  }

  /// The flags the public dependencies of [variable] hand this target
  /// ([forwarded]), which GN hands on to its dependents in turn -- public
  /// configs travel along public_deps chains -- collected into
  /// [propagated] for [_checkPropagatedFlags].
  void _forwardedFlagsInto(List<ForwardedFlag> propagated, GnVariable variable, GnTarget target) {
    _forEachItem(variable, into: _ListAttribute(), (_Element e) {
      if (_isUnconvertedDep(target, _string(e))) {
        return;
      }
      for (final ForwardedFlag flag in forwarded.flagsOf(_gnLabel(_string(e)))) {
        propagated.add((condition: e.condition.and(flag.condition), flag: flag.flag));
      }
    });
  }

  /// A target that hands compiler flags to its dependents -- through its
  /// own public configs, or those of its public_deps, which GN forwards --
  /// is read twice: by its own conversion, into [propagated], and by its
  /// dependents' through dependency_resolver.dart. The two readings must agree,
  /// or the dependents compile with other flags than the owner's file says.
  void _checkPropagatedFlags(GnTarget target, List<ForwardedFlag> propagated) {
    final Set<ForwardedFlag> actual = propagated.toSet();
    final Set<ForwardedFlag> derived = publicFlagsOf(
      target,
      gnPackage: gnPackage,
      localConfigs: localConfigs,
      forwarded: forwarded.flagsOf,
    ).toSet();
    if (derived.length != actual.length || !derived.containsAll(actual)) {
      throw GnError(
        target.location,
        'converting $gnPackage:${target.name} finds it handing ${_describe(actual)} to its '
        'dependents, and dependency_resolver.dart derives ${_describe(derived)}: the two '
        'readings of its public configs and public_deps disagree',
      );
    }
  }

  static String _describe(Set<ForwardedFlag> flags) {
    return <String>[
      for (final ForwardedFlag f in flags)
        if (f.condition == Condition.always) f.flag else '${f.flag} under `${f.condition}`',
    ].toString();
  }

  /// A GN label as written in this file, as `//dir:name`.
  String _gnLabel(String value) => absoluteGnLabel(value, package: gnPackage, implicitName: true);

  /// config("x") becomes a header-only library carrying the defines, include
  /// directories and link flags, which dependents list in deps; Bazel
  /// propagates those the way GN propagates a config. Compiler flags cannot
  /// travel that way: a target of this file that lists the config gets them
  /// inlined (and its dependents, for a public config, derive them from
  /// this file: dependency_resolver.dart); a config with flags that no target
  /// here lists is refused.
  void _convertConfig(GnTarget target) {
    _use('@rules_cc//cc:defs.bzl', 'cc_library');
    final rule = _Rule('cc_library', target.name, target.comments);
    for (final GnVariable variable in target.variables.values) {
      switch (variable.name) {
        case final String name when !_configVariables.contains(name):
          // A local of the config block: scratch for the values below. GN
          // rejects an assignment nothing reads ("had no effect"), unless
          // the name starts with `_`, so a name outside config()'s own
          // variables is one the block itself uses (the Linux shell's
          // `warning_flags`, read by its cflags and cflags_cc).
          break;
        case 'defines':
          _stringsInto(rule.list('defines'), variable, defines: true);
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

  /// The variables GN's config() reads (`gn help config`); anything else in
  /// a config block is a local.
  static const Set<String> _configVariables = <String>{
    ...flagVariables,
    'asmflags',
    'configs',
    'defines',
    'framework_dirs',
    'frameworks',
    'include_dirs',
    'inputs',
    'ldflags',
    'lib_dirs',
    'libs',
    'precompiled_header',
    'precompiled_source',
    'rustenv',
    'rustflags',
    'swiftflags',
    'testonly',
    'visibility',
    'weak_frameworks',
  };

  /// Copies a private config of this file into [rule] (see [_configsInto]).
  /// [use] is the assignment that listed the config; its condition applies
  /// on top of the config's own. With [flagsOnly], only the compiler flags
  /// (what a public config cannot carry as a dependency).
  void _inlineConfig(_Rule rule, GnTarget config, GnAssignment use, {bool flagsOnly = false}) {
    for (final GnVariable variable in config.variables.values) {
      if (flagVariables.contains(variable.name)) {
        _compilerFlagsInto(rule, variable, use.condition);
        continue;
      }
      if (flagsOnly) {
        continue;
      }
      final String attribute;
      switch (variable.name) {
        case final String name when !_configVariables.contains(name):
          // A local of the config block (see _convertConfig).
          continue;
        case 'defines':
          attribute = 'local_defines';
        case 'include_dirs':
          _includeDirsInto(rule, variable, use.condition);
          continue;
        case 'libs' || 'frameworks' || 'ldflags':
          _linkFlagsInto(rule, variable, under: use.condition);
          continue;
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
        final String text = switch (attribute) {
          'includes' => _filePath(_string(e), e.assignment.location),
          'local_defines' => _tokenizerEscaped(_defineText(_string(e), e)),
          _ => _tokenizerEscaped(_string(e)),
        };
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

  /// `libs`, `frameworks` and `ldflags` all become `linkopts`; [under] is
  /// the condition of the listing that brings them (an inlined config's).
  void _linkFlagsInto(_Rule rule, GnVariable variable, {Condition under = Condition.always}) {
    final _ListAttribute linkopts = rule.list('linkopts');
    switch (variable.name) {
      case 'libs':
        _forEachItem(variable, into: linkopts, (_Element e) {
          final String lib = _string(e);
          if (lib.contains('/')) {
            throw GnError(e.assignment.location, 'library path $lib in libs is not supported');
          }
          linkopts.add(under.and(e.condition), _item('-l$lib', e));
        });
      case 'frameworks':
        _forEachItem(variable, into: linkopts, (_Element e) {
          final String framework = _string(e).replaceFirst(RegExp(r'\.framework$'), '');
          linkopts
            ..add(under.and(e.condition), _item('-framework', e, note: false))
            ..add(under.and(e.condition), _Item(framework, comment: e.note));
        });
      case 'ldflags':
        _forEachItem(variable, into: linkopts, (_Element e) {
          if (e.value is! GnStringValue || !_rawString(e).contains(rebasedPathMarker)) {
            linkopts.add(
              under.and(e.condition),
              e.value is GnStringValue ? _item(_tokenizerEscaped(_string(e)), e) : _flagItem(e),
            );
            return;
          }
          // A flag naming a source file through rebase_path(..., root_build_dir)
          // (a linker version script): the file is a linker input, and the
          // flag names it with $(execpath), which Bazel expands in linkopts.
          final List<String> parts = _rawString(e).split(rebasedPathMarker);
          if (parts.length.isEven) {
            throw GnError(e.assignment.location, 'unbalanced rebased path in ldflags');
          }
          final out = StringBuffer();
          for (var i = 0; i < parts.length; i++) {
            if (i.isEven) {
              out.write(_tokenizerEscaped(parts[i]));
              continue;
            }
            final String path = parts[i];
            if (path.startsWith('$genDirRoot/') || path.startsWith(buildDirRoot)) {
              throw GnError(
                e.assignment.location,
                'only a source file can be named in ldflags; $path is generated',
              );
            }
            final String file = _filePath(path, e.assignment.location);
            final label = file.startsWith('//') || file.startsWith('@') ? file : ':$file';
            rule.list('additional_linker_inputs').addUnique(Condition.always, _Item(label));
            out.write('\$(execpath $label)');
          }
          linkopts.add(under.and(e.condition), _item(out.toString(), e));
        });
    }
  }

  // -------------------------------------------------------------------------
  // Variables
  // -------------------------------------------------------------------------

  /// Calls [visit] for every item of a list variable with the condition it
  /// is appended under ([GnVariable.liveItems]: removals only
  /// unconditionally).
  ///
  /// The comments on the `=` that defined the variable describe the whole
  /// list and go above [into], the attribute the items end up in; comments on
  /// a `+=` describe the addition and go with its first item.
  void _forEachItem(
    GnVariable variable,
    void Function(_Element) visit, {
    required _ListAttribute into,
  }) {
    for (final GnAssignment assignment in variable.assignments) {
      if (assignment.op == '=') {
        into.comments.addAll(assignment.comments);
      }
    }
    // A compiler flag list's `-isystem <rebased include dir>` pairs go (see
    // withoutSystemIncludeDirs); the resolver drops them the same way for
    // the flags a config hands on.
    final List<GnListItem> items = flagVariables.contains(variable.name)
        ? withoutSystemIncludeDirs(variable.liveItems)
        : variable.liveItems;
    for (final item in items) {
      visit(_element(item, withComments: item.assignment.op == '+='));
    }
  }

  /// The elements of one assignment; with [withComments], the comment lines
  /// before the assignment itself go with its first element.
  static List<_Element> _elements(GnAssignment assignment, {required bool withComments}) {
    return <_Element>[
      for (var i = 0; i < assignment.items.length; i++)
        _element(GnListItem(assignment, i), withComments: withComments),
    ];
  }

  static _Element _element(GnListItem item, {required bool withComments}) {
    final GnAssignment assignment = item.assignment;
    return _Element(
      item.condition,
      item.value,
      assignment,
      item.index == 0 && withComments && assignment.comments.isNotEmpty
          ? GnItemComments(
              before: <String>[...assignment.comments, ...item.comments.before],
              suffix: item.comments.suffix,
            )
          : item.comments,
    );
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

  /// [_string] for an action's args, where a rebased path belongs. A label
  /// whose only expansion is its toolchain
  /// (`"$dart_src/runtime/bin:analyze_snapshot($host_toolchain)"`) is kept
  /// as written, for the label table to read the toolchain off.
  static String _rawString(_Element element) {
    final GnValue value = element.value;
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
    if (value is! GnStringValue) {
      throw GnError(element.assignment.location, 'expected a string, got $value');
    }
    return value.value;
  }

  /// An item for [element] with its comments; [note] false leaves the line
  /// comment for a following item.
  static _Item _item(
    String text,
    _Element element, {
    bool quoted = true,
    bool expression = false,
    bool note = true,
  }) {
    return _Item(
      text,
      quoted: quoted,
      expression: expression,
      comment: note ? element.note : null,
      before: element.comments.before,
    );
  }

  _Item _flagItem(_Element element) {
    switch (element.value) {
      case GnStringValue(:final String value):
        return _item(_tokenizerEscaped(value), element);
      case GnReference(:final String name):
        return _item(_constant(name, element), element, quoted: false);
      case GnExpandedString(:final List<GnValue> parts):
        // `"X=\"$engine_version\""` as `"X=\\\"" + ENGINE_VERSION + "\\\""`; the
        // constant's value is taken as it is.
        final String text = parts
            .map(
              (GnValue part) => switch (part) {
                GnReference(:final String name) => _constant(name, element),
                _ => _Item(_tokenizerEscaped((part as GnStringValue).value)).starlark,
              },
            )
            .join(' + ');
        return _item(text, element, quoted: false, expression: true);
      default:
        throw GnError(element.assignment.location, 'unexpected flag value ${element.value}');
    }
  }

  /// A string for an attribute Bazel reads with Make-variable substitution
  /// and Bourne tokenization (`defines`, `local_defines`, `copts`,
  /// `linkopts`). GN hands the compiler the string as it is, so Bazel's
  /// reading of it must give the same string: quotes, backslashes and
  /// whitespace escaped, `$` doubled. Most flags come through unchanged.
  static String _tokenizerEscaped(String value) =>
      value.replaceAllMapped(_tokenizerSpecial, (Match m) => '\\${m[0]}').replaceAll(r'$', r'$$');

  static final RegExp _tokenizerSpecial = RegExp(r'''[\\"' \t]''');

  /// The Starlark constant for a reference to [name], loaded from its file.
  String _constant(String name, _Element element) {
    final ReferenceConstant? constant = referenceConstants[name];
    if (constant == null) {
      throw GnError(element.assignment.location, 'no Bazel constant for $name');
    }
    _use(constant.file, constant.symbol);
    return constant.symbol;
  }

  /// Strings into [attribute]; [defines] applies [_defineText].
  void _stringsInto(_ListAttribute attribute, GnVariable variable, {bool defines = false}) {
    _forEachItem(variable, into: attribute, (_Element e) {
      // A `.gni` list the Bazel side keeps as a constant (config.gni's
      // feature_defines_list) stands as itself, like a flag list does; so
      // does a string around a reference (version.gni's arguments).
      if (e.value is! GnStringValue) {
        attribute.add(e.condition, _flagItem(e));
        return;
      }
      final String text = defines ? _defineText(_string(e), e) : _string(e);
      attribute.add(e.condition, _item(_tokenizerEscaped(text), e));
    });
  }

  /// A define's value, with a generated file's GN path (`$target_gen_dir`,
  /// `get_label_info(..., "target_gen_dir")`) as the file's path at run time
  /// relative to the source directory the test helpers report: GN's
  /// GetSourcePath() is the source root, under which the build directory
  /// sits; Bazel's is `engine/src/` in the runfiles tree, under which the
  /// generated files sit too (the embedder's JIT snapshot paths). A path in
  /// the build directory proper has no such place.
  String _defineText(String text, _Element e) {
    if (text.contains(buildDirRoot)) {
      throw GnError(
        e.assignment.location,
        'a build-directory path in a define has no run-time counterpart; convert by hand',
      );
    }
    return text.replaceAll('$genDirRoot/', '');
  }

  void _labelsInto(
    _ListAttribute attribute,
    GnVariable variable,
    GnTarget target, {
    bool withViews = true,
  }) {
    _forEachItem(variable, into: attribute, (_Element e) {
      final String gnLabel = _string(e);
      // A dependency on a target of this file that is not converted (the
      // entitlement lists an archive depends on) has nothing to name; the
      // file's header lists the target.
      if (gnLabel.startsWith(':') && skippedTargets.contains(_localName(gnLabel))) {
        return;
      }
      if (_isUnconvertedDep(target, gnLabel)) {
        return;
      }
      final String label = bazelLabel(gnLabel, package: gnPackage, location: e.assignment.location);
      attribute.addUnique(e.condition, _item(_localLabel(label), e));
      if (withViews) {
        _rootIncludeViewsInto(attribute, label, e.condition);
      }
    });
  }

  /// A dependency into a repository with header views brings them along:
  /// the headers under the engine's root-relative spellings, as GN's root
  /// include directories give every target.
  void _rootIncludeViewsInto(_ListAttribute attribute, String label, Condition condition) {
    for (final MapEntry<String, List<String>> views in rootIncludeViews.entries) {
      if (label.startsWith(views.key)) {
        for (final String view in views.value) {
          attribute.addUnique(condition, _Item(view));
        }
      }
    }
  }

  /// GN's `action()` targets of this file, whose outputs a dependent takes
  /// as sources: in GN a dependency on an action only orders it before the
  /// compile, the files being on disk; in Bazel the compile's inputs must
  /// name them.
  bool _isLocalAction(String gnLabel) => _localRule(gnLabel) == 'action';

  /// GN's `copy()` targets of this file, whose products a dependent reads
  /// at run time (the Linux shell's suite reads the compiled GSettings
  /// schemas its copy places under the fixtures directory), and the targets
  /// of templates whose macros produce files rather than libraries
  /// ([TemplateMapping.files]: the test fixtures' AOT snapshot of the VM
  /// service, which //flutter/testing:fixture_test lists in the profile
  /// mode): in GN the dependency orders the action and the binary finds the
  /// file in the build directory; in Bazel the files must be the binary's
  /// runfiles.
  bool _isLocalData(String gnLabel) {
    return _isLocalWasmLink(gnLabel) ||
        _isFilesRule(_localRule(gnLabel) ?? _ruleElsewhere(gnLabel)) ||
        _isFilesGroup(gnLabel);
  }

  /// Whether [gnLabel] names a group the manifest marks as a group of things
  /// to build (filesGroups), of this file or another: a filegroup, which a
  /// C++ target carries as data.
  bool _isFilesGroup(String gnLabel) {
    final String label = _gnLabel(_withoutToolchain(gnLabel));
    final int colon = label.indexOf(':');
    if (colon < 0) {
      return false;
    }
    final String directory = label.substring(0, colon);
    final String name = label.substring(colon + 1);
    return directory == gnPackage
        ? filesGroups.contains(name)
        : manifestEntry(directory)?.filesGroups.contains(name) ?? false;
  }

  /// Whether a `:name` label names a link in a wasm toolchain of this file:
  /// a wasm_lib, or an executable with `output_extension = "js"`.
  bool _isLocalWasmLink(String gnLabel) {
    if (!gnLabel.startsWith(':')) {
      return false;
    }
    final GnTarget? local = localTargets[_withoutToolchain(gnLabel).substring(1)];
    if (local == null) {
      return false;
    }
    return local.rule == 'wasm_lib' || (local.rule == 'executable' && _isWasmExecutable(local));
  }

  /// Whether a target of GN rule [rule] is files rather than a library: a
  /// `copy()`, or a template whose macro's target is files (an archive, a
  /// snapshot).
  static bool _isFilesRule(String? rule) =>
      rule == 'copy' || (templateMappings[rule]?.files ?? false);

  /// The GN rule of a target of another file (`//flutter/shell/platform/
  /// embedder:embedder-archive`), through the resolver; null when it cannot
  /// say.
  String? _ruleElsewhere(String gnLabel) {
    if (gnLabel.startsWith(':')) {
      return null;
    }
    return forwarded.targetOf(_gnLabel(gnLabel))?.rule;
  }

  /// The GN rule of a target of this file named by a `:name` label, or null
  /// for any other label.
  String? _localRule(String gnLabel) {
    if (!gnLabel.startsWith(':')) {
      return null;
    }
    return localTargets[_localName(gnLabel)]?.rule;
  }

  /// The target name of a local label (`:name`, `:name(toolchain)`).
  static String _localName(String gnLabel) {
    final String name = gnLabel.substring(1);
    final int paren = name.indexOf('(');
    return paren >= 0 ? name.substring(0, paren) : name;
  }

  /// Like [_labelsInto] for a compiled target's dependencies: those on
  /// actions of this file go to `srcs` instead, those on copies and
  /// file-producing templates of this file to `data`.
  /// Whether [gnLabel], a dependency of [target], is one the manifest
  /// leaves out of a group (unconvertedDeps: no Bazel counterpart yet); the
  /// header lists it.
  bool _isUnconvertedDep(GnTarget target, String gnLabel) {
    if (target.rule != 'group') {
      return false;
    }
    final String label = _gnLabel(_withoutToolchain(gnLabel));
    if (!unconvertedDeps.contains(label)) {
      return false;
    }
    usedUnconvertedDeps.add(label);
    return true;
  }

  void _depsInto(_Rule rule, GnVariable variable, GnTarget target) {
    _forEachItem(variable, into: rule.list('deps'), (_Element e) {
      final String gnLabel = _string(e);
      if (_isUnconvertedDep(target, gnLabel)) {
        return;
      }
      final String label = bazelLabel(gnLabel, package: gnPackage, location: e.assignment.location);
      final list = _isLocalAction(gnLabel)
          ? 'srcs'
          : _isLocalData(gnLabel)
          ? 'data'
          : 'deps';
      rule.list(list).addUnique(e.condition, _item(_localLabel(label), e));
      _rootIncludeViewsInto(rule.list(list), label, e.condition);
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

  /// [gnPath] (`//dir/sub/../file`) with its `.` and `..` segments resolved,
  /// as GN resolves them; `..` above the root is an error.
  static String _normalized(String gnPath, GnLocation location) {
    if (!gnPath.contains('/./') &&
        !gnPath.contains('/../') &&
        !gnPath.endsWith('/..') &&
        !gnPath.substring(2).contains('//')) {
      return gnPath;
    }
    final segments = <String>[];
    for (final String segment in gnPath.substring(2).split('/')) {
      switch (segment) {
        // An empty segment is a doubled slash (GN's "$dir/" + "/file"),
        // which GN reads past.
        case '.' || '':
          break;
        case '..':
          if (segments.isEmpty) {
            throw GnError(location, '$gnPath leaves the source root');
          }
          segments.removeLast();
        default:
          segments.add(segment);
      }
    }
    return '//${segments.join('/')}';
  }

  /// How a GN file path (a source, header or include directory) is written
  /// in the generated file: relative to the package when the package owns
  /// it, as a `//pkg:file` label when another package of the repository
  /// does. A path outside the output repository is an error: the GN file
  /// then names something Bazel cannot see from here.
  String _filePath(String gnFilePath, GnLocation location) {
    String absolute = gnFilePath.startsWith('//')
        ? _normalized(gnFilePath, location)
        : gnFilePath == '.'
        ? gnPackage
        : _normalized('$gnPackage/$gnFilePath', location);
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
          // The file of the repository being generated, named from its
          // root package (the secondary tree's GN over the synced tree
          // writes `$_checkout_dir/layers/x.cpp`): relative to it, as
          // `includes` needs and `srcs` reads best.
          if (entry.value == '${layout.repository}//' && package.package.isEmpty) {
            return rest.isEmpty ? '.' : rest;
          }
          return rest.isEmpty ? entry.value : '${entry.value}:$rest';
        }
      }
      // A file of a repository whose targets are not converted, which
      // exports its files (the Dart tree's core library sources).
      for (final MapEntry<String, String> entry in fileRepositoryPrefixes.entries) {
        if (absolute.startsWith(entry.key)) {
          return '${entry.value}:${absolute.substring(entry.key.length)}';
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

  /// A scope of booleans and strings (a wasm toolchain's
  /// extra_toolchain_args) as a dictionary, in GN's order.
  String _scopeText(GnVariable variable) {
    final GnLocation location = variable.assignments.first.location;
    final List<GnValue>? items = variable.unconditionalItems;
    if (items == null || items.length != 1 || items.single is! GnScopeValue) {
      throw GnError(location, '${variable.name} is not one unconditional scope');
    }
    final scope = items.single as GnScopeValue;
    final out = StringBuffer('{\n');
    for (final GnVariable member in scope.variables.values) {
      final List<GnValue>? values = member.unconditionalItems;
      if (values == null || values.length != 1) {
        throw GnError(location, '${variable.name}.${member.name} is not one unconditional value');
      }
      final String text = switch (values.single) {
        GnBoolValue(:final bool value) => value ? 'True' : 'False',
        GnStringValue(:final String value) => _starlarkString(value),
        GnIntValue(:final int value) => '$value',
        final GnValue other => throw GnError(
          location,
          '${variable.name}.${member.name} is $other, not a boolean, string or integer',
        ),
      };
      out.writeln('        "${member.name}": $text,');
    }
    out.write('    }');
    return out.toString();
  }

  /// Strings among which a `rebase_path()` result names a file (a wasm
  /// module's `--js-library` and its library): the file's `$(execpath)`,
  /// with the file listed in the attribute the rule expands against.
  void _pathStringsInto(_Rule rule, TemplateArgument argument, GnVariable variable) {
    final _ListAttribute strings = rule.list(argument.attribute);
    final _ListAttribute inputs = rule.list(argument.inputs!);
    _forEachItem(variable, into: strings, (_Element e) {
      if (e.value is! GnStringValue) {
        strings.add(e.condition, _flagItem(e));
        return;
      }
      final String raw = _rawString(e);
      if (!raw.contains(rebasedPathMarker)) {
        strings.add(e.condition, _item(_tokenizerEscaped(_string(e)), e));
        return;
      }
      // The item is a rebased path, or a string with rebased paths inside
      // it (CanvasKit's `--closure-args=--externs=$externs_path`): each
      // becomes the file's $(execpath), which the rule expands anywhere in
      // the string.
      final buffer = StringBuffer();
      final List<String> parts = raw.split(rebasedPathMarker);
      if (parts.length.isEven) {
        throw GnError(e.assignment.location, 'an unterminated rebased path in a string: $raw');
      }
      for (var i = 0; i < parts.length; i++) {
        if (i.isEven) {
          buffer.write(_tokenizerEscaped(parts[i]));
          continue;
        }
        final String file = _filePath(parts[i], e.assignment.location);
        buffer.write('\$(execpath $file)');
        inputs.addUnique(e.condition, _Item(file));
      }
      strings.add(e.condition, _item(buffer.toString(), e));
    });
  }

  void _filesInto(_ListAttribute attribute, GnVariable variable) {
    _forEachItem(variable, into: attribute, (_Element e) {
      // A source given as an absolute path (sky_engine's
      // `rebase_path(sources, "", lib_path)`) is the file at that path.
      final String raw = _rawString(e);
      final String path = raw.contains(rebasedPathMarker) ? _unmarked(raw) : _string(e);
      if (path.contains(rebasedPathMarker)) {
        throw GnError(e.assignment.location, 'a rebased path inside a file name: $raw');
      }
      attribute.addUnique(e.condition, _item(_filePath(path, e.assignment.location), e));
    });
  }

  /// [path] without the marks of a `rebase_path()` result: a source given
  /// as an absolute path (sky_engine's `rebase_path(sources, "", lib_path)`)
  /// is the file at that path.
  static String _unmarked(String path) {
    if (path.length >= 2 &&
        path.startsWith(rebasedPathMarker) &&
        path.endsWith(rebasedPathMarker) &&
        !path.substring(1, path.length - 1).contains(rebasedPathMarker)) {
      return path.substring(1, path.length - 1);
    }
    return path;
  }

  /// `include_dirs`: `includes` entries, except that a generated directory
  /// of an ancestor package (`$root_gen_dir/flutter`) is a dependency on
  /// the target whose `includes` already spans it (see
  /// [genDirIncludeTargets]), and a source directory outside this package
  /// is a dependency on the library that carries it when
  /// [includeDirLibraries] names one; [under] is the condition of the
  /// config that carries them, when they are inlined.
  void _includeDirsInto(_Rule rule, GnVariable variable, Condition under) {
    _forEachItem(variable, into: rule.list('includes'), (_Element e) {
      final String path = _string(e);
      final String? ancestor = _genDirIncludeTarget(path);
      if (ancestor != null) {
        rule.list('deps').addUnique(under.and(e.condition), _Item(_localLabel(ancestor)));
        return;
      }
      // A directory of another repository or package that one of its
      // libraries carries (includeDirLibraries): the dependency puts the
      // same -I on the compile. This package's own directories are
      // `includes` whatever the table says: the library named for them is
      // in this package (the accessibility tree's root config carries the
      // tree's root), and would depend on itself.
      final String directory = _gnPath(path);
      if (directory != gnPackage && !directory.startsWith('$gnPackage/')) {
        final String? library = includeDirLibraries[directory];
        if (library != null) {
          rule.list('deps').addUnique(under.and(e.condition), _Item(_localLabel(library)));
          return;
        }
      }
      rule
          .list('includes')
          .addUnique(under.and(e.condition), _item(_filePath(path, e.assignment.location), e));
    });
  }

  /// A GN path as written in this file, as `//dir`.
  String _gnPath(String path) =>
      path.startsWith('//') ? path : _normalized('$gnPackage/$path', GnLocation(gnPackage, 0, 0));

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
      // The outputs of another target (`sources += get_target_outputs(
      // ":icudtl_asm")`, the Android shell's assembly of icudtl.dat): the
      // target itself, whose files Bazel compiles by their extensions.
      if (e.value case GnTargetOutputsValue(:final String label, :final List<String> patterns)) {
        if (patterns.isNotEmpty) {
          throw GnError(e.assignment.location, 'filtered outputs of $label in sources');
        }
        rule
            .list('srcs')
            .addUnique(
              e.condition,
              _item(
                _localLabel(bazelLabel(label, package: gnPackage, location: e.assignment.location)),
                e,
              ),
            );
        // bin_to_assembly's output `.incbin`s its input by path: the compile
        // of the assembly reads the blob too (lib/snapshot's hand-written
        // file lists them the same way).
        final int colon = label.lastIndexOf(':');
        final GnTarget? producer = label.substring(0, colon) == gnPackage
            ? localTargets[label.substring(colon + 1)]
            : null;
        if (producer != null && producer.rule == 'bin_to_assembly') {
          final String? input = _singleString(producer.variables['input']);
          if (input != null) {
            rule
                .list('additional_compiler_inputs')
                .addUnique(e.condition, _Item(_filePath(input, e.assignment.location)));
          }
        }
        return;
      }
      final String path = _string(e);
      // A generated file named by its build-directory path (the embedder's
      // `$root_build_dir/gen/.../icudtl.dat.S`, the Android shell's assembly
      // of icudtl.dat): the target that produces it, as a zip_bundle's
      // entries resolve (_buildOutputLabel).
      if (path.startsWith('$buildDirRoot/') || path.startsWith('$genDirRoot/')) {
        rule
            .list('srcs')
            .addUnique(
              e.condition,
              _item(_localLabel(_buildOutputLabel(path, target, e.assignment.location)), e),
            );
        for (final String input in buildOutputCompilerInputs[path] ?? const <String>[]) {
          rule.list('additional_compiler_inputs').addUnique(e.condition, _Item(input));
        }
        return;
      }
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
    required List<ForwardedFlag> propagatedFlags,
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
          for (final ForwardedFlag flag in flagsOfConfig(local)) {
            propagatedFlags.add((
              condition: assignment.condition.and(flag.condition),
              flag: flag.flag,
            ));
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
          case ConfigDependency(:final String label, :final List<String> copts):
            if (assignment.op == '-=') {
              throw GnError(assignment.location, 'removing config $config is not supported');
            }
            final attribute = private && local == null && rule.kind == 'cc_library'
                ? 'implementation_deps'
                : 'deps';
            rule.list(attribute).addUnique(assignment.condition, _item(label, element));
            // The config's compiler flags, which the dependency cannot
            // carry: on this target's compiles, after its own flags and
            // the constants, where a config's flags sit in GN.
            for (final flag in copts) {
              rule
                  .list('copts')
                  .addUnique(assignment.condition, _Item(flag, comment: 'from $config'));
            }
            if (!private) {
              // Listed publicly, the config's flags reach dependents too.
              for (final flag in copts) {
                propagatedFlags.add((condition: assignment.condition, flag: flag));
              }
            }
          case ConfigImplied():
            break;
          case ConfigCopts(:final List<(Condition, List<String>)> copts):
            if (assignment.op == '-=') {
              throw GnError(assignment.location, 'removing config $config is not supported');
            }
            if (!private) {
              throw GnError(
                assignment.location,
                'config $config carries flags alone and can only be listed privately',
              );
            }
            for (final (Condition condition, List<String> flags) in copts) {
              // The table's condition as GN would have evaluated it here.
              final Condition under = assignment.condition.and(assumptions.apply(condition));
              if (under == Condition.never) {
                continue;
              }
              for (final flag in flags) {
                rule.list('copts').addUnique(under, _Item(flag, comment: 'from $config'));
              }
            }
          case ConfigToolchain(:final List<String> removalCopts):
            if (assignment.op != '-=') {
              // Already on every compile.
              break;
            }
            if (!assignment.isUnconditional) {
              throw GnError(assignment.location, 'conditional removal of $config is not supported');
            }
            for (final flag in removalCopts) {
              rule
                  .list('copts')
                  .addUnique(Condition.always, _Item(flag, comment: 'configs -= $config'));
            }
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
    final List<GnScalarCase> cases = _enumerated(
      variable.cases(variable.assignments.first.location),
      variable.assignments.first.location,
    );
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
    // The cases exclude each other by construction (each stands only where
    // no later write happens), so their keys never match together. The one
    // key added beside them -- `None` under the complement of a case that is
    // a negation, where GN leaves the variable undefined -- must not overlap
    // another case either, or Bazel would find two keys with two values.
    final branches = <String, String>{};
    final resolved = <GnScalarCase, _SelectKeys>{
      for (final scalarCase in cases)
        scalarCase: _selectKeys(
          scalarCase.condition,
          rule,
          scalarCase.assignment.location,
          () => 'of the value of ${variable.name} (${rule.kind} ${rule.name})',
        ),
    };
    for (final scalarCase in cases) {
      final _SelectKeys keys = resolved[scalarCase]!;
      if (!keys.negated) {
        for (final String setting in keys.settings) {
          branches[setting] = _scalarText(scalarCase);
        }
      }
    }
    String? fallback;
    for (final scalarCase in cases) {
      final _SelectKeys keys = resolved[scalarCase]!;
      if (!keys.negated) {
        continue;
      }
      if (fallback != null) {
        throw GnError(
          scalarCase.assignment.location,
          'two values of ${variable.name} hold under negations; a select() has one default',
        );
      }
      fallback = _scalarText(scalarCase);
      // The complement's terms, one per key: `!is_win && !is_mac` (the
      // else of a chain) has `is_win` and `is_mac`, which are other cases'
      // own keys and keep their values; a term that merely overlaps another
      // case would make two keys match with two values.
      final List<Condition> complementTerms = switch (scalarCase.condition) {
        ConditionAnd(:final List<Condition> terms) => <Condition>[
          for (final Condition t in terms) t.negated,
        ],
        final Condition c => <Condition>[c.negated],
      };
      for (var i = 0; i < keys.settings.length; i++) {
        final String setting = keys.settings[i];
        if (branches.containsKey(setting)) {
          continue;
        }
        final Condition term = complementTerms[i];
        for (final other in cases) {
          if (other != scalarCase && term.and(other.condition) != Condition.never) {
            throw GnError(
              scalarCase.assignment.location,
              '${variable.name} is unset where `$term` holds without `${other.condition}`, '
              'which a select() cannot say beside the value under `${other.condition}`; '
              'give the assignment under `${scalarCase.condition}` an else branch',
            );
          }
        }
        branches[setting] = 'None';
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
    // The rules first, into their own buffer: rendering a select() under a
    // conjunction may add that conjunction's config_setting_group to the
    // rules (rendered in its turn, by index) and a load() to the file's,
    // which the header below must then carry.
    final body = StringBuffer();
    for (var i = 0; i < rules.length; i++) {
      body.writeln();
      _renderRule(body, rules[i]);
    }
    final out = StringBuffer()
      ..write(_licenseHeader)
      ..writeln()
      ..writeln('# Generated from $gnPackage/BUILD.gn by gn_to_bazel; do not edit.');
    if (skipped.isNotEmpty) {
      out.writeln('# Not converted: ${skipped.join(', ')}.');
    }
    if (usedUnconvertedDeps.isNotEmpty) {
      final List<String> left = unconvertedDeps.where(usedUnconvertedDeps.contains).toList();
      out.writeln('# Dependencies left out, having no Bazel counterpart yet: ${left.join(', ')}.');
    }
    out.writeln();
    final List<String> loadFiles = loads.keys.toList()..sort(_compareLoads);
    for (final bzl in loadFiles) {
      final List<String> symbols = loads[bzl]!.toList()..sort();
      out.writeln('load("$bzl", ${symbols.map((String s) => '"$s"').join(', ')})');
    }
    // One blank line between the header and the package() (a file of
    // filegroups alone loads nothing).
    if (loadFiles.isNotEmpty) {
      out.writeln();
    }
    out
      ..writeln('package(default_visibility = ["//visibility:public"])')
      ..write(body);
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

  // buildifier's priority table, as far as the generated files use it.
  static const List<String> _leadingAttributes = <String>[
    'name',
    'size',
    'testonly',
    'src',
    'srcs',
    'out',
    'outs',
    'hdrs',
  ];
  // buildifier's order: `deps` and `alwayslink` trail; `implementation_deps`
  // is not in its priority table and sorts with the rest.
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
  /// does not sort across) do not leak into the result. The names are from
  /// buildifier's table of sortable list arguments (`fixtures` is not, but
  /// GN's order of fixtures carries no meaning either). `includes` is in
  /// buildifier's table too, but its order is the compiler's search order --
  /// freetype2's `include/freetype-flutter-config` ahead of `include`, so
  /// that Flutter's public-macros.h hides the API where the stock one
  /// exports it -- so the emitter keeps GN's and marks a list buildifier
  /// would reorder `# do not sort` ([_keptOrderAttributes]).
  static const Set<String> _sortedAttributes = <String>{
    'srcs',
    'hdrs',
    'deps',
    'implementation_deps',
    'data',
    'tags',
    'tools',
    'visibility',
    'fixtures',
  };

  /// Attributes buildifier sorts whose order the build reads: emitted in
  /// GN's order, `# do not sort` leading a list that is not in buildifier's.
  static const Set<String> _keptOrderAttributes = <String>{'includes'};

  void _renderList(StringBuffer out, _ListAttribute list, _Rule rule, String attribute) {
    final bool sorted = _sortedAttributes.contains(attribute);
    final bool keepOrder = _keptOrderAttributes.contains(attribute);
    final parts = <String>[];
    // Bare list constants (FLUTTER_COPTS, FLUTTER_LOCAL_DEFINES) stand as
    // themselves wherever they sit; the
    // elements between them form list literals (a target's own flags lead
    // its copts, ahead of the constants, as in GN).
    bool constant(_Item item) => !item.quoted && !item.expression && item.comment == null;
    final elements = <_Item>[];
    void flush() {
      if (elements.isNotEmpty) {
        parts.add(
          _renderItems(sorted ? _sortItems(elements) : elements, indent: 4, keepOrder: keepOrder),
        );
        elements.clear();
      }
    }

    void unconditional(List<_Item> items) {
      for (final item in items) {
        if (constant(item)) {
          flush();
          parts.add(item.text);
        } else {
          elements.add(item);
        }
      }
      flush();
    }

    if (!sorted && list.conditional.isNotEmpty && list.hasOrder) {
      // In GN's order: a run of unconditional items, a select() for a run
      // under one condition, and so on -- the compiler reads these
      // attributes in order (an include directory's place is its priority).
      Condition? current;
      final run = <_Item>[];
      void flushRun() {
        if (run.isEmpty) {
          return;
        }
        if (current == Condition.always) {
          unconditional(run);
        } else {
          parts.add(_renderSelect(current!, List<_Item>.of(run), rule, keepOrder: keepOrder));
        }
        run.clear();
      }

      for (final (Condition condition, _Item item) in list.sequence) {
        if (condition != current) {
          flushRun();
          current = condition;
        }
        run.add(item);
      }
      flushRun();
      out.write(parts.join(' + '));
      return;
    }
    unconditional(list.always);
    if (parts.isEmpty && list.conditional.isEmpty) {
      parts.add('[]');
    }
    for (final MapEntry<Condition, List<_Item>> entry in list.conditional.entries) {
      parts.add(
        _renderSelect(
          entry.key,
          sorted ? _sortItems(entry.value) : entry.value,
          rule,
          keepOrder: keepOrder,
        ),
      );
    }
    out.write(parts.join(' + '));
  }

  /// A select() branch's items: list constants (FLUTTER_CFLAGS_OBJC under
  /// test_enable_metal) stand as themselves, joined by `+` with the list
  /// literals of the elements around them, as [_renderList] lays out an
  /// attribute; a constant's comment has no place in the expression.
  static String _renderBranch(List<_Item> items, {required int indent, bool keepOrder = false}) {
    if (!items.any((_Item item) => !item.quoted && !item.expression)) {
      return _renderItems(items, indent: indent, keepOrder: keepOrder);
    }
    final parts = <String>[];
    final elements = <_Item>[];
    void flush() {
      if (elements.isNotEmpty) {
        parts.add(_renderItems(elements, indent: indent, keepOrder: keepOrder));
        elements.clear();
      }
    }

    for (final item in items) {
      if (!item.quoted && !item.expression) {
        flush();
        parts.add(item.text);
      } else {
        elements.add(item);
      }
    }
    flush();
    return parts.join(' + ');
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

    return List<_Item>.of(items)..sort((_Item a, _Item b) {
      final int byPhase = phase(a).compareTo(phase(b));
      if (byPhase != 0) {
        return byPhase;
      }
      return compareBuildifierStrings(a.text, b.text);
    });
  }

  /// Whether [items] already stand in buildifier's order ([_sortItems]).
  static bool _inBuildifierOrder(List<_Item> items) {
    final List<_Item> sorted = _sortItems(items);
    for (var i = 0; i < items.length; i++) {
      if (items[i].text != sorted[i].text) {
        return false;
      }
    }
    return true;
  }

  /// A list literal of [items]; with [keepOrder], in their order, led by
  /// `# do not sort` when it is not the order buildifier would put them in.
  static String _renderItems(List<_Item> items, {required int indent, bool keepOrder = false}) {
    if (items.isEmpty) {
      return '[]';
    }
    if (items.length == 1 && items.single.comment == null && items.single.before.isEmpty) {
      return '[${items.single.starlark}]';
    }
    final String pad = ' ' * (indent + 4);
    final out = StringBuffer('[\n');
    if (keepOrder && !_inBuildifierOrder(items)) {
      out.writeln('$pad# do not sort');
    }
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
  String _renderSelect(
    Condition condition,
    List<_Item> items,
    _Rule rule, {
    bool keepOrder = false,
  }) {
    final _SelectKeys keys = _selectKeys(
      condition,
      rule,
      GnLocation('$gnPackage/BUILD.gn', 0, 0),
      () => 'on ${rule.kind} ${rule.name}',
    );
    final String branch = _renderBranch(items, indent: 8, keepOrder: keepOrder);
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
        // A conjunction among the alternatives (Skia's fontmgr_custom:
        // `skia_enable_fontmgr_android || ...`, the former being
        // `!is_wasm && skia_use_freetype`) is its match_all group, one key
        // among the others.
        return _SelectKeys(<String>[
          for (final Condition t in terms)
            if (t case ConditionAnd(terms: final List<Condition> conjuncts))
              _conjunctionSetting(t, conjuncts, rule, location, where)
            else
              _setting(t, rule),
        ], negated: false);
      case ConditionAnd(:final List<Condition> terms)
          when terms.every(
            (Condition t) => t is ConditionNot || t is ConditionComparison && !t.equals,
          ):
        return _SelectKeys(<String>[
          for (final Condition t in terms) _setting(t.negated, rule),
        ], negated: true);
      case ConditionAnd(:final List<Condition> terms):
        return _SelectKeys(<String>[
          _conjunctionSetting(condition, terms, rule, location, where),
        ], negated: false);
      default:
        throw GnError(
          location,
          'condition `$condition` ${where()} cannot be expressed as a select()',
        );
    }
  }

  /// A `config_setting_group(match_all = ...)` of this file for a
  /// conjunction of mixed settings (`impeller_enable_opengles && !is_wasm`):
  /// each asserted term by its setting, each denied OS predicate by the
  /// complement group of //engine/src/flutter/build/bazel. One per distinct
  /// condition, named after it.
  String _conjunctionSetting(
    Condition condition,
    List<Condition> terms,
    _Rule rule,
    GnLocation location,
    String Function() where,
  ) {
    final String? existing = _conjunctionGroups[condition];
    if (existing != null) {
      return existing;
    }
    final settings = <String>[];
    for (final term in terms) {
      switch (term) {
        case ConditionVariable():
        case ConditionComparison():
          settings.add(_setting(term, rule));
        case ConditionNot(operand: ConditionVariable(:final String name))
            when negatedSettings.containsKey(name):
          settings.add(_absoluteLabel(negatedSettings[name]!));
        case ConditionOr(terms: final List<Condition> alternatives):
          // A disjunction among the terms (`impeller_supports_rendering &&
          // enable_unittests`, the former being the three backends): its
          // own match_any group, one member of this one.
          settings.add(_disjunctionSetting(term, alternatives, rule, location, where));
        default:
          throw GnError(
            location,
            'condition `$condition` ${where()} cannot be expressed as a select(): '
            'no config_setting holds exactly when `$term` does',
          );
      }
    }
    return _group(condition, 'match_all', settings);
  }

  /// A `config_setting_group(match_any = ...)` for a disjunction that is a
  /// term of a conjunction (a select() key can hold a disjunction's terms
  /// side by side, but a match_all member cannot).
  String _disjunctionSetting(
    Condition condition,
    List<Condition> terms,
    _Rule rule,
    GnLocation location,
    String Function() where,
  ) {
    final String? existing = _conjunctionGroups[condition];
    if (existing != null) {
      return existing;
    }
    final settings = <String>[];
    for (final term in terms) {
      switch (term) {
        case ConditionVariable():
        case ConditionComparison():
          settings.add(_setting(term, rule));
        case ConditionNot(operand: ConditionVariable(:final String name))
            when negatedSettings.containsKey(name):
          settings.add(_absoluteLabel(negatedSettings[name]!));
        default:
          throw GnError(
            location,
            'condition `$condition` ${where()} cannot be expressed as a select(): '
            'no config_setting holds exactly when `$term` does',
          );
      }
    }
    return _group(condition, 'match_any', settings);
  }

  /// The group for [condition] over [settings], added to the file's rules
  /// once and named after the condition.
  String _group(Condition condition, String kind, List<String> settings) {
    final name =
        'when_${condition.gnSource.replaceAll('&&', 'and').replaceAll('||', 'or').replaceAll('!', 'not_').replaceAll(RegExp('[^A-Za-z0-9_]+'), '_').replaceAll(RegExp('_+'), '_').replaceAll(RegExp(r'^_|_$'), '')}';
    _use('@bazel_skylib//lib:selects.bzl', 'selects');
    final group = _Rule('selects.config_setting_group', name, <String>[
      '# `$condition`, for the select()s of this file.',
    ]);
    for (final setting in settings) {
      group.list(kind).always.add(_Item(setting));
    }
    rules.add(group);
    _conjunctionGroups[condition] = ':$name';
    return ':$name';
  }

  /// The config_setting that is true exactly when [condition] (a variable,
  /// an equality, or a denied variable with a complement setting -- a term
  /// of a disjunction, `!enable_backtrace || is_wasm`) holds.
  String _setting(Condition condition, _Rule rule) {
    final String? setting = switch (condition) {
      ConditionVariable(:final String name) => conditionSettings[name],
      ConditionComparison(:final String name, equals: true, :final String value) =>
        comparisonSettings[name]?[value],
      ConditionComparison(:final String name, equals: false, :final String value) =>
        comparisonNegatedSettings[name]?[value],
      ConditionNot(operand: ConditionVariable(:final String name)) => negatedSettings[name],
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
