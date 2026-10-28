// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:gn_to_bazel/gn_to_bazel.dart';
import 'package:path/path.dart' as p;

/// Checks the converter's reading of GN files against GN's own.
///
///     dart tool/gn_desc_diff.dart --out=out/host_debug_unopt [--assume=x=y]... <BUILD.gn>...
///
/// For every target of each file, what the converter evaluates (sources,
/// public headers, dependencies, and the defines of configs) is compared
/// with `gn desc <out> <label> --format=json`, GN's resolved view of the
/// same target in that out directory. The assumptions are the out
/// directory's: its arguments (`gn args --list`: is_debug, the Skia,
/// Impeller and shell arguments, use_ios_simulator) and what BUILDCONFIG.gn
/// and config.gni derive from its target and host (the OS predicates, the
/// toolchains, the platform names; outDirectoryAssumptions), over the Linux
/// host build's for the rest; `--assume` overrides any of them. So the tool
/// reads a Mac host or an iOS simulator directory on a Mac as it reads a
/// Linux host one. A difference is a converter bug or a GN construct it
/// reads wrongly; the exit code is 1 when there is one.
///
/// This is the oracle for a new conversion: the generated BUILD.bazel is
/// right when this agrees and Bazel builds it.
Future<void> main(List<String> arguments) async {
  exitCode = await run(arguments);
}

Future<int> run(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('root', help: 'The GN source root.', defaultsTo: _defaultRoot())
    ..addOption(
      'out',
      help: 'The GN out directory to compare with (under --root).',
      mandatory: true,
    )
    ..addMultiOption('assume', help: 'GN values beyond the Linux host defaults, as name=value.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    return 64;
  }
  if (options.flag('help') || options.rest.isEmpty) {
    stdout.writeln('Usage: dart tool/gn_desc_diff.dart --out=<dir> [options] <BUILD.gn>...\n');
    stdout.writeln(parser.usage);
    return options.rest.isEmpty ? 64 : 0;
  }
  final String root = p.canonicalize(options.option('root')!);
  final String gn = p.join(root, 'flutter/third_party/gn/gn');
  final String outDir = p.join(root, options.option('out'));
  // GN spells the build directory's paths by its real location (an out
  // directory reached through a symbolic link is described under its
  // target), so the normalization below uses that.
  final String outDirectory = p.relative(
    Directory(outDir).existsSync() ? Directory(outDir).resolveSymbolicLinksSync() : outDir,
    from: root,
  );
  // The out directory's own arguments, and what BUILDCONFIG.gn derives from
  // them (outDirectoryAssumptions), over the Linux host build's; --assume
  // on top.
  final Map<String, GnValue> args = await _gnArgs(gn, outDir);
  final Assumptions assumptions = outDirectoryAssumptions(args).withValues(<String, GnValue>{
    for (final String spec in options.multiOption('assume'))
      spec.substring(0, spec.indexOf('=')): Assumptions.parseValue(
        spec.substring(spec.indexOf('=') + 1),
      ),
  });
  final Map<String, List<String>> referenceValues = _referenceValues(args);
  final tree = GnSourceTree(root, gnBinary: gn);

  var differences = 0;
  var compared = 0;
  for (final String input in options.rest) {
    final String file = p.canonicalize(input);
    final String gnPackage = tree.gnDirectory(file);
    final Set<String> skip = manifestEntry(gnPackage)?.skip.keys.toSet() ?? const <String>{};
    final GnFileEvaluation evaluation;
    try {
      evaluation = evaluateGnFile(
        tree.load(file),
        assumptions: assumptions,
        templates: templateMappings.keys.toSet(),
        externalVariables: knownExternalVariables,
        booleanVariables: knownBooleanVariables,
        skipTargets: skip,
        tree: tree,
        importPolicy: engineImportPolicy,
      );
    } on GnError catch (e) {
      stderr.writeln('error: $e');
      differences++;
      continue;
    }
    // `dir:*` describes the targets; configs are described one by one (a
    // directory of configs alone has no targets, and gn desc says so).
    final Map<String, Object?> described = await _gnDesc(
      gn,
      outDir,
      '$gnPackage:*',
      failIfMissing: false,
    );
    final seen = <String>{...skip.map((String name) => '$gnPackage:$name')};
    // The all_dependent_configs the file itself names (as opposed to those
    // GN propagates in from dependencies in other files).
    final named = <String>{
      for (final GnTarget t in evaluation.targets)
        for (final GnAssignment a
            in t.variables['all_dependent_configs']?.assignments ?? const <GnAssignment>[])
          for (final GnValue v in a.items)
            if (v is GnStringValue) _absoluteLabel(v.value, gnPackage),
    };
    // A config nesting a config of another file (`configs = [
    // "//flutter/impeller:impeller_public_config" ]`): gn desc flattens it
    // into the nesting config; the converter makes it a dependency on that
    // config's library, which carries the same, so its own description
    // stands for it here.
    final nestedElsewhere = <String, Map<String, Object?>>{};
    for (final GnTarget target in evaluation.targets) {
      if (target.rule != 'config') {
        continue;
      }
      for (final GnValue nested
          in target.variables['configs']?.unconditionalItems ?? const <GnValue>[]) {
        if (nested is GnStringValue && !nested.value.startsWith(':')) {
          final String nestedLabel = _absoluteLabel(nested.value, gnPackage);
          final Map<String, Object?> config = await _gnDesc(
            gn,
            outDir,
            nestedLabel,
            failIfMissing: false,
          );
          nestedElsewhere[nestedLabel] = config[nestedLabel] as Map<String, Object?>? ?? const {};
        }
      }
    }
    for (final GnTarget target in evaluation.targets) {
      final label = '$gnPackage:${target.name}';
      seen.add(label);
      final TemplateMapping? template = templateMappings[target.rule];
      if (template != null) {
        // A known template becomes a Bazel macro; what it expands to in GN
        // (a group over `_`-prefixed targets, or the names the mapping
        // records) is the macro's business.
        for (final String inner in template.innerTargetsOf(target.name)) {
          seen.add('$gnPackage:$inner');
        }
        continue;
      }
      var gnTarget = described[label] as Map<String, Object?>?;
      if (gnTarget == null && target.rule == 'config') {
        final Map<String, Object?> config = await _gnDesc(gn, outDir, label, failIfMissing: false);
        gnTarget = config[label] as Map<String, Object?>?;
      }
      if (gnTarget == null) {
        if (target.condition != Condition.always) {
          // Defined under a condition the assumptions left open, which this
          // out directory may well decide against.
          stdout.writeln(
            '  $label: defined under ${target.condition}, which the GN build lacks '
            '(undecided; not compared)',
          );
          continue;
        }
        _report(label, 'is not in the GN build (gn desc knows nothing of it)');
        differences++;
        continue;
      }
      compared++;
      differences += _compare(
        label,
        target,
        gnTarget,
        gnPackage,
        evaluation.inheritedConfigs,
        namedAllDependentConfigs: named,
        localTargets: <String, GnTarget>{for (final GnTarget t in evaluation.targets) t.name: t},
        nestedElsewhere: nestedElsewhere,
        referenceValues: referenceValues,
        outDir: outDirectory,
      );
    }
    for (final String label in described.keys) {
      // GN's `_`-prefixed targets are the internals of template expansions;
      // a label with a toolchain suffix is another toolchain's instance of
      // a target compared under the default one (the host toolchain's fml
      // in an iOS build, for gen_snapshot).
      if (label.contains('(')) {
        continue;
      }
      if (!seen.contains(label) && !label.substring(label.indexOf(':') + 1).startsWith('_')) {
        _report(label, 'is in the GN build but the converter did not evaluate it');
        differences++;
      }
    }
  }
  stdout.writeln(
    '$compared target(s) compared, '
    '${differences == 0 ? 'no differences' : '$differences difference(s)'}',
  );
  return differences == 0 ? 0 : 1;
}

/// The values of the variables build files read by reference from an
/// imported `.gni`, as GN has them in the out directory.
///
/// The converter leaves such a reference as the Starlark constant
/// [referenceConstants] names (`FLUTTER_FEATURE_DEFINES`, the version strings
/// of `@engine_version`), whose Bazel-side content tool/compile_command_diff.py
/// checks against GN's compile commands; the comparison here needs the GN
/// value, read from the out directory's arguments ([_gnArgs]): the version
/// arguments as `tools/gn` set them, and `feature_defines_list` as
/// config.gni computes it from `flutter_runtime_mode` and `slimpeller`.
Map<String, List<String>> _referenceValues(Map<String, GnValue> args) {
  String string(String name) {
    final GnValue? value = args[name];
    return value is GnStringValue ? value.value : '';
  }

  final GnValue? slimpeller = args['slimpeller'];
  return <String, List<String>>{
    'feature_defines_list': <String>[
      'FLUTTER_RUNTIME_MODE_DEBUG=1',
      'FLUTTER_RUNTIME_MODE_PROFILE=2',
      'FLUTTER_RUNTIME_MODE_RELEASE=3',
      'FLUTTER_RUNTIME_MODE_JIT_RELEASE=4',
      'DART_LEGACY_API=[[deprecated]]',
      ...switch (string('flutter_runtime_mode')) {
        'debug' => const <String>['FLUTTER_RUNTIME_MODE=1', 'FLUTTER_JIT_RUNTIME=1'],
        'profile' => const <String>['FLUTTER_RUNTIME_MODE=2'],
        'release' => const <String>['FLUTTER_RUNTIME_MODE=3', 'FLUTTER_RELEASE=1'],
        'jit_release' => const <String>[
          'FLUTTER_RUNTIME_MODE=4',
          'FLUTTER_RELEASE=1',
          'FLUTTER_JIT_RUNTIME=1',
        ],
        _ => const <String>['FLUTTER_RUNTIME_MODE=0'],
      },
      if (slimpeller is GnBoolValue && slimpeller.value) 'SLIMPELLER=1',
    ],
    for (final String name in <String>[
      'engine_version',
      'content_hash',
      'skia_version',
      'dart_version',
    ])
      name: <String>[string(name)],
  };
}

/// The out directory's GN arguments (`gn args --list --short --json`): each
/// argument's current value, or its default where args.gn leaves it.
Future<Map<String, GnValue>> _gnArgs(String gn, String outDir) async {
  final ProcessResult result = await Process.run(gn, <String>[
    'args',
    outDir,
    '--list',
    '--short',
    '--json',
  ]);
  if (result.exitCode != 0) {
    throw StateError('gn args $outDir --list failed: ${result.stderr}');
  }
  final stdout = result.stdout as String;
  final entries = jsonDecode(stdout.substring(stdout.indexOf('['))) as List<Object?>;
  return <String, GnValue>{
    for (final Object? entry in entries)
      if (entry is Map<String, Object?>)
        entry['name']! as String: Assumptions.parseValue(
          ((entry['current'] ?? entry['default'])! as Map<String, Object?>)['value']! as String,
        ),
  };
}

/// Compares one target; returns the number of differences.
int _compare(
  String label,
  GnTarget target,
  Map<String, Object?> gnTarget,
  String gnPackage,
  Map<String, Map<String, Condition>> inherited, {
  required Set<String> namedAllDependentConfigs,
  required Map<String, GnTarget> localTargets,
  required Map<String, Map<String, Object?>> nestedElsewhere,
  required Map<String, List<String>> referenceValues,
  required String outDir,
}) {
  var differences = 0;
  // Items under conditions the assumptions did not decide cannot be
  // compared with one out directory; they are reported, not counted, and
  // GN having one of them is not the converter lacking it (it is in the
  // generated select()).
  final undecided = <String>[];
  final undecidedValues = <String>{};
  final notes = <String>[];
  // A value built on a reference constant the oracle has no value for (the
  // Xcode SDK paths of @macos_sdk, which GN computes at generation time):
  // its tail after the reference, which a GN value of the same tail
  // matches (`$mac_platform_path/Developer/usr/lib` against
  // `//flutter/prebuilts/Platforms/MacOSX.platform/Developer/usr/lib`).
  final referenceTails = <String>{};
  void check(
    String what,
    Set<String> ours,
    Set<String> theirs, {
    bool subset = false,
    Set<String> notOurs = const <String>{},
  }) {
    final Set<String> missing = subset
        ? const <String>{}
        : theirs
              .difference(ours)
              .difference(undecidedValues)
              .difference(notOurs)
              .where(
                (String t) =>
                    !referenceTails.any((String tail) => tail.isNotEmpty && t.endsWith(tail)),
              )
              .toSet();
    final Set<String> extra = ours.difference(theirs);
    if (missing.isEmpty && extra.isEmpty) {
      return;
    }
    differences++;
    _report(label, '$what differ');
    for (final String m in missing.toList()..sort()) {
      stdout.writeln('    GN has, converter lacks: $m');
    }
    for (final String e in extra.toList()..sort()) {
      stdout.writeln('    converter has, GN lacks: $e');
    }
  }

  // A config's description has no type.
  final String type = gnTarget['type'] as String? ?? 'config';
  if (type != target.rule) {
    _report(label, 'is a ${target.rule} to the converter, a $type to GN');
    differences++;
  }
  Set<String> items(String variable, String Function(String) normalize) {
    final GnVariable? v = target.variables[variable];
    if (v == null) {
      return const <String>{};
    }
    final result = <String>{};
    // The values of one item: a string's itself, a reference's its known
    // values, an expansion's the parts joined. A reference the oracle has
    // no value for (a constant of the Bazel build) yields none; an
    // expansion built on one is matched by its literal tail instead
    // (referenceTails), and a bare one is noted and not compared.
    Iterable<String> valuesOf(String variable, GnValue item) {
      if (item is GnReference && referenceValues[item.name] == null) {
        notes.add('$variable: ${item.name} is a constant of the Bazel build (not compared)');
        return const <String>[];
      }
      if (item is GnExpandedString &&
          item.parts.first is GnReference &&
          referenceValues[(item.parts.first as GnReference).name] == null &&
          item.parts.skip(1).every((GnValue part) => part is GnStringValue)) {
        final String tail = item.parts
            .skip(1)
            .map((GnValue part) => (part as GnStringValue).value)
            .join();
        notes.add(
          '$variable: ${(item.parts.first as GnReference).name}$tail is built on a constant of '
          'the Bazel build (matched by its tail)',
        );
        referenceTails.add(tail);
        return const <String>[];
      }
      return switch (item) {
        GnStringValue(:final String value) => <String>[value],
        GnReference(:final String name) => referenceValues[name] ?? const <String>[],
        GnExpandedString(:final List<GnValue> parts) => <String>[
          parts
              .map(
                (GnValue part) => switch (part) {
                  GnReference(:final String name) => referenceValues[name]?.join() ?? '',
                  _ => (part as GnStringValue).value,
                },
              )
              .join(),
        ],
        _ => const <String>[],
      };
    }

    for (final GnAssignment a in v.assignments) {
      if (!a.isUnconditional) {
        // The branch's values are in the generated select(): GN having one
        // of them is not the converter lacking it, whether a string or a
        // value built on a constant of the Bazel build (the iOS platform's
        // Developer/usr/lib under use_ios_simulator).
        undecided.add('$variable under ${a.condition}');
        for (final GnValue item in a.items) {
          undecidedValues.addAll(valuesOf(variable, item).map(normalize));
        }
        continue;
      }
      for (final GnValue item in a.items) {
        for (final String value in valuesOf(variable, item)) {
          switch (a.op) {
            case '-=':
              result.remove(normalize(value));
            case '=' || '+=':
              result.add(normalize(value));
          }
        }
      }
      if (a.op == '=' && a.items.isEmpty) {
        result.clear();
      }
    }
    return result;
  }

  // GN's generated-file directory is the converter's `//@gen` root, and the
  // build directory itself its `//@out` root (a copy's source under
  // `$root_out_dir`: the dylib the Apple frameworks copy into the bundle).
  final String gnGenDir = p.posix.normalize('//$outDir/gen');
  final String gnOutDir = p.posix.normalize('//$outDir');
  String path(String value) {
    final String absolute = _absolutePath(value, gnPackage);
    if (absolute == gnGenDir) {
      return p.posix.normalize(genDirRoot);
    }
    if (absolute.startsWith('$gnGenDir/')) {
      return p.posix.normalize('$genDirRoot/${absolute.substring(gnGenDir.length + 1)}');
    }
    if (absolute.startsWith('$gnOutDir/')) {
      return p.posix.normalize('$buildDirRoot/${absolute.substring(gnOutDir.length + 1)}');
    }
    return absolute;
  }

  String labelOf(String value) => _absoluteLabel(value, gnPackage);

  check('sources', items('sources', path), _strings(gnTarget['sources']).map(path).toSet());
  final Object? public = gnTarget['public'];
  if (public is List<Object?>) {
    check('public', items('public', path), _strings(public).map(path).toSet());
  } else if (target.variables['public'] case final GnVariable publicList) {
    // A public list under an undecided condition alone (a merged optional()
    // target's) is as undecided as its items.
    if (publicList.assignments.every((GnAssignment a) => !a.isUnconditional)) {
      items('public', path);
    } else {
      _report(label, 'has a public list to the converter, all headers public to GN');
      differences++;
    }
  }
  // gn desc's deps are deps and public_deps together, plus what
  // BUILDCONFIG.gn's executable and shared_library templates add (the C++
  // runtime, which the Bazel toolchain provides); a static library that
  // names the runtime itself (a complete one archiving it) is compared as
  // written.
  final Set<String> gnDeps = _strings(gnTarget['deps']).map(_stripToolchain).map(labelOf).toSet();
  if (const <String>{
    'executable',
    'shared_library',
    'loadable_module',
  }.contains(gnTarget['type'])) {
    gnDeps.removeAll(_toolchainDeps);
  }
  check('deps', items('deps', labelOf).union(items('public_deps', labelOf)), gnDeps);
  // gn desc lists public_configs after propagation from public_deps, so the
  // target's own are a subset; all_dependent_configs are compared after
  // propagation on both sides. The converter follows deps within the file;
  // what GN propagates in from dependencies in other files reaches the
  // Bazel target through those dependencies' own public deps (the other
  // file's conversion), so it is reported, not counted, unless this file
  // names the config itself.
  check(
    'public_configs',
    items('public_configs', labelOf),
    _strings(gnTarget['public_configs']).map(labelOf).toSet(),
    subset: true,
  );
  final Set<String> gnAllDependent = _strings(gnTarget['all_dependent_configs'])
      .map(labelOf)
      .toSet();
  final Set<String> fromElsewhere = gnAllDependent
      .where((String c) => !c.startsWith('$gnPackage:') && !namedAllDependentConfigs.contains(c))
      .toSet();
  // A config inherited under a condition the assumptions left open (a merged
  // optional() target's, or through a conditional dep) is as undecided as a
  // conditional item.
  final inheritedHere = <String>{};
  for (final MapEntry<String, Condition> config
      in (inherited[target.name] ?? const <String, Condition>{}).entries) {
    if (config.value == Condition.always) {
      inheritedHere.add(labelOf(config.key));
    } else {
      undecided.add('all_dependent_configs ${config.key} under ${config.value}');
      undecidedValues.add(labelOf(config.key));
    }
  }
  check('all_dependent_configs', inheritedHere, gnAllDependent, notOurs: fromElsewhere);
  if (fromElsewhere.isNotEmpty) {
    notes.add(
      'all_dependent_configs from other files, which reach the Bazel target through its deps (not compared): ${(fromElsewhere.toList()..sort()).join(', ')}',
    );
  }
  if (type == 'config') {
    // gn desc reports a config's nested configs (`configs = [...]`)
    // flattened into its own defines and include_dirs: a local one from
    // the converter's view of it, one of another file from gn desc's.
    Set<String> flattened(String variable, String Function(String) normalize) {
      final result = <String>{...items(variable, normalize)};
      for (final GnValue nested
          in target.variables['configs']?.unconditionalItems ?? const <GnValue>[]) {
        if (nested is! GnStringValue) {
          continue;
        }
        if (nested.value.startsWith(':')) {
          final GnTarget? config = localTargets[nested.value.substring(1)];
          final GnVariable? v = config?.variables[variable];
          for (final GnValue item in v?.unconditionalItems ?? const <GnValue>[]) {
            if (item is GnStringValue) {
              result.add(normalize(item.value));
            }
          }
        } else {
          final Map<String, Object?>? config = nestedElsewhere[labelOf(nested.value)];
          result.addAll(_strings(config?[variable]).map(normalize));
        }
      }
      return result;
    }

    // A define may embed a generated file's path (the embedder's JIT
    // snapshot setup); GN's out-directory spelling of it is the converter's
    // `//@gen` root, as for paths.
    String defineText(String value) => value
        .replaceAll('$gnGenDir/', '${p.posix.normalize(genDirRoot)}/')
        .replaceAll('$gnOutDir/', '${p.posix.normalize(buildDirRoot)}/');
    check(
      'defines',
      flattened('defines', (String s) => s),
      _strings(gnTarget['defines']).map(defineText).toSet(),
    );
    check(
      'include_dirs',
      flattened('include_dirs', path),
      _strings(gnTarget['include_dirs']).map(path).toSet(),
    );
  }
  for (final u in undecided) {
    stdout.writeln('  $label: $u (undecided; not compared)');
  }
  for (final n in notes) {
    stdout.writeln('  $label: $n');
  }
  return differences;
}

void _report(String label, String message) => stdout.writeln('$label $message');

/// Dependencies BUILDCONFIG.gn adds to every executable, shared library and
/// loadable module: the C++ runtime, which is the Bazel toolchain's.
const Set<String> _toolchainDeps = <String>{
  '//flutter/third_party/libcxx:libcxx',
  '//flutter/third_party/libcxxabi:libcxxabi',
};

Future<Map<String, Object?>> _gnDesc(
  String gn,
  String outDir,
  String pattern, {
  bool failIfMissing = true,
}) async {
  final ProcessResult result = await Process.run(gn, <String>[
    'desc',
    outDir,
    pattern,
    '--format=json',
  ]);
  if (result.exitCode != 0) {
    if (!failIfMissing) {
      return const <String, Object?>{};
    }
    throw StateError('gn desc $pattern failed: ${result.stderr}');
  }
  // gn prints warnings about args.gn ahead of the JSON.
  final stdout = result.stdout as String;
  return jsonDecode(stdout.substring(stdout.indexOf('{'))) as Map<String, Object?>;
}

List<String> _strings(Object? json) =>
    json is List<Object?> ? json.cast<String>() : const <String>[];

/// `//flutter/skia`, `:x`, `modules/skcms` and `//a/b:c` as `//dir:name`.
String _absoluteLabel(String value, String gnPackage) =>
    absoluteGnLabel(value, package: gnPackage, implicitName: true);

String _stripToolchain(String label) {
  final int paren = label.indexOf('(');
  return paren < 0 ? label : label.substring(0, paren);
}

/// A GN path as `//dir/file`, without a trailing slash (gn desc lists
/// include directories with one). A `rebase_path()` result the evaluator
/// kept (the marked absolute path a source list may hold) is its path.
String _absolutePath(String value, String gnPackage) {
  if (value.length >= 2 &&
      value.startsWith(rebasedPathMarker) &&
      value.endsWith(rebasedPathMarker)) {
    value = value.substring(1, value.length - 1);
  }
  final absolute = value.startsWith('//') ? value : '$gnPackage/$value';
  return p.posix.normalize(absolute);
}

String _defaultRoot() {
  // tool/gn_desc_diff.dart lives at engine/src/flutter/tools/gn_to_bazel/tool.
  return p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), '../../../..'));
}
