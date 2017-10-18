// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:test/test.dart';

void main() {
  test('Semantic announcement', () async {
    final List<Map<String, dynamic>> log = <Map<String, dynamic>>[];

    SystemChannels.accessibility.setMockMessageHandler((Map<String, dynamic> message) async {
      log.add(message);
    });

    await SemanticsService.announce('announcement 1');
    await SemanticsService.announce('announcement 2');

    expect(log, equals(<Map<String, dynamic>>[
      {'type': 'announce', 'data': {'message': 'announcement 1'}},
      {'type': 'announce', 'data': {'message': 'announcement 2'}},
    ]));
  });
}
