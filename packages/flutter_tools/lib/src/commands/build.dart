// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
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
  Future<Null> verifyThenRunCommand() async {
    commandValidator();
    return super.verifyThenRunCommand();
  }

  @override
  Future<Null> runCommand() async { }
}

abstract class BuildSubCommand extends FlutterCommand {
  @override
  @mustCallSuper
  Future<Null> verifyThenRunCommand() async {
    commandValidator();
    return super.verifyThenRunCommand();
  }

  @override
  @mustCallSuper
  Future<Null> runCommand() async {
    if (isRunningOnBot) {
      File dotPackages = fs.file('.packages');
      printStatus('Contents of .packages:');
      if (dotPackages.existsSync())
        printStatus(dotPackages.readAsStringSync());
      else
        printError('File not found: ${dotPackages.absolute.path}');

      File pubspecLock = fs.file('pubspec.lock');
      printStatus('Contents of pubspec.lock:');
      if (pubspecLock.existsSync())
        printStatus(pubspecLock.readAsStringSync());
      else
        printError('File not found: ${pubspecLock.absolute.path}');
    }
  }
}

class BuildCleanCommand extends FlutterCommand {
  @override
  final String name = 'clean';

  @override
  final String description = 'Delete the build/ directory.';

  @override
  Future<Null> verifyThenRunCommand() async {
    commandValidator();
    return super.verifyThenRunCommand();
  }

  @override
  Future<Null> runCommand() async {
    Directory buildDir = fs.directory(getBuildDirectory());
    printStatus("Deleting '${buildDir.path}${fs.pathSeparator}'.");

    if (!buildDir.existsSync())
      return;

    try {
      buildDir.deleteSync(recursive: true);
    } catch (error) {
      throwToolExit(error.toString());
    }
  }
}
