// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The tests use fake cursors and sessions, and call [MouseCursorManager]
// directly instead of going through [MouseTracker], because cursor candidate
// resolution is pure Dart logic.

void main() {
  test('the fallback mouse cursor must not be MouseCursor.defer', () {
    expect(() => MouseCursorManager(MouseCursor.defer), throwsAssertionError);
  });

  test('activates the first non-deferred cursor candidate', () {
    final log = <String>[];
    final first = _TestMouseCursor('cursor.a', log);
    final second = _TestMouseCursor('cursor.b', log);
    final manager = MouseCursorManager(_TestMouseCursor('fallback', log));

    // MouseCursor.defer delegates the choice to the next cursor in the list.
    manager.handleDeviceCursorUpdate(0, const PointerAddedEvent(), <MouseCursor>[
      MouseCursor.defer,
      first,
      second,
    ]);

    expect(log, <String>['create cursor.a (device 0)', 'activate cursor.a (device 0)']);
    expect(manager.debugDeviceActiveCursor(0), first);
  });

  test('activates the fallback cursor when every candidate defers', () {
    final log = <String>[];
    final fallback = _TestMouseCursor('fallback', log);
    final manager = MouseCursorManager(fallback);

    manager.handleDeviceCursorUpdate(0, const PointerAddedEvent(), const <MouseCursor>[
      MouseCursor.defer,
      MouseCursor.defer,
    ]);

    expect(log, <String>['create fallback (device 0)', 'activate fallback (device 0)']);
    expect(manager.debugDeviceActiveCursor(0), fallback);
  });

  test('activates the fallback cursor when there are no candidates', () {
    final log = <String>[];
    final fallback = _TestMouseCursor('fallback', log);
    final manager = MouseCursorManager(fallback);

    manager.handleDeviceCursorUpdate(0, const PointerHoverEvent(), <MouseCursor>[]);

    expect(log, <String>['create fallback (device 0)', 'activate fallback (device 0)']);
  });

  test('does nothing if the resolved cursor is already active', () {
    final log = <String>[];
    final mouseCursor = _TestMouseCursor('cursor.a', log);
    final manager = MouseCursorManager(_TestMouseCursor('fallback', log));

    // Even with a triggering event, re-resolving the same cursor must not
    // recreate or re-activate the session.
    manager.handleDeviceCursorUpdate(0, const PointerAddedEvent(), <MouseCursor>[mouseCursor]);
    manager.handleDeviceCursorUpdate(0, const PointerHoverEvent(), <MouseCursor>[mouseCursor]);

    // Also try with a null triggering event, e.g. a refresh after a frame
    // completes with the mouse still.
    manager.handleDeviceCursorUpdate(0, null, <MouseCursor>[mouseCursor]);

    expect(log, <String>['create cursor.a (device 0)', 'activate cursor.a (device 0)']);
  });

  test('disposes the old session before activating the new session', () {
    final log = <String>[];
    final first = _TestMouseCursor('cursor.a', log);
    final second = _TestMouseCursor('cursor.b', log);
    final manager = MouseCursorManager(_TestMouseCursor('fallback', log));

    manager.handleDeviceCursorUpdate(0, const PointerAddedEvent(), <MouseCursor>[first]);
    manager.handleDeviceCursorUpdate(0, const PointerHoverEvent(), <MouseCursor>[second]);

    expect(log, <String>[
      'create cursor.a (device 0)',
      'activate cursor.a (device 0)',
      'create cursor.b (device 0)',
      'dispose cursor.a (device 0)',
      'activate cursor.b (device 0)',
    ]);
  });

  test('tracks devices independently', () {
    final log = <String>[];
    final cursorA = _TestMouseCursor('cursor.a', log);
    final cursorB = _TestMouseCursor('cursor.b', log);
    final manager = MouseCursorManager(_TestMouseCursor('fallback', log));

    manager.handleDeviceCursorUpdate(0, const PointerAddedEvent(), <MouseCursor>[cursorA]);
    manager.handleDeviceCursorUpdate(1, const PointerAddedEvent(device: 1), <MouseCursor>[cursorB]);

    // A cursor can be active on multiple devices at the same time, and each
    // device gets its own session.
    expect(cursorA.sessions, hasLength(1));
    expect(cursorB.sessions, hasLength(1));
    expect(manager.debugDeviceActiveCursor(0), cursorA);
    expect(manager.debugDeviceActiveCursor(1), cursorB);

    // Switching the cursor of one device does not disturb the other.
    manager.handleDeviceCursorUpdate(0, const PointerHoverEvent(), <MouseCursor>[cursorB]);

    expect(cursorB.sessions, hasLength(2));
    expect(cursorB.sessions[1].wasDisposed, isFalse);
    expect(manager.debugDeviceActiveCursor(0), cursorB);
    expect(manager.debugDeviceActiveCursor(1), cursorB);
  });

  test('forgets the device cursor on PointerRemovedEvent', () {
    final log = <String>[];
    final cursorA = _TestMouseCursor('cursor.a', log);
    final cursorB = _TestMouseCursor('cursor.b', log);
    final manager = MouseCursorManager(_TestMouseCursor('fallback', log));

    manager.handleDeviceCursorUpdate(0, const PointerAddedEvent(), <MouseCursor>[cursorA]);
    expect(manager.debugDeviceActiveCursor(0), cursorA);

    manager.handleDeviceCursorUpdate(0, const PointerRemovedEvent(), <MouseCursor>[cursorB]);

    // The removal event forgets the device without disposing its session:
    // disposal is handled elsewhere.
    expect(log, <String>['create cursor.a (device 0)', 'activate cursor.a (device 0)']);
    expect(cursorA.sessions.single.wasDisposed, isFalse);
    expect(manager.debugDeviceActiveCursor(0), isNull);

    // The device has been forgotten, so the same cursor is activated anew.
    manager.handleDeviceCursorUpdate(0, const PointerHoverEvent(), <MouseCursor>[cursorA]);

    expect(cursorA.sessions, hasLength(2));
    expect(manager.debugDeviceActiveCursor(0), cursorA);
  });

  test('debugDeviceActiveCursor returns null before any update', () {
    final log = <String>[];
    final cursor = _TestMouseCursor('fallback', log);
    final manager = MouseCursorManager(cursor);

    // Constructing the manager must not create sessions for any device.
    expect(manager.debugDeviceActiveCursor(0), isNull);
    expect(cursor.sessions, isEmpty);
    expect(log, isEmpty);
  });
}

class _TestMouseCursor extends MouseCursor {
  _TestMouseCursor(this.debugDescription, List<String> log) : _log = log;

  final List<String> _log;

  @override
  final String debugDescription;

  final List<_TestMouseCursorSession> sessions = <_TestMouseCursorSession>[];

  @override
  MouseCursorSession createSession(int device) {
    final session = _TestMouseCursorSession(this, device, _log);
    sessions.add(session);
    _log.add('create $debugDescription (device $device)');
    return session;
  }
}

class _TestMouseCursorSession extends MouseCursorSession {
  _TestMouseCursorSession(super.cursor, super.device, List<String> log) : _log = log;

  final List<String> _log;

  int disposeCallCount = 0;

  bool get wasDisposed => disposeCallCount > 0;

  @override
  Future<void> activate() {
    _log.add('activate ${cursor.debugDescription} (device $device)');
    return Future<void>.value();
  }

  @override
  void dispose() {
    assert(
      disposeCallCount == 0,
      'The session for device $device was disposed ${disposeCallCount + 1} times, but a session should be disposed at most once.',
    );
    disposeCallCount += 1;
    _log.add('dispose ${cursor.debugDescription} (device $device)');
  }
}
