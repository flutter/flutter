// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:gn_to_bazel/gn_to_bazel.dart';
import 'package:path/path.dart' as p;

/// Converts GN build files to BUILD.bazel files.
///
///     dart bin/gn_to_bazel.dart [options] <BUILD.gn>...
///
/// Each file is written next to its input as `BUILD.bazel` unless
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
    ..addMultiOption('skip', help: 'GN targets to leave out, by name.')
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
  if (options.flag('help') || options.rest.isEmpty) {
    stdout.writeln('Usage: dart bin/gn_to_bazel.dart [options] <BUILD.gn>...\n');
    stdout.writeln(parser.usage);
    return options.flag('help') ? 0 : 64;
  }

  final String root = p.canonicalize(options.option('root')!);
  final String gn = options.wasParsed('gn')
      ? options.option('gn')!
      : p.join(root, 'flutter/third_party/gn/gn');
  final Assumptions assumptions = _assumptions(options.multiOption('assume'));
  final Set<String> skip = options.multiOption('skip').toSet();
  final String? buildifier = options.option('buildifier') ?? await _findOnPath('buildifier');

  var failures = 0;
  for (final String input in options.rest) {
    final String file = p.canonicalize(input);
    if (!p.isWithin(root, file)) {
      stderr.writeln('$input is not under the GN root $root');
      failures++;
      continue;
    }
    final gnPackage = '//${p.posix.joinAll(p.split(p.dirname(p.relative(file, from: root))))}';
    try {
      final GnBlock tree = await loadGnFile(file, gnBinary: gn);
      final GnFileEvaluation evaluation = evaluateGnFile(
        tree,
        assumptions: assumptions,
        templates: templateMappings.keys.toSet(),
        externalVariables: knownExternalVariables,
      );
      String output = emitBuildFile(evaluation, gnPackage: gnPackage, skipTargets: skip);
      if (buildifier != null) {
        output = await _format(buildifier, output);
      }
      final String outputPath = options.option('out-dir') == null
          ? p.join(p.dirname(file), 'BUILD.bazel')
          : p.join(options.option('out-dir')!, gnPackage.substring(2), 'BUILD.bazel');
      if (options.flag('check')) {
        final existing = File(outputPath);
        if (!existing.existsSync() || existing.readAsStringSync() != output) {
          stderr.writeln('$outputPath is out of date with respect to $input');
          failures++;
        }
      } else {
        File(outputPath)
          ..createSync(recursive: true)
          ..writeAsStringSync(output);
        stdout.writeln('$input -> $outputPath (${evaluation.targets.length} targets)');
      }
    } on GnError catch (e) {
      stderr.writeln('error: $e');
      failures++;
    }
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
