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

  static const String _launchActionIdentifier = 'LaunchAction';
  static const String _testActionIdentifier = 'TestAction';

  @override
  Future<void> migrate() async {
    SchemeInfo? schemeInfo;
    try {
      if (!_xcodeProjectInfoFile.existsSync()) {
        throw Exception('Xcode project not found.');
      }

      schemeInfo = await _getSchemeInfo();

      final bool isSchemeMigrated = await _isSchemeMigrated(schemeInfo);
      if (isSchemeMigrated) {
        return;
      }
      _migrateScheme(schemeInfo);
    } on Exception catch (e) {
      logger.printError(
        'An error occurred when adding LLDB Init File:\n'
        '$e',
      );
    }
  }

  Future<SchemeInfo> _getSchemeInfo() async {
    final XcodeProjectInfo? projectInfo = await _xcodeProject.projectInfo();
    if (projectInfo == null) {
      throw Exception('Unable to get Xcode project info.');
    }
    if (_xcodeProject.xcodeWorkspace == null) {
      throw Exception('Xcode workspace not found.');
    }
    final String? scheme = projectInfo.schemeFor(_buildInfo);
    if (scheme == null) {
      projectInfo.reportFlavorNotFoundAndExit();
    }

    final File schemeFile = _xcodeProject.xcodeProjectSchemeFile(scheme: scheme);
    if (!schemeFile.existsSync()) {
      throw Exception('Unable to get scheme file for $scheme.');
    }

    final String schemeContent = schemeFile.readAsStringSync();
    return SchemeInfo(schemeName: scheme, schemeFile: schemeFile, schemeContent: schemeContent);
  }

  Future<bool> _isSchemeMigrated(SchemeInfo schemeInfo) async {
    final String? lldbInitFileLaunchPath;
    final String? lldbInitFileTestPath;
    try {
      // Check that both the LaunchAction and TestAction have the customLLDBInitFile set to flutter_lldbinit.
      final XmlDocument document = XmlDocument.parse(schemeInfo.schemeContent);

      lldbInitFileLaunchPath = _parseLLDBInitFileFromScheme(
        action: _launchActionIdentifier,
        document: document,
        schemeFile: schemeInfo.schemeFile,
      );
      lldbInitFileTestPath = _parseLLDBInitFileFromScheme(
        action: _testActionIdentifier,
        document: document,
        schemeFile: schemeInfo.schemeFile,
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
        throw _missingActionException('Test', schemeInfo.schemeName);
      } else if (testActionMigrated && !launchActionMigrated) {
        // If TestAction has it set, but LaunchAction doesn't, give an error
        // with instructions to add it to the LaunchAction.
        throw _missingActionException('Launch', schemeInfo.schemeName);
      }
    } on XmlException catch (exception) {
      throw Exception(
        'Failed to parse ${schemeInfo.schemeFile.basename}: Invalid xml: ${schemeInfo.schemeContent}\n$exception',
      );
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
        throw Exception(
          'Failed to parse ${schemeInfo.schemeFile.basename}: Invalid xml: ${schemeInfo.schemeContent}\n$exception',
        );
      }

      throw Exception(
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
      final XmlDocument document = XmlDocument.parse(newScheme);
      _validateSchemeAction(
        action: _launchActionIdentifier,
        document: document,
        schemeFile: schemeFile,
      );
      _validateSchemeAction(
        action: _testActionIdentifier,
        document: document,
        schemeFile: schemeFile,
      );
    } on XmlException catch (exception) {
      throw Exception(
        'Failed to parse ${schemeFile.basename}: Invalid xml: $newScheme\n$exception',
      );
    }
    schemeFile.writeAsStringSync(newScheme);
  }

  /// Parse the customLLDBInitFile from the XML for the [action] and validate
  /// it contains [_initPath].
  void _validateSchemeAction({
    required String action,
    required XmlDocument document,
    required File schemeFile,
  }) {
    final String? lldbInitFile = _parseLLDBInitFileFromScheme(
      action: action,
      document: document,
      schemeFile: schemeFile,
    );
    if (lldbInitFile == null || !lldbInitFile.contains(_initPath)) {
      throw Exception(
        'Failed to find correct customLLDBInitFile in $action for the Scheme in ${schemeFile.path}.',
      );
    }
  }

  /// Parse the customLLDBInitFile from the XML for the [action].
  String? _parseLLDBInitFileFromScheme({
    required String action,
    required XmlDocument document,
    required File schemeFile,
  }) {
    final Iterable<XmlNode> nodes = document.xpath('/Scheme/$action');
    if (nodes.isEmpty) {
      throw Exception('Failed to find $action for the Scheme in ${schemeFile.path}.');
    }
    final XmlNode actionNode = nodes.first;
    final XmlAttribute? lldbInitFile =
        actionNode.attributes
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

  Exception _missingActionException(String missingAction, String schemeName) {
    return Exception(
      'Running Flutter in debug mode on new iOS versions requires a LLDB '
      'Init File, but the $missingAction action in the $schemeName scheme '
      'does not have it set. To ensure debug mode works, please complete '
      'the following:\n'
      '  * Open Xcode > Product > Scheme > Edit Scheme and for the '
      '$missingAction action, set LLDB Init File to:\n\n'
      '  $_initPath\n',
    );
  }
}

class SchemeInfo {
  SchemeInfo({required this.schemeName, required this.schemeFile, required this.schemeContent});

  final String schemeName;
  final File schemeFile;
  final String schemeContent;
}
