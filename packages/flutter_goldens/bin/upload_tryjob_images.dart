// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Sends the golden images a test run left in directories to Flutter Gold, as
// results of the pull request's tryjob:
//
//   dart packages/flutter_goldens/bin/upload_tryjob_images.dart <directory>...
//
// This is for a runner whose tests have no network (the Bazel shards of
// dev/bots/test.dart). There the golden comparisons are made in the test by
// the offline comparator, against what Flutter Gold accepts, and the images
// that are to go to Gold -- those it does not accept, whose tests fail, and
// those of tests it does not know -- are left in the tests' output
// directories. The runner calls this once the tests are over, in a LUCI
// presubmit: the environment `flutter test` uploads from (GOLDCTL,
// GOLD_TRYJOB, LOGDOG_STREAM_PREFIX, LUCI_CONTEXT, FLUTTER_ROOT), with the
// same client, so that an image lands on the trace `flutter test` would have
// sent it to.
//
// A PNG file's path under its directory is its golden's name.
//
// Exits with 1 if an image could not be sent. An image Gold holds as
// untriaged is sent, not a failure here: the test that rendered it has
// failed already, and Gold's check on the pull request waits for the triage.

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_goldens/skia_client.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

Future<void> main(List<String> arguments) async {
  const FileSystem fs = LocalFileSystem();
  const Platform platform = LocalPlatform();
  final Directory work = fs.systemTempDirectory.createTempSync('flutter_gold_tryjob.');
  final httpClient = io.HttpClient();
  final client = SkiaGoldClient(
    work,
    fs: fs,
    process: const LocalProcessManager(),
    platform: platform,
    httpClient: httpClient,
    log: io.stdout.writeln,
  );
  final results = <String, String?>{};
  try {
    for (final argument in arguments) {
      final Directory images = fs.directory(argument);
      if (!images.existsSync()) {
        io.stderr.writeln('$argument is not a directory.');
        io.exitCode = 1;
        continue;
      }
      // One test run's images failing to go leaves the other runs' to be sent.
      try {
        results.addAll(await client.tryjobAddDirectory(images));
      } on SkiaException catch (error) {
        io.stderr.writeln('The images of $argument were not all sent.\n$error');
        io.exitCode = 1;
      }
    }
  } finally {
    httpClient.close(force: true);
    work.deleteSync(recursive: true);
  }

  final untriaged = <String>[
    for (final MapEntry<String, String?> result in results.entries)
      if (result.value != null) result.key,
  ]..sort();
  io.stdout.writeln(
    'Sent ${results.length} golden image(s) to Flutter Gold; '
    'Gold accepts ${results.length - untriaged.length} and holds ${untriaged.length} for triage.',
  );
  if (untriaged.isNotEmpty) {
    for (final name in untriaged) {
      io.stdout.writeln('  $name: ${results[name]!.trim()}');
    }
    // GOLD_TRYJOB is refs/pull/<number>/head.
    final List<String> refs = (platform.environment['GOLD_TRYJOB'] ?? '').split('/');
    if (refs.length >= 2) {
      io.stdout.writeln(
        'Triage them at https://flutter-gold.skia.org/cl/github/${refs[refs.length - 2]}',
      );
    }
  }
}
