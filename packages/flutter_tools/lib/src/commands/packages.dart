// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/os.dart';
import '../dart/pub.dart';
import '../globals.dart';
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
  Future<int> verifyThenRunCommand() async {
    if (!commandValidator())
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  Future<int> runCommand() => new Future<int>.value(0);
}

class PackagesGetCommand extends FlutterCommand {
  @override
  final String name;

  final bool upgrade;

  PackagesGetCommand(this.name, this.upgrade);

  // TODO: implement description
  @override
  String get description =>
      (upgrade ? 'Upgrade' : 'Get') + ' packages in a Flutter project.';

  @override
  String get invocation =>
      "${runner.executableName} packages $name [<target directory>]";

  @override
  Future<int> runCommand() async {
    if (argResults.rest.length > 1) {
      printStatus('Too many arguments.');
      printStatus(usage);
      return 1;
    }

    String target = findProjectRoot(
        argResults.rest.length == 1 ? argResults.rest[0] : null);
    if (target == null) {
      printStatus('Expected to find project root starting at ' +
          (argResults.rest.length == 1
              ? argResults.rest[0]
              : 'current working directory'));
      printStatus(usage);
      return 1;
    }

    // TODO: If the user is using a local build, we should use the packages from their build instead of the cache.

    return pubGet(directory: target, upgrade: upgrade, checkLastModified: false);
  }
}
