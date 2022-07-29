// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TapRegionSurface detects outside taps', (WidgetTester tester) async {
    final Set<String> clickedOutside = <String>{};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            const Text('Outside Surface'),
            TapRegionSurface(
              child: Row(
                children: <Widget>[
                  const Text('Outside'),
                  TapRegion(
                    onTapOutside: (PointerEvent event) {
                      clickedOutside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      clickedOutside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      clickedOutside.add('Group 1 B');
                    },
                    child: const Text('Group 1 B'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pump();

    Future<void> click(Finder finder) async {
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(finder),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.up();
      await gesture.removePointer();
    }

    expect(clickedOutside, isEmpty);

    await click(find.text('No Group'));
    expect(
        clickedOutside,
        unorderedEquals(<String>{
          'Group 1 A',
          'Group 1 B',
        }));
    clickedOutside.clear();

    await click(find.text('Group 1 A'));
    expect(
        clickedOutside,
        equals(<String>{
          'No Group',
        }));
    clickedOutside.clear();

    await click(find.text('Group 1 B'));
    expect(
        clickedOutside,
        equals(<String>{
          'No Group',
        }));
    clickedOutside.clear();

    await click(find.text('Outside'));
    expect(
        clickedOutside,
        unorderedEquals(<String>{
          'No Group',
          'Group 1 A',
          'Group 1 B',
        }));
    clickedOutside.clear();

    await click(find.text('Outside Surface'));
    expect(clickedOutside, isEmpty);
  });
  testWidgets('TapRegionSurface detects inside taps', (WidgetTester tester) async {
    final Set<String> clickedInside = <String>{};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            const Text('Outside Surface'),
            TapRegionSurface(
              child: Row(
                children: <Widget>[
                  const Text('Outside'),
                  TapRegion(
                    onTapInside: (PointerEvent event) {
                      clickedInside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapInside: (PointerEvent event) {
                      clickedInside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapInside: (PointerEvent event) {
                      clickedInside.add('Group 1 B');
                    },
                    child: const Text('Group 1 B'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pump();

    Future<void> click(Finder finder) async {
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(finder),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.up();
      await gesture.removePointer();
    }

    expect(clickedInside, isEmpty);

    await click(find.text('No Group'));
    expect(
        clickedInside,
        unorderedEquals(<String>{
          'No Group',
        }));
    clickedInside.clear();

    await click(find.text('Group 1 A'));
    expect(
        clickedInside,
        equals(<String>{
          'Group 1 A',
          'Group 1 B',
        }));
    clickedInside.clear();

    await click(find.text('Group 1 B'));
    expect(
        clickedInside,
        equals(<String>{
          'Group 1 A',
          'Group 1 B',
        }));
    clickedInside.clear();

    await click(find.text('Outside'));
    expect(clickedInside, isEmpty);
    clickedInside.clear();

    await click(find.text('Outside Surface'));
    expect(clickedInside, isEmpty);
  });
}
