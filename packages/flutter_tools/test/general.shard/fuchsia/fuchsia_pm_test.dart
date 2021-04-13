// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_pm.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group('FuchsiaPM', () {
    File pm;
    MockProcessManager mockProcessManager;
    MockFuchsiaArtifacts mockFuchsiaArtifacts;

    setUp(() {
      pm = MemoryFileSystem.test().file('pm');

      mockFuchsiaArtifacts = MockFuchsiaArtifacts();
      when(mockFuchsiaArtifacts.pm).thenReturn(pm);

      mockProcessManager = MockProcessManager();
    });

    testUsingContext('serve - IPv4 address', () async {
      when(mockProcessManager.start(any)).thenAnswer((_) {
        return Future<Process>.value(createMockProcess());
      });

      await FuchsiaPM().serve('<repo>', '127.0.0.1', 43819);

      verify(mockProcessManager.start(<String>[
        'pm',
        'serve',
        '-repo',
        '<repo>',
        '-l',
        '127.0.0.1:43819',
      ])).called(1);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => mockFuchsiaArtifacts,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('serve - IPv6 address', () async {
      when(mockProcessManager.start(any)).thenAnswer((_) {
        return Future<Process>.value(createMockProcess());
      });

      await FuchsiaPM().serve('<repo>', 'fe80::ec4:7aff:fecc:ea8f%eno2', 43819);

      verify(mockProcessManager.start(<String>[
        'pm',
        'serve',
        '-repo',
        '<repo>',
        '-l',
        '[fe80::ec4:7aff:fecc:ea8f%eno2]:43819',
      ])).called(1);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => mockFuchsiaArtifacts,
      ProcessManager: () => mockProcessManager,
    });
  });
}

class MockFuchsiaArtifacts extends Mock implements FuchsiaArtifacts {}
class MockProcessManager extends Mock implements ProcessManager {}
