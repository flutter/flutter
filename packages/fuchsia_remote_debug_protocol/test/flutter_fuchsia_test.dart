// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';

import '../lib/flutter_fuchsia.dart';

void main() {
  group('FlutterFuchsiaDriver.connect', () {
    MockFuchsiaDartVm mockVmService;

    setUp(() {
      mockRunner = MockFuchsiaDeviceCommandRunner();
      // TODO(awdavies): Set things up!
    });

    tearDown(() {
      // TODO(awdavies): Tear things down!
    });
  });
}

class MockFuchsiaDartVm extends Mock implements FuchsiaDartVm {}

class MockFuchsiaDeviceCommandRunner extends Mock
    implements FuchsiaDeviceCommandRunner {}
