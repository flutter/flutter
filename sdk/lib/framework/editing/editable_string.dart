// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library editing_editable_string;

import 'package:mojom/keyboard/keyboard.mojom.dart';

typedef void StringUpdated();

class TextRange {
  final int start;
  final int end;

  TextRange({this.start, this.end});
  TextRange.collapsed(int position)
      : start = position,
        end = position;
  const TextRange.empty()
      : start = -1,
        end = -1;

  bool get isValid => start >= 0 && end >= 0;
  bool get isCollapsed => start == end;
}

class EditableString implements KeyboardClient {
  String text;
  TextRange composing = const TextRange.empty();
  TextRange selection = const TextRange.empty();

  final StringUpdated onUpdated;

  KeyboardClientStub stub;

  EditableString({this.text: '', this.onUpdated}) {
    stub = new KeyboardClientStub.unbound()..impl = this;
  }

  String textBefore(TextRange range) {
    return text.substring(0, range.start);
  }

  String textAfter(TextRange range) {
    return text.substring(range.end);
  }

  String textInside(TextRange range) {
    return text.substring(range.start, range.end);
  }

  void _delete(TextRange range) {
    if (range.isCollapsed || !range.isValid) return;
    text = textBefore(range) + textAfter(range);
  }

  TextRange _append(String newText) {
    int start = text.length;
    text += newText;
    return new TextRange(start: start, end: start + newText.length);
  }

  TextRange _replace(TextRange range, String newText) {
    assert(range.isValid);

    String before = textBefore(range);
    String after = textAfter(range);

    text = before + newText + after;
    return new TextRange(
        start: before.length, end: before.length + newText.length);
  }

  TextRange _replaceOrAppend(TextRange range, String newText) {
    if (!range.isValid) return _append(newText);
    return _replace(range, newText);
  }

  void commitCompletion(CompletionData completion) {
    // TODO(abarth): Not implemented.
  }

  void commitCorrection(CorrectionData correction) {
    // TODO(abarth): Not implemented.
  }

  void commitText(String text, int newCursorPosition) {
    // TODO(abarth): Why is |newCursorPosition| always 1?
    TextRange committedRange = _replaceOrAppend(composing, text);
    selection = new TextRange.collapsed(committedRange.end);
    composing = const TextRange.empty();
    onUpdated();
  }

  void deleteSurroundingText(int beforeLength, int afterLength) {
    TextRange beforeRange = new TextRange(
        start: selection.start - beforeLength, end: selection.start);
    TextRange afterRange =
        new TextRange(start: selection.end, end: selection.end + afterLength);
    _delete(afterRange);
    _delete(beforeRange);
    selection = new TextRange(
        start: selection.start - beforeLength,
        end: selection.end - beforeLength);
    onUpdated();
  }

  void setComposingRegion(int start, int end) {
    composing = new TextRange(start: start, end: end);
    onUpdated();
  }

  void setComposingText(String text, int newCursorPosition) {
    // TODO(abarth): Why is |newCursorPosition| always 1?
    composing = _replaceOrAppend(composing, text);
    selection = new TextRange.collapsed(composing.end);
    onUpdated();
  }

  void setSelection(int start, int end) {
    selection = new TextRange(start: start, end: end);
    onUpdated();
  }
}
