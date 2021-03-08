// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'android_platform_view.dart';
import 'future_data_handler.dart';
import 'page.dart';

class NestedViewEventPage extends PageWidget {
  const NestedViewEventPage({Key key})
      : super('Nested View Event Tests', const ValueKey<String>('NestedViewEventTile'), key: key);

  @override
  Widget build(BuildContext context) => const NestedViewEventBody();
}

class NestedViewEventBody extends StatefulWidget {
  const NestedViewEventBody({Key key}) : super(key: key);

  @override
  State<NestedViewEventBody> createState() => NestedViewEventBodyState();
}

enum _LastTestStatus {
  pending,
  success,
  error
}

class NestedViewEventBodyState extends State<NestedViewEventBody> {

  MethodChannel viewChannel;
  _LastTestStatus lastTestStatus = _LastTestStatus.pending;
  String lastError;
  int id;
  int nestedViewClickCount = 0;
  bool showPlatformView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nested view event'),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 300,
              child: showPlatformView ?
                AndroidPlatformView(
                  key: const ValueKey<String>('PlatformView'),
                  viewType: 'simple_view',
                  onPlatformViewCreated: onPlatformViewCreated,
                ) : null,
          ),
          if (lastTestStatus != _LastTestStatus.pending) _statusWidget(),
          if (viewChannel != null) ... <Widget>[
            ElevatedButton(
              key: const ValueKey<String>('ShowAlertDialog'),
              child: const Text('SHOW ALERT DIALOG'),
              onPressed: onShowAlertDialogPressed,
            ),
            ElevatedButton(
              key: const ValueKey<String>('TogglePlatformView'),
              child: const Text('TOGGLE PLATFORM VIEW'),
              onPressed: onTogglePlatformView,
            ),
            Row(
              children: <Widget>[
                ElevatedButton(
                  key: const ValueKey<String>('AddChildView'),
                  child: const Text('ADD CHILD VIEW'),
                  onPressed: onChildViewPressed,
                ),
                ElevatedButton(
                  key: const ValueKey<String>('TapChildView'),
                  child: const Text('TAP CHILD VIEW'),
                  onPressed: onTapChildViewPressed,
                ),
                if (nestedViewClickCount > 0)
                  Text(
                      'Click count: $nestedViewClickCount',
                      key: const ValueKey<String>('NestedViewClickCount'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusWidget() {
    assert(lastTestStatus != _LastTestStatus.pending);
    final String message = lastTestStatus == _LastTestStatus.success ? 'Success' : lastError;
    return Container(
      color: lastTestStatus == _LastTestStatus.success ? Colors.green : Colors.red,
      child: Text(
        message,
        key: const ValueKey<String>('Status'),
        style: TextStyle(
          color: lastTestStatus == _LastTestStatus.error ? Colors.yellow : null,
        ),
      ),
    );
  }

  Future<void> onShowAlertDialogPressed() async {
    if (lastTestStatus != _LastTestStatus.pending) {
      setState(() {
        lastTestStatus = _LastTestStatus.pending;
      });
    }
    try {
      await viewChannel.invokeMethod<void>('showAndHideAlertDialog');
      setState(() {
        lastTestStatus = _LastTestStatus.success;
      });
    } catch(e) {
      setState(() {
        lastTestStatus = _LastTestStatus.error;
        lastError = '$e';
      });
    }
  }

  Future<void> onTogglePlatformView() async {
    setState(() {
      showPlatformView = !showPlatformView;
    });
  }

  Future<void> onChildViewPressed() async {
    try {
      await viewChannel.invokeMethod<void>('addChildViewAndWaitForClick');
      setState(() {
        nestedViewClickCount++;
      });
    } catch(e) {
      setState(() {
        lastTestStatus = _LastTestStatus.error;
        lastError = '$e';
      });
    }
  }

  Future<void> onTapChildViewPressed() async {
    await Future<void>.delayed(const Duration(seconds: 1));

    // Dispatch a tap event on the child view inside the platform view.
    //
    // Android mutates `MotionEvent` instances, so in this case *do not* dispatch
    // new instances as it won't cover the `MotionEventTracker` class in the embedding
    // which tracks events.
    //
    // See the issue this prevents: https://github.com/flutter/flutter/issues/61169
    await Process.run('input', const <String>['tap', '250', '550']);
  }

  void onPlatformViewCreated(int id) {
    this.id = id;
    setState(() {
      viewChannel = MethodChannel('simple_view/$id');
    });
    driverDataHandler.registerHandler('hierarchy')
      .complete(() => channel.invokeMethod<String>('getViewHierarchy'));
  }
}
