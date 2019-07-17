// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/reporting/usage.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  MockFlutterVersion mockFlutterVersion;
  MockFlutterConfig mockFlutterConfig;

  setUp(() {
    mockFlutterVersion = MockFlutterVersion();
    mockFlutterConfig = MockFlutterConfig();
    when(mockFlutterVersion.getVersionString(redactUnknownBranches: true))
        .thenReturn('v1.2.3');
    when(mockFlutterVersion.getBranchName(redactUnknownBranches: true))
        .thenReturn('dev');
    testbed = Testbed(
      overrides: <Type, Generator>{
        FlutterVersion: () => mockFlutterVersion,
        Config: () => mockFlutterConfig,
    });
  });

  test('Usage records one feature in experiment setting', () => testbed.run(() async {
    when<bool>(mockFlutterConfig.getValue(flutterWebFeature.configSetting))
        .thenReturn(true);
    final Usage usage = Usage();

    usage.suppressAnalytics = false;
    final Future<Map<String, dynamic>> data = usage.onSend.first;
    usage.sendCommand('test');

    expect(await data, containsPair(enabledFlutterFeatures, 'enable-web'));
  }));

  test('Usage records multiple features in experiment setting', () => testbed.run(() async {
    when<bool>(mockFlutterConfig.getValue(flutterWebFeature.configSetting))
        .thenReturn(true);
    when<bool>(mockFlutterConfig.getValue(flutterLinuxDesktopFeature.configSetting))
        .thenReturn(true);
    when<bool>(mockFlutterConfig.getValue(flutterMacOSDesktopFeature.configSetting))
        .thenReturn(true);
    final Usage usage = Usage();

    usage.suppressAnalytics = false;
    final Future<Map<String, dynamic>> data = usage.onSend.first;
    usage.sendCommand('test');

    expect(await data, containsPair(enabledFlutterFeatures, 'enable-web,enable-linux-desktop,enable-macos-desktop'));
  }));
}

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockFlutterConfig extends Mock implements Config {}
