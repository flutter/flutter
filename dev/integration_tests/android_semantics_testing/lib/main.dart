// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'src/tests/controls_page.dart';
import 'src/tests/headings_page.dart';
import 'src/tests/popup_page.dart';
import 'src/tests/text_field_page.dart';

void main() {
  timeDilation = 0.05; // remove animations.
  enableFlutterDriverExtension(handler: dataHandler);
  runApp(const TestApp());
}

const MethodChannel kSemanticsChannel = MethodChannel('semantics');

Future<String> dataHandler(String message) async {
  if (message.contains('getSemanticsNode')) {
    final Completer<String> completer = Completer<String>();
    final int id = int.tryParse(message.split('#')[1]) ?? 0;
    Future<void> completeSemantics([Object _]) async {
      final dynamic result = await kSemanticsChannel.invokeMethod<dynamic>('getSemanticsNode', <String, dynamic>{
        'id': id,
      });
      completer.complete(json.encode(result));
    }
    if (SchedulerBinding.instance.hasScheduledFrame) {
      SchedulerBinding.instance.addPostFrameCallback(completeSemantics);
    } else {
      completeSemantics();
    }
    return completer.future;
  }
  if (message.contains('setClipboard')) {
    final Completer<String> completer = Completer<String>();
    final String str = message.split('#')[1];
    Future<void> completeSetClipboard([Object _]) async {
      await kSemanticsChannel.invokeMethod<dynamic>('setClipboard', <String, dynamic>{
        'message': str,
      });
      completer.complete('');
    }
    if (SchedulerBinding.instance.hasScheduledFrame) {
      SchedulerBinding.instance.addPostFrameCallback(completeSetClipboard);
    } else {
      completeSetClipboard();
    }
    return completer.future;
  }
  throw UnimplementedError();
}

Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  selectionControlsRoute : (BuildContext context) => const SelectionControlsPage(),
  popupControlsRoute : (BuildContext context) => const PopupControlsPage(),
  textFieldRoute : (BuildContext context) => const TextFieldPage(),
  headingsRoute: (BuildContext context) => const HeadingsPage(),
};

class TestApp extends StatelessWidget {
  const TestApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: routes,
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: ListView(
              children: routes.keys.map<Widget>((String value) {
                return MaterialButton(
                  child: Text(value),
                  onPressed: () {
                    Navigator.of(context).pushNamed(value);
                  },
                );
              }).toList(),
            ),
          );
        }
      ),
    );
  }
}
