// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/os.dart';
import '../dart/pub.dart';
import '../runner/flutter_command.dart';

class PackagesCommand extends FlutterCommand {
  PackagesCommand() {
    addSubcommand(new PackagesGetCommand('get', false));
    addSubcommand(new PackagesGetCommand('upgrade', true));
  }

  @override
  final String name = 'packages';

  @override
  List<String> get aliases => const <String>['pub'];

  @override
  final String description = 'Commands for managing Flutter packages.';

  @override
  Future<Null> verifyThenRunCommand() async {
    commandValidator();
    return super.verifyThenRunCommand();
  }

  @override
  Future<Null> runCommand() async { }
}

class PackagesGetCommand extends FlutterCommand {
  @override
  final String name;

  final bool upgrade;

  PackagesGetCommand(this.name, this.upgrade) {
    argParser.addFlag('offline',
      negatable: false,
      help: 'Use cached packages instead of accessing the network.'
    );
  }

  @override
  String get description {
    return '${ upgrade ? "Upgrade" : "Get" } packages in a Flutter project.';
  }

  @override
  String get invocation {
    return '${runner.executableName} packages $name [<target directory>]';
  }

  @override
  Future<Null> runCommand() async {
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

    // TODO(ianh): If the user is using a local build, we should use the
    // packages from their build instead of the cache.

    await pubGet(
      directory: target,
      upgrade: upgrade,
      offline: argResults['offline'],
      checkLastModified: false,
    );
  }
}
