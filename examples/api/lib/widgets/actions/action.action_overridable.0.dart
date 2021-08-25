// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/freeform.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for Action.Action.overridable
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This sample implements a custom text input field that handles the
// [DeleteTextIntent] intent, as well as a US telephone number input widget
// that consists of multiple text fields for area code, prefix and line
// number. When the backspace key is pressed, the phone number input widget
// sends the focus to the preceding text field when the currently focused
// field becomes empty.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

//****************************************************************************
//* ▼▼▼▼▼▼▼▼ code-imports ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//* ▲▲▲▲▲▲▲▲ code-imports ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//****************************************************************************

//*************************************************************************
//* ▼▼▼▼▼▼▼▼ code-main ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: SimpleUSPhoneNumberEntry()),
      ),
    ),
  );
}

//* ▲▲▲▲▲▲▲▲ code-main ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//*************************************************************************

//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This implements a custom phone number input field that handles the
// [DeleteTextIntent] intent.
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
  late final Action<DeleteTextIntent> _deleteTextAction =
      CallbackAction<DeleteTextIntent>(
    onInvoke: (DeleteTextIntent intent) {
      // For simplicity we delete everything in the section.
      widget.controller.clear();
    },
  );

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        // Make the default `DeleteTextIntent` handler overridable.
        DeleteTextIntent: Action<DeleteTextIntent>.overridable(
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

class _DeleteDigit extends Action<DeleteTextIntent> {
  _DeleteDigit(this.state);

  final _SimpleUSPhoneNumberEntryState state;
  @override
  Object? invoke(DeleteTextIntent intent) {
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
        DeleteTextIntent: _DeleteDigit(this),
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Expanded(
              child: Text(
                '(',
                textAlign: TextAlign.center,
              ),
              flex: 1),
          Expanded(
              child: DigitInput(
                  focusNode: areaCodeFocusNode,
                  controller: areaCodeController,
                  maxLength: 3),
              flex: 3),
          const Expanded(
              child: Text(
                ')',
                textAlign: TextAlign.center,
              ),
              flex: 1),
          Expanded(
              child: DigitInput(
                  focusNode: prefixFocusNode,
                  controller: prefixController,
                  maxLength: 3),
              flex: 3),
          const Expanded(
              child: Text(
                '-',
                textAlign: TextAlign.center,
              ),
              flex: 1),
          Expanded(
              child: DigitInput(
                  focusNode: lineNumberFocusNode,
                  controller: lineNumberController,
                  textInputAction: TextInputAction.done,
                  maxLength: 4),
              flex: 4),
        ],
      ),
    );
  }
}

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************
