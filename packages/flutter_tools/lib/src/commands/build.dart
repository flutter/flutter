// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/android_sdk.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../build_system/build_system.dart';
import '../commands/build_linux.dart';
import '../commands/build_macos.dart';
import '../commands/build_windows.dart';
import '../runner/flutter_command.dart';
import 'build_aar.dart';
import 'build_apk.dart';
import 'build_appbundle.dart';
import 'build_bundle.dart';
import 'build_ios.dart';
import 'build_ios_framework.dart';
import 'build_macos_framework.dart';
import 'build_web.dart';

class BuildCommand extends FlutterCommand {
  BuildCommand({
    required FileSystem fileSystem,
    required BuildSystem buildSystem,
    required OperatingSystemUtils osUtils,
    required AndroidSdk? androidSdk,
    bool verboseHelp = false,
  }){
    _addSubcommand(
        BuildAarCommand(
          fileSystem: fileSystem,
          androidSdk: androidSdk,
          verboseHelp: verboseHelp,
        )
    );
    _addSubcommand(BuildApkCommand(verboseHelp: verboseHelp));
    _addSubcommand(BuildAppBundleCommand(verboseHelp: verboseHelp));
    _addSubcommand(BuildIOSCommand(verboseHelp: verboseHelp));
    _addSubcommand(BuildIOSFrameworkCommand(
      buildSystem: buildSystem,
      verboseHelp: verboseHelp,
    ));
    _addSubcommand(BuildMacOSFrameworkCommand(
      buildSystem: buildSystem,
      verboseHelp: verboseHelp,
    ));
    _addSubcommand(BuildIOSArchiveCommand(verboseHelp: verboseHelp));
    _addSubcommand(BuildBundleCommand(verboseHelp: verboseHelp));
    _addSubcommand(BuildWebCommand(
      fileSystem: fileSystem,
      verboseHelp: verboseHelp,
    ));
    _addSubcommand(BuildMacosCommand(verboseHelp: verboseHelp));
    _addSubcommand(BuildLinuxCommand(
      operatingSystemUtils: osUtils,
      verboseHelp: verboseHelp
    ));
    _addSubcommand(BuildWindowsCommand(verboseHelp: verboseHelp));
  }

  void _addSubcommand(BuildSubCommand command) {
    if (command.supported) {
      addSubcommand(command);
    }
  }

  @override
  final String name = 'build';

  @override
  final String description = 'Build an executable app or install bundle.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand({
    required bool verboseHelp
  }) {
    requiresPubspecYaml();
    usesFatalWarningsOption(verboseHelp: verboseHelp);
  }

  bool get supported => true;
}
