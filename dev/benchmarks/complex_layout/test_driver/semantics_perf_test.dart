// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_driver/flutter_self_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:complex_layout/main.dart' as app;

Future<void> main() async {
  final FlutterSelfDriver driver = await FlutterSelfDriver.connect();
  app.main();
  group('semantics performance test', () {
    setUpAll(() async {
    });

    tearDownAll(() async {
    });

    test('inital tree creation', () async {
      // Let app become fully idle.
      await Future<void>.delayed(const Duration(seconds: 2));

      await driver.forceGC();

      final Timeline timeline = await driver.traceAction(() async {
        expect(await driver.setSemantics(true), isTrue);
      });

      final Iterable<TimelineEvent> semanticsEvents = timeline.events.where((TimelineEvent event) => event.name == 'Semantics');
      if (semanticsEvents.length != 1)
        fail('Expected exactly one semantics event, got ${semanticsEvents.length}');
      final Duration semanticsTreeCreation = semanticsEvents.first.duration;

      final String jsonEncoded = json.encode(<String, dynamic>{'initialSemanticsTreeCreation': semanticsTreeCreation.inMilliseconds});
      print(jsonEncoded);
    });
  });
}
