// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The compiler flags a GN target hands its dependents, read from the
/// dependency's own GN file.
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
/// A dependency whose file is absent or does not evaluate (the Dart
/// runtime's, abseil's: their imports are outside the converter's policy)
/// hands nothing, as far as the converter can tell; none of those carries
/// compiler flags in a public config today, and the compile-command parity
/// check (tool/compile_command_diff.py) is the backstop.
library;

import 'dart:io';

import 'bazel_mapping.dart';
import 'gn_ast.dart';
import 'gn_eval.dart';
import 'manifest.dart';

/// A compiler flag a target hands its dependents, and when.
typedef ForwardedFlag = ({Condition condition, String flag});

/// Resolves the flags a GN target (`//dir:name`) hands its dependents.
final class ForwardedFlags {
  /// A resolver over [tree], evaluating dependency files under
  /// [assumptions]; one per conversion run, so that every file is
  /// evaluated once.
  ForwardedFlags({required GnSourceTree tree, required Assumptions assumptions})
    : _tree = tree,
      _assumptions = assumptions;

  /// A resolver with no tree to read: every dependency hands nothing (a
  /// lone file converted without its tree, as in tests).
  ForwardedFlags.none() : _tree = null, _assumptions = null;

  final GnSourceTree? _tree;
  final Assumptions? _assumptions;

  /// Evaluations by GN directory; null for a file that is absent or does
  /// not evaluate.
  final Map<String, GnFileEvaluation?> _evaluations = <String, GnFileEvaluation?>{};
  final Map<String, List<ForwardedFlag>> _flags = <String, List<ForwardedFlag>>{};

  /// The flags [label] (`//dir:name`) hands its dependents; empty when it
  /// hands none, or when its file cannot say.
  List<ForwardedFlag> of(String label) => _flags.putIfAbsent(label, () => _derive(label));

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
          forwarded: of,
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
      final String file = tree.resolve('$directory/BUILD.gn');
      if (!File(file).existsSync()) {
        return null;
      }
      try {
        return evaluateGnFile(
          tree.load(file),
          assumptions: assumptions,
          templates: templateMappings.keys.toSet(),
          externalVariables: knownExternalVariables,
          skipTargets: manifestEntry(directory)?.skip.keys.toSet() ?? const <String>{},
          tree: tree,
          importPolicy: engineImportPolicy,
        );
      } on GnError {
        // A file the converter cannot read says nothing.
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
          flags.add((condition: item.condition, flag: flag));
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
/// target's flags, so a target's never takes effect.
List<ForwardedFlag> flagsOfConfig(GnTarget config) {
  return <ForwardedFlag>[
    for (final GnVariable variable in config.variables.values)
      if (flagVariables.contains(variable.name))
        for (final GnListItem item in variable.liveItems)
          if (item.value case GnStringValue(:final String value) when !value.startsWith('-std='))
            (condition: item.condition, flag: value),
  ];
}
