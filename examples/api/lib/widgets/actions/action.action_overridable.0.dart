// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Action.Action.overridable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: SimpleUSPhoneNumberEntry()),
      ),
    ),
  );
}

// This implements a custom phone number input field that handles the
// [DeleteCharacterIntent] intent.
class DigitInput extends StatefulWidget {
  const DigitInput({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.maxLength,
    this.textInputAction = TextInputAction.next,
  }) : super(key: key);

  final int? maxLength;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final FocusNode focusNode;

  @override
  DigitInputState createState() => DigitInputState();
}

class DigitInputState extends State<DigitInput> {
  late final Action<DeleteCharacterIntent> _deleteTextAction =
      CallbackAction<DeleteCharacterIntent>(
    onInvoke: (DeleteCharacterIntent intent) {
      // For simplicity we delete everything in the section.
      widget.controller.clear();
      return null;
    },
  );

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        // Make the default `DeleteCharacterIntent` handler overridable.
        DeleteCharacterIntent: Action<DeleteCharacterIntent>.overridable(
            defaultAction: _deleteTextAction, context: context),
      },
      child: TextField(
        controller: widget.controller,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.phone,
        focusNode: widget.focusNode,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.maxLength),
        ],
      ),
    );
  }
}

class SimpleUSPhoneNumberEntry extends StatefulWidget {
  const SimpleUSPhoneNumberEntry({Key? key}) : super(key: key);

  @override
  State<SimpleUSPhoneNumberEntry> createState() =>
      _SimpleUSPhoneNumberEntryState();
}

class _DeleteDigit extends Action<DeleteCharacterIntent> {
  _DeleteDigit(this.state);

  final _SimpleUSPhoneNumberEntryState state;
  @override
  void invoke(DeleteCharacterIntent intent) {
    assert(callingAction != null);
    callingAction?.invoke(intent);

    if (state.lineNumberController.text.isEmpty &&
        state.lineNumberFocusNode.hasFocus) {
      state.prefixFocusNode.requestFocus();
    }

    if (state.prefixController.text.isEmpty && state.prefixFocusNode.hasFocus) {
      state.areaCodeFocusNode.requestFocus();
    }
  }

  // This action is only enabled when the `callingAction` exists and is
  // enabled.
  @override
  bool get isActionEnabled => callingAction?.isActionEnabled ?? false;
}

class _SimpleUSPhoneNumberEntryState extends State<SimpleUSPhoneNumberEntry> {
  final FocusNode areaCodeFocusNode = FocusNode();
  final TextEditingController areaCodeController = TextEditingController();
  final FocusNode prefixFocusNode = FocusNode();
  final TextEditingController prefixController = TextEditingController();
  final FocusNode lineNumberFocusNode = FocusNode();
  final TextEditingController lineNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        DeleteCharacterIntent: _DeleteDigit(this),
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Expanded(
            child: Text('(', textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 3,
            child: DigitInput(
              focusNode: areaCodeFocusNode,
              controller: areaCodeController,
              maxLength: 3,
            ),
          ),
          const Expanded(
            child: Text(')', textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 3,
            child: DigitInput(
              focusNode: prefixFocusNode,
              controller: prefixController,
              maxLength: 3,
            ),
          ),
          const Expanded(
            child: Text('-', textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 4,
            child: DigitInput(
              focusNode: lineNumberFocusNode,
              controller: lineNumberController,
              textInputAction: TextInputAction.done,
              maxLength: 4,
            ),
          ),
        ],
      ),
    );
  }
}
