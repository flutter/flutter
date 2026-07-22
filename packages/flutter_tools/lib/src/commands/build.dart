// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/template.dart';
import '../base/terminal.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../ios/code_signing.dart';
import '../ios/plist_parser.dart';
import '../macos/xcode.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'build_aar.dart';
import 'build_apk.dart';
import 'build_appbundle.dart';
import 'build_bundle.dart';
import 'build_ios.dart';
import 'build_ios_framework.dart';
import 'build_linux.dart';
import 'build_macos.dart';
import 'build_macos_framework.dart';
import 'build_swift_package.dart';
import 'build_web.dart';
import 'build_windows.dart';
import 'darwin_add_to_app.dart';

class BuildCommand extends FlutterCommand {
  BuildCommand({
    required Artifacts artifacts,
    required Cache cache,
    required FileSystem fileSystem,
    required FlutterVersion flutterVersion,
    required BuildSystem buildSystem,
    required OperatingSystemUtils osUtils,
    required Logger logger,
    required AndroidSdk? androidSdk,
    required Config config,
    required Platform platform,
    required ProcessUtils processUtils,
    required ProcessManager processManager,
    required FileSystemUtils fileSystemUtils,
    required TemplateRenderer templateRenderer,
    required Terminal terminal,
    required PlistParser plistParser,
    required Xcode? xcode,
    bool verboseHelp = false,
  }) {
    _addSubcommand(
      BuildAarCommand(
        fileSystem: fileSystem,
        androidSdk: androidSdk,
        logger: logger,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(BuildApkCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildAppBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildIOSCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildIOSFrameworkCommand(
        logger: logger,
        buildSystem: buildSystem,
        verboseHelp: verboseHelp,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: processUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
      ),
    );
    _addSubcommand(
      BuildMacOSFrameworkCommand(
        logger: logger,
        buildSystem: buildSystem,
        verboseHelp: verboseHelp,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: processUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
      ),
    );
    _addSubcommand(
      BuildSwiftPackage(
        logger: logger,
        analytics: analytics,
        artifacts: artifacts,
        buildSystem: buildSystem,
        cache: cache,
        featureFlags: featureFlags,
        fileSystem: fileSystem,
        flutterVersion: flutterVersion,
        platform: platform,
        processManager: processManager,
        templateRenderer: templateRenderer,
        xcode: xcode,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: processUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
        verboseHelp: verboseHelp,
      ),
    );

    _addSubcommand(BuildIOSArchiveCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildWebCommand(fileSystem: fileSystem, logger: logger, verboseHelp: verboseHelp),
    );
    _addSubcommand(BuildMacosCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildLinuxCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
    _addSubcommand(
      BuildWindowsCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
  }

  void _addSubcommand(BuildSubCommand command) {
    if (command.supported) {
      addSubcommand(command);
    }
  }

  @override
  final name = 'build';

  @override
  final description = 'Build an executable app or install bundle.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand({required this.logger, required bool verboseHelp}) {
    requiresPubspecYaml();
    usesFatalWarningsOption(verboseHelp: verboseHelp);
  }

  @protected
  final Logger logger;

  /// Whether this command is supported and should be shown.
  bool get supported => true;

  /// Warns when an explicit `--[no-]enable-hcpp` conflicts with an explicit
  /// `io.flutter.embedding.android.EnableHcpp` value in the app manifest.
  ///
  /// Build commands, unlike `flutter run`/`flutter test`, have no launch-time
  /// override channel: the packaged manifest is authoritative, and the build
  /// never overwrites an explicit manifest entry. An explicit flag that
  /// disagrees with an explicit manifest value therefore has no effect on the
  /// artifact, so surface that instead of silently ignoring the flag.
  @protected
  void warnIfHcppFlagConflictsWithManifest(FlutterProject project) {
    final bool? flag = explicitEnableHcpp;
    if (flag == null) {
      return;
    }
    final bool? manifestValue = project.android.explicitHcppFromManifest();
    if (manifestValue == null || manifestValue == flag) {
      return;
    }
    globals.logger.printWarning(
      'The --${flag ? '' : 'no-'}enable-hcpp flag does not affect this build. '
      'AndroidManifest.xml explicitly sets io.flutter.embedding.android.EnableHcpp '
      'to "$manifestValue", which is authoritative for the built artifact; the flag '
      'only sets the default when the manifest does not. To change the packaged '
      'value, edit the manifest. ("flutter run" and "flutter test" instead honor the '
      'flag at launch, overriding the manifest.)',
    );
  }
}
