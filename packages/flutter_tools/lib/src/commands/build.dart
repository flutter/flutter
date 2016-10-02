// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';

import '../build_info.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../base/utils.dart';
import 'build_apk.dart';
import 'build_aot.dart';
import 'build_flx.dart';
import 'build_ios.dart';

class BuildCommand extends FlutterCommand {
  BuildCommand({bool verboseHelp: false}) {
    addSubcommand(new BuildApkCommand());
    addSubcommand(new BuildAotCommand());
    addSubcommand(new BuildCleanCommand());
    addSubcommand(new BuildIOSCommand());
    addSubcommand(new BuildFlxCommand(verboseHelp: verboseHelp));
  }

  @override
  final String name = 'build';

  @override
  final String description = 'Flutter build commands.';

  @override
  Future<int> verifyThenRunCommand() async {
    if (!commandValidator())
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  Future<int> runCommand() => new Future<int>.value(0);
}

abstract class BuildSubCommand extends FlutterCommand {
  @override
  @mustCallSuper
  Future<int> verifyThenRunCommand() async {
    if (!commandValidator())
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  @mustCallSuper
  Future<int> runCommand() async {
    if (isRunningOnBot) {
      File dotPackages = new File('.packages');
      printStatus('Contents of .packages:');
      if (dotPackages.existsSync())
        printStatus(dotPackages.readAsStringSync());
      else
        printError('File not found: ${dotPackages.absolute.path}');

      File pubspecLock = new File('pubspec.lock');
      printStatus('Contents of pubspec.lock:');
      if (pubspecLock.existsSync())
        printStatus(pubspecLock.readAsStringSync());
      else
        printError('File not found: ${pubspecLock.absolute.path}');
    }
    return 0;
  }
}

class BuildCleanCommand extends FlutterCommand {
  @override
  final String name = 'clean';

  @override
  final String description = 'Delete the build/ directory.';

  @override
  Future<int> verifyThenRunCommand() async {
    if (!commandValidator())
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  Future<int> runCommand() async {
    Directory buildDir = new Directory(getBuildDirectory());
    printStatus("Deleting '${buildDir.path}${Platform.pathSeparator}'.");

    if (!buildDir.existsSync())
      return 0;

    try {
      buildDir.deleteSync(recursive: true);
      return 0;
    } catch (error) {
      printError(error.toString());
      return 1;
    }
  }
}
