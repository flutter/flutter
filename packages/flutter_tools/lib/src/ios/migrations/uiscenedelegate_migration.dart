// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart' show visibleForTesting;
import 'package:xml/xml.dart';

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../xcode_project.dart';

const String _manifestKey = 'UIApplicationSceneManifest';
const String _storyboardKey = 'UIMainStoryboardFile';

String _addition(String storyboard) => '''
<key>UIApplicationSceneManifest</key>
<dict>
  <key>UIApplicationSupportsMultipleScenes</key>
  <false/>
  <key>UISceneConfigurations</key>
  <dict>
    <key>UIWindowSceneSessionRoleApplication</key>
    <array>
      <dict>
        <key>UISceneClassName</key>
        <string>UIWindowScene</string>
        <key>UISceneDelegateClassName</key>
        <string>FlutterSceneDelegate</string>
        <key>UISceneConfigurationName</key>
        <string>flutter</string>
        <key>UISceneStoryboardFile</key>
        <string>$storyboard</string>
      </dict>
    </array>
  </dict>
</dict>
''';

/// Update Info.plist.
class UISceneDelegateMigration extends ProjectMigrator {
  UISceneDelegateMigration(IosProject project, super.logger)
    : _infoPlist = project.defaultHostInfoPlist;

  final File _infoPlist;

  @override
  Future<void> migrate() async {
    if (!_infoPlist.existsSync()) {
      logger.printTrace('Info.plist not found, skipping host app Info.plist migration.');
      return;
    }

    processFileLines(_infoPlist);
  }

  @visibleForTesting
  static Map<String, XmlElement> extractPlistDict(XmlElement dict) {
    final Map<String, XmlElement> keyValues = <String, XmlElement>{};
    String? key;
    for (final XmlElement child in dict.childElements) {
      if (key != null) {
        keyValues[key] = child;
        key = null;
      } else {
        key = child.innerText;
      }
    }
    return keyValues;
  }

  @override
  String migrateFileContents(String fileContents) {
    try {
      final XmlDocument read = XmlDocument.parse(fileContents);
      final XmlElement readPlist = read.childElements.first;
      final XmlElement readDict = readPlist.childElements.first;
      final Map<String, XmlElement> keyValues = extractPlistDict(readDict);

      if (!keyValues.containsKey(_manifestKey)) {
        if (keyValues.containsKey(_storyboardKey)) {
          final String storyboard = keyValues[_storyboardKey]!.innerText;
          final String xmlAddition = _addition(storyboard);
          final XmlDocumentFragment fragment = XmlDocumentFragment.parse(xmlAddition);
          for (final XmlNode node in fragment.children) {
            readDict.children.add(node.copy());
          }
        }
      }
      return '${read.toXmlString(pretty: true)}\n';
    } on Exception catch (_) {
      return fileContents;
    }
  }
}
