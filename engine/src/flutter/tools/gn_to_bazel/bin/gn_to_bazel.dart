// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:gn_to_bazel/gn_to_bazel.dart';
import 'package:path/path.dart' as p;

/// Converts GN build files to BUILD.bazel files.
///
///     dart bin/gn_to_bazel.dart [options] [<BUILD.gn>...]
///
/// Without inputs, every file in the manifest (lib/src/manifest.dart) is
/// converted. Each file is written next to its input as `BUILD.bazel` unless
/// `--out-dir` names a directory, in which case the output is laid out there
/// by GN package (`<out-dir>/flutter/fml/BUILD.bazel`). With `--check` the
/// existing files are compared instead and a difference is a failure.
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
          'Defaults to the Linux x64 host build; pass --assume=none to keep every condition.',
    )
    ..addMultiOption(
      'skip',
      help: "GN targets to leave out, by name (in addition to the manifest's).",
    )
    ..addOption(
      'buildifier',
      help: 'Format the output with this buildifier (default: the one on PATH, if any).',
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
  final Assumptions assumptions = _assumptions(options.multiOption('assume'));
  final Set<String> extraSkips = options.multiOption('skip').toSet();
  final String? buildifier = options.option('buildifier') ?? await _findOnPath('buildifier');
  final String? outDir = options.option('out-dir');
  final bool check = options.flag('check');

  // The inputs: the manifest's files, or the ones named (which pick up the
  // manifest's skip list and appendix when they are in it).
  final List<String> inputs = options.rest.isEmpty
      ? <String>[
          for (final ConvertedFile file in convertedFiles)
            p.join(root, file.gnPackage.substring(2), 'BUILD.gn'),
        ]
      : options.rest;

  var failures = 0;
  for (final input in inputs) {
    final String file = p.canonicalize(input);
    if (!p.isWithin(root, file)) {
      stderr.writeln('$input is not under the GN root $root');
      failures++;
      continue;
    }
    final gnPackage = '//${p.posix.joinAll(p.split(p.dirname(p.relative(file, from: root))))}';
    final ConvertedFile? manifest = convertedFiles
        .where((ConvertedFile f) => f.gnPackage == gnPackage)
        .firstOrNull;
    final skip = <String>{...?manifest?.skip.keys, ...extraSkips};
    try {
      final GnBlock tree = await loadGnFile(file, gnBinary: gn);
      final GnFileEvaluation evaluation = evaluateGnFile(
        tree,
        assumptions: assumptions,
        templates: templateMappings.keys.toSet(),
        externalVariables: knownExternalVariables,
        skipTargets: skip,
      );
      String output = emitBuildFile(
        evaluation,
        gnPackage: gnPackage,
        skipTargets: skip,
        appendix: manifest?.appendix,
      );
      if (buildifier != null) {
        output = await _format(buildifier, output);
      }
      final String outputPath = outDir == null
          ? p.join(p.dirname(file), 'BUILD.bazel')
          : p.join(outDir, gnPackage.substring(2), 'BUILD.bazel');
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
  if (check && failures == 0) {
    stdout.writeln('${inputs.length} generated BUILD.bazel file(s) up to date');
  }
  return failures == 0 ? 0 : 1;
}

String _defaultRoot() {
  // bin/gn_to_bazel.dart lives at engine/src/flutter/tools/gn_to_bazel/bin.
  return p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), '../../../..'));
}

Assumptions _assumptions(List<String> specs) {
  if (specs.contains('none')) {
    return Assumptions(const <String, GnValue>{});
  }
  if (specs.isEmpty) {
    return linuxHostAssumptions();
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

Future<String?> _findOnPath(String name) async {
  final ProcessResult which = await Process.run('which', <String>[name]);
  return which.exitCode == 0 ? (which.stdout as String).trim() : null;
}

Future<String> _format(String buildifier, String content) async {
  final Process process = await Process.start(buildifier, <String>['-type=build']);
  process.stdin.write(content);
  await process.stdin.close();
  final String formatted = await process.stdout.transform(const SystemEncoding().decoder).join();
  final String errors = await process.stderr.transform(const SystemEncoding().decoder).join();
  if (await process.exitCode != 0) {
    throw GnError(const GnLocation('<buildifier>', 0, 0), 'buildifier failed: $errors');
  }
  return formatted;
}
