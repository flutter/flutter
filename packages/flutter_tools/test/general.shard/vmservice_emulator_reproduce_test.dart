// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';

void main() {
  testWithoutContext('VM Service registers device emulator detection service', () async {
    final mockDevice = FakeDevice();
    final mockVMService = FakeVMService();

    await setUpVmService(device: mockDevice, vmService: mockVMService);

    // This service is expected to be registered to allow DevTools / clients to detect
    // whether the current device is an emulator or physical device.
    expect(
      mockVMService.services,
      containsPair('flutterDeviceInfo', 'Flutter Tools'),
      reason: 'The VM service must register "flutterDeviceInfo" to expose emulator information',
    );
  });

  testWithoutContext(
    'VM Service does not register device emulator detection service if device is null',
    () async {
      final mockVMService = FakeVMService();

      await setUpVmService(vmService: mockVMService);

      expect(
        mockVMService.services.containsKey('flutterDeviceInfo'),
        isFalse,
        reason: 'The VM service must not register "flutterDeviceInfo" if device is null',
      );
    },
  );

  testWithoutContext(
    'VM Service device emulator detection service returns emulator=true',
    () async {
      final mockDevice = FakeDevice(isEmulator: true);
      final mockVMService = FakeVMService();

      await setUpVmService(device: mockDevice, vmService: mockVMService);

      final vm_service.ServiceCallback? callback =
          mockVMService.serviceCallBacks['flutterDeviceInfo'];
      expect(callback, isNotNull);

      final Map<String, Object?> result = await callback!(<String, Object?>{});
      expect(result, <String, Object?>{
        'result': <String, Object?>{'type': 'Success', 'emulator': true},
      });
    },
  );

  testWithoutContext(
    'VM Service device emulator detection service returns emulator=false',
    () async {
      final mockDevice = FakeDevice();
      final mockVMService = FakeVMService();

      await setUpVmService(device: mockDevice, vmService: mockVMService);

      final vm_service.ServiceCallback? callback =
          mockVMService.serviceCallBacks['flutterDeviceInfo'];
      expect(callback, isNotNull);

      final Map<String, Object?> result = await callback!(<String, Object?>{});
      expect(result, <String, Object?>{
        'result': <String, Object?>{'type': 'Success', 'emulator': false},
      });
    },
  );
}

class FakeVMService extends Fake implements vm_service.VmService {
  final services = <String, String>{};
  final serviceCallBacks = <String, vm_service.ServiceCallback>{};

  @override
  void registerServiceCallback(String service, vm_service.ServiceCallback cb) {
    serviceCallBacks[service] = cb;
  }

  @override
  Future<vm_service.Success> registerService(String service, String alias) async {
    services[service] = alias;
    return vm_service.Success();
  }
}

class FakeDevice extends Fake implements Device {
  FakeDevice({this.isEmulator = false});

  final bool isEmulator;

  @override
  Future<bool> get isLocalEmulator async => isEmulator;
}
