// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import '../lib/fuchsia_remote_debug_protocol.dart';

void main() {
  group('FuchsiaRemoteConnection.connect', () {
    MockDartVm mockVmService;
    MockSshCommandRunner mockRunner;

    setUp(() {
      mockRunner = new MockSshCommandRunner();
      mockVmService = new MockDartVm();
      // TODO(awdavies): Set things up!
    });

    tearDown(() {
      // TODO(awdavies): Tear things down!
    });

    test('connects or whatever without ssh config path', () async {
      when(mockRunner.run(any)).thenReturn(['wahoo']);
      final FuchsiaRemoteConnection connection =
          await FuchsiaRemoteConnection.connect('whatever');
    });
  });
}

class MockDartVm extends Mock implements DartVm {}

class MockSshCommandRunner extends Mock implements SshCommandRunner {}
