// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/terminal.dart';
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
    // Warn if building a release app on Master channel
    final String channel = FlutterVersion.instance.channel;
    if (channel == 'master') {
      printStatus('🐉', newline: false, color: TerminalColor.red);
      printStatus(' This is the $channel channel. Shipping apps from this channel is not recommended as it has not been as heavily tested as the stable channel. To build using the stable channel, consider using:\n    flutter channel stable');
    }
    return null;
  }
}
