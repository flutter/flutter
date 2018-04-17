// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('semantics performance test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect(printCommunication: true);
    });

    tearDownAll(() async {
      if (driver != null)
        driver.close();
    });

    test('inital tree creation', () async {
      // Let app become fully idle.
      await new Future<Null>.delayed(const Duration(seconds: 1));

      final Timeline timeline = await driver.traceAction(() async {
        expect(await driver.setSemantics(true), isTrue);
      });

      final Iterable<TimelineEvent> semanticsEvents = timeline.events.where((TimelineEvent event) => event.name == 'Semantics');
      if (semanticsEvents.length != 1)
        fail('Expected exactly one semantics event, got ${semanticsEvents.length}');
      final Duration semanticsTreeCreation = semanticsEvents.first.duration;

      final String jsonEncoded = json.encode(<String, dynamic>{'initialSemanticsTreeCreation': semanticsTreeCreation.inMilliseconds});
      new File(p.join(testOutputsDirectory, 'complex_layout_semantics_perf.json')).writeAsStringSync(jsonEncoded);
    });
  });
}
