// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TapRegionSurface detects outside tap down events', (WidgetTester tester) async {
    final tappedOutside = <String>{};
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
                      tappedOutside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 B');
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
      // We intentionally don't call up() here because we're testing the down event.
      await gesture.cancel();
      await gesture.removePointer();
    }

    expect(tappedOutside, isEmpty);

    await click(find.text('No Group'));
    expect(tappedOutside, unorderedEquals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedOutside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    tappedOutside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    tappedOutside.clear();

    await click(find.text('Outside'));
    expect(tappedOutside, unorderedEquals(<String>{'No Group', 'Group 1 A', 'Group 1 B'}));
    tappedOutside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedOutside, isEmpty);
  });

  testWidgets('TapRegionSurface detects outside tap up events', (WidgetTester tester) async {
    final tappedOutside = <String>{};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TapRegionSurface(
          child: Row(
            children: <Widget>[
              const Text('Outside'),
              TapRegion(
                onTapUpOutside: (PointerEvent event) {
                  tappedOutside.add('No Group');
                },
                child: const Text('No Group'),
              ),
              TapRegion(
                groupId: 1,
                onTapUpOutside: (PointerEvent event) {
                  tappedOutside.add('Group 1 A');
                },
                child: const Text('Group 1 A'),
              ),
              TapRegion(
                groupId: 1,
                onTapUpOutside: (PointerEvent event) {
                  tappedOutside.add('Group 1 B');
                },
                child: const Text('Group 1 B'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    Future<void> click(Finder finder) async {
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(finder),
        kind: PointerDeviceKind.mouse,
      );
      expect(tappedOutside, isEmpty); // No callbacks should been called before up event.
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedOutside, isEmpty);

    await click(find.text('No Group'));
    expect(tappedOutside, unorderedEquals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedOutside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    tappedOutside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    tappedOutside.clear();

    await click(find.text('Outside'));
    expect(tappedOutside, unorderedEquals(<String>{'No Group', 'Group 1 A', 'Group 1 B'}));
    tappedOutside.clear();
  });

  testWidgets('TapRegionSurface consumes outside taps when asked', (WidgetTester tester) async {
    final tappedOutside = <String>{};
    var propagatedTaps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            const Text('Outside Surface'),
            TapRegionSurface(
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      propagatedTaps += 1;
                    },
                    child: const Text('Outside'),
                  ),
                  TapRegion(
                    consumeOutsideTaps: true,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    consumeOutsideTaps: true,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 B');
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

    expect(tappedOutside, isEmpty);
    expect(propagatedTaps, equals(0));

    await click(find.text('No Group'));
    expect(tappedOutside, unorderedEquals(<String>{'Group 1 A', 'Group 1 B'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Outside'));
    expect(tappedOutside, unorderedEquals(<String>{'No Group', 'Group 1 A', 'Group 1 B'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedOutside, isEmpty);
  });

  testWidgets('TapRegionSurface detects inside tap down events', (WidgetTester tester) async {
    final tappedInside = <String>{};
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
                      tappedInside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapInside: (PointerEvent event) {
                      tappedInside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapInside: (PointerEvent event) {
                      tappedInside.add('Group 1 B');
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
      // We intentionally don't call up() here because we're testing the down event.
      await gesture.cancel();
      await gesture.removePointer();
    }

    expect(tappedInside, isEmpty);

    await click(find.text('No Group'));
    expect(tappedInside, unorderedEquals(<String>{'No Group'}));
    tappedInside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedInside, equals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedInside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedInside, equals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedInside.clear();

    await click(find.text('Outside'));
    expect(tappedInside, isEmpty);
    tappedInside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedInside, isEmpty);
  });

  testWidgets('TapRegionSurface detects inside tap up events', (WidgetTester tester) async {
    final tappedInside = <String>{};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TapRegionSurface(
          child: Row(
            children: <Widget>[
              const Text('Outside'),
              TapRegion(
                onTapUpInside: (PointerEvent event) {
                  tappedInside.add('No Group');
                },
                child: const Text('No Group'),
              ),
              TapRegion(
                groupId: 1,
                onTapUpInside: (PointerEvent event) {
                  tappedInside.add('Group 1 A');
                },
                child: const Text('Group 1 A'),
              ),
              TapRegion(
                groupId: 1,
                onTapUpInside: (PointerEvent event) {
                  tappedInside.add('Group 1 B');
                },
                child: const Text('Group 1 B'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    Future<void> click(Finder finder) async {
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(finder),
        kind: PointerDeviceKind.mouse,
      );
      expect(tappedInside, isEmpty); // No callbacks should been called before up event.
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedInside, isEmpty);

    await click(find.text('No Group'));
    expect(tappedInside, unorderedEquals(<String>{'No Group'}));
    tappedInside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedInside, equals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedInside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedInside, equals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedInside.clear();

    await click(find.text('Outside'));
    expect(tappedInside, isEmpty);
    tappedInside.clear();
  });

  testWidgets('TapRegionSurface detects inside taps correctly with behavior', (
    WidgetTester tester,
  ) async {
    final tappedInside = <String>{};
    const noGroupKey = ValueKey<String>('No Group');
    const group1AKey = ValueKey<String>('Group 1 A');
    const group1BKey = ValueKey<String>('Group 1 B');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            const Text('Outside Surface'),
            TapRegionSurface(
              child: Row(
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints.tightFor(width: 100, height: 100),
                    child: TapRegion(
                      onTapInside: (PointerEvent event) {
                        tappedInside.add(noGroupKey.value);
                      },
                      child: const Stack(key: noGroupKey),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints.tightFor(width: 100, height: 100),
                    child: TapRegion(
                      groupId: 1,
                      behavior: HitTestBehavior.opaque,
                      onTapInside: (PointerEvent event) {
                        tappedInside.add(group1AKey.value);
                      },
                      child: const Stack(key: group1AKey),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints.tightFor(width: 100, height: 100),
                    child: TapRegion(
                      groupId: 1,
                      behavior: HitTestBehavior.translucent,
                      onTapInside: (PointerEvent event) {
                        tappedInside.add(group1BKey.value);
                      },
                      child: const Stack(key: group1BKey),
                    ),
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

    expect(tappedInside, isEmpty);

    await click(find.byKey(noGroupKey));
    expect(tappedInside, isEmpty); // No hittable children, so no hit.

    await click(find.byKey(group1AKey));
    // No hittable children, but set to opaque, so it hits, triggering the
    // group.
    expect(tappedInside, equals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedInside.clear();

    await click(find.byKey(group1BKey));
    expect(tappedInside, isEmpty); // No hittable children while translucent, so no hit.
    tappedInside.clear();
  });

  testWidgets('Setting the group updates the registration', (WidgetTester tester) async {
    final tappedOutside = <String>{};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TapRegionSurface(
          child: Row(
            children: <Widget>[
              const Text('Outside'),
              TapRegion(
                groupId: 1,
                onTapOutside: (PointerEvent event) {
                  tappedOutside.add('Group 1 A');
                },
                child: const Text('Group 1 A'),
              ),
              TapRegion(
                groupId: 1,
                onTapOutside: (PointerEvent event) {
                  tappedOutside.add('Group 1 B');
                },
                child: const Text('Group 1 B'),
              ),
            ],
          ),
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

    expect(tappedOutside, isEmpty);

    await click(find.text('Group 1 A'));
    expect(tappedOutside, isEmpty);
    await click(find.text('Group 1 B'));
    expect(tappedOutside, isEmpty);
    await click(find.text('Outside'));
    expect(tappedOutside, equals(<String>['Group 1 A', 'Group 1 B']));
    tappedOutside.clear();

    // Now change out the groups.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TapRegionSurface(
          child: Row(
            children: <Widget>[
              const Text('Outside'),
              TapRegion(
                groupId: 1,
                onTapOutside: (PointerEvent event) {
                  tappedOutside.add('Group 1 A');
                },
                child: const Text('Group 1 A'),
              ),
              TapRegion(
                groupId: 2,
                onTapOutside: (PointerEvent event) {
                  tappedOutside.add('Group 2 A');
                },
                child: const Text('Group 2 A'),
              ),
            ],
          ),
        ),
      ),
    );

    await click(find.text('Group 1 A'));
    expect(tappedOutside, equals(<String>['Group 2 A']));
    tappedOutside.clear();

    await click(find.text('Group 2 A'));
    expect(tappedOutside, equals(<String>['Group 1 A']));
    tappedOutside.clear();

    await click(find.text('Outside'));
    expect(tappedOutside, equals(<String>['Group 1 A', 'Group 2 A']));
    tappedOutside.clear();
  });

  testWidgets('TapRegionSurface detects outside right click', (WidgetTester tester) async {
    final tappedOutside = <String>{};
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
                      tappedOutside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 B');
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
        buttons: kSecondaryButton,
      );
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedOutside, isEmpty);

    await click(find.text('No Group'));
    expect(tappedOutside, unorderedEquals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedOutside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    tappedOutside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    tappedOutside.clear();

    await click(find.text('Outside'));
    expect(tappedOutside, unorderedEquals(<String>{'No Group', 'Group 1 A', 'Group 1 B'}));
    tappedOutside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedOutside, isEmpty);
  });

  testWidgets('TapRegionSurface detects outside middle click', (WidgetTester tester) async {
    final tappedOutside = <String>{};
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
                      tappedOutside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 B');
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
        buttons: kTertiaryButton,
      );
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedOutside, isEmpty);

    await click(find.text('No Group'));
    expect(tappedOutside, unorderedEquals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedOutside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    tappedOutside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    tappedOutside.clear();

    await click(find.text('Outside'));
    expect(tappedOutside, unorderedEquals(<String>{'No Group', 'Group 1 A', 'Group 1 B'}));
    tappedOutside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedOutside, isEmpty);
  });

  testWidgets('TapRegionSurface consumes outside right click when asked', (
    WidgetTester tester,
  ) async {
    final tappedOutside = <String>{};
    var propagatedTaps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            const Text('Outside Surface'),
            TapRegionSurface(
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      propagatedTaps += 1;
                    },
                    child: const Text('Outside'),
                  ),
                  TapRegion(
                    consumeOutsideTaps: true,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    consumeOutsideTaps: true,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 B');
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
        buttons: kSecondaryButton,
      );
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedOutside, isEmpty);
    expect(propagatedTaps, equals(0));

    await click(find.text('No Group'));
    expect(tappedOutside, unorderedEquals(<String>{'Group 1 A', 'Group 1 B'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Outside'));
    expect(tappedOutside, unorderedEquals(<String>{'No Group', 'Group 1 A', 'Group 1 B'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedOutside, isEmpty);
  });

  testWidgets('TapRegionSurface consumes outside middle click when asked', (
    WidgetTester tester,
  ) async {
    final tappedOutside = <String>{};
    var propagatedTaps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            const Text('Outside Surface'),
            TapRegionSurface(
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      propagatedTaps += 1;
                    },
                    child: const Text('Outside'),
                  ),
                  TapRegion(
                    consumeOutsideTaps: true,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    consumeOutsideTaps: true,
                    onTapOutside: (PointerEvent event) {
                      tappedOutside.add('Group 1 B');
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
        buttons: kTertiaryButton,
      );
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedOutside, isEmpty);
    expect(propagatedTaps, equals(0));

    await click(find.text('No Group'));
    expect(tappedOutside, unorderedEquals(<String>{'Group 1 A', 'Group 1 B'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedOutside, equals(<String>{'No Group'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Outside'));
    expect(tappedOutside, unorderedEquals(<String>{'No Group', 'Group 1 A', 'Group 1 B'}));
    expect(propagatedTaps, equals(0));
    tappedOutside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedOutside, isEmpty);
  });

  testWidgets('TapRegionSurface detects inside right click', (WidgetTester tester) async {
    final tappedInside = <String>{};
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
                      tappedInside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapInside: (PointerEvent event) {
                      tappedInside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapInside: (PointerEvent event) {
                      tappedInside.add('Group 1 B');
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
        buttons: kSecondaryButton,
      );
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedInside, isEmpty);

    await click(find.text('No Group'));
    expect(tappedInside, unorderedEquals(<String>{'No Group'}));
    tappedInside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedInside, equals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedInside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedInside, equals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedInside.clear();

    await click(find.text('Outside'));
    expect(tappedInside, isEmpty);
    tappedInside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedInside, isEmpty);
  });

  testWidgets('TapRegionSurface detects inside middle click', (WidgetTester tester) async {
    final tappedInside = <String>{};
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
                      tappedInside.add('No Group');
                    },
                    child: const Text('No Group'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapInside: (PointerEvent event) {
                      tappedInside.add('Group 1 A');
                    },
                    child: const Text('Group 1 A'),
                  ),
                  TapRegion(
                    groupId: 1,
                    onTapInside: (PointerEvent event) {
                      tappedInside.add('Group 1 B');
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
        buttons: kTertiaryButton,
      );
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedInside, isEmpty);

    await click(find.text('No Group'));
    expect(tappedInside, unorderedEquals(<String>{'No Group'}));
    tappedInside.clear();

    await click(find.text('Group 1 A'));
    expect(tappedInside, equals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedInside.clear();

    await click(find.text('Group 1 B'));
    expect(tappedInside, equals(<String>{'Group 1 A', 'Group 1 B'}));
    tappedInside.clear();

    await click(find.text('Outside'));
    expect(tappedInside, isEmpty);
    tappedInside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedInside, isEmpty);
  });

  // Regression test for https://github.com/flutter/flutter/issues/153093.
  testWidgets('TapRegion onTapOutside should only trigger on the current route during navigation', (
    WidgetTester tester,
  ) async {
    const tapRegion1Key = ValueKey<String>('TapRegion');
    const tapRegion2Key = ValueKey<String>('TapRegion2');

    var count1 = 0;
    var count2 = 0;

    final tapRegion1 = TapRegion(
      key: tapRegion1Key,
      onTapOutside: (PointerEvent event) {
        count1 += 1;
      },
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.square(dimension: 100),
    );

    final tapRegion2 = TapRegion(
      key: tapRegion2Key,
      onTapOutside: (PointerEvent event) {
        count2 += 1;
      },
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.square(dimension: 100),
    );

    Future<void> tapOutside(WidgetTester tester, Finder regionFinder) async {
      // Find the RenderBox of the region.
      final RenderBox renderBox = tester.firstRenderObject(find.byType(Scaffold).last);
      final Offset outsidePoint = renderBox.localToGlobal(Offset.zero) + const Offset(200, 200);

      await tester.tapAt(outsidePoint);
      await tester.pump();
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: tapRegion1),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                tester.element(find.byType(FloatingActionButton)),
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => Scaffold(body: Center(child: tapRegion2)),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap outside the first TapRegion to trigger onTapOutside.
    await tapOutside(tester, find.byKey(tapRegion1Key));
    expect(count1, 1);
    expect(count2, 0);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Tap outside the second TapRegion to trigger onTapOutside
    await tapOutside(tester, find.byKey(tapRegion2Key));
    expect(count1, 2); // When the Fab is pressed, the first TapRegion is still active.
    expect(count2, 1);

    // Back to the first page.
    Navigator.pop(tester.element(find.byType(Scaffold).last));
    await tester.pumpAndSettle();

    // Tap outside the first TapRegion to trigger onTapOutside
    await tapOutside(tester, find.byKey(tapRegion1Key));
    expect(count1, 3);
    expect(count2, 1);
  });

  // Regression test for https://github.com/flutter/flutter/issues/153093.
  testWidgets('TapRegion on non-current routes should not respond to onTapOutside events', (
    WidgetTester tester,
  ) async {
    const tapRegion1Key = ValueKey<String>('TapRegion1');
    const tapRegion2Key = ValueKey<String>('TapRegion2');

    var count1 = 0;
    var count2 = 0;

    final tapRegion1 = TapRegion(
      key: tapRegion1Key,
      onTapOutside: (PointerEvent event) {
        count1 += 1;
      },
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.square(dimension: 100),
    );

    final tapRegion2 = TapRegion(
      key: tapRegion2Key,
      onTapOutside: (PointerEvent event) {
        count2 += 1;
      },
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.square(dimension: 100),
    );

    Future<void> tapOutside(WidgetTester tester, Finder regionFinder) async {
      // Find the RenderBox of the region.
      final RenderBox renderBox = tester.firstRenderObject(find.byType(Scaffold).last);
      final Offset outsidePoint = renderBox.localToGlobal(Offset.zero) + const Offset(200, 200);

      await tester.tapAt(outsidePoint);
      await tester.pump();
    }

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Scaffold(body: Center(child: tapRegion1)),
          '/second': (BuildContext context) => Scaffold(body: Center(child: tapRegion2)),
        },
        onGenerateInitialRoutes: (String initialRouteName) {
          return <Route<void>>[
            MaterialPageRoute<void>(
              builder: (BuildContext context) => Scaffold(body: Center(child: tapRegion1)),
            ),
            MaterialPageRoute<void>(
              builder: (BuildContext context) => Scaffold(body: Center(child: tapRegion2)),
            ),
          ];
        },
      ),
    );

    await tester.pumpAndSettle();

    // At this point, tapRegion2 is on top of tapRegion1.
    // Tap outside tapRegion2.
    await tapOutside(tester, find.byKey(tapRegion2Key));
    expect(count1, 0); // tapRegion1 should not respond.
    expect(count2, 1); // tapRegion2 should respond.

    // Now pop the top route to reveal tapRegion1.
    Navigator.pop(tester.element(find.byType(Scaffold).last));
    await tester.pumpAndSettle();

    // Tap outside tapRegion1.
    await tapOutside(tester, find.byKey(tapRegion1Key));
    expect(count1, 1); // tapRegion1 should respond.
    expect(count2, 1); // tapRegion2 should not respond anymore.
  });

  // Regression test for the consumeOutsideTaps issue when navigating between pages
  testWidgets('TapRegion with consumeOutsideTaps should not consume taps after navigation', (
    WidgetTester tester,
  ) async {
    const tapRegionKey = ValueKey<String>('TapRegion');
    const buttonKey = ValueKey<String>('Button');

    var buttonTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TapRegion(
              key: tapRegionKey,
              consumeOutsideTaps: true,
              onTapOutside: (PointerEvent event) {},
              behavior: HitTestBehavior.opaque,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    tester.element(find.byType(GestureDetector)),
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => Scaffold(
                        body: Center(
                          child: ElevatedButton(
                            key: buttonKey,
                            onPressed: () {
                              buttonTapped = true;
                            },
                            child: const Text('Test Button'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Container(width: 250.0, height: 250.0, color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Navigate to the second page
    await tester.tap(find.byKey(tapRegionKey));
    await tester.pumpAndSettle();

    // Verify that the button on the second page can be tapped
    // If consumeOutsideTaps is still active from the first page's TapRegion,
    // this tap would be consumed and buttonTapped would remain false
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();

    expect(
      buttonTapped,
      true,
      reason: 'Button tap was not consumed by a TapRegion on a non-current route',
    );
  });
}
