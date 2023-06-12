// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:connectivity_for_web/src/network_information_api_connectivity_plugin.dart';
import 'package:connectivity_platform_interface/connectivity_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'src/connectivity_mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('checkConnectivity', () {
    void testCheckConnectivity({
      String? type,
      String? effectiveType,
      num? downlink = 10,
      int? rtt = 50,
      required ConnectivityResult expected,
    }) {
      final connection = FakeNetworkInformation(
        type: type,
        effectiveType: effectiveType,
        downlink: downlink,
        rtt: rtt,
      );

      NetworkInformationApiConnectivityPlugin plugin =
          NetworkInformationApiConnectivityPlugin.withConnection(connection);
      expect(plugin.checkConnectivity(), completion(equals(expected)));
    }

    testWidgets('0 downlink and rtt -> none', (WidgetTester tester) async {
      testCheckConnectivity(
          effectiveType: '4g',
          downlink: 0,
          rtt: 0,
          expected: ConnectivityResult.none);
    });
    testWidgets('slow-2g -> mobile', (WidgetTester tester) async {
      testCheckConnectivity(
          effectiveType: 'slow-2g', expected: ConnectivityResult.mobile);
    });
    testWidgets('2g -> mobile', (WidgetTester tester) async {
      testCheckConnectivity(
          effectiveType: '2g', expected: ConnectivityResult.mobile);
    });
    testWidgets('3g -> mobile', (WidgetTester tester) async {
      testCheckConnectivity(
          effectiveType: '3g', expected: ConnectivityResult.mobile);
    });
    testWidgets('4g -> wifi', (WidgetTester tester) async {
      testCheckConnectivity(
          effectiveType: '4g', expected: ConnectivityResult.wifi);
    });
  });

  group('get onConnectivityChanged', () {
    testWidgets('puts change events in a Stream', (WidgetTester tester) async {
      final connection = FakeNetworkInformation();
      NetworkInformationApiConnectivityPlugin plugin =
          NetworkInformationApiConnectivityPlugin.withConnection(connection);

      // The onConnectivityChanged stream is infinite, so we only .take(2) so the test completes.
      // We need to do .toList() now, because otherwise the Stream won't be actually listened to,
      // and we'll miss the calls to mockChangeValue below.
      final results = plugin.onConnectivityChanged.take(2).toList();

      // Fake a disconnect-reconnect
      await connection.mockChangeValue(downlink: 0, rtt: 0);
      await connection.mockChangeValue(
          downlink: 10, rtt: 50, effectiveType: '4g');

      // Expect to see the disconnect-reconnect in the resulting stream.
      expect(
        results,
        completion([ConnectivityResult.none, ConnectivityResult.wifi]),
      );
    });
  });
}
