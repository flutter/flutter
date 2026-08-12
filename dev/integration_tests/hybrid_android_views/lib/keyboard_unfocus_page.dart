// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'android_platform_view.dart';
import 'future_data_handler.dart';
import 'page.dart';

class KeyboardUnfocusPage extends PageWidget {
  const KeyboardUnfocusPage({super.key})
    : super('Keyboard Unfocus Tests', const ValueKey<String>('KeyboardUnfocusListTile'));

  @override
  Widget build(BuildContext context) {
    return const KeyboardUnfocusBody();
  }
}

class KeyboardUnfocusBody extends StatefulWidget {
  const KeyboardUnfocusBody({super.key});

  @override
  State createState() => KeyboardUnfocusBodyState();
}

class KeyboardUnfocusBodyState extends State<KeyboardUnfocusBody> {
  final TextEditingController _editingController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final MethodChannel _integrationChannel = const MethodChannel('android_views_integration');
  String _textValue = '';

  @override
  void initState() {
    super.initState();
    _editingController.addListener(() {
      setState(() {
        _textValue = _editingController.text;
      });
    });

    driverDataHandler.registerHandler('commitText').complete(() async {
      final bool success = await _integrationChannel.invokeMethod<bool>('commitText') ?? false;
      return success.toString();
    });
  }

  @override
  void dispose() {
    _editingController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Keyboard Unfocus')),
      body: Column(
        children: <Widget>[
          const SizedBox(
            key: ValueKey<String>('PlatformViewContainer'),
            height: 300.0,
            child: AndroidPlatformView(viewType: 'simple_view', useHybridComposition: true),
          ),
          TextField(
            key: const ValueKey<String>('textfield'),
            controller: _editingController,
            focusNode: _textFieldFocusNode,
          ),
          Text(_textValue, key: const ValueKey<String>('text_value')),
        ],
      ),
    );
  }
}
