// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TapRegionSurface detects outside taps', (WidgetTester tester) async {
    final Set<String> tappedOutside = <String>{};
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
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedOutside, isEmpty);

    await click(find.text('No Group'));
    expect(
        tappedOutside,
        unorderedEquals(<String>{
          'Group 1 A',
          'Group 1 B',
        }));
    tappedOutside.clear();

    await click(find.text('Group 1 A'));
    expect(
        tappedOutside,
        equals(<String>{
          'No Group',
        }));
    tappedOutside.clear();

    await click(find.text('Group 1 B'));
    expect(
        tappedOutside,
        equals(<String>{
          'No Group',
        }));
    tappedOutside.clear();

    await click(find.text('Outside'));
    expect(
        tappedOutside,
        unorderedEquals(<String>{
          'No Group',
          'Group 1 A',
          'Group 1 B',
        }));
    tappedOutside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedOutside, isEmpty);
  });

  testWidgets('TapRegionSurface detects inside taps', (WidgetTester tester) async {
    final Set<String> tappedInside = <String>{};
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
      await gesture.up();
      await gesture.removePointer();
    }

    expect(tappedInside, isEmpty);

    await click(find.text('No Group'));
    expect(
        tappedInside,
        unorderedEquals(<String>{
          'No Group',
        }));
    tappedInside.clear();

    await click(find.text('Group 1 A'));
    expect(
        tappedInside,
        equals(<String>{
          'Group 1 A',
          'Group 1 B',
        }));
    tappedInside.clear();

    await click(find.text('Group 1 B'));
    expect(
        tappedInside,
        equals(<String>{
          'Group 1 A',
          'Group 1 B',
        }));
    tappedInside.clear();

    await click(find.text('Outside'));
    expect(tappedInside, isEmpty);
    tappedInside.clear();

    await click(find.text('Outside Surface'));
    expect(tappedInside, isEmpty);
  });

  testWidgets('TapRegionSurface detects inside taps correctly with behavior', (WidgetTester tester) async {
    final Set<String> tappedInside = <String>{};
    const ValueKey<String> noGroupKey = ValueKey<String>('No Group');
    const ValueKey<String> group1AKey = ValueKey<String>('Group 1 A');
    const ValueKey<String> group1BKey = ValueKey<String>('Group 1 B');
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
                      // ignore: avoid_redundant_argument_values
                      behavior: HitTestBehavior.deferToChild,
                      onTapInside: (PointerEvent event) {
                        tappedInside.add(noGroupKey.value);
                      },
                      child: Stack(key: noGroupKey),
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
                      child: Stack(key: group1AKey),
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
                      child: Stack(key: group1BKey),
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
    expect(tappedInside,
      equals(<String>{
        'Group 1 A',
        'Group 1 B',
      }),
    );
    tappedInside.clear();

    await click(find.byKey(group1BKey));
    expect(tappedInside, isEmpty); // No hittable children while translucent, so no hit.
    tappedInside.clear();
  });

  testWidgets('Setting the group updates the registration', (WidgetTester tester) async {
    final Set<String> tappedOutside = <String>{};
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
    expect(
        tappedOutside,
        equals(<String>[
          'Group 1 A',
          'Group 1 B',
        ]));
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
    expect(
        tappedOutside,
        equals(<String>[
          'Group 1 A',
          'Group 2 A',
        ]));
    tappedOutside.clear();
  });
}
