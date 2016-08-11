// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'globals.dart';
import 'observatory.dart';

/// Peered to a Android/iOS FlutterView widget on a device.
class FlutterView {
  FlutterView(this.viewId, this.viewManager);

  final String viewId;
  final ViewManager viewManager;
  String _uiIsolateId;
  String get uiIsolateId => _uiIsolateId;

  Future<Null> runFromSource(String entryPath,
                             String packagesPath,
                             String assetsDirectoryPath) async {
    return viewManager._runFromSource(this,
                                      entryPath,
                                      packagesPath,
                                      assetsDirectoryPath);
  }

  @override
  String toString() => viewId;

  @override
  bool operator ==(FlutterView other) {
    return other.viewId == viewId;
  }

  @override
  int get hashCode => viewId.hashCode;
}

/// Manager of FlutterViews.
class ViewManager {
  ViewManager(this.serviceProtocol);

  final Observatory serviceProtocol;

  Future<Null> refresh() async {
    List<Map<String, String>> viewList = await serviceProtocol.getViewList();
    for (Map<String, String> viewDescription in viewList) {
      FlutterView view = new FlutterView(viewDescription['id'], this);
      if (!views.contains(view)) {
        // Canonicalize views against the view set.
        views.add(view);
      }
    }
  }

  // TODO(johnmccutchan): Report errors when running failed.
  Future<Null> _runFromSource(FlutterView view,
                              String entryPath,
                              String packagesPath,
                              String assetsDirectoryPath) async {
    final String viewId = await serviceProtocol.getFirstViewId();
    // When this completer completes the isolate is running.
    final Completer<Null> completer = new Completer<Null>();
    final StreamSubscription<Event> subscription =
      serviceProtocol.onIsolateEvent.listen((Event event) {
      // TODO(johnmccutchan): Listen to the debug stream and catch initial
      // launch errors.
      if (event.kind == 'IsolateRunnable') {
        printTrace('Isolate is runnable.');
        completer.complete(null);
      }
    });
    await serviceProtocol.runInView(viewId,
                                   entryPath,
                                   packagesPath,
                                   assetsDirectoryPath);
    await completer.future;
    await subscription.cancel();
  }

  // TODO(johnmccutchan): Remove this accessor and make the runner multi-view
  // aware.
  FlutterView get mainView {
    return views.first;
  }

  final Set<FlutterView> views = new Set<FlutterView>();
}
