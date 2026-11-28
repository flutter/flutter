// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The SDK owns this contract. A transient hit-test/hover error must be
  // reported without disabling subsequent input for the entire application.
  for (final phase in ['hit test', 'enter', 'exit', 'reentrant update']) {
    test('mouse input recovers after a failed $phase', () {
      final error = StateError('transient $phase failure');
      var failing = false;
      var enters = 0;
      var exits = 0;
      late MouseTracker tracker;
      final region = RenderMouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (failing && phase == 'enter') {
            throw error;
          }
          if (failing && phase == 'reentrant update') {
            tracker.updateAllDevices();
          }
          enters++;
        },
        onExit: (_) {
          if (failing && phase == 'exit') {
            throw error;
          }
          exits++;
        },
      )..layout(BoxConstraints.tight(const Size(100, 100)));
      tracker = MouseTracker((position, viewId) {
        if (failing && phase == 'hit test') {
          throw error;
        }
        final result = BoxHitTestResult();
        region.hitTest(result, position: position);
        return result;
      });
      addTearDown(tracker.dispose);
      addTearDown(region.dispose);
      final connections = <bool>[];
      tracker.addListener(() => connections.add(tracker.mouseIsConnected));
      final bool startsInside = phase == 'hit test' || phase == 'exit';
      tracker.updateWithEvent(
        PointerAddedEvent(
          kind: PointerDeviceKind.mouse,
          position: startsInside ? const Offset(10, 10) : const Offset(200, 200),
        ),
        null,
      );

      failing = true;
      expect(
        () {
          if (phase == 'hit test') {
            tracker.updateAllDevices();
          } else {
            tracker.updateWithEvent(
              PointerHoverEvent(
                kind: PointerDeviceKind.mouse,
                position: phase == 'exit' ? const Offset(200, 200) : const Offset(10, 10),
              ),
              null,
            );
          }
        },
        phase == 'reentrant update' ? throwsAssertionError : throwsA(same(error)),
      );

      failing = false;
      // These are precisely the frame/input paths that used to assert forever.
      tracker.updateAllDevices();
      tracker.updateWithEvent(const PointerRemovedEvent(kind: PointerDeviceKind.mouse), null);
      enters = exits = 0;
      tracker.updateWithEvent(
        const PointerAddedEvent(kind: PointerDeviceKind.mouse, position: Offset(10, 10)),
        null,
      );
      tracker.updateAllDevices();
      expect(tracker.debugDeviceActiveCursor(0), SystemMouseCursors.click);
      tracker.updateWithEvent(
        const PointerHoverEvent(kind: PointerDeviceKind.mouse, position: Offset(200, 200)),
        null,
      );
      tracker.updateWithEvent(const PointerRemovedEvent(kind: PointerDeviceKind.mouse), null);
      expect(enters, 1);
      expect(exits, 1);
      expect(connections, [true, false, true, false]);
    });
  }

  testWidgets('reload hover failure does not freeze subsequent reloads or clicks', (tester) async {
    var generation = 0;
    var failing = false;
    var clicks = 0;
    final error = StateError('hover callback during reload');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => MouseRegion(
            key: ValueKey<int>(generation),
            onEnter: (_) {
              if (failing) {
                throw error;
              }
            },
            child: GestureDetector(
              onTap: () => clicks++,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    final TestGesture mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(20, 20));
    await tester.pump();

    // Replacing the region under a stationary cursor dispatches onEnter in
    // the reload's post-frame mouse update, without any physical mouse input.
    generation++;
    failing = true;
    final Future<void> reload = tester.binding.reassembleApplication();
    await tester.pump();
    await reload;
    expect(tester.takeException(), same(error));
    failing = false;

    for (var i = 0; i < 20; i++) {
      generation++;
      final Future<void> reload = tester.binding.reassembleApplication();
      await tester.pump();
      await reload;
      expect(tester.takeException(), isNull);
      await mouse.moveTo(Offset(21 + i.toDouble(), 20));
      await mouse.down(Offset(21 + i.toDouble(), 20));
      await mouse.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    expect(clicks, 20);
    await mouse.removePointer();
  });
}
