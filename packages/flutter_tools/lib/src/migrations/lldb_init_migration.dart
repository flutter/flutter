// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

import '../base/file_system.dart';
import '../base/project_migrator.dart';
import '../build_info.dart';
import '../ios/xcodeproj.dart';
import '../project.dart';

class LLDBInitMigration extends ProjectMigrator {
  LLDBInitMigration(
    IosProject project,
    BuildInfo buildInfo,
    super.logger, {
    required FileSystem fileSystem,
    required EnvironmentType environmentType,
    String? deviceID,
  }) : _xcodeProject = project,
       _buildInfo = buildInfo,
       _xcodeProjectInfoFile = project.xcodeProjectInfoFile,
       _fileSystem = fileSystem,
       _environmentType = environmentType,
       _deviceID = deviceID;

  final IosProject _xcodeProject;
  final BuildInfo _buildInfo;
  final FileSystem _fileSystem;
  final File _xcodeProjectInfoFile;
  final EnvironmentType _environmentType;
  final String? _deviceID;

  String get _initPath =>
      _xcodeProject.lldbInitFile.path.replaceFirst(_xcodeProject.hostAppRoot.path, r'$(SRCROOT)');

  static const _launchActionIdentifier = 'LaunchAction';
  static const _testActionIdentifier = 'TestAction';

  @override
  Future<void> migrate() async {
    SchemeInfo? schemeInfo;
    // LLDB Init File is only needed for debug and profile mode.
    if (_buildInfo.mode == BuildMode.release) {
      return;
    }
    try {
      if (!_xcodeProjectInfoFile.existsSync()) {
        logger.printTrace('Xcode project not found.');
        throw _exceptionMessage();
      }

      schemeInfo = await _getSchemeInfo();

      final bool isSchemeMigrated = await _isSchemeMigrated(schemeInfo);
      if (isSchemeMigrated) {
        return;
      }
      _migrateScheme(schemeInfo);
    } on _LLDBError catch (e) {
      logger.printError(
        'An error occurred when adding LLDB Init File:\n'
        '${e.message}',
      );
    }
  }

  Future<SchemeInfo> _getSchemeInfo() async {
    final XcodeProjectInfo? projectInfo = await _xcodeProject.projectInfo();
    if (projectInfo == null) {
      logger.printTrace('Unable to get Xcode project info.');
      throw _exceptionMessage();
    }
    if (_xcodeProject.xcodeWorkspace == null) {
      logger.printTrace('Xcode workspace not found.');
      throw _exceptionMessage();
    }
    final String? scheme = projectInfo.schemeFor(_buildInfo);
    if (scheme == null) {
      projectInfo.reportFlavorNotFoundAndExit();
    }

    final File schemeFile = _xcodeProject.xcodeProjectSchemeFile(scheme: scheme);
    if (!schemeFile.existsSync()) {
      logger.printTrace('Unable to get scheme file for $scheme.');
      throw _exceptionMessage(schemeName: scheme);
    }

    final String schemeContent = schemeFile.readAsStringSync();
    return SchemeInfo(schemeName: scheme, schemeFile: schemeFile, schemeContent: schemeContent);
  }

  Future<bool> _isSchemeMigrated(SchemeInfo schemeInfo) async {
    final String? lldbInitFileLaunchPath;
    final String? lldbInitFileTestPath;
    try {
      // Check that both the LaunchAction and TestAction have the customLLDBInitFile set to flutter_lldbinit.
      final document = XmlDocument.parse(schemeInfo.schemeContent);

      lldbInitFileLaunchPath = _parseLLDBInitFileFromScheme(
        action: _launchActionIdentifier,
        document: document,
        schemeInfo: schemeInfo,
      );
      lldbInitFileTestPath = _parseLLDBInitFileFromScheme(
        action: _testActionIdentifier,
        document: document,
        schemeInfo: schemeInfo,
      );
      final bool launchActionMigrated =
          lldbInitFileLaunchPath != null && lldbInitFileLaunchPath.contains(_initPath);
      final bool testActionMigrated =
          lldbInitFileTestPath != null && lldbInitFileTestPath.contains(_initPath);

      if (launchActionMigrated && testActionMigrated) {
        return true;
      } else if (launchActionMigrated && !testActionMigrated) {
        // If LaunchAction has it set, but TestAction doesn't, give an error
        // with instructions to add it to the TestAction.
        throw _exceptionMessage(missingAction: 'Test', schemeName: schemeInfo.schemeName);
      } else if (testActionMigrated && !launchActionMigrated) {
        // If TestAction has it set, but LaunchAction doesn't, give an error
        // with instructions to add it to the LaunchAction.
        throw _exceptionMessage(missingAction: 'Run', schemeName: schemeInfo.schemeName);
      }
    } on XmlException catch (exception) {
      logger.printTrace(
        'Failed to parse ${schemeInfo.schemeFile.basename}: Invalid xml: ${schemeInfo.schemeContent}\n$exception',
      );
      throw _exceptionMessage(schemeName: schemeInfo.schemeName);
    }

    // If the scheme is using a LLDB Init File that is not flutter_lldbinit,
    // attempt to read the file and check if it's importing flutter_lldbinit.
    // If the file name contains a variable, attempt to substitute the variable
    // using the build settings. If it fails to find the file or fails to
    // detect it's using flutter_lldbinit, print a warning to either remove
    // their LLDB Init file or append flutter_lldbinit to their existing one.
    if (schemeInfo.schemeContent.contains('customLLDBInitFile')) {
      try {
        Map<String, String>? buildSettings;
        if ((lldbInitFileLaunchPath != null && lldbInitFileLaunchPath.contains(r'$')) ||
            (lldbInitFileTestPath != null && lldbInitFileTestPath.contains(r'$'))) {
          buildSettings =
              await _xcodeProject.buildSettingsForBuildInfo(
                _buildInfo,
                environmentType: _environmentType,
                deviceId: _deviceID,
              ) ??
              <String, String>{};
        }

        final File? lldbInitFileLaunchFile = _resolveLLDBInitFile(
          lldbInitFileLaunchPath,
          buildSettings,
        );
        final File? lldbInitFileTestFile = _resolveLLDBInitFile(
          lldbInitFileTestPath,
          buildSettings,
        );

        if (lldbInitFileLaunchFile != null &&
            lldbInitFileLaunchFile.existsSync() &&
            lldbInitFileLaunchFile.readAsStringSync().contains(
              _xcodeProject.lldbInitFile.basename,
            ) &&
            lldbInitFileTestFile != null &&
            lldbInitFileTestFile.existsSync() &&
            lldbInitFileTestFile.readAsStringSync().contains(_xcodeProject.lldbInitFile.basename)) {
          return true;
        }
      } on XmlException catch (exception) {
        logger.printTrace(
          'Failed to parse ${schemeInfo.schemeFile.basename}: Invalid xml: ${schemeInfo.schemeContent}\n$exception',
        );
        throw _exceptionMessage(schemeName: schemeInfo.schemeName);
      }

      throw _LLDBError(
        'Running Flutter in debug mode on new iOS versions requires a LLDB '
        'Init File, but the scheme already has one set. To ensure debug '
        'mode works, please complete one of the following:\n'
        '  * Open Xcode > Product > Scheme > Edit Scheme and remove LLDB Init '
        'File for both the Run and Test actions.\n'
        '  * Append the following to your custom LLDB Init File:\n\n'
        '    command source ${_xcodeProject.lldbInitFile.absolute.path}\n',
      );
    }
    return false;
  }

  /// Add customLLDBInitFile and set to [_initPath] for both LaunchAction and TestAction.
  void _migrateScheme(SchemeInfo schemeInfo) {
    final File schemeFile = schemeInfo.schemeFile;
    final String schemeContent = schemeInfo.schemeContent;

    final String newScheme = schemeContent.replaceAll(
      'selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"',
      '''
selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      customLLDBInitFile = "$_initPath"''',
    );
    try {
      final document = XmlDocument.parse(newScheme);
      _validateSchemeAction(
        action: _launchActionIdentifier,
        document: document,
        schemeInfo: schemeInfo,
      );
      _validateSchemeAction(
        action: _testActionIdentifier,
        document: document,
        schemeInfo: schemeInfo,
      );
    } on XmlException catch (exception) {
      logger.printTrace(
        'Failed to parse ${schemeFile.basename}: Invalid xml: $newScheme\n$exception',
      );
      throw _exceptionMessage(schemeName: schemeInfo.schemeName);
    }
    schemeFile.writeAsStringSync(newScheme);
  }

  /// Parse the customLLDBInitFile from the XML for the [action] and validate
  /// it contains [_initPath].
  void _validateSchemeAction({
    required String action,
    required XmlDocument document,
    required SchemeInfo schemeInfo,
  }) {
    final String? lldbInitFile = _parseLLDBInitFileFromScheme(
      action: action,
      document: document,
      schemeInfo: schemeInfo,
    );
    if (lldbInitFile == null || !lldbInitFile.contains(_initPath)) {
      logger.printTrace(
        'Failed to find correct customLLDBInitFile in $action for the Scheme in ${schemeInfo.schemeFile.path}.',
      );
      throw _exceptionMessage(schemeName: schemeInfo.schemeName);
    }
  }

  /// Parse the customLLDBInitFile from the XML for the [action].
  String? _parseLLDBInitFileFromScheme({
    required String action,
    required XmlDocument document,
    required SchemeInfo schemeInfo,
  }) {
    // ignore: experimental_member_use
    final Iterable<XmlNode> nodes = document.xpath('/Scheme/$action');
    if (nodes.isEmpty) {
      logger.printTrace('Failed to find $action for the Scheme in ${schemeInfo.schemeFile.path}.');
      throw _exceptionMessage(schemeName: schemeInfo.schemeName);
    }
    final XmlNode actionNode = nodes.first;
    final XmlAttribute? lldbInitFile = actionNode.attributes
        .where((XmlAttribute attribute) => attribute.localName == 'customLLDBInitFile')
        .firstOrNull;
    return lldbInitFile?.value;
  }

  /// Replace any Xcode variables in [lldbInitFilePath] from [buildSettings].
  File? _resolveLLDBInitFile(String? lldbInitFilePath, Map<String, String>? buildSettings) {
    if (lldbInitFilePath == null) {
      return null;
    }
    if (lldbInitFilePath.contains(r'$') && buildSettings != null) {
      // If the path to the LLDB Init File contains a $, it may contain a
      // variable from build settings.
      final String resolvedInitFilePath = substituteXcodeVariables(lldbInitFilePath, buildSettings);
      return _fileSystem.file(resolvedInitFilePath);
    }
    return _fileSystem.file(lldbInitFilePath);
  }

  _LLDBError _exceptionMessage({String? missingAction, String? schemeName}) {
    final String buildMode = _buildInfo.mode.cliName;
    if (missingAction != null && schemeName != null) {
      return _LLDBError(
        'Running Flutter in $buildMode mode on new iOS versions requires a LLDB '
        'Init File, but the $missingAction action in the $schemeName scheme '
        'does not have it set. To ensure $buildMode mode works, please complete '
        'the following:\n'
        '  * Open Xcode > Product > Scheme > Edit Scheme and for the '
        '$missingAction action, set LLDB Init File to:\n\n'
        '  $_initPath\n',
      );
    } else if (schemeName != null) {
      return _LLDBError(
        'Running Flutter in $buildMode mode on new iOS versions requires a LLDB '
        'Init File, but the $schemeName scheme does not have it set. To ensure '
        '$buildMode mode works, please complete the following:\n'
        '  * Open Xcode > Product > Scheme > Edit Scheme and for the Run and Test actions, set LLDB Init File to:\n\n'
        '  $_initPath\n',
      );
    }
    return _LLDBError(
      'Running Flutter in $buildMode mode on new iOS versions requires a LLDB '
      'Init File, but the scheme does not have it set. To ensure $buildMode mode '
      'works, please complete the following:\n'
      '  * Open Xcode > Product > Scheme > Edit Scheme and for the Run and Test actions, set LLDB Init File to:\n\n'
      '  $_initPath\n',
    );
  }
}

class _LLDBError implements Exception {
  _LLDBError(this.message);

  final String message;
}

class SchemeInfo {
  SchemeInfo({required this.schemeName, required this.schemeFile, required this.schemeContent});

  final String schemeName;
  final File schemeFile;
  final String schemeContent;
}
