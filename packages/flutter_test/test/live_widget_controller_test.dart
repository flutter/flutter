// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  test('Input event array on LiveWidgetController', () async {
    final List<String> logs = <String>[];
    runApp(
      MaterialApp(
        home: Listener(
          onPointerDown: (PointerDownEvent event) => logs.add('down ${event.buttons}'),
          onPointerMove: (PointerMoveEvent event) => logs.add('move ${event.buttons}'),
          onPointerUp: (PointerUpEvent event) => logs.add('up ${event.buttons}'),
          child: const Text('test'),
        ),
      ),
    );
    await SchedulerBinding.instance.endOfFrame;
    final WidgetController controller =
        LiveWidgetController(WidgetsBinding.instance);

    final Offset location = controller.getCenter(find.text('test'));
    final List<PointerEventRecord> records = <PointerEventRecord>[
      PointerEventRecord(Duration.zero, <PointerEvent>[
        // Typically PointerAddedEvent is not used in testers, but for records
        // captured on a device it is usually what start a gesture.
        PointerAddedEvent(
          timeStamp: Duration.zero,
          position: location,
        ),
        PointerDownEvent(
          timeStamp: Duration.zero,
          position: location,
          buttons: kSecondaryMouseButton,
          pointer: 1,
        ),
      ]),
      ...<PointerEventRecord>[
        for (Duration t = const Duration(milliseconds: 5);
            t < const Duration(milliseconds: 80);
            t += const Duration(milliseconds: 16))
          PointerEventRecord(t, <PointerEvent>[
            PointerMoveEvent(
              timeStamp: t - const Duration(milliseconds: 1),
              position: location,
              buttons: kSecondaryMouseButton,
              pointer: 1,
            )
          ])
      ],
      PointerEventRecord(const Duration(milliseconds: 80), <PointerEvent>[
        PointerUpEvent(
          timeStamp: const Duration(milliseconds: 79),
          position: location,
          buttons: kSecondaryMouseButton,
          pointer: 1,
        )
      ])
    ];
    final List<Duration> timeDiffs =
        await controller.handlePointerEventRecord(records);

    expect(timeDiffs.length, records.length);
    for (final Duration diff in timeDiffs) {
      // Allow some freedom of time delay in real world.
      assert(diff.inMilliseconds > -1);
    }

    const String b = '$kSecondaryMouseButton';
    expect(logs.first, 'down $b');
    for (int i = 1; i < logs.length - 1; i++) {
      expect(logs[i], 'move $b');
    }
    expect(logs.last, 'up $b');
  });
}
