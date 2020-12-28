// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('installDynamicFeature test', () async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.dynamicFeature.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await DynamicFeature.installDynamicFeature(moduleName: 'testModuleName');

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'installDynamicFeature',
      arguments: <String, dynamic>{'loadingUnitId': -1, 'moduleName': 'testModuleName'},
    ));
  });

  test('getDynamicFeatureInstallState test', () async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.dynamicFeature.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await DynamicFeature.getDynamicFeatureInstallState(moduleName: 'testModuleName');

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'getDynamicFeatureInstallState',
      arguments: <String, dynamic>{'loadingUnitId': -1, 'moduleName': 'testModuleName'},
    ));
  });

  test('uninstallDynamicFeature test', () async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.dynamicFeature.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await DynamicFeature.uninstallDynamicFeature(moduleName: 'testModuleName');

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'uninstallDynamicFeature',
      arguments: <String, dynamic>{'loadingUnitId': -1, 'moduleName': 'testModuleName'},
    ));
  });
}