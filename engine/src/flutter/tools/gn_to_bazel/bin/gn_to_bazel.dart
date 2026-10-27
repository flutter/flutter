// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:gn_to_bazel/gn_to_bazel.dart';
import 'package:path/path.dart' as p;

/// Converts GN build files to BUILD.bazel files.
///
///     dart bin/gn_to_bazel.dart [options] [<BUILD.gn>...]
///
/// Without inputs, every checked-in file of the manifest
/// (lib/src/manifest.dart) is converted. Each file is written next to its
/// input as `BUILD.bazel` unless `--out-dir` names a directory, in which case
/// the output is laid out there by GN package
/// (`<out-dir>/flutter/fml/BUILD.bazel`). With `--check` the existing files
/// are compared instead and a difference is a failure. With `--repository`
/// the inputs are laid out as the packages of an external repository (the
/// fetch-time conversion of build_defs/repositories/repositories.bzl).
Future<void> main(List<String> arguments) async {
  exitCode = await run(arguments);
}

Future<int> run(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'root',
      help: 'The GN source root (the directory with .gn).',
      defaultsTo: _defaultRoot(),
    )
    ..addOption(
      'gn',
      help: 'The gn binary.',
      defaultsTo: 'flutter/third_party/gn/gn (under --root)',
    )
    ..addOption(
      'out-dir',
      help: 'Write outputs under this directory instead of next to the inputs.',
    )
    ..addMultiOption(
      'assume',
      help:
          'A GN variable value to take as given, as name=value. '
          'Defaults to the generation scope (a Linux x64 host building for Linux or the web; '
          "bazel_mapping.dart's generationAssumptions); --assume=host is the Linux host's full "
          "set (linuxHostAssumptions, the oracle's), --assume=none keeps every condition.",
    )
    ..addMultiOption(
      'skip',
      help: "GN targets to leave out, by name (in addition to the manifest's).",
    )
    ..addOption(
      'buildifier',
      help:
          'Format the output with this buildifier (default: the one on PATH, if any; '
          '`none` for no formatting).',
    )
    ..addOption(
      'repository',
      help:
          'Generate into an external repository made from a synced tree, as '
          '@repo=//gn/dir/of/its/root (e.g. @skia=//flutter/third_party/skia); the inputs '
          'become the packages of the repository, written under --out-dir.',
    )
    ..addOption('depfile', help: 'Write the GN files read, one per line, to this file.')
    ..addOption(
      'host',
      help:
          'EXPERIMENTAL: evaluate for another host than the Linux x64 one the checked-in files '
          'assume (macos-arm64, macos-x64), with --out-dir, to see what of the generated files '
          'depends on the host (research/20 §8).',
    )
    ..addFlag(
      'check',
      help: 'Compare with the existing BUILD.bazel files instead of writing.',
      negatable: false,
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    return 64;
  }
  if (options.flag('help')) {
    stdout.writeln('Usage: dart bin/gn_to_bazel.dart [options] [<BUILD.gn>...]\n');
    stdout.writeln(parser.usage);
    return 0;
  }

  final String root = p.canonicalize(options.option('root')!);
  final String gn = options.wasParsed('gn')
      ? options.option('gn')!
      : p.join(root, 'flutter/third_party/gn/gn');
  Assumptions assumptions = _assumptions(options.multiOption('assume'));
  final String? host = options.option('host');
  if (host != null) {
    assumptions = assumptions.withValues(_hostAssumptions(host));
  }
  final Set<String> extraSkips = options.multiOption('skip').toSet();
  final String? buildifierOption = options.option('buildifier');
  final String? buildifier = buildifierOption == 'none'
      ? null
      : buildifierOption ?? await _findOnPath('buildifier');
  final String? outDir = options.option('out-dir');
  final bool check = options.flag('check');
  final String? repository = options.option('repository');
  if (repository != null && outDir == null) {
    stderr.writeln('--repository needs --out-dir');
    return 64;
  }
  final tree = GnSourceTree(root, gnBinary: gn);

  // The inputs: the manifest's checked-in files, or the ones named (which
  // pick up the manifest's skip list, appendix and implicit deps when they
  // are in it).
  final List<String> inputs = options.rest.isEmpty
      ? <String>[
          for (final ConvertedFile file in convertedFiles)
            p.join(root, file.gnPackage.substring(2), 'BUILD.gn'),
        ]
      : options.rest;
  final files = <String>[];
  var failures = 0;
  // The targets each converted file defines (less the skipped), for the
  // builder files' ninja targets.
  final convertedTargets = <String, Set<String>>{};
  final convertedTests = <String, Set<String>>{};
  // The condition a file is read under (the manifest's), by package: a
  // target of such a file exists in the builds the condition holds for.
  final packageConditions = <String, String?>{};
  for (final input in inputs) {
    final String file = p.canonicalize(input);
    if (!p.isWithin(root, file)) {
      stderr.writeln('$input is not under the GN root $root');
      failures++;
      continue;
    }
    files.add(file);
  }
  final OutputLayout layout;
  try {
    layout = _layout(
      repository,
      files.map(tree.gnDirectory),
      secondarySource: tree.secondarySource,
    );
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    return 64;
  }

  // The compiler flags dependencies hand this run's targets, read from
  // their GN files (dependency_resolver.dart); shared, so each file is
  // evaluated once.
  final forwardedFlags = DependencyResolver(tree: tree, assumptions: assumptions);

  for (final file in files) {
    final String gnPackage = tree.gnDirectory(file);
    final ConvertedFile? manifest = manifestEntry(gnPackage);
    final skip = <String>{...?manifest?.skip.keys, ...extraSkips};
    try {
      final GnFileEvaluation evaluation = evaluateGnFile(
        tree.load(file),
        assumptions: manifest == null || manifest.assume.isEmpty
            ? assumptions
            : assumptions.withValues(manifest.assume),
        templates: templateMappings.keys.toSet(),
        externalVariables: knownExternalVariables,
        booleanVariables: knownBooleanVariables,
        skipTargets: skip,
        tree: tree,
        importPolicy: engineImportPolicy,
        condition: manifest?.condition == null
            ? Condition.always
            : ConditionVariable(manifest!.condition!),
        targetConditions: <String, Condition>{
          for (final MapEntry<String, String> entry
              in (manifest?.targetConditions ?? const <String, String>{}).entries)
            entry.key: ConditionVariable(entry.value),
        },
      );
      convertedTargets[gnPackage] = <String>{
        for (final GnTarget target in evaluation.targets)
          if (!skip.contains(target.name)) target.name,
      };
      packageConditions[gnPackage] = manifest?.condition;
      convertedTests[gnPackage] = <String>{
        for (final GnTarget target in evaluation.targets)
          if (!skip.contains(target.name) && isBazelTest(target, gnPackage)) target.name,
      };
      String output = emitBuildFile(
        evaluation,
        gnPackage: gnPackage,
        skipTargets: skip,
        appendix: manifest?.appendix,
        layout: layout,
        implicitDeps: manifest?.implicitDeps ?? const <String>[],
        tree: tree,
        forwardedFlags: forwardedFlags,
        unconvertedDeps: manifest?.unconvertedDeps ?? const <String>[],
        filesGroups: manifest?.filesGroups ?? const <String>{},
      );
      if (buildifier != null) {
        output = await _format(buildifier, output);
      }
      final String outputPath;
      if (outDir == null) {
        outputPath = p.join(p.dirname(file), 'BUILD.bazel');
      } else if (layout.isMain) {
        outputPath = p.join(outDir, gnPackage.substring(2), 'BUILD.bazel');
      } else {
        outputPath = p.join(outDir, _repositoryPackage(gnPackage, layout), 'BUILD.bazel');
      }
      if (check) {
        final existing = File(outputPath);
        if (!existing.existsSync() || existing.readAsStringSync() != output) {
          stderr.writeln(
            '$outputPath is out of date with respect to ${p.relative(file, from: root)}; '
            'rerun tools/gn_to_bazel',
          );
          failures++;
        }
      } else {
        File(outputPath)
          ..createSync(recursive: true)
          ..writeAsStringSync(output);
        stdout.writeln(
          '${p.relative(file, from: root)} -> $outputPath '
          '(${evaluation.targets.length - evaluation.targets.where((GnTarget t) => skip.contains(t.name)).length} targets'
          '${evaluation.skipped.isEmpty ? '' : ', ${evaluation.skipped.length} skipped'})',
        );
      }
    } on GnError catch (e) {
      stderr.writeln('error: $e');
      failures++;
    }
  }
  // The hand-written files that repeat a list of their GN file (the Dart
  // test packages' `tests`): the two must agree, in every run over the
  // manifest's files.
  if (options.rest.isEmpty && outDir == null) {
    for (final String message in mirroredListMismatches(tree, mirroredLists)) {
      stderr.writeln('error: $message');
      failures++;
    }
    // The builder files' Linux and Mac builds (the hosts' own, the web's, the
    // cross builds') as configurations and install targets (lib/src/builders.dart).
    failures += await _builderOutputs(
      root,
      convertedTargets,
      convertedTests,
      packageConditions,
      buildifier: buildifier,
      check: check,
    );
    // felt's configuration as the Starlark table lib/web_ui/BUILD.bazel's
    // web_ui_tests call reads (lib/src/felt_config.dart).
    failures += await _feltOutputs(root, buildifier: buildifier, check: check);
  }
  final String? depfile = options.option('depfile');
  if (depfile != null) {
    File(depfile)
      ..createSync(recursive: true)
      ..writeAsStringSync('${tree.loadedFiles.join('\n')}\n');
  }
  if (check && failures == 0) {
    stdout.writeln(
      '${inputs.length} generated BUILD.bazel file(s) up to date; '
      '${mirroredLists.length} hand-written list(s) match their GN files'
      '${options.rest.isEmpty && outDir == null ? "; the builders' configurations and install targets, and lib/web_ui's felt_config.bzl, are current" : ''}',
    );
  }
  return failures == 0 ? 0 : 1;
}

/// Writes (or, with [check], compares) ci/builders/configs.bazelrc and
/// ci/builders/BUILD.bazel from the builder files; returns the number of
/// failures.
Future<int> _builderOutputs(
  String root,
  Map<String, Set<String>> convertedTargets,
  Map<String, Set<String>> convertedTests,
  Map<String, String?> packageConditions, {
  required String? buildifier,
  required bool check,
}) async {
  final String buildersDir = p.join(root, 'flutter/ci/builders');
  final loader = BuildConfigLoader(buildConfigsDir: Directory(buildersDir));
  final Map<String, BuilderConfig> configs = loader.configs;
  if (loader.errors.isNotEmpty) {
    for (final String error in loader.errors) {
      stderr.writeln('error: $error');
    }
    return loader.errors.length;
  }
  final List<BuilderBuild> builds = builderBuilds(configs);
  final String bazelrc;
  try {
    bazelrc = configsBazelrc(builds, leftOut: leftOutBuilds(configs));
  } on FormatException catch (e) {
    stderr.writeln('error: ${e.message}');
    return 1;
  }
  String buildFile = buildersBuildFile(
    builds,
    convertedTargets,
    convertedTests: convertedTests,
    packageConditions: packageConditions,
  );
  if (buildifier != null) {
    buildFile = await _format(buildifier, buildFile);
  }
  final outputs = <String, String>{
    p.join(buildersDir, 'configs.bazelrc'): bazelrc,
    p.join(buildersDir, 'BUILD.bazel'): buildFile,
  };
  var failures = 0;
  for (final MapEntry<String, String> output in outputs.entries) {
    final file = File(output.key);
    if (check) {
      if (!file.existsSync() || file.readAsStringSync() != output.value) {
        stderr.writeln(
          '${output.key} is out of date with respect to flutter/ci/builders/{linux,mac}_*.json; '
          'rerun tools/gn_to_bazel',
        );
        failures++;
      }
    } else {
      file.writeAsStringSync(output.value);
      stdout.writeln(
        'flutter/ci/builders/{linux,mac}_*.json -> ${output.key} (${builds.length} builds, '
        '${builds.where((BuilderBuild b) => b.host == BuilderHost.linux).length} Linux and '
        '${builds.where((BuilderBuild b) => b.host == BuilderHost.mac).length} Mac, '
        '${builds.where((BuilderBuild b) => b.unsupported.isEmpty).length} with a configuration)',
      );
    }
  }
  return failures;
}

/// Writes (or, with [check], compares) lib/web_ui/felt_config.bzl from
/// lib/web_ui/test/felt_config.yaml; returns the number of failures.
Future<int> _feltOutputs(String root, {required String? buildifier, required bool check}) async {
  final String webUiDir = p.join(root, 'flutter/lib/web_ui');
  final yaml = File(p.join(webUiDir, 'test/felt_config.yaml'));
  final bzl = File(p.join(webUiDir, 'felt_config.bzl'));
  final String relative = p.relative(bzl.path, from: root);
  String content;
  try {
    content = FeltConfig.parse(yaml.readAsStringSync()).toStarlark();
  } on FormatException catch (e) {
    stderr.writeln('error: ${p.relative(yaml.path, from: root)}: ${e.message}');
    return 1;
  }
  if (buildifier != null) {
    content = await _format(buildifier, content, type: 'bzl');
  }
  if (check) {
    if (!bzl.existsSync() || bzl.readAsStringSync() != content) {
      stderr.writeln(
        '$relative is out of date with respect to flutter/lib/web_ui/test/felt_config.yaml; '
        'rerun tools/gn_to_bazel',
      );
      return 1;
    }
    return 0;
  }
  bzl.writeAsStringSync(content);
  stdout.writeln('flutter/lib/web_ui/test/felt_config.yaml -> $relative');
  return 0;
}

/// `--repository=@skia=//flutter/third_party/skia`, with the packages of
/// the GN directories being converted.
OutputLayout _layout(String? repository, Iterable<String> gnPackages, {String? secondarySource}) {
  if (repository == null) {
    return mainRepositoryLayout;
  }
  final int equals = repository.indexOf('=');
  if (!repository.startsWith('@') ||
      equals < 0 ||
      !repository.substring(equals + 1).startsWith('//')) {
    throw FormatException('--repository takes @repo=//gn/dir, not $repository');
  }
  final bare = OutputLayout.repository(
    repository.substring(0, equals),
    repositoryGnRoot: repository.substring(equals + 1),
  );
  return OutputLayout.repository(
    bare.repository,
    repositoryGnRoot: bare.repositoryGnRoot,
    packages: <String>{
      for (final String gnPackage in gnPackages) _repositoryPackage(gnPackage, bare),
    },
    secondarySource: secondarySource,
  );
}

/// The package path of [gnPackage] within the repository of [layout].
String _repositoryPackage(String gnPackage, OutputLayout layout) {
  final package = BazelLabel.parse(bazelLabel(gnPackage, package: gnPackage));
  if (package.repository != layout.repository) {
    throw FormatException(
      '$gnPackage maps to ${package.repository}//${package.package}, '
      'not into ${layout.repository}',
    );
  }
  return package.package;
}

String _defaultRoot() {
  // bin/gn_to_bazel.dart lives at engine/src/flutter/tools/gn_to_bazel/bin.
  return p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), '../../../..'));
}

Assumptions _assumptions(List<String> specs) {
  if (specs.contains('none')) {
    return Assumptions(const <String, GnValue>{});
  }
  if (specs.contains('host')) {
    return linuxHostAssumptions();
  }
  if (specs.isEmpty) {
    return generationAssumptions();
  }
  final values = <String, GnValue>{};
  for (final spec in specs) {
    final int equals = spec.indexOf('=');
    if (equals <= 0) {
      throw FormatException('--assume takes name=value, not $spec');
    }
    values[spec.substring(0, equals)] = Assumptions.parseValue(spec.substring(equals + 1));
  }
  return Assumptions(values);
}

/// What the generation assumes of the host, for another host than the Linux
/// x64 one (--host): GN's host_os and host_cpu, config.gni's names of the
/// host and the prebuilt Dart SDK's directory (DEPS: prebuilts/<host>).
Map<String, GnValue> _hostAssumptions(String host) {
  final List<String> parts = host.split('-');
  if (parts.length != 2 || !const <String>{'linux', 'macos'}.contains(parts[0])) {
    throw FormatException('--host takes <os>-<cpu> (linux-x64, macos-arm64, macos-x64), not $host');
  }
  final String os = parts[0];
  final String cpu = parts[1];
  final gnOs = os == 'macos' ? 'mac' : os;
  final platformName = os == 'macos' ? 'darwin' : os;
  final sdk = '//flutter/prebuilts/$host/dart-sdk';
  return <String, GnValue>{
    'host_os': GnStringValue(gnOs),
    'host_cpu': GnStringValue(cpu),
    'platform_name': GnStringValue(platformName),
    'full_platform_name': GnStringValue('$platformName-$cpu'),
    'prebuilt_dart_sdk': GnStringValue(sdk),
    'host_prebuilt_dart_sdk': GnStringValue(sdk),
    'target_prebuilt_dart_sdk': GnStringValue(sdk),
  };
}

Future<String?> _findOnPath(String name) async {
  final ProcessResult which = await Process.run('which', <String>[name]);
  return which.exitCode == 0 ? (which.stdout as String).trim() : null;
}

Future<String> _format(String buildifier, String content, {String type = 'build'}) async {
  final Process process = await Process.start(buildifier, <String>['-type=$type']);
  process.stdin.write(content);
  await process.stdin.close();
  final String formatted = await process.stdout.transform(const SystemEncoding().decoder).join();
  final String errors = await process.stderr.transform(const SystemEncoding().decoder).join();
  if (await process.exitCode != 0) {
    throw GnError(const GnLocation('<buildifier>', 0, 0), 'buildifier failed: $errors');
  }
  return formatted;
}
