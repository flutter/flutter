// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regenerates `dev/bots/web_test_durations.json` from recent postsubmit
// builds' ResultDB durations.
//
//   dart dev/bots/update_web_test_durations.dart [--builds=N]

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'suite_runners/run_web_tests.dart';
import 'test_durations.dart';
import 'utils.dart';

/// The prod builders that run each renderer.
const Map<String, String> _builderPatterns = <String, String>{
  'canvaskit': r'^Linux web_canvaskit_tests_\d+(_last)?$',
  'skwasm': r'^Linux web_skwasm_tests_\d+$',
};

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('builds', defaultsTo: '3', help: 'Successful builds to sample per subshard.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults args = parser.parse(arguments);
  if (args.flag('help')) {
    print(parser.usage);
    return;
  }
  final int builds = int.parse(args.option('builds')!);

  final output = File(path.join(flutterRoot, 'dev', 'bots', 'web_test_durations.json'));
  final DurationsByGroup previous = readDurations(output);
  final List<String> localFiles = WebTestsSuite.webUnitTestFiles();
  final Set<String> localFileSet = localFiles.toSet();
  final sampler = TestDurationSampler();
  final List<String> prodBuilders = await sampler.listProdBuilders();
  final sampled = <String, DurationsByFile>{};
  for (final MapEntry(key: renderer, value: pattern) in _builderPatterns.entries) {
    final builderName = RegExp(pattern);
    final List<String> builders = prodBuilders.where(builderName.hasMatch).toList();
    if (builders.isEmpty) {
      throw StateError('No $renderer builders found');
    }
    sampled[renderer] = await sampler.sampleDurations(
      builders,
      builds,
      keyFor: (String file) => localFileSet.contains(file) ? file : null,
    );
  }
  sampler.close();
  writeDurations(output, reconcile(sampled, localFiles, previous));
}
