// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:connectivity/connectivity.dart';
import 'package:connectivity_platform_interface/connectivity_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:test/fake.dart';

const ConnectivityResult kCheckConnectivityResult = ConnectivityResult.wifi;
const LocationAuthorizationStatus kRequestLocationResult =
    LocationAuthorizationStatus.authorizedAlways;
const LocationAuthorizationStatus kGetLocationResult =
    LocationAuthorizationStatus.authorizedAlways;

void main() {
  group('Connectivity', () {
    late Connectivity connectivity;
    late MockConnectivityPlatform fakePlatform;
    setUp(() async {
      fakePlatform = MockConnectivityPlatform();
      ConnectivityPlatform.instance = fakePlatform;
      connectivity = Connectivity();
    });

    test('checkConnectivity', () async {
      ConnectivityResult result = await connectivity.checkConnectivity();
      expect(result, kCheckConnectivityResult);
    });
  });
}

class MockConnectivityPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {
  Future<ConnectivityResult> checkConnectivity() async {
    return kCheckConnectivityResult;
  }
}
