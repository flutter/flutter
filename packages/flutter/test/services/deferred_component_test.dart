// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('installDeferredComponent test', () async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.deferredComponent.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await DeferredComponent.installDeferredComponent(moduleName: 'testModuleName');

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'installDeferredComponent',
      arguments: <String, dynamic>{'loadingUnitId': -1, 'moduleName': 'testModuleName'},
    ));
  });

  test('uninstallDeferredComponent test', () async {
    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.deferredComponent.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await DeferredComponent.uninstallDeferredComponent(moduleName: 'testModuleName');

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
      'uninstallDeferredComponent',
      arguments: <String, dynamic>{'loadingUnitId': -1, 'moduleName': 'testModuleName'},
    ));
  });
}
