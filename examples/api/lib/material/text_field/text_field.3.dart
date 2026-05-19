// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter code sample for [TextField].

void main() {
  runApp(const TextFieldExampleApp());
}

class TextFieldExampleApp extends StatelessWidget {
  const TextFieldExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('TextField Shift+Enter Example')),
        body: const TextFieldShiftEnterExample(),
      ),
    );
  }
}

class TextFieldShiftEnterExample extends StatefulWidget {
  const TextFieldShiftEnterExample({super.key});

  @override
  State<TextFieldShiftEnterExample> createState() =>
      _TextFieldShiftEnterExampleState();
}

class _TextFieldShiftEnterExampleState
    extends State<TextFieldShiftEnterExample> {
  final FocusNode _focusNode = FocusNode();

  final TextEditingController _controller = TextEditingController();

  String? _submittedText;

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: Text(
              _submittedText == null
                  ? 'Please submit some text\n\n'
                        'Press Shift+Enter for a new line\n'
                        'Press Enter to submit'
                  : 'Submitted text:\n\n${_submittedText!}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            // Map the `Shift+Enter` combination to our custom intent.
            const SingleActivator(LogicalKeyboardKey.enter, shift: true):
                _InsertNewLineTextIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              // When the _InsertNewLineTextIntent is invoked, CallbackAction's
              // onInvoke callback is executed.
              _InsertNewLineTextIntent:
                  CallbackAction<_InsertNewLineTextIntent>(
                    onInvoke: (_InsertNewLineTextIntent intent) {
                      final TextEditingValue value = _controller.value;
                      final String newText = value.text.replaceRange(
                        value.selection.start,
                        value.selection.end,
                        '\n',
                      );
                      _controller.value = value.copyWith(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: value.selection.start + 1,
                        ),
                      );

                      return null;
                    },
                  ),
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                focusNode: _focusNode,
                autofocus: true,
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Text',
                ),
                maxLines: null,
                textInputAction: TextInputAction.done,
                onSubmitted: (String? text) {
                  setState(() {
                    _submittedText = text;
                    _controller.clear();
                    _focusNode.requestFocus();
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A custom [Intent] to represent the action of inserting a newline.
class _InsertNewLineTextIntent extends Intent {}
