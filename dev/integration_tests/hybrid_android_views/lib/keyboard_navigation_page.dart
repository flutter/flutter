// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'android_platform_view.dart';
import 'page.dart';

class KeyboardNavigationPage extends PageWidget {
  const KeyboardNavigationPage({super.key})
    : super('Keyboard Navigation Tests', const ValueKey<String>('KeyboardNavigationTile'));

  @override
  Widget build(BuildContext context) => const KeyboardNavigationBody();
}

class KeyboardNavigationBody extends StatefulWidget {
  const KeyboardNavigationBody({super.key});

  @override
  State<KeyboardNavigationBody> createState() => _KeyboardNavigationBodyState();
}

class _KeyboardNavigationBodyState extends State<KeyboardNavigationBody> {
  final GlobalKey _platformViewKey = GlobalKey();
  final FocusNode _flutterTextFieldFocusNode = FocusNode(debugLabel: 'FlutterTextField');
  final FocusNode _testTabKeyFocusNode = FocusNode(debugLabel: 'TestTabKey');
  String _status = 'Pending';

  @override
  void dispose() {
    _flutterTextFieldFocusNode.dispose();
    _testTabKeyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard Navigation Test')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              key: const ValueKey<String>('FlutterTextField'),
              focusNode: _flutterTextFieldFocusNode,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Flutter Editable Text Field',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: AndroidPlatformView(
              key: _platformViewKey,
              viewType: 'edit_text_view',
              useHybridComposition: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _status,
              key: const ValueKey<String>('KeyboardNavigationStatus'),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            key: const ValueKey<String>('TestTabKey'),
            focusNode: _testTabKeyFocusNode,
            onPressed: _runTest,
            child: const Text('TEST TAB KEY'),
          ),
        ],
      ),
    );
  }

  Future<void> _runTest() async {
    _flutterTextFieldFocusNode.requestFocus();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    const integrationChannel = MethodChannel('android_views_integration');

    // 1. Tab from Flutter text field into platform view containing editable text
    await integrationChannel.invokeMethod<void>('sendAndroidKeyEvent', <String, dynamic>{
      'keyCode': 61, // KEYCODE_TAB
    });


    // 2. Type character 'h' (KEYCODE_H = 36) into the focused text field
    await integrationChannel.invokeMethod<void>('sendAndroidKeyEvent', <String, dynamic>{
      'keyCode': 36, // KEYCODE_H
    });

    // 3. Type character 'i' (KEYCODE_I = 37) into the focused text field
    await integrationChannel.invokeMethod<void>('sendAndroidKeyEvent', <String, dynamic>{
      'keyCode': 37, // KEYCODE_I
    });

    // 4. Validate typed text is present in the platform view's EditText ("hi").
    final String typedText = await integrationChannel.invokeMethod<String>('getEditText') ?? '';

    // 5. Tab back out of the platform view (focus should move to the next focusable widget, which is the ElevatedButton)
    final Completer<void> focusCompleter = Completer<void>();
    void focusListener() {
      if (_testTabKeyFocusNode.hasFocus && !focusCompleter.isCompleted) {
        focusCompleter.complete();
      }
    }

    _testTabKeyFocusNode.addListener(focusListener);

    await integrationChannel.invokeMethod<void>('sendAndroidKeyEvent', <String, dynamic>{
      'keyCode': 61, // KEYCODE_TAB
    });

    try {
      await focusCompleter.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      // Timeout occurred, focus didn't arrive.
    } finally {
      _testTabKeyFocusNode.removeListener(focusListener);
    }

    final bool focusIsOnFlutterView = _testTabKeyFocusNode.hasFocus;

    setState(() {
      if (typedText == 'hi' && focusIsOnFlutterView) {
        _status = 'Success';
      } else {
        _status =
            'Failure: typedText="$typedText" (expected "hi"), focusIsOnFlutterView=$focusIsOnFlutterView';
      }
    });
  }
}
