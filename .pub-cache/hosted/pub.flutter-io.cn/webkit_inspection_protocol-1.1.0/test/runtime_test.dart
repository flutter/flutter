// Copyright 2020 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library wip.runtime_test;

import 'dart:async';

import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'test_setup.dart';

void main() {
  group('WipRuntime', () {
    WipRuntime? runtime;
    List<StreamSubscription> subs = [];

    setUp(() async {
      runtime = (await wipConnection).runtime;
    });

    tearDown(() async {
      await runtime?.disable();
      runtime = null;

      await closeConnection();
      for (var s in subs) {
        s.cancel();
      }
      subs.clear();
    });

    test('getIsolateId', () async {
      await runtime!.enable();
      await navigateToPage('runtime_test.html');

      expect(await runtime!.getIsolateId(), isNotEmpty);
    });

    test('getHeapUsage', () async {
      await runtime!.enable();
      await navigateToPage('runtime_test.html');

      HeapUsage usage = await runtime!.getHeapUsage();

      expect(usage.usedSize, greaterThan(0));
      expect(usage.totalSize, greaterThan(0));
    });

    test('evaluate', () async {
      await runtime!.enable();
      await navigateToPage('runtime_test.html');

      RemoteObject result = await runtime!.evaluate('1+1');
      expect(result.type, 'number');
      expect(result.value, 2);
    });

    test('callFunctionOn', () async {
      await runtime!.enable();
      await navigateToPage('runtime_test.html');

      RemoteObject console = await runtime!.evaluate('console');
      RemoteObject result = await runtime!.callFunctionOn(
        '''
        function(msg) {
          console.log(msg);
          return msg;
        }''',
        objectId: console.objectId,
        arguments: [
          'foo',
        ],
      );

      expect(result.type, 'string');
      expect(result.value, 'foo');
    });

    test('getProperties', () async {
      await runtime!.enable();
      await navigateToPage('runtime_test.html');

      RemoteObject console = await runtime!.evaluate('console');

      List<PropertyDescriptor> properties = await runtime!.getProperties(
        console,
        ownProperties: true,
      );

      expect(properties, isNotEmpty);

      PropertyDescriptor property = properties.first;
      expect(property.name, isNotEmpty);
    });
  });
}
