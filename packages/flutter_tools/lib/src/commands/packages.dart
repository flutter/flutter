// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/os.dart';
import '../dart/pub.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class PackagesCommand extends FlutterCommand {
  PackagesCommand() {
    addSubcommand(PackagesGetCommand('get', false));
    addSubcommand(PackagesGetCommand('upgrade', true));
    addSubcommand(PackagesTestCommand());
    addSubcommand(PackagesPassthroughCommand());
  }

  @override
  final String name = 'packages';

  @override
  List<String> get aliases => const <String>['pub'];

  @override
  final String description = 'Commands for managing Flutter packages.';

  @override
  Future<FlutterCommandResult> runCommand() async => null;
}

class PackagesGetCommand extends FlutterCommand {
  PackagesGetCommand(this.name, this.upgrade) {
    requiresPubspecYaml();
    argParser.addFlag('offline',
      negatable: false,
      help: 'Use cached packages instead of accessing the network.'
    );
  }

  @override
  final String name;

  final bool upgrade;

  @override
  String get description {
    return '${ upgrade ? "Upgrade" : "Get" } packages in a Flutter project.';
  }

  @override
  String get invocation {
    return '${runner.executableName} packages $name [<target directory>]';
  }

  Future<void> _runPubGet (String directory) async {
    await pubGet(context: PubContext.pubGet,
      directory: directory,
      upgrade: upgrade ,
      offline: argResults['offline'],
      checkLastModified: false,
    );
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults.rest.length > 1)
      throwToolExit('Too many arguments.\n$usage');

    final String target = findProjectRoot(
      argResults.rest.length == 1 ? argResults.rest[0] : null
    );
    if (target == null) {
      throwToolExit(
       'Expected to find project root in '
       '${ argResults.rest.length == 1 ? argResults.rest[0] : "current working directory" }.'
      );
    }

    await _runPubGet(target);
    final FlutterProject rootProject = await FlutterProject.fromPath(target);
    await rootProject.ensureReadyForPlatformSpecificTooling();

    // Get/upgrade packages in example app as well
    if (rootProject.hasExampleApp) {
      final FlutterProject exampleProject = rootProject.example;
      await _runPubGet(exampleProject.directory.path);
      await exampleProject.ensureReadyForPlatformSpecificTooling();
    }

    return null;
  }
}

class PackagesTestCommand extends FlutterCommand {
  PackagesTestCommand() {
    requiresPubspecYaml();
  }

  @override
  String get name => 'test';

  @override
  String get description {
    return 'Run the "test" package.\n'
           'This is similar to "flutter test", but instead of hosting the tests in the '
           'flutter environment it hosts the tests in a pure Dart environment. The main '
           'differences are that the "dart:ui" library is not available and that tests '
           'run faster. This is helpful for testing libraries that do not depend on any '
           'packages from the Flutter SDK. It is equivalent to "pub run test".';
  }

  @override
  String get invocation {
    return '${runner.executableName} packages test [<tests...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pub(<String>['run', 'test']..addAll(argResults.rest), context: PubContext.runTest, retry: false);
    return null;
  }
}

class PackagesPassthroughCommand extends FlutterCommand {
  PackagesPassthroughCommand() {
    requiresPubspecYaml();
  }

  @override
  String get name => 'pub';

  @override
  String get description {
    return 'Pass the remaining arguments to Dart\'s "pub" tool.\n'
           'This runs the "pub" tool in a Flutter context.';
  }

  @override
  String get invocation {
    return '${runner.executableName} packages pub [<arguments...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pubInteractively(argResults.rest);
    return null;
  }
}
