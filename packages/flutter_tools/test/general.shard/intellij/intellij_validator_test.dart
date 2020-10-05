// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:archive/archive.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/intellij/intellij_validator.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

final Platform macPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{'HOME': '/foo/bar'}
);

void main() {
  testWithoutContext('Intellij validator can parse plugin manifest from plugin JAR', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    // Create plugin JAR file for Flutter and Dart plugin.
    final List<int> flutterPluginBytes = utf8.encode(kIntellijFlutterPluginXml);
    final Archive flutterPlugins = Archive();
    flutterPlugins.addFile(ArchiveFile('META-INF/plugin.xml', flutterPluginBytes.length, flutterPluginBytes));
    fileSystem.file('plugins/flutter-intellij.jar')
      ..createSync(recursive: true)
      ..writeAsBytesSync(ZipEncoder().encode(flutterPlugins));
    final List<int> dartPluginBytes = utf8.encode(kIntellijDartPluginXml);
    final Archive dartPlugins = Archive();
    dartPlugins.addFile(ArchiveFile('META-INF/plugin.xml', dartPluginBytes.length, dartPluginBytes));
    fileSystem.file('plugins/Dart/lib/Dart.jar')
      ..createSync(recursive: true)
      ..writeAsBytesSync(ZipEncoder().encode(dartPlugins));

    final ValidationResult result = await IntelliJValidatorTestTarget('', 'path/to/intellij', fileSystem).validate();
    expect(result.type, ValidationType.partial);
    expect(result.statusInfo, 'version test.test.test');
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('IntelliJ at path/to/intellij'),
      ValidationMessage.error('Flutter plugin version 0.1.3 - the recommended minimum version is 16.0.0'),
      ValidationMessage('Dart plugin version 162.2485'),
      ValidationMessage('For information about installing plugins, see\n'
          'https://flutter.dev/intellij-setup/#installing-the-plugins')
    ]);
  });

  testWithoutContext('Intellij plugins path checking on mac', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Directory pluginsDirectory = fileSystem.directory('/foo/bar/Library/Application Support/JetBrains/TestID2020.10/plugins')
      ..createSync(recursive: true);
    final IntelliJValidatorOnMac validator = IntelliJValidatorOnMac(
      'Test',
      'TestID',
      '/path/to/app',
      fileSystem: fileSystem,
      homeDirPath: '/foo/bar',
      userMessages: UserMessages(),
      plistParser: FakePlistParser(<String, String>{
        PlistParser.kCFBundleShortVersionStringKey: '2020.10',
      })
    );

    expect(validator.plistFile, '/path/to/app/Contents/Info.plist');
    expect(validator.pluginsPath, pluginsDirectory.path);
  });

  testWithoutContext('legacy Intellij plugins path checking on mac', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final IntelliJValidatorOnMac validator = IntelliJValidatorOnMac(
      'Test',
      'TestID',
      '/foo',
      fileSystem: fileSystem,
      homeDirPath: '/foo/bar',
      userMessages: UserMessages(),
      plistParser: FakePlistParser(<String, String>{
        PlistParser.kCFBundleShortVersionStringKey: '2020.10',
      })
    );

    expect(validator.pluginsPath, '/foo/bar/Library/Application Support/TestID2020.10');
  });

  testWithoutContext('Intellij plugins path checking on mac with JetBrains toolbox override', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final IntelliJValidatorOnMac validator = IntelliJValidatorOnMac(
      'Test',
      'TestID',
      '/foo',
      fileSystem: fileSystem,
      homeDirPath: '/foo/bar',
      userMessages: UserMessages(),
      plistParser: FakePlistParser(<String, String>{
        'JetBrainsToolboxApp': '/path/to/JetBrainsToolboxApp',
      })
    );

    expect(validator.pluginsPath, '/path/to/JetBrainsToolboxApp.plugins');
  });
}

class FakePlistParser extends Fake implements PlistParser {
  FakePlistParser(this.values);

  final Map<String, String> values;

  @override
  String getValueFromFile(String plistFilePath, String key) {
    return values[key];
  }
}

class IntelliJValidatorTestTarget extends IntelliJValidator {
  IntelliJValidatorTestTarget(String title, String installPath,  FileSystem fileSystem)
    : super(title, installPath, fileSystem: fileSystem, userMessages: UserMessages());

  @override
  String get pluginsPath => 'plugins';

  @override
  String get version => 'test.test.test';
}


/// These file contents were derived from the META-INF/plugin.xml from an Intellij Flutter
/// plugin installation.
///
/// The file is loacted in a plugin JAR, which can be located by looking at the plugin
/// path for the Intellij and Android Studio validators.
///
/// If more XML contents are needed, prefer modifying these contents over checking
/// in another JAR.
const String kIntellijFlutterPluginXml = r'''
<idea-plugin version="2">
  <id>io.flutter</id>
  <name>Flutter</name>
  <description>Support for developing Flutter applications.</description>
  <vendor url="https://github.com/flutter/flutter-intellij">flutter.io</vendor>

  <category>Custom Languages</category>

  <version>0.1.3</version>

  <idea-version since-build="162.1" until-build="163.*"/>
</idea-plugin>

<idea-plugin version="2">
  <name>Dart</name>
  <version>162.2485</version>
  <idea-version since-build="162.1121" until-build="162.*"/>

  <description>Support for Dart programming language</description>
  <vendor>JetBrains</vendor>
  <depends>com.intellij.modules.xml</depends>
  <depends optional="true" config-file="dartium-debugger-support.xml">JavaScriptDebugger</depends>
  <depends optional="true" config-file="dart-yaml.xml">org.jetbrains.plugins.yaml</depends>
  <depends optional="true" config-file="dart-copyright.xml">com.intellij.copyright</depends>
  <depends optional="true" config-file="dart-coverage.xml">com.intellij.modules.coverage</depends>
</idea-plugin>
''';

/// These file contents were derived from the META-INF/plugin.xml from an Intellij Dart
/// plugin installation.
///
/// The file is loacted in a plugin JAR, which can be located by looking at the plugin
/// path for the Intellij and Android Studio validators.
///
/// If more XML contents are needed, prefer modifying these contents over checking
/// in another JAR.
const String kIntellijDartPluginXml = r'''
<idea-plugin version="2">
  <name>Dart</name>
  <version>162.2485</version>
  <idea-version since-build="162.1121" until-build="162.*"/>

  <description>Support for Dart programming language</description>
  <vendor>JetBrains</vendor>
  <depends>com.intellij.modules.xml</depends>
  <depends optional="true" config-file="dartium-debugger-support.xml">JavaScriptDebugger</depends>
  <depends optional="true" config-file="dart-yaml.xml">org.jetbrains.plugins.yaml</depends>
  <depends optional="true" config-file="dart-copyright.xml">com.intellij.copyright</depends>
  <depends optional="true" config-file="dart-coverage.xml">com.intellij.modules.coverage</depends>
</idea-plugin>
''';
