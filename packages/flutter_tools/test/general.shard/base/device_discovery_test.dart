
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';

void main() {
  test('PollingDeviceDiscovery sends notifications as devices are discovered', () async {
    final FakeDeviceDiscovery discovery = FakeDeviceDiscovery();
    final Device deviceA = MockDevice('a');
    final Device deviceB = MockDevice('b');
    final Device deviceC = MockDevice('c');
    final Future<void> onAdded = expectLater(discovery.onAdded, emitsInOrder(<Device>[
      deviceA,
      deviceB,
      deviceC,
    ]));
    final Future<void> onRemoved = expectLater(discovery.onRemoved, emitsInOrder(<Device>[
      deviceB,
    ]));

    discovery.devicesToBeDiscovered = <Device>[
      deviceA,
      deviceB,
    ];
    await discovery.poll();

    discovery.devicesToBeDiscovered = <Device>[
      deviceA,
      deviceC,
    ];
    await discovery.poll();

    discovery.dispose();
    await onAdded;
    await onRemoved;
  });
}

class FakeDeviceDiscovery extends PollingDeviceDiscovery {
  FakeDeviceDiscovery() : super('fake');

  List<Device> devicesToBeDiscovered = <Device>[];

  @override
  bool get canListAnything => throw UnimplementedError();

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    return devicesToBeDiscovered;
  }

  @override
  bool get supportsPlatform => throw UnimplementedError();
}

class MockDevice extends Mock implements Device {
  MockDevice(this.id);

  @override
  final String id;
}
