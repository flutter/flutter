// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// What a conversion needs to know about targets of other GN files, read
/// from those files: the compiler flags a target hands its dependents, and
/// the target itself (for the files it produces, which an archive packs).
///
/// GN applies a dependency's `public_configs` (and `all_dependent_configs`)
/// to the dependent's compiles, and forwards them along `public_deps`
/// chains: whoever depends on A also gets the public configs of A's
/// public_deps, and of theirs. wuffs turns warnings off for whoever
/// includes it that way, the Vulkan allocator's suppressions reach
/// everything on `//flutter/impeller`'s public side, and gmock's
/// `-Wno-inconsistent-missing-override` reaches a test through
/// `//flutter/testing:testing_core`'s public_deps. Bazel cannot carry a
/// compiler flag along a dependency, so the converter puts such flags on
/// the dependent's own `copts` (`_propagatedFlagsInto` in
/// starlark_emitter.dart), and this resolver finds them: it evaluates the
/// dependency's `BUILD.gn` under the same assumptions (once per file;
/// memoized) and reads the target's public configs -- the flags of configs
/// of its own file, the mapped copts of foreign ones (`configEffects`) --
/// plus, recursively, what its public_deps hand on. Each flag comes with
/// the condition it is handed on under (a config listed under `is_clang`,
/// a flag the config sets under one, a public dependency under one), which
/// the dependent's `copts` take as a `select()` on top of its own. The
/// owner's conversion checks the same reading against its own
/// (`_checkPropagatedFlags`).
///
/// A dependency whose file is absent or belongs to a tree the converter
/// does not read (the Dart runtime's, abseil's: their imports are outside
/// the converter's policy) hands nothing, as far as the converter can tell;
/// none of those carries compiler flags in a public config today, and the
/// compile-command parity check (tool/compile_command_diff.py) is the
/// backstop. A file within the policy that does not evaluate is an error:
/// the converter reads it for its conversion too, and a regression there
/// must not silently take a dependency's flags away.
///
/// The same evaluations answer [DependencyResolver.targetOf]: the target a
/// label names, for a `zip_bundle` whose `files` name a build output
/// (`$root_build_dir/impellerc`) that a target of another file produces.
library;

import 'dart:io';

import 'bazel_mapping.dart';
import 'gn_ast.dart';
import 'gn_eval.dart';
import 'manifest.dart';

/// A compiler flag a target hands its dependents, and when: a string, or a
/// string around references the Bazel side holds as constants
/// ([GnExpandedString]; darwin/common's test_config names the Xcode
/// platform's directories through `mac_platform_path`).
typedef ForwardedFlag = ({Condition condition, GnValue flag});

/// Resolves what other GN files say about their targets: the flags a target
/// (`//dir:name`) hands its dependents, and the target itself.
final class DependencyResolver {
  /// A resolver over [tree], evaluating dependency files under
  /// [assumptions]; one per conversion run, so that every file is
  /// evaluated once.
  DependencyResolver({required GnSourceTree tree, required Assumptions assumptions})
    : _tree = tree,
      _assumptions = assumptions;

  /// A resolver with no tree to read: every dependency hands nothing and
  /// no target is found (a lone file converted without its tree, as in
  /// tests).
  DependencyResolver.none() : _tree = null, _assumptions = null;

  final GnSourceTree? _tree;
  final Assumptions? _assumptions;

  /// Evaluations by GN directory; null for a file that is absent or does
  /// not evaluate.
  final Map<String, GnFileEvaluation?> _evaluations = <String, GnFileEvaluation?>{};
  final Map<String, List<ForwardedFlag>> _flags = <String, List<ForwardedFlag>>{};

  /// The flags [label] (`//dir:name`) hands its dependents; empty when it
  /// hands none, or when its file cannot say.
  List<ForwardedFlag> flagsOf(String label) => _flags.putIfAbsent(label, () => _derive(label));

  /// The evaluation of the `BUILD.gn` of [directory] (`//flutter/fml`), or
  /// null when the file is absent or does not evaluate.
  GnFileEvaluation? evaluationOf(String directory) => _evaluate(directory);

  /// The target [label] (`//dir:name`) names, other than a config, or null
  /// when its file is absent, does not evaluate, or has no such target.
  /// GN's placeholder idiom defines a name twice (the real target under a
  /// condition, an empty group otherwise): the one that is not a group.
  GnTarget? targetOf(String label) {
    final int colon = label.indexOf(':');
    if (colon < 0 || !label.startsWith('//')) {
      return null;
    }
    final String name = label.substring(colon + 1);
    final targets = <GnTarget>[
      ...?_evaluate(label.substring(0, colon))?.targets
          .where((GnTarget t) => t.rule != 'config' && t.name == name),
    ];
    if (targets.length > 1) {
      targets.removeWhere((GnTarget t) => t.rule == 'group');
    }
    return targets.length == 1 ? targets.single : null;
  }

  /// The config() [label] names in its file (evaluated as [targetOf]
  /// evaluates it), or null: no such file, or no such config. A config and
  /// a target may share a name; [targetOf] leaves the configs out.
  GnTarget? configOf(String label) {
    final int colon = label.indexOf(':');
    if (colon < 0 || !label.startsWith('//')) {
      return null;
    }
    final String name = label.substring(colon + 1);
    final configs = <GnTarget>[
      ...?_evaluate(label.substring(0, colon))?.targets
          .where((GnTarget t) => t.rule == 'config' && t.name == name),
    ];
    return configs.length == 1 ? configs.single : null;
  }

  List<ForwardedFlag> _derive(String label) {
    final int colon = label.indexOf(':');
    if (colon < 0 || !label.startsWith('//')) {
      return const <ForwardedFlag>[];
    }
    final String directory = label.substring(0, colon);
    final String name = label.substring(colon + 1);
    final GnFileEvaluation? evaluation = _evaluate(directory);
    if (evaluation == null) {
      return const <ForwardedFlag>[];
    }
    final localConfigs = <String, GnTarget>{
      for (final GnTarget target in evaluation.targets)
        if (target.rule == 'config') target.name: target,
    };
    // GN's placeholder idiom defines the name twice (the real target under
    // a condition, an empty group otherwise); the group hands nothing on.
    final flags = <ForwardedFlag>[];
    for (final GnTarget target in evaluation.targets) {
      if (target.rule != 'config' && target.name == name) {
        for (final ForwardedFlag flag in publicFlagsOf(
          target,
          gnPackage: directory,
          localConfigs: localConfigs,
          forwarded: flagsOf,
        )) {
          if (!flags.contains(flag)) {
            flags.add(flag);
          }
        }
      }
    }
    return flags;
  }

  GnFileEvaluation? _evaluate(String directory) {
    final GnSourceTree? tree = _tree;
    final Assumptions? assumptions = _assumptions;
    if (tree == null || assumptions == null) {
      return null;
    }
    return _evaluations.putIfAbsent(directory, () {
      // A repository whose targets are never converted (the Dart tree's,
      // wrapped whole; its labels go through labelOverrides to the wrap's
      // facades, which carry what their GN public configs would): its
      // files say nothing here, and may not even read under the engine's
      // assumptions (double-conversion's tests is_posix, BUILDCONFIG.gn's).
      if (fileRepositoryPrefixes.keys.any((String prefix) => '$directory/'.startsWith(prefix))) {
        return null;
      }
      final String file = tree.resolve('$directory/BUILD.gn');
      if (!File(file).existsSync()) {
        return null;
      }
      try {
        final ConvertedFile? manifest = manifestEntry(directory);
        return evaluateGnFile(
          tree.load(file),
          // Under the file's own assumptions (the manifest's `assume`), as
          // its conversion evaluates it: a file whose macOS branches are
          // deferred reads the same way here, rather than failing on an
          // import of a branch its conversion never takes.
          assumptions: manifest == null || manifest.assume.isEmpty
              ? assumptions
              : assumptions.withValues(manifest.assume),
          templates: templateMappings.keys.toSet(),
          externalVariables: knownExternalVariables,
          booleanVariables: knownBooleanVariables,
          skipTargets: manifest?.skip.keys.toSet() ?? const <String>{},
          tree: tree,
          importPolicy: engineImportPolicy,
          // The file's own condition (the Android shell's is_android), as
          // its conversion evaluates it.
          condition: manifest?.condition == null
              ? Condition.always
              : ConditionVariable(manifest!.condition!),
          targetConditions: <String, Condition>{
            for (final MapEntry<String, String> entry
                in (manifest?.targetConditions ?? const <String, String>{}).entries)
              entry.key: ConditionVariable(entry.value),
          },
        );
      } on GnError catch (e) {
        // A file of a tree the converter does not read (one importing a
        // file outside the import policy) says nothing. Any other error is
        // the converter's own -- a file it read yesterday and cannot today
        // would otherwise hand nothing, silently (glslang's -Wno-conversion
        // went missing that way once) -- and fails the conversion.
        if (!e.isUnreadImport) {
          rethrow;
        }
        return null;
      }
    });
  }
}

/// The variables of a config that hold compiler flags.
const Set<String> flagVariables = <String>{
  'cflags',
  'cflags_c',
  'cflags_cc',
  'cflags_objc',
  'cflags_objcc',
};

/// The compiler flags [target] hands its dependents, each under the
/// condition it does so: those of its public configs -- a config of its
/// own file ([localConfigs]) contributes its flags ([flagsOfConfig]), a
/// foreign one its mapped copts (`configEffects`), under the condition the
/// config is listed -- and those its public_deps hand on ([forwarded]),
/// which GN forwards in turn, under the condition of the dependency.
List<ForwardedFlag> publicFlagsOf(
  GnTarget target, {
  required String gnPackage,
  required Map<String, GnTarget> localConfigs,
  required List<ForwardedFlag> Function(String label) forwarded,
}) {
  final flags = <ForwardedFlag>[];
  for (final name in <String>['public_configs', 'all_dependent_configs']) {
    for (final GnListItem item in target.variables[name]?.liveItems ?? const <GnListItem>[]) {
      final GnValue value = item.value;
      if (value is! GnStringValue) {
        continue;
      }
      final String config = value.value;
      if (config.startsWith(':')) {
        final GnTarget? local = localConfigs[config.substring(1)];
        if (local == null) {
          continue;
        }
        for (final ForwardedFlag flag in flagsOfConfig(local)) {
          flags.add((condition: item.condition.and(flag.condition), flag: flag.flag));
        }
        continue;
      }
      final ConfigEffect? effect =
          configEffects[config] ??
          configEffects[absoluteGnLabel(config, package: gnPackage, implicitName: true)];
      if (effect is ConfigDependency) {
        for (final String flag in effect.copts) {
          flags.add((condition: item.condition, flag: GnStringValue(flag)));
        }
      }
    }
  }
  for (final GnListItem item
      in target.variables['public_deps']?.liveItems ?? const <GnListItem>[]) {
    final GnValue value = item.value;
    if (value is! GnStringValue) {
      continue;
    }
    for (final ForwardedFlag flag in forwarded(
      absoluteGnLabel(value.value, package: gnPackage, implicitName: true),
    )) {
      flags.add((condition: item.condition.and(flag.condition), flag: flag.flag));
    }
  }
  return flags;
}

/// The compiler flags of [config], each under the condition it is set
/// -- `-std=` aside: GN's compiler config sets the standard after every
/// target's flags, so a target's never takes effect. An include directory
/// outside the tree, named around a constant (test_config's
/// `$mac_platform_path/Developer/usr/lib`), is a compile flag too, `-I<dir>`
/// (the emitter's _includeDirsInto): Bazel's `includes` cannot carry it.
List<ForwardedFlag> flagsOfConfig(GnTarget config) {
  final flags = <ForwardedFlag>[];
  for (final GnVariable variable in config.variables.values) {
    if (flagVariables.contains(variable.name)) {
      for (final GnListItem item in withoutSystemIncludeDirs(variable.liveItems)) {
        switch (item.value) {
          case GnStringValue(:final String value) when !value.startsWith('-std='):
          case GnExpandedString():
            flags.add((condition: item.condition, flag: item.value));
          default:
            break;
        }
      }
    } else if (variable.name == 'include_dirs') {
      for (final GnListItem item in variable.liveItems) {
        if (item.value case GnExpandedString(:final List<GnValue> parts)) {
          final GnValue first = parts.first;
          flags.add((
            condition: item.condition,
            flag: GnExpandedString(<GnValue>[
              if (first is GnStringValue)
                GnStringValue('-I${first.value}')
              else ...<GnValue>[const GnStringValue('-I'), first],
              ...parts.sublist(1),
            ]),
          ));
        }
      }
    }
  }
  return flags;
}

/// [items] less the `-isystem <dir>` pairs whose directory is a
/// `rebase_path()` result: a config that names its include directories a
/// second time as system include directories (Skia's third-party ICU and
/// brotli: `foreach(dir, include_dirs) { cflags += [ "-isystem",
/// rebase_path(dir) ] }`). Bazel reaches a directory through the
/// `includes` of the library that carries it, spelled as the toolchain
/// spells include directories (-I, as GN's include_dirs are), and a flag
/// cannot name a directory of another repository; the pair goes.
List<GnListItem> withoutSystemIncludeDirs(List<GnListItem> items) {
  final kept = <GnListItem>[];
  for (var i = 0; i < items.length; i++) {
    if (i + 1 < items.length &&
        items[i].value == const GnStringValue('-isystem') &&
        items[i + 1].value is GnStringValue &&
        (items[i + 1].value as GnStringValue).value.startsWith(rebasedPathMarker)) {
      i++;
      continue;
    }
    kept.add(items[i]);
  }
  return kept;
}
