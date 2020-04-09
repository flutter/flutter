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
          if (viewChannel != null) RaisedButton(
            key: const ValueKey<String>('ShowAlertDialog'),
            child: const Text('SHOW ALERT DIALOG'),
            onPressed: onShowAlertDialogPressed,
          ),
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

  void onPlatformViewCreated(int id) {
    setState(() {
      viewChannel = MethodChannel('simple_view/$id');
    });
  }
}
