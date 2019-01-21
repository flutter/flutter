// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

class VersionCommand extends FlutterCommand {
  @override
  final String name = 'version';

  @override
  final String description = 'List or switch flutter versions.';

  Future<List<String>> getTags() async {
    final RunResult runResult = await runCheckedAsync(
      <String>['git', 'tag', '-l', 'v*'],
      workingDirectory: Cache.flutterRoot
    );
    return runResult.toString().split('\n');
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> tags = await getTags();
    if (argResults.rest.isEmpty) {
      tags.forEach(printStatus);
      return const FlutterCommandResult(ExitStatus.success);
    }
    String version = argResults.rest[0];
    if (!version.startsWith('v')) {
      version = 'v$version';
    }
    if (!tags.contains(version)) {
      printError('There is no version: $version');
    }

    try {
      await runCheckedAsync(<String>['git', 'checkout', version],
          workingDirectory: Cache.flutterRoot);
    } catch (e) {
      throwToolExit('Unable to checkout version branch for version $version.');
    }

    final FlutterVersion flutterVersion = FlutterVersion();

    printStatus(
        'Switching Flutter to version ${flutterVersion.frameworkVersion}...');

    // Check for and download any engine and pkg/ updates.
    // We run the 'flutter' shell script re-entrantly here
    // so that it will download the updated Dart and so forth
    // if necessary.
    printStatus('');
    printStatus('Downloading engine...');
    int code = await runCommandAndStreamOutput(<String>[
      fs.path.join('bin', 'flutter'),
      '--no-color',
      'precache',
    ], workingDirectory: Cache.flutterRoot, allowReentrantFlutter: true);

    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }

    printStatus('');
    printStatus(flutterVersion.toString());

    final String projectRoot = findProjectRoot();
    if (projectRoot != null) {
      printStatus('');
      await pubGet(
        context: PubContext.pubUpgrade,
        directory: projectRoot,
        upgrade: true,
        checkLastModified: false
      );
    }

    // Run a doctor check in case system requirements have changed.
    printStatus('');
    printStatus('Running flutter doctor...');
    code = await runCommandAndStreamOutput(
      <String>[
        fs.path.join('bin', 'flutter'),
        'doctor',
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true,
    );

    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }

    return const FlutterCommandResult(ExitStatus.success);
  }
}
