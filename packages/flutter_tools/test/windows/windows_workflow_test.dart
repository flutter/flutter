// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/windows/windows_workflow.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(WindowsWorkflow, () {
    final MockPlatform windows = MockPlatform();
    final MockPlatform notWindows = MockPlatform();
    when(windows.isWindows).thenReturn(true);
    when(notWindows.isWindows).thenReturn(false);

    testUsingContext('Applies to windows platform', () {
      expect(windowsWorkflow.appliesToHostPlatform, true);
    }, overrides: <Type, Generator>{
      Platform: () => windows,
    });
    testUsingContext('Does not apply to non-windows platform', () {
      expect(windowsWorkflow.appliesToHostPlatform, false);
    }, overrides: <Type, Generator>{
      Platform: () => notWindows,
    });

    final MockFileSystem fileSystem = MockFileSystem();
    final MockDirectory directory = MockDirectory();
    Cache.flutterRoot = '';
    when(fileSystem.directory(Cache.flutterRoot)).thenReturn(directory);
    when(directory.parent).thenReturn(directory);
    when(directory.childDirectory('flutter-desktop-embedding')).thenReturn(directory);
    when(directory.existsSync()).thenReturn(true);

    testUsingContext('defaults', () {
      expect(windowsWorkflow.canListEmulators, false);
      expect(windowsWorkflow.canLaunchDevices, true);
      expect(windowsWorkflow.canListDevices, true);
    }, overrides: <Type, Generator>{
      Platform: () => windows,
      FileSystem: () => fileSystem,
    });
  });
}

class MockFileSystem extends Mock implements FileSystem {}

class MockDirectory extends Mock implements Directory {}

class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> get environment => const <String, String>{};
}
