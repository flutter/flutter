// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'build_aot.dart';
import 'build_apk.dart';
import 'build_appbundle.dart';
import 'build_bundle.dart';
import 'build_flx.dart';
import 'build_ios.dart';

class BuildCommand extends FlutterCommand {
  BuildCommand({bool verboseHelp = false}) {
    addSubcommand(BuildApkCommand(verboseHelp: verboseHelp));
    addSubcommand(BuildAppBundleCommand(verboseHelp: verboseHelp));
    addSubcommand(BuildAotCommand());
    addSubcommand(BuildIOSCommand());
    addSubcommand(BuildFlxCommand());
    addSubcommand(BuildBundleCommand(verboseHelp: verboseHelp));
  }

  @override
  final String name = 'build';

  @override
  final String description = 'Flutter build commands.';

  @override
  Future<FlutterCommandResult> runCommand() async => null;
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand() {
    requiresPubspecYaml();
  }

  @override
  @mustCallSuper
  Future<FlutterCommandResult> runCommand() async {
    warnIfOnMasterChannel();
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
    return null;
  }

  void warnIfOnMasterChannel() {
    String channel = FlutterVersion.instance.channel;
    if (channel == 'master') {
      printStatus('🐉', newline: false, color: TerminalColor.red);
      printStatus(' This is the $channel channel. Shipping apps from this channel is not recommended as it has not been as heavily tested as the stable channel. To build using the stable channel, consider using:\n    flutter channel stable');
    }
  }
}
