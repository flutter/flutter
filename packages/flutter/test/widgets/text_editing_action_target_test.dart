// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('can create Text-based TextEditingActionTarget', (WidgetTester tester) async {
    const String text = 'hello world';
    final TextEditingController controller = TextEditingController(
      text: text,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: _TestTextEditor(
            controller: controller,
            textSpan: const TextSpan(
              text: text,
            ),
          ),
        ),
      ),
    );

    expect(controller.value.text, text);
    await tester.tap(find.byType(_TestTextEditor));
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(controller.value, TextEditingValue.empty);
  });
}

class _TestTextEditor extends StatefulWidget {
  const _TestTextEditor({
    Key? key,
    required this.textSpan,
    required this.controller,
  }) : super(key: key);

  final TextSpan textSpan;
  final TextEditingController controller;

  @override
  _TestTextEditorState createState() => _TestTextEditorState();
}

class _TestTextEditorState extends State<_TestTextEditor>
    with TextEditingActionTarget implements DeltaTextInputClient {
  final GlobalKey _textKey = GlobalKey();
  final FocusNode focusNode = FocusNode();

  TextEditingValue get _value => widget.controller.value;

  late FocusAttachment? _focusAttachment;
  bool get _hasFocus => focusNode.hasFocus;

  TextInputConnection? _textInputConnection;
  TextEditingValue? _lastKnownRemoteTextEditingValue;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  RenderParagraph get _renderParagraph =>
      _textKey.currentContext?.findRenderObject() as RenderParagraph;

  @override
  void initState() {
    super.initState();
    _focusAttachment = focusNode.attach(context);
    focusNode.addListener(_handleFocusChanged);
    widget.controller.addListener(_didChangeTextEditingValue);
  }

  @override
  void didUpdateWidget(covariant _TestTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_hasFocus) {
      _openInputConnection();
    }
  }

  // Start TextEditingActionTarget.

  @override
  bool get obscureText => false;

  @override
  bool get readOnly => false;

  @override
  bool get selectionEnabled => true;

  @override
  TextEditingValue get textEditingValue => widget.controller.value;

  @override
  TextLayoutMetrics get textLayoutMetrics => _renderParagraph;

  @override
  void debugAssertLayoutUpToDate() {}

  @override
  void setTextEditingValue(TextEditingValue newValue, SelectionChangedCause cause) {
    if (newValue == textEditingValue) {
      return;
    }
    widget.controller.value = newValue;
  }

  // End TextEditingActionTarget.

  @override
  Widget build(BuildContext context) {
    _focusAttachment!.reparent();

    return Actions(
      actions: <Type, Action<Intent>>{
        DeleteCharacterIntent: _DeleteTextAction<DeleteCharacterIntent>(this),
      },
      child: Focus(
        focusNode: focusNode,
        child: GestureDetector(
          onTap: _requestKeyboard,
          child: Container(
            width: 350.0,
            height: 250.0,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text.rich(
              widget.controller
                  .buildTextSpan(context: context, withComposing: true),
              key: _textKey,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeTextEditingValue);
    _closeInputConnectionIfNeeded();
    assert(!_hasInputConnection);
    _focusAttachment!.detach();
    focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void _requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      focusNode
          .requestFocus(); // This eventually calls _openInputConnection also, see _handleFocusChanged.
    }
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (!_hasInputConnection)
      return;
    final TextEditingValue localValue = _value;
    if (localValue == _lastKnownRemoteTextEditingValue)
      return;
    _textInputConnection!.setEditingState(localValue);
    _lastKnownRemoteTextEditingValue = localValue;
  }

  void _didChangeTextEditingValue() {
    // Handler for when the text editing value has been updated.
    //
    // We will first check if we should update the remote value and then rebuild.
    // After our rebuild we should trigger an update to the text overlay.
    //
    // We update this after the text has been fully laid out and not before because
    // we will not have the most up to date renderParagraph before that time. We
    // need the most up to date renderParagraph to properly calculate the caret
    // position.
    _updateRemoteEditingValueIfNeeded();
    setState(() {/* We use widget.controller.value in build(). */});
  }

  void _closeInputConnectionIfNeeded() {
    // Only close the connection if we currently have one.
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      widget.controller.clearComposing();
    }
  }

  void _handleFocusChanged() {
    _openOrCloseInputConnectionIfNeeded();
  }

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  void _openInputConnection() {
    if (!_hasInputConnection) {
      final TextEditingValue localValue = _value;

      _textInputConnection = TextInput.attach(
        this,
        const TextInputConfiguration(
          enableDeltaModel: true,
        ),
      );

      _textInputConnection!.show();

      _textInputConnection!.setEditingState(localValue);
    } else {
      _textInputConnection!.show();
    }
  }

  @override
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
  TextEditingValue? get currentTextEditingValue => _value;

  @override
  void performAction(TextInputAction action) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void updateEditingValue(TextEditingValue value) {}

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}
}

class _DeleteTextAction<T extends DirectionalTextEditingIntent> extends ContextAction<T> {
  _DeleteTextAction(this.target);

  final TextEditingActionTarget target;

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    target.setTextEditingValue(TextEditingValue.empty, SelectionChangedCause.keyboard);
  }

  @override
  bool get isActionEnabled => !target.readOnly;
}
