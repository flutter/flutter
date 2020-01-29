// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../aot.dart';
import '../bundle.dart';
import '../commands/build_linux.dart';
import '../commands/build_macos.dart';
import '../commands/build_windows.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import 'build_aar.dart';
import 'build_aot.dart';
import 'build_apk.dart';
import 'build_appbundle.dart';
import 'build_bundle.dart';
import 'build_fuchsia.dart';
import 'build_ios.dart';
import 'build_ios_framework.dart';
import 'build_web.dart';

class BuildCommand extends FlutterCommand {
  BuildCommand({bool verboseHelp = false}) {
    addSubcommandWithFontSubsetFlag(BuildAarCommand());
    addSubcommandWithFontSubsetFlag(BuildApkCommand(verboseHelp: verboseHelp));
    addSubcommandWithFontSubsetFlag(BuildAppBundleCommand(verboseHelp: verboseHelp));
    addSubcommandWithFontSubsetFlag(BuildAotCommand(verboseHelp: verboseHelp));
    addSubcommandWithFontSubsetFlag(BuildIOSCommand());
    addSubcommandWithFontSubsetFlag(BuildIOSFrameworkCommand(
      aotBuilder: AotBuilder(),
      bundleBuilder: BundleBuilder(),
      cache: globals.cache,
      platform: globals.platform,
    ));
    addSubcommandWithFontSubsetFlag(BuildBundleCommand(verboseHelp: verboseHelp));
    addSubcommandWithFontSubsetFlag(BuildWebCommand());
    addSubcommandWithFontSubsetFlag(BuildMacosCommand());
    addSubcommandWithFontSubsetFlag(BuildLinuxCommand());
    addSubcommandWithFontSubsetFlag(BuildWindowsCommand());
    addSubcommandWithFontSubsetFlag(BuildFuchsiaCommand(verboseHelp: verboseHelp));
  }

  void addSubcommandWithFontSubsetFlag(BuildSubCommand command) {
    command.addFontSubsetFlag();
    addSubcommand(command);
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
}
