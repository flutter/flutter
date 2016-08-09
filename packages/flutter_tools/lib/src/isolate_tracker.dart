// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'globals.dart';
import 'observatory.dart';

// Track and report isolate life cycle events.
class IsolateTracker {
  IsolateTracker(this.serviceProtocol);

  // TODO(johnmccutchan): There can be more than one view.
  String _viewIsolateId;
  set viewIsolateId(String viewIsolateId) {
    _viewIsolateId = viewIsolateId;
    printStatus('View is now controlled by isolate $_viewIsolateId');
  }
  final Observatory serviceProtocol;
  StreamSubscription<Event> _isolateEventSubscription;
  StreamSubscription<Event> _debugEventSubscription;

  bool _isViewIsolate(String isolateId) {
    return (_viewIsolateId != null) && (_viewIsolateId == isolateId);
  }

  void onEvent(Event event) {
    _onEvent(event);
  }

  Future<Null> _onEvent(Event event) async {
    const List<String> kInterestingEventKinds =
        const <String>['IsolateStart',
                       'IsolateExit',
                       'IsolateRunnable',
                       'PauseStart',
                       'PauseExit',
                       'PauseBreakpoint',
                       'PauseException'];
    if (!kInterestingEventKinds.contains(event.kind))
      return;
    String messagePrefix = 'Isolate ${event.isolate.id}:';
    if (_isViewIsolate(event.isolate.id)) {
      messagePrefix = 'View isolate ${event.isolate.id}:';
    }
    if (event.kind == 'PauseExit') {
      // TODO(johnmccutchan): Load the isolate and get any error.
    }
    printStatus('$messagePrefix ${event.kind}');
  }

  Future<Null> start() async {
    if (_isolateEventSubscription != null) {
      assert(_debugEventSubscription != null);
      return;
    }
    _isolateEventSubscription =
        serviceProtocol.onIsolateEvent.listen(onEvent);
    _debugEventSubscription =
        serviceProtocol.onDebugEvent.listen(onEvent);
  }

  Future<Null> stop() async {
    _isolateEventSubscription?.cancel();
    _debugEventSubscription?.cancel();
  }
}
