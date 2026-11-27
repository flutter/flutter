// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/android_workflow.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/user_messages.dart';
import '../context/android_context.dart';
import '../context/tool_context.dart';
import '../doctor.dart';
import '../experimental/extension_manager.dart';
import '../runner/flutter_command.dart';

/// The `flutter doctor` command, which displays diagnostic information about the
/// installed developer environment and tooling.
class DoctorCommand extends FlutterCommand {
  DoctorCommand({
    required this._androidContext,
    required this._doctor,
    required super.toolContext,
    this.extensionManager,
    this.verbose = false,
  }) {
    argParser.addFlag(
      'android-licenses',
      negatable: false,
      help: "Run the Android SDK manager tool to accept the SDK's licenses.",
    );
    argParser.addOption(
      'check-for-remote-artifacts',
      hide: !verbose,
      help:
          'Used to determine if Flutter engine artifacts for all platforms '
          'are available for download.',
      valueHelp: 'engine revision git hash',
    );
  }

  final AndroidContext _androidContext;
  final Doctor _doctor;
  final bool verbose;
  final ExtensionManager? extensionManager;

  @override
  final name = 'doctor';

  @override
  final description = 'Show information about the installed tooling.';

  @override
  final String category = FlutterCommandCategory.sdk;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults?.wasParsed('check-for-remote-artifacts') ?? false) {
      final String engineRevision = stringArg('check-for-remote-artifacts')!;
      if (engineRevision.startsWith(RegExp(r'[a-f0-9]{1,40}'))) {
        final bool success = await _doctor.checkRemoteArtifacts(engineRevision);
        if (success) {
          throwToolExit(
            'Artifacts for engine $engineRevision are missing or are '
            'not yet available.',
            exitCode: 1,
          );
        }
      } else {
        throwToolExit(
          'Remote artifact revision $engineRevision is not a valid '
          'git hash.',
        );
      }
    }
    final bool androidLicenses = boolArg('android-licenses');
    AndroidLicenseValidator? androidLicenseValidator;
    if (androidLicenses) {
      final ToolContext(
        :Logger logger,
        :Platform platform,
        :Stdio stdio,
        :UserMessages userMessages,
      ) = toolContext;
      androidLicenseValidator = AndroidLicenseValidator(
        androidSdk: _androidContext.androidSdk,
        java: _androidContext.java,
        logger: logger,
        platform: platform,
        processManager: toolContext.processManager,
        stdio: stdio,
        userMessages: userMessages,
      );
    }
    final bool success = await _doctor.diagnose(
      androidLicenses: androidLicenses,
      verbose: verbose,
      androidLicenseValidator: androidLicenseValidator,
      extensionManager: extensionManager,
    );
    return FlutterCommandResult(success ? ExitStatus.success : ExitStatus.warning);
  }
}
