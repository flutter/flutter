// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show TextDirection;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;

import '../flutter_test_alternative.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Semantic announcement', () async {
    final List<Map<dynamic, dynamic>> log = <Map<dynamic, dynamic>>[];

    SystemChannels.accessibility.setMockMessageHandler((Object mockMessage) async {
      final Map<dynamic, dynamic> message = mockMessage as Map<dynamic, dynamic>;
      log.add(message);
    });

    await SemanticsService.announce('announcement 1', TextDirection.ltr);
    await SemanticsService.announce('announcement 2', TextDirection.rtl);

    expect(log, equals(<Map<String, dynamic>>[
      <String, dynamic>{'type': 'announce', 'data': <String, dynamic>{'message': 'announcement 1', 'textDirection': 1}},
      <String, dynamic>{'type': 'announce', 'data': <String, dynamic>{'message': 'announcement 2', 'textDirection': 0}},
    ]));
  });
}
