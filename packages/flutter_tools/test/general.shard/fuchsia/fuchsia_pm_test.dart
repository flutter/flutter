// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_pm.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';

void main() {
  group('FuchsiaPM', () {
    File pm;
    FakeProcessManager fakeProcessManager;
    FakeFuchsiaArtifacts fakeFuchsiaArtifacts;

    setUp(() {
      pm = MemoryFileSystem.test().file('pm');

      fakeFuchsiaArtifacts = FakeFuchsiaArtifacts(pm);
      fakeProcessManager = FakeProcessManager.empty();
    });

    testUsingContext('serve - IPv4 address', () async {
      fakeProcessManager.addCommand(const FakeCommand(command: <String>[
        'pm',
        'serve',
        '-repo',
        '<repo>',
        '-l',
        '127.0.0.1:43819',
        '-c',
        '2',
      ]));

      await FuchsiaPM().serve('<repo>', '127.0.0.1', 43819);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => fakeFuchsiaArtifacts,
      ProcessManager: () => fakeProcessManager,
    });

    testUsingContext('serve - IPv6 address', () async {
      fakeProcessManager.addCommand(const FakeCommand(command: <String>[
        'pm',
        'serve',
        '-repo',
        '<repo>',
        '-l',
        '[fe80::ec4:7aff:fecc:ea8f%eno2]:43819',
        '-c',
        '2'
      ]));

      await FuchsiaPM().serve('<repo>', 'fe80::ec4:7aff:fecc:ea8f%eno2', 43819);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => fakeFuchsiaArtifacts,
      ProcessManager: () => fakeProcessManager,
    });
  });
}

class FakeFuchsiaArtifacts extends Fake implements FuchsiaArtifacts {
  FakeFuchsiaArtifacts(this.pm);

  @override
  final File pm;
}
