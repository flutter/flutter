// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('AndroidPlugin', () {
    MockFileSystem mockFileSystem;
    MockPathContext pathContext;

    setUp(() {
      pathContext = MockPathContext();
      when(pathContext.separator).thenReturn('/');

      mockFileSystem = MockFileSystem();
      when(mockFileSystem.path).thenReturn(pathContext);
    });

    testUsingContext("throws tool exit if the plugin main class can't be read", () {
      when(pathContext.join('.pub_cache/plugin_a', 'android', 'src', 'main'))
        .thenReturn('.pub_cache/plugin_a/android/src/main');

      when(pathContext.join('.pub_cache/plugin_a/android/src/main', 'java', 'com/company', 'PluginA.java'))
        .thenReturn('.pub_cache/plugin_a/android/src/main/java/com/company/PluginA.java');

      when(pathContext.join('.pub_cache/plugin_a/android/src/main', 'kotlin', 'com/company', 'PluginA.kt'))
        .thenReturn('.pub_cache/plugin_a/android/src/main/kotlin/com/company/PluginA.kt');

      final MockFile pluginJavaMainClass = MockFile();
      when(pluginJavaMainClass.existsSync()).thenReturn(true);
      when(pluginJavaMainClass.readAsStringSync(encoding: anyNamed('encoding'))).thenThrow(const FileSystemException());
      when(mockFileSystem.file('.pub_cache/plugin_a/android/src/main/java/com/company/PluginA.java'))
        .thenReturn(pluginJavaMainClass);

      final MockFile pluginKotlinMainClass = MockFile();
      when(pluginKotlinMainClass.existsSync()).thenReturn(false);
      when(mockFileSystem.file('.pub_cache/plugin_a/android/src/main/kotlin/com/company/PluginA.kt'))
        .thenReturn(pluginKotlinMainClass);

      expect(() {
        AndroidPlugin(
          name: 'pluginA',
          package: 'com.company',
          pluginClass: 'PluginA',
          pluginPath: '.pub_cache/plugin_a',
        ).toMap();
      }, throwsToolExit(
        message: "Couldn't read file null even though it exists. "
                 'Please verify that this file has read permission and try again.'
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class MockFile extends Mock implements File {}
class MockFileSystem extends Mock implements FileSystem {}
class MockPathContext extends Mock implements p.Context {}
