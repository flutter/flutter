// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/linux/linux_workflow.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(LinuxWorkflow, () {
    final MockPlatform linux = MockPlatform();
    final MockPlatform notLinux = MockPlatform();
    when(linux.isLinux).thenReturn(true);
    when(notLinux.isLinux).thenReturn(false);

    testUsingContext('Applies to linux platform', () {
      expect(linuxWorkflow.appliesToHostPlatform, true);
    }, overrides: <Type, Generator>{
      Platform: () => linux,
    });
    testUsingContext('Does not apply to non-linux platform', () {
      expect(linuxWorkflow.appliesToHostPlatform, false);
    }, overrides: <Type, Generator>{
      Platform: () => notLinux,
    });

    final MockFileSystem fileSystem = MockFileSystem();
    final MockDirectory directory = MockDirectory();
    Cache.flutterRoot = '';
    when(fileSystem.directory(Cache.flutterRoot)).thenReturn(directory);
    when(directory.parent).thenReturn(directory);
    when(directory.childDirectory('flutter-desktop-embedding')).thenReturn(directory);
    when(directory.existsSync()).thenReturn(true);

    testUsingContext('defaults', () {
      expect(linuxWorkflow.canListEmulators, false);
      expect(linuxWorkflow.canLaunchDevices, true);
      expect(linuxWorkflow.canListDevices, true);
    }, overrides: <Type, Generator>{
      Platform: () => linux,
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
