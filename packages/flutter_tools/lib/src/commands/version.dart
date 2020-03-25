// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import '../version.dart';

class VersionCommand extends FlutterCommand {
  VersionCommand() : super() {
    argParser.addFlag('force',
      abbr: 'f',
      help: 'Force switch to older Flutter versions that do not include a version command',
    );
    // Don't use usesPubOption here. That will cause the version command to
    // require a pubspec.yaml file, which it doesn't need.
    argParser.addFlag('pub',
      defaultsTo: true,
      hide: true,
      help: 'Whether to run "flutter pub get" after switching versions.',
    );
  }

  @override
  final String name = 'version';

  @override
  final String description = 'List or switch flutter versions.';

  // The first version of Flutter which includes the flutter version command. Switching to older
  // versions will require the user to manually upgrade.
  Version minSupportedVersion = Version.parse('1.2.1');

  Future<List<String>> getTags() async {
    globals.flutterVersion.fetchTagsAndUpdate();
    RunResult runResult;
    try {
      runResult = await globals.processUtils.run(
        <String>['git', 'tag', '-l', 'v*', '--sort=-creatordate'],
        throwOnError: true,
        workingDirectory: Cache.flutterRoot,
      );
    } on ProcessException catch (error) {
      throwToolExit(
        'Unable to get the tags. '
        'This might be due to git not being installed or an internal error'
        '\nError: $error.'
      );
    }
    return runResult.toString().split('\n');
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> tags = await getTags();
    if (argResults.rest.isEmpty) {
      tags.forEach(globals.printStatus);
      return FlutterCommandResult.success();
    }

    globals.printStatus(
      '╔══════════════════════════════════════════════════════════════════════════════╗\n'
      '║ Warning: "flutter version" will leave the SDK in a detached HEAD state.      ║\n'
      '║ If you are using the command to return to a previously installed SDK version ║\n'
      '║ consider using the "flutter downgrade" command instead.                      ║\n'
      '╚══════════════════════════════════════════════════════════════════════════════╝\n',
      emphasis: true,
    );
    if (globals.stdio.stdinHasTerminal) {
      globals.terminal.usesTerminalUi = true;
      final String result = await globals.terminal.promptForCharInput(
        <String>['y', 'n'],
        logger: globals.logger,
        prompt: 'Are you sure you want to proceed?'
      );
      if (result == 'n') {
        return FlutterCommandResult.success();
      }
    }

    final String version = argResults.rest[0].replaceFirst('v', '');
    if (!tags.contains('v$version')) {
      globals.printError('There is no version: $version');
    }

    // check min supported version
    final Version targetVersion = Version.parse(version);
    if (targetVersion == null) {
      throwToolExit('Failed to parse version "$version"');
    }

    bool withForce = false;
    if (targetVersion < minSupportedVersion) {
      if (!boolArg('force')) {
        globals.printError(
          'Version command is not supported in $targetVersion and it is supported since version $minSupportedVersion '
          'which means if you switch to version $minSupportedVersion then you can not use version command. '
          'If you really want to switch to version $targetVersion, please use `--force` flag: `flutter version --force $targetVersion`.'
        );
        return const FlutterCommandResult(ExitStatus.success);
      }
      withForce = true;
    }

    try {
      await globals.processUtils.run(
        <String>['git', 'checkout', 'v$version'],
        throwOnError: true,
        workingDirectory: Cache.flutterRoot,
      );
    } on Exception catch (e) {
      throwToolExit('Unable to checkout version branch for version $version: $e');
    }

    final FlutterVersion flutterVersion = FlutterVersion();

    globals.printStatus('Switching Flutter to version ${flutterVersion.frameworkVersion}${withForce ? ' with force' : ''}');

    // Check for and download any engine and pkg/ updates.
    // We run the 'flutter' shell script re-entrantly here
    // so that it will download the updated Dart and so forth
    // if necessary.
    globals.printStatus('');
    globals.printStatus('Downloading engine...');
    int code = await globals.processUtils.stream(<String>[
      globals.fs.path.join('bin', 'flutter'),
      '--no-color',
      'precache',
    ], workingDirectory: Cache.flutterRoot, allowReentrantFlutter: true);

    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }

    globals.printStatus('');
    globals.printStatus(flutterVersion.toString());

    final String projectRoot = findProjectRoot();
    if (projectRoot != null && boolArg('pub')) {
      globals.printStatus('');
      await pub.get(
        context: PubContext.pubUpgrade,
        directory: projectRoot,
        upgrade: true,
        checkLastModified: false,
      );
    }

    // Run a doctor check in case system requirements have changed.
    globals.printStatus('');
    globals.printStatus('Running flutter doctor...');
    code = await globals.processUtils.stream(
      <String>[
        globals.fs.path.join('bin', 'flutter'),
        'doctor',
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true,
    );

    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }

    return FlutterCommandResult.success();
  }
}
