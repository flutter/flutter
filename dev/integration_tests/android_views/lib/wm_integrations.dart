// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'page.dart';

class WindowManagerIntegrationsPage extends PageWidget {
  const WindowManagerIntegrationsPage()
      : super('Window Manager Integrations Tests', const ValueKey<String>('WmIntegrationsListTile'));

  @override
  Widget build(BuildContext context) => WindowManagerBody();

}

class WindowManagerBody extends StatefulWidget {
  @override
  State<WindowManagerBody> createState() => WindowManagerBodyState();
}

enum _LastTestStatus {
  pending,
  success,
  error
}

class WindowManagerBodyState extends State<WindowManagerBody> {

  MethodChannel viewChannel;
  _LastTestStatus lastTestStatus = _LastTestStatus.pending;
  String lastError;
  int id;
  int windowClickCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Window Manager Integrations'),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 300,
            child: AndroidView(
              viewType: 'simple_view',
              onPlatformViewCreated: onPlatformViewCreated,
            ),
          ),
          if (lastTestStatus != _LastTestStatus.pending) _statusWidget(),
          if (viewChannel != null) ... <Widget>[
            RaisedButton(
              key: const ValueKey<String>('ShowAlertDialog'),
              child: const Text('SHOW ALERT DIALOG'),
              onPressed: onShowAlertDialogPressed,
            ),
            Row(
              children: <Widget>[
                RaisedButton(
                  key: const ValueKey<String>('AddWindow'),
                  child: const Text('ADD WINDOW'),
                  onPressed: onAddWindowPressed,
                ),
                RaisedButton(
                  key: const ValueKey<String>('TapWindow'),
                  child: const Text('TAP WINDOW'),
                  onPressed: onTapWindowPressed,
                ),
                if (windowClickCount > 0)
                  Text(
                      'Click count: $windowClickCount',
                      key: const ValueKey<String>('WindowClickCount'),
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

  Future<void> onAddWindowPressed() async {
    try {
      await viewChannel.invokeMethod<void>('addWindowAndWaitForClick');
      setState(() {
        windowClickCount++;
      });
    } catch(e) {
      setState(() {
        lastTestStatus = _LastTestStatus.error;
        lastError = '$e';
      });
    }
  }


  Future<void> onTapWindowPressed() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    for (final AndroidMotionEvent event in _tapSequence) {
      await SystemChannels.platform_views.invokeMethod<dynamic>(
        'touch',
        _motionEventasList(event, id),
      );
    }
  }

  void onPlatformViewCreated(int id) {
    this.id = id;
    setState(() {
      viewChannel = MethodChannel('simple_view/$id');
    });
  }


  static List<double> _pointerCoordsAsList(AndroidPointerCoords coords) {
    return <double>[
      coords.orientation,
      coords.pressure,
      coords.size,
      coords.toolMajor,
      coords.toolMinor,
      coords.touchMajor,
      coords.touchMinor,
      coords.x,
      coords.y,
    ];
  }

  static List<dynamic> _motionEventasList(AndroidMotionEvent event, int viewId) {
    return <dynamic>[
      viewId,
      event.downTime,
      event.eventTime,
      event.action,
      event.pointerCount,
      event.pointerProperties.map<List<int>>((AndroidPointerProperties p) => <int> [p.id, p.toolType]).toList(),
      event.pointerCoords.map<List<double>>((AndroidPointerCoords p) => _pointerCoordsAsList(p)).toList(),
      event.metaState,
      event.buttonState,
      event.xPrecision,
      event.yPrecision,
      event.deviceId,
      event.edgeFlags,
      event.source,
      event.flags,
    ];
  }

  static final List<AndroidMotionEvent> _tapSequence = <AndroidMotionEvent> [
    AndroidMotionEvent(
      downTime: 723657071,
      pointerCount: 1,
      pointerCoords:  <AndroidPointerCoords> [
        const AndroidPointerCoords(
          orientation: 0.0,
          touchMajor: 5.0,
          size: 0.019607843831181526,
          x: 180.0,
          y: 200.0,
          touchMinor: 5.0,
          pressure: 1.0,
          toolMajor: 5.0,
          toolMinor: 5.0,
        ),
      ],
      yPrecision: 1.0,
      buttonState: 0,
      flags: 0,
      source: 4098,
      deviceId: 4,
      metaState: 0,
      pointerProperties:  <AndroidPointerProperties> [
        const AndroidPointerProperties(
          id: 0,
          toolType: 1,
        ),
      ],
      edgeFlags: 0,
      eventTime: 723657071,
      action: 0,
      xPrecision: 1.0,
      motionEventId: 1,
    ),
    AndroidMotionEvent(
      downTime: 723657071,
      eventTime: 723657137,
      action: 1,
      pointerCount: 1,
      pointerProperties: <AndroidPointerProperties> [
        const AndroidPointerProperties(
          id:  0,
          toolType: 1,
        ),
      ],
      pointerCoords: <AndroidPointerCoords> [
        const AndroidPointerCoords(
          orientation: 0.0,
          touchMajor: 5.0,
          size: 0.019607843831181526,
          x: 180.0,
          y: 200.0,
          touchMinor: 5.0,
          pressure: 1.0,
          toolMajor: 5.0,
          toolMinor: 5.0,
        )
      ],
      metaState: 0,
      buttonState: 0,
      xPrecision: 1.0,
      yPrecision: 1.0,
      deviceId: 4,
      edgeFlags: 0,
      source: 4098,
      flags: 0,
      motionEventId: 2,
    ),
  ];
}
