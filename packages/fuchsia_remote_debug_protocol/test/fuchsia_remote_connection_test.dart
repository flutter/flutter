// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'package:fuchsia_remote_debug_protocol/fuchsia_remote_debug_protocol.dart';

void main() {
  group('FuchsiaRemoteConnection.connect', () {
    MockDartVm mockVmService;
    MockSshCommandRunner mockRunner;

    setUp(() {
      mockRunner = new MockSshCommandRunner();
      mockVmService = new MockDartVm();
    });

    tearDown(() {
      /// Most functions will mock out the port forwarding and connection
      /// functions.
      restoreFuchsiaPortForwardingFunction();
      restoreVmServiceConnectionFunction();
    });

    test('???', () async {});
  });
}

class MockDartVm extends Mock implements DartVm {}

class MockSshCommandRunner extends Mock implements SshCommandRunner {}

class MockPortForwarder extends Mock implements PortForwarder {}

class MockPeer extends Mock implements json_rpc.Peer {}
