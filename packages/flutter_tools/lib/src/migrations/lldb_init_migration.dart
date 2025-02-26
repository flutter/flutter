// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/project_migrator.dart';
import '../build_info.dart';
import '../ios/xcodeproj.dart';
import '../project.dart';

class LLDBInitMigration extends ProjectMigrator {
  LLDBInitMigration(
    XcodeBasedProject project,
    SupportedPlatform platform,
    BuildInfo buildInfo, {
    required Logger logger,
  }) : _xcodeProject = project,
       _platform = platform,
       _buildInfo = buildInfo,
       _xcodeProjectInfoFile = project.xcodeProjectInfoFile,
       super(logger);

  final XcodeBasedProject _xcodeProject;
  final SupportedPlatform _platform;
  final BuildInfo _buildInfo;
  final File _xcodeProjectInfoFile;

  final String initPath = 'packages/flutter_tools/bin/.lldbinit';

  @override
  Future<void> migrate() async {
    // Only needed for iOS
    if (_platform != SupportedPlatform.ios) {
      return;
    }
    SchemeInfo? schemeInfo;
    try {
      if (!_xcodeProjectInfoFile.existsSync()) {
        throw Exception('Xcode project not found.');
      }

      schemeInfo = await _getSchemeInfo();

      final bool isSchemeMigrated = _isSchemeMigrated(schemeInfo);
      if (isSchemeMigrated) {
        return;
      }

      _migrateScheme(schemeInfo);

    } on Exception catch (e) {
      throwToolExit(
        'An error occurred when adding LLDB Init File:\n'
        '  $e'
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

  bool _isSchemeMigrated(SchemeInfo schemeInfo) {
    if (schemeInfo.schemeContent.contains(initPath)) {
      return true;
    }
    return false;
  }

  void _migrateScheme(SchemeInfo schemeInfo) {
    final File schemeFile = schemeInfo.schemeFile;
    final String schemeContent = schemeInfo.schemeContent;

    if (schemeContent.contains('customLLDBInitFile')) {
      throw Exception('Running Flutter in debug mode on new iOS versions requires an LLDB File, but the scheme already has one set. Please remove the LLDB Init File for the scheme ${schemeInfo.schemeName}');
    }

    final String newScheme = schemeContent.replaceAll(
      'selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"',
      '''
selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      customLLDBInitFile = "\$(FLUTTER_ROOT)/$initPath"''',
    );
    try {
      final XmlDocument document = XmlDocument.parse(newScheme);
      _validateSchemeAction(action: 'LaunchAction', document: document, schemeFile: schemeFile);
      _validateSchemeAction(action: 'TestAction', document: document, schemeFile: schemeFile);
    } on XmlException catch (exception) {
      throw Exception(
        'Failed to parse ${schemeFile.basename}: Invalid xml: $newScheme\n$exception',
      );
    }
    schemeFile.writeAsStringSync(newScheme);
  }

  void _validateSchemeAction({
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
    if (lldbInitFile == null || !lldbInitFile.value.contains(initPath)) {
      throw Exception(
        'Failed to find correct customLLDBInitFile in $action for the Scheme in ${schemeFile.path}.',
      );
    }
  }
}

class SchemeInfo {
  SchemeInfo({required this.schemeName, required this.schemeFile, required this.schemeContent});

  final String schemeName;
  final File schemeFile;
  final String schemeContent;
}
