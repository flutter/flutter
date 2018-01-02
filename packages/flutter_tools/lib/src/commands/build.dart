// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/utils.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import 'build_aot.dart';
import 'build_apk.dart';
import 'build_flx.dart';
import 'build_ios.dart';

class BuildCommand extends FlutterCommand {
  BuildCommand({bool verboseHelp: false}) {
    addSubcommand(new BuildApkCommand(verboseHelp: verboseHelp));
    addSubcommand(new BuildAotCommand(verboseHelp: verboseHelp));
    addSubcommand(new BuildIOSCommand(verboseHelp: verboseHelp));
    addSubcommand(new BuildFlxCommand(verboseHelp: verboseHelp));
  }

  @override
  final String name = 'build';

  @override
  final String description = 'Flutter build commands.';

  @override
  Future<Null> runCommand() async { }
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand() {
    requiresPubspecYaml();
  }

  @override
  @mustCallSuper
  Future<Null> runCommand() async {
    if (isRunningOnBot) {
      final File dotPackages = fs.file('.packages');
      printStatus('Contents of .packages:');
      if (dotPackages.existsSync())
        printStatus(dotPackages.readAsStringSync());
      else
        printError('File not found: ${dotPackages.absolute.path}');

      final File pubspecLock = fs.file('pubspec.lock');
      printStatus('Contents of pubspec.lock:');
      if (pubspecLock.existsSync())
        printStatus(pubspecLock.readAsStringSync());
      else
        printError('File not found: ${pubspecLock.absolute.path}');
    }
  }
}
