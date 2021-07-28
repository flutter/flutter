// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/rendering_tester.dart';

class _FakeEditableTextState with TextSelectionDelegate, TextEditingActionTarget {
  _FakeEditableTextState({
    required this.value,
    // Render editable parameters:
    this.obscureText = false,
    required this.textSpan,
    this.textDirection = TextDirection.ltr,
  });

  final TextDirection textDirection;
  final TextSpan textSpan;

  RenderEditable? _renderEditable;
  RenderEditable get renderEditable {
    if (_renderEditable != null) {
      return _renderEditable!;
    }
    _renderEditable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: textDirection,
      cursorColor: Colors.red,
      offset: ViewportOffset.zero(),
      textSelectionDelegate: this,
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: textSpan,
      selection: value.selection,
      textAlign: TextAlign.start,
    );
    return _renderEditable!;
  }

  // Start TextSelectionDelegate

  @override
  TextEditingValue get textEditingValue => value;
  set textEditingValue(TextEditingValue nextValue) {
    value = nextValue;
  }

  @override
  void hideToolbar([bool hideHandles = true]) { }

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) { }

  @override
  void bringIntoView(TextPosition position) { }

  // End TextSelectionDelegate
  // Start TextEditingActionTarget

  @override
  TextEditingValue value;

  @override
  bool get readOnly => false;

  @override
  final bool obscureText;

  @override
  bool get selectionEnabled => true;

  @override
  TextMetrics get textMetrics => renderEditable;

  @override
  void setSelection(TextSelection selection, SelectionChangedCause cause) {
    renderEditable.selection = selection;
    value = value.copyWith(
      selection: selection,
    );
  }

  @override
  void setTextEditingValue(TextEditingValue newValue, SelectionChangedCause cause) {
    value = newValue;
  }

  // End TextEditingActionTarget
}

void main() {
  test('moveSelectionLeft/RightByLine stays on the current line', () async {
    const String text = 'one two three\n\nfour five six';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    layout(editable);
    editable.hasFocus = true;

    editableTextState.setSelection(const TextSelection.collapsed(offset: 0), SelectionChangedCause.tap);
    pumpFrame();

    // Move to the end of the first line.
    editableTextState.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 13);
    // RenderEditable relies on its parent that passes onSelectionChanged to set
    // the selection.

    // Try moveSelectionRightByLine again and nothing happens because we're
    // already at the end of a line.
    editableTextState.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 13);

    // Move back to the start of the line.
    editableTextState.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 0);

    // Trying moveSelectionLeftByLine does nothing at the leftmost of the field.
    editableTextState.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 0);

    // Move the selection to the empty line.
    editableTextState.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 13);
    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 14);

    // Neither moveSelectionLeftByLine nor moveSelectionRightByLine do anything
    // here, because we're at both the beginning and end of the line.
    editableTextState.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 14);
    editableTextState.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 14);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys and delete handle simple text correctly', () async {
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: 'test',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: 'test',
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    layout(editable);
    editable.hasFocus = true;

    editableTextState.setSelection(const TextSelection.collapsed(offset: 0), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 1);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 0);

    editableTextState.deleteForward(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.text, 'est');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys and delete handle surrogate pairs correctly', () async {
    const String text = '0123😆6789';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    layout(editable);
    editable.hasFocus = true;

    editableTextState.setSelection(const TextSelection.collapsed(offset: 4), SelectionChangedCause.keyboard);
    pumpFrame();

    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 6);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 4);

    editableTextState.deleteForward(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.text, '01236789');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys and delete handle grapheme clusters correctly', () async {
    const String text = '0123👨‍👩‍👦2345';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    layout(editable);
    editable.hasFocus = true;

    editableTextState.setSelection(const TextSelection.collapsed(offset: 4), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 12);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 4);

    editableTextState.deleteForward(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.text, '01232345');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys and delete handle surrogate pairs correctly case 2', () async {
    const String text = '\u{1F44D}';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    layout(editable);
    editable.hasFocus = true;

    editableTextState.setSelection(const TextSelection.collapsed(offset: 0), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 2);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 0);

    editableTextState.deleteForward(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.text, '');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys work after detaching the widget and attaching it again', () async {
    const String text = 'W Szczebrzeszynie chrząszcz brzmi w trzcinie';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    final PipelineOwner pipelineOwner = PipelineOwner();
    editable.attach(pipelineOwner);
    editable.hasFocus = true;
    editable.detach();
    layout(editable);
    editable.hasFocus = true;
    editableTextState.setSelection(const TextSelection.collapsed(offset: 0), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editable.selection?.isCollapsed, true);
    expect(editable.selection?.baseOffset, 4);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editable.selection?.isCollapsed, true);
    expect(editable.selection?.baseOffset, 3);

     editableTextState.deleteForward(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.text, 'W Sczebrzeszynie chrząszcz brzmi w trzcinie');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('RenderEditable registers and unregisters raw keyboard listener correctly', () async {
    const String text = 'how are you';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    final PipelineOwner pipelineOwner = PipelineOwner();
    editable.attach(pipelineOwner);

    editableTextState.deleteForward(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.text, 'ow are you');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys with selection text', () async {
    const String text = '012345';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    layout(editable);
    editable.hasFocus = true;

    editableTextState.setSelection(const TextSelection(baseOffset: 2, extentOffset: 4), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 4);

    editableTextState.setSelection(const TextSelection(baseOffset: 4, extentOffset: 2), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 4);

    editableTextState.setSelection(const TextSelection(baseOffset: 2, extentOffset: 4), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 2);

    editableTextState.setSelection(const TextSelection(baseOffset: 4, extentOffset: 2), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 2);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/58068

  test('arrow keys with selection text and shift', () async {
    const String text = '012345';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    layout(editable);
    editable.hasFocus = true;

    editableTextState.setSelection(const TextSelection(baseOffset: 2, extentOffset: 4), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.extendSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, false);
    expect(editableTextState.value.selection.baseOffset, 2);
    expect(editableTextState.value.selection.extentOffset, 5);

    editableTextState.setSelection(const TextSelection(baseOffset: 4, extentOffset: 2), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.extendSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, false);
    expect(editableTextState.value.selection.baseOffset, 4);
    expect(editableTextState.value.selection.extentOffset, 3);

    editableTextState.setSelection(const TextSelection(baseOffset: 2, extentOffset: 4), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.extendSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, false);
    expect(editableTextState.value.selection.baseOffset, 2);
    expect(editableTextState.value.selection.extentOffset, 3);

    editableTextState.setSelection(const TextSelection(baseOffset: 4, extentOffset: 2), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.extendSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, false);
    expect(editableTextState.value.selection.baseOffset, 4);
    expect(editableTextState.value.selection.extentOffset, 1);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/58068

  test('respects enableInteractiveSelection', () async {
    const String text = '012345';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      value: const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    final RenderEditable editable = editableTextState.renderEditable;

    layout(editable);
    editable.hasFocus = true;

    editableTextState.setSelection(const TextSelection.collapsed(offset: 2), SelectionChangedCause.tap);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.shift);

    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 3);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 2);

    final LogicalKeyboardKey wordModifier =
        Platform.isMacOS ? LogicalKeyboardKey.alt : LogicalKeyboardKey.control;

    await simulateKeyDownEvent(wordModifier);

    editableTextState.moveSelectionRightByWord(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 6);

    editableTextState.moveSelectionLeftByWord(SelectionChangedCause.keyboard);
    expect(editableTextState.value.selection.isCollapsed, true);
    expect(editableTextState.value.selection.baseOffset, 0);

    await simulateKeyUpEvent(wordModifier);
    await simulateKeyUpEvent(LogicalKeyboardKey.shift);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/58068

  group('delete', () {
    test('when as a non-collapsed selection, it should delete a selection', () async {
      const String text = 'test';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection(baseOffset: 1, extentOffset: 3),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.delete(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'tt');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 1);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when as simple text, it should delete the character to the left', () async {
      const String text = 'test';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.delete(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'tet');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 2);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when has surrogate pairs, it should delete the pair', () async {
      const String text = '\u{1F44D}';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.delete(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, '');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when has grapheme clusters, it should delete the grapheme cluster', () async {
      const String text = '0123👨‍👩‍👦2345';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: 12),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.delete(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, '01232345');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 4);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when is at the start of the text, it should be a no-op', () async {
      const String text = 'test';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.delete(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'test');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when input has obscured text, it should delete the character to the left', () async {
      const String text = 'test';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        obscureText: true,
        textSpan: const TextSpan(
          text: '****',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.delete(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'tes');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 3);
    }, skip: isBrowser);

    test('when using cjk characters', () async {
      const String text = '用多個塊測試';
      // TODO(justinmc): Did I delete too much here in all these offset tests?
      const int offset = 4;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.delete(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, '用多個測試');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 3);
    }, skip: isBrowser);

    test('when using rtl', () async {
      const String text = 'برنامج أهلا بالعالم';
      const int offset = text.length;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textDirection: TextDirection.rtl,
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.delete(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'برنامج أهلا بالعال');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, text.length - 1);
    }, skip: isBrowser);
  });

  group('deleteByWord', () {
    test('when cursor is on the middle of a word, it should delete the left part of the word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 8;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test h multiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when includeWhiteSpace is true, it should treat a whiteSpace as a single word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 10;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByWord(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'test withmultiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 9);
    }, skip: isBrowser);

    test('when cursor is after a word, it should delete the whole word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 9;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test  multiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when cursor is preceeded by white spaces, it should delete the spaces and the next word to the left', () async {
      const String text = 'test with   multiple blocks';
      const int offset = 12;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test multiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when cursor is preceeded by tabs spaces', () async {
      const String text = 'test with\t\t\tmultiple blocks';
      const int offset = 12;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test multiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when cursor is preceeded by break line, it should delete the breaking line and the word right before it', () async {
      const String text = 'test with\nmultiple blocks';
      const int offset = 10;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test multiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when using cjk characters', () async {
        const String text = '用多個塊測試';
        const int offset = 4;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, '用多個測試');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 3);
    }, skip: isBrowser);

    test('when using rtl', () async {
      const String text = 'برنامج أهلا بالعالم';
      const int offset = text.length;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textDirection: TextDirection.rtl,
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'برنامج أهلا ');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 12);
    }, skip: isBrowser);

    test('when input has obscured text, it should delete everything before the selection', () async {
      const int offset = 21;
      const String text = 'test with multiple\n\n words';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        obscureText: true,
        textSpan: const TextSpan(
          text: '****',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'words');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);
  });

  group('deleteByLine', () {
    test('when cursor is on last character of a line, it should delete everything to the left', () async {
      const String text = 'test with multiple blocks';
      const int offset = text.length;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, '');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);

    test('when cursor is on the middle of a word, it should delete delete everything to the left', () async {
      const String text = 'test with multiple blocks';
      const int offset = 8;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'h multiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);

    test('when previous character is a breakline, it should preserve it', () async {
      const String text = 'test with\nmultiple blocks';
      const int offset = 10;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, text);
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when text is multiline, it should delete until the first line break it finds', () async {
      const String text = 'test with\n\nMore stuff right here.\nmultiple blocks';
      const int offset = 22;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'test with\n\nright here.\nmultiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 11);
    }, skip: isBrowser);

    test('when input has obscured text, it should delete everything before the selection', () async {
      const int offset = 21;
      const String text = 'test with multiple\n\n words';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        obscureText: true,
        textSpan: const TextSpan(
          text: '****',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'words');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);
  });

  group('deleteForward', () {
    test('when as a non-collapsed selection, it should delete a selection', () async {
      const String text = 'test';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection(baseOffset: 1, extentOffset: 3),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForward(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'tt');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 1);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when includeWhiteSpace is true, it should treat a whiteSpace as a single word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 9;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByWord(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'test withmultiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 9);
    }, skip: isBrowser);

    test('when at the end of a text, it should be a no-op', () async {
      const String text = 'test';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForward(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'test');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 4);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when the input has obscured text, it should delete the forward character', () async {
      const String text = 'test';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        obscureText: true,
        textSpan: const TextSpan(
          text: '****',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForward(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'est');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);

    test('when using cjk characters', () async {
      const String text = '用多個塊測試';
      const int offset = 0;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForward(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, '多個塊測試');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);

    test('when using rtl', () async {
      const String text = 'برنامج أهلا بالعالم';
      const int offset = 0;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textDirection: TextDirection.rtl,
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForward(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'رنامج أهلا بالعالم');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);
  });

  group('deleteForwardByWord', () {
    test('when cursor is on the middle of a word, it should delete the next part of the word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 6;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test w multiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is before a word, it should delete the whole word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 10;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test with  blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is preceeded by white spaces, it should delete the spaces and the next word', () async {
      const String text = 'test with   multiple blocks';
      const int offset = 9;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test with blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is before tabs, it should delete the tabs and the next word', () async {
      const String text = 'test with\t\t\tmultiple blocks';
      const int offset = 9;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test with blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is followed by break line, it should delete the next word', () async {
      const String text = 'test with\n\n\nmultiple blocks';
      const int offset = 9;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test with blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when using cjk characters', () async {
        const String text = '用多個塊測試';
        const int offset = 0;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, '多個塊測試');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when using rtl', () async {
      const String text = 'برنامج أهلا بالعالم';
      const int offset = 0;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textDirection: TextDirection.rtl,
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, ' أهلا بالعالم');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when input has obscured text, it should delete everything after the selection', () async {
      const int offset = 4;
      const String text = 'test';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        obscureText: true,
        textSpan: const TextSpan(
          text: '****',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(editableTextState.textEditingValue.text, 'test');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);
  });

  group('deleteForwardByLine', () {
    test('when cursor is on first character of a line, it should delete everything that follows', () async {
      const String text = 'test with multiple blocks';
      const int offset = 4;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'test');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is on the middle of a word, it should delete delete everything that follows', () async {
      const String text = 'test with multiple blocks';
      const int offset = 8;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'test wit');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when next character is a breakline, it should preserve it', () async {
      const String text = 'test with\n\n\nmultiple blocks';
      const int offset = 9;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, text);
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when text is multiline, it should delete until the first line break it finds', () async {
      const String text = 'test with\n\nMore stuff right here.\nmultiple blocks';
      const int offset = 2;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'te\n\nMore stuff right here.\nmultiple blocks');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when input has obscured text, it should delete everything after the selection', () async {
      const String text = 'test with multiple\n\n words';
      const int offset = 4;
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        obscureText: true,
        textSpan: const TextSpan(
          text: '****',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      final RenderEditable editable = editableTextState.renderEditable;

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editableTextState.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(editableTextState.textEditingValue.text, 'test');
      expect(editableTextState.textEditingValue.selection.isCollapsed, true);
      expect(editableTextState.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);
  });

  group('delete API implementations', () {
    // Regression test for: https://github.com/flutter/flutter/issues/80226.
    //
    // This textSelectionDelegate has different text and selection from the
    // render editable.
    late _FakeEditableTextState delegate;

    late RenderEditable editable;

    setUp(() {
      delegate = _FakeEditableTextState(
        textSpan: TextSpan(
          text: 'A ' * 50,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        value: const TextEditingValue(
          text: 'BBB',
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      editable = delegate.renderEditable;
    });

    void verifyDoesNotCrashWithInconsistentTextEditingValue(void Function(SelectionChangedCause) method) {
      editable = RenderEditable(
        text: TextSpan(
          text: 'A ' * 50,
        ),
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        textDirection: TextDirection.ltr,
        offset: ViewportOffset.fixed(0),
        textSelectionDelegate: delegate,
        selection: const TextSelection(baseOffset: 0, extentOffset: 50),
      );

      layout(editable, constraints: BoxConstraints.loose(const Size(500.0, 500.0)));
      dynamic error;
      try {
        method(SelectionChangedCause.tap);
      } catch (e) {
        error = e;
      }
      expect(error, isNull);
    }

    test('delete is not racy and handles composing region correctly', () {
      delegate.textEditingValue = const TextEditingValue(
        text: 'ABCDEF',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 1, end: 6),
      );
      verifyDoesNotCrashWithInconsistentTextEditingValue(delegate.delete);
      final TextEditingValue textEditingValue = editable.textSelectionDelegate.textEditingValue;
      expect(textEditingValue.text, 'ACDEF');
      expect(textEditingValue.selection.isCollapsed, isTrue);
      expect(textEditingValue.selection.baseOffset, 1);
      expect(textEditingValue.composing, const TextRange(start: 1, end: 5));
    });

    test('deleteForward is not racy and handles composing region correctly', () {
      delegate.textEditingValue = const TextEditingValue(
        text: 'ABCDEF',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 2, end: 6),
      );
      final TextEditingActionTarget target = delegate as TextEditingActionTarget;
      verifyDoesNotCrashWithInconsistentTextEditingValue(target.deleteForward);
      final TextEditingValue textEditingValue = editable.textSelectionDelegate.textEditingValue;
      expect(textEditingValue.text, 'ABDEF');
      expect(textEditingValue.selection.isCollapsed, isTrue);
      expect(textEditingValue.selection.baseOffset, 2);
      expect(textEditingValue.composing, const TextRange(start: 2, end: 5));
    });
  });
}
