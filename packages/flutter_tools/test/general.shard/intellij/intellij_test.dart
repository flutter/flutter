// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/intellij/intellij.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const String dartPluginContents = '''<idea-plugin version="2">
<name>Dart</name>
<version>162.2485</version>
</idea-plugin>

''';
const String flutterPluginContents = r'''
<idea-plugin version="2">
<name>Flutter</name>
<version>0.1.3</version>
</idea-plugin>
''';

void main() {
  testUsingContext('IntelliJ plugins found', () async {
    fs.directory(fs.path.join(_kPluginsPath, 'Dart'))
      .createSync(recursive: true);
    fs.file(fs.path.join(_kPluginsPath, 'flutter-intellij.jar'))
      .createSync(recursive: true);

    when(os.unzip(any, any)).thenAnswer((Invocation invocation) {
      final File file = invocation.positionalArguments.first as File;
      final Directory destination = invocation.positionalArguments.last as Directory;
      destination
        .childDirectory('META-INF')
        .childFile('plugin.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(file.path.contains('Dart')
          ? dartPluginContents
          : flutterPluginContents);
    });

    final IntelliJPlugins plugins = IntelliJPlugins(_kPluginsPath);

    final List<ValidationMessage> messages = <ValidationMessage>[];
    plugins.validatePackage(messages, <String>['Dart'], 'Dart');
    plugins.validatePackage(messages,
        <String>['flutter-intellij', 'flutter-intellij.jar'], 'Flutter',
        minVersion: IntelliJPlugins.kMinFlutterPluginVersion);

    ValidationMessage message = messages
        .firstWhere((ValidationMessage m) => m.message.startsWith('Dart '));

    expect(message.message, 'Dart plugin version 162.2485');
    message = messages.firstWhere(
        (ValidationMessage m) => m.message.startsWith('Flutter '));

    expect(message.message, contains('Flutter plugin version 0.1.3'));
    expect(message.message, contains('recommended minimum version'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
    OperatingSystemUtils: () => MockOperatingSystemUtils(),
  });

  testUsingContext('IntelliJ plugins not found', () async {
    final IntelliJPlugins plugins = IntelliJPlugins(_kPluginsPath);
    final List<ValidationMessage> messages = <ValidationMessage>[];
    plugins.validatePackage(messages, <String>['Dart'], 'Dart');
    plugins.validatePackage(messages,
        <String>['flutter-intellij', 'flutter-intellij.jar'], 'Flutter',
        minVersion: IntelliJPlugins.kMinFlutterPluginVersion);

    ValidationMessage message = messages
        .firstWhere((ValidationMessage m) => m.message.startsWith('Dart '));

    expect(message.message, contains('Dart plugin not installed'));

    message = messages.firstWhere(
        (ValidationMessage m) => m.message.startsWith('Flutter '));

    expect(message.message, contains('Flutter plugin not installed'));
  }, overrides: <Type, Generator>{
    OperatingSystemUtils: () => MockOperatingSystemUtils(),
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

const String _kPluginsPath = '/data/intellij/plugins';
