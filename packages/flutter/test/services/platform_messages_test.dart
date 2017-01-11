// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:test/test.dart';

void main() {
  test('Mock string message handler control test', () async {
    List<String> log = <String>[];

    PlatformMessages.setMockStringMessageHandler('test1', (String message) async {
      log.add(message);
    });

    await PlatformMessages.sendString('test1', 'hello');
    expect(log, equals(<String>['hello']));
    log.clear();

    PlatformMessages.setMockStringMessageHandler('test1', null);
    await PlatformMessages.sendString('test1', 'fail');
    expect(log, isEmpty);
  });

  test('Mock JSON message handler control test', () async {
    List<dynamic> log = <dynamic>[];

    PlatformMessages.setMockJSONMessageHandler('test2', (dynamic message) async {
      log.add(message);
    });

    await PlatformMessages.sendString('test2', '{"hello": "world"}');
    expect(log, equals(<Map<String, String>>[<String, String>{'hello': 'world'}]));
    log.clear();

    PlatformMessages.setMockStringMessageHandler('test2', null);
    await PlatformMessages.sendString('test2', '{"fail": "message"}');
    expect(log, isEmpty);
  });
}
