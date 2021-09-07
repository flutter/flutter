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
    required this.textEditingValue,
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
      selection: textEditingValue.selection,
      textAlign: TextAlign.start,
    );
    return _renderEditable!;
  }

  // Start TextSelectionDelegate

  @override
  TextEditingValue textEditingValue;

  @override
  void hideToolbar([bool hideHandles = true]) { }

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) { }

  @override
  void bringIntoView(TextPosition position) { }

  // End TextSelectionDelegate
  // Start TextEditingActionTarget

  @override
  bool get readOnly => false;

  @override
  final bool obscureText;

  @override
  bool get selectionEnabled => true;

  @override
  TextLayoutMetrics get textLayoutMetrics => renderEditable;

  @override
  void setSelection(TextSelection selection, SelectionChangedCause cause) {
    renderEditable.selection = selection;
    textEditingValue = textEditingValue.copyWith(
      selection: selection,
    );
  }

  @override
  void setTextEditingValue(TextEditingValue newValue, SelectionChangedCause cause) {
    textEditingValue = newValue;
  }

  @override
  void debugAssertLayoutUpToDate() {}

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
      textEditingValue: const TextEditingValue(
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
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 13);
    expect(editableTextState.textEditingValue.selection.affinity, TextAffinity.upstream);
    // RenderEditable relies on its parent that passes onSelectionChanged to set
    // the selection.

    // Try moveSelectionRightByLine again and nothing happens because we're
    // already at the end of a line.
    editableTextState.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 13);
    expect(editableTextState.textEditingValue.selection.affinity, TextAffinity.upstream);

    // Move back to the start of the line.
    editableTextState.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    expect(editableTextState.textEditingValue.selection.affinity, TextAffinity.downstream);

    // Trying moveSelectionLeftByLine does nothing at the leftmost of the field.
    editableTextState.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 0);
    expect(editableTextState.textEditingValue.selection.affinity, TextAffinity.downstream);

    // Move the selection to the empty line.
    editableTextState.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 13);
    expect(editableTextState.textEditingValue.selection.affinity, TextAffinity.upstream);
    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 14);
    expect(editableTextState.textEditingValue.selection.affinity, TextAffinity.downstream);

    // Neither moveSelectionLeftByLine nor moveSelectionRightByLine do anything
    // here, because we're at both the beginning and end of the line.
    editableTextState.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 14);
    expect(editableTextState.textEditingValue.selection.affinity, TextAffinity.downstream);
    editableTextState.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 14);
    expect(editableTextState.textEditingValue.selection.affinity, TextAffinity.downstream);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys and delete handle simple text correctly', () async {
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: 'test',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      textEditingValue: const TextEditingValue(
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
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 1);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 0);

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
      textEditingValue: const TextEditingValue(
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
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 6);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 4);

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
      textEditingValue: const TextEditingValue(
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
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 12);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 4);

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
      textEditingValue: const TextEditingValue(
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
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 2);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 0);

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
      textEditingValue: const TextEditingValue(
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
      textEditingValue: const TextEditingValue(
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
      textEditingValue: const TextEditingValue(
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
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 4);

    editableTextState.setSelection(const TextSelection(baseOffset: 4, extentOffset: 2), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 4);

    editableTextState.setSelection(const TextSelection(baseOffset: 2, extentOffset: 4), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 2);

    editableTextState.setSelection(const TextSelection(baseOffset: 4, extentOffset: 2), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 2);
  });

  test('arrow keys with selection text and shift', () async {
    const String text = '012345';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      textEditingValue: const TextEditingValue(
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
    expect(editableTextState.textEditingValue.selection.isCollapsed, false);
    expect(editableTextState.textEditingValue.selection.baseOffset, 2);
    expect(editableTextState.textEditingValue.selection.extentOffset, 5);

    editableTextState.setSelection(const TextSelection(baseOffset: 4, extentOffset: 2), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.extendSelectionRight(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, false);
    expect(editableTextState.textEditingValue.selection.baseOffset, 4);
    expect(editableTextState.textEditingValue.selection.extentOffset, 3);

    editableTextState.setSelection(const TextSelection(baseOffset: 2, extentOffset: 4), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.extendSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, false);
    expect(editableTextState.textEditingValue.selection.baseOffset, 2);
    expect(editableTextState.textEditingValue.selection.extentOffset, 3);

    editableTextState.setSelection(const TextSelection(baseOffset: 4, extentOffset: 2), SelectionChangedCause.tap);
    pumpFrame();

    editableTextState.extendSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, false);
    expect(editableTextState.textEditingValue.selection.baseOffset, 4);
    expect(editableTextState.textEditingValue.selection.extentOffset, 1);
  });

  test('respects enableInteractiveSelection', () async {
    const String text = '012345';
    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      textSpan: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      textEditingValue: const TextEditingValue(
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
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 3);

    editableTextState.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 2);

    final LogicalKeyboardKey wordModifier =
        Platform.isMacOS ? LogicalKeyboardKey.alt : LogicalKeyboardKey.control;

    await simulateKeyDownEvent(wordModifier);

    editableTextState.moveSelectionRightByWord(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 6);

    editableTextState.moveSelectionLeftByWord(SelectionChangedCause.keyboard);
    expect(editableTextState.textEditingValue.selection.isCollapsed, true);
    expect(editableTextState.textEditingValue.selection.baseOffset, 0);

    await simulateKeyUpEvent(wordModifier);
    await simulateKeyUpEvent(LogicalKeyboardKey.shift);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/87681

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
        textEditingValue: const TextEditingValue(
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
        textEditingValue: const TextEditingValue(
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
        textEditingValue: const TextEditingValue(
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
        textEditingValue: const TextEditingValue(
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
        textEditingValue: const TextEditingValue(
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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });
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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });
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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });
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
        textEditingValue: const TextEditingValue(
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
        textEditingValue: const TextEditingValue(
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
    });

    test('when at the end of a text, it should be a no-op', () async {
      const String text = 'test';
      final _FakeEditableTextState editableTextState = _FakeEditableTextState(
        textSpan: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        textEditingValue: const TextEditingValue(
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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });
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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });
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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    });

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
        textEditingValue: const TextEditingValue(
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
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/87685

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
        textEditingValue: const TextEditingValue(
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
    });
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
          style: const TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        textEditingValue: const TextEditingValue(
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
      final TextEditingActionTarget target = delegate;
      verifyDoesNotCrashWithInconsistentTextEditingValue(target.deleteForward);
      final TextEditingValue textEditingValue = editable.textSelectionDelegate.textEditingValue;
      expect(textEditingValue.text, 'ABDEF');
      expect(textEditingValue.selection.isCollapsed, isTrue);
      expect(textEditingValue.selection.baseOffset, 2);
      expect(textEditingValue.composing, const TextRange(start: 2, end: 5));
    });
  });

  group('nextCharacter', () {
    test('handles normal strings correctly', () {
      expect(TextEditingActionTarget.nextCharacter(0, '01234567'), 1);
      expect(TextEditingActionTarget.nextCharacter(3, '01234567'), 4);
      expect(TextEditingActionTarget.nextCharacter(7, '01234567'), 8);
      expect(TextEditingActionTarget.nextCharacter(8, '01234567'), 8);
    });

    test('throws for invalid indices', () {
      expect(() => TextEditingActionTarget.nextCharacter(-1, '01234567'), throwsAssertionError);
      expect(() => TextEditingActionTarget.nextCharacter(9, '01234567'), throwsAssertionError);
    });

    test('skips spaces in normal strings when includeWhitespace is false', () {
      expect(TextEditingActionTarget.nextCharacter(3, '0123 5678', false), 5);
      expect(TextEditingActionTarget.nextCharacter(4, '0123 5678', false), 5);
      expect(TextEditingActionTarget.nextCharacter(3, '0123      0123', false), 10);
      expect(TextEditingActionTarget.nextCharacter(2, '0123      0123', false), 3);
      expect(TextEditingActionTarget.nextCharacter(4, '0123      0123', false), 10);
      expect(TextEditingActionTarget.nextCharacter(9, '0123      0123', false), 10);
      expect(TextEditingActionTarget.nextCharacter(10, '0123      0123', false), 11);
      // If the subsequent characters are all whitespace, it returns the length
      // of the string.
      expect(TextEditingActionTarget.nextCharacter(5, '0123      ', false), 10);
    });

    test('handles surrogate pairs correctly', () {
      expect(TextEditingActionTarget.nextCharacter(3, '0123👨👩👦0123'), 4);
      expect(TextEditingActionTarget.nextCharacter(4, '0123👨👩👦0123'), 6);
      expect(TextEditingActionTarget.nextCharacter(5, '0123👨👩👦0123'), 6);
      expect(TextEditingActionTarget.nextCharacter(6, '0123👨👩👦0123'), 8);
      expect(TextEditingActionTarget.nextCharacter(7, '0123👨👩👦0123'), 8);
      expect(TextEditingActionTarget.nextCharacter(8, '0123👨👩👦0123'), 10);
      expect(TextEditingActionTarget.nextCharacter(9, '0123👨👩👦0123'), 10);
      expect(TextEditingActionTarget.nextCharacter(10, '0123👨👩👦0123'), 11);
    });

    test('handles extended grapheme clusters correctly', () {
      expect(TextEditingActionTarget.nextCharacter(3, '0123👨‍👩‍👦2345'), 4);
      expect(TextEditingActionTarget.nextCharacter(4, '0123👨‍👩‍👦2345'), 12);
      // Even when extent falls within an extended grapheme cluster, it still
      // identifies the whole grapheme cluster.
      expect(TextEditingActionTarget.nextCharacter(5, '0123👨‍👩‍👦2345'), 12);
      expect(TextEditingActionTarget.nextCharacter(12, '0123👨‍👩‍👦2345'), 13);
    });
  });

  group('previousCharacter', () {
    test('handles normal strings correctly', () {
      expect(TextEditingActionTarget.previousCharacter(8, '01234567'), 7);
      expect(TextEditingActionTarget.previousCharacter(0, '01234567'), 0);
      expect(TextEditingActionTarget.previousCharacter(1, '01234567'), 0);
      expect(TextEditingActionTarget.previousCharacter(5, '01234567'), 4);
      expect(TextEditingActionTarget.previousCharacter(8, '01234567'), 7);
    });

    test('throws for invalid indices', () {
      expect(() => TextEditingActionTarget.previousCharacter(-1, '01234567'), throwsAssertionError);
      expect(() => TextEditingActionTarget.previousCharacter(9, '01234567'), throwsAssertionError);
    });

    test('skips spaces in normal strings when includeWhitespace is false', () {
      expect(TextEditingActionTarget.previousCharacter(5, '0123 0123', false), 3);
      expect(TextEditingActionTarget.previousCharacter(10, '0123      0123', false), 3);
      expect(TextEditingActionTarget.previousCharacter(11, '0123      0123', false), 10);
      expect(TextEditingActionTarget.previousCharacter(9, '0123      0123', false), 3);
      expect(TextEditingActionTarget.previousCharacter(4, '0123      0123', false), 3);
      expect(TextEditingActionTarget.previousCharacter(3, '0123      0123', false), 2);
      // If the previous characters are all whitespace, it returns zero.
      expect(TextEditingActionTarget.previousCharacter(3, '          0123', false), 0);
    });

    test('handles surrogate pairs correctly', () {
      expect(TextEditingActionTarget.previousCharacter(11, '0123👨👩👦0123'), 10);
      expect(TextEditingActionTarget.previousCharacter(10, '0123👨👩👦0123'), 8);
      expect(TextEditingActionTarget.previousCharacter(9, '0123👨👩👦0123'), 8);
      expect(TextEditingActionTarget.previousCharacter(8, '0123👨👩👦0123'), 6);
      expect(TextEditingActionTarget.previousCharacter(7, '0123👨👩👦0123'), 6);
      expect(TextEditingActionTarget.previousCharacter(6, '0123👨👩👦0123'), 4);
      expect(TextEditingActionTarget.previousCharacter(5, '0123👨👩👦0123'), 4);
      expect(TextEditingActionTarget.previousCharacter(4, '0123👨👩👦0123'), 3);
      expect(TextEditingActionTarget.previousCharacter(3, '0123👨👩👦0123'), 2);
    });

    test('handles extended grapheme clusters correctly', () {
      expect(TextEditingActionTarget.previousCharacter(13, '0123👨‍👩‍👦2345'), 12);
      // Even when extent falls within an extended grapheme cluster, it still
      // identifies the whole grapheme cluster.
      expect(TextEditingActionTarget.previousCharacter(12, '0123👨‍👩‍👦2345'), 4);
      expect(TextEditingActionTarget.previousCharacter(11, '0123👨‍👩‍👦2345'), 4);
      expect(TextEditingActionTarget.previousCharacter(5, '0123👨‍👩‍👦2345'), 4);
      expect(TextEditingActionTarget.previousCharacter(4, '0123👨‍👩‍👦2345'), 3);
    });
  });
}
