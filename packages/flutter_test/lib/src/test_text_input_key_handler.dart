// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'binding.dart';

/// Processes text input events that were not handled by the framework.
abstract class TestTextInputKeyHandler {
  /// Process key down event that was not handled by the framework.
  Future<void> handleKeyDownEvent(LogicalKeyboardKey key);

  /// Process key up event that was not handled by the framework.
  Future<void> handleKeyUpEvent(LogicalKeyboardKey key);
}

/// MacOS specific key input handler
class MacOSTestTextInputKeyHandler extends TestTextInputKeyHandler {
  /// Create a new macOS specific text input handler.
  MacOSTestTextInputKeyHandler(this.client);

  /// ClientId of TextInput
  final int client;

  Future<void> _sendSelector(String selector) async {
    await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall('TextInputClient.performSelector', <dynamic>[client, selector]),
      ),
      (ByteData? data) {/* response from framework is discarded */},
    );
  }

  // These combination must match NSStandardKeyBindingResponding
  static final Map<SingleActivator, String> _macOSActivatorToSelector = <SingleActivator, String>{
    for (final bool pressShift in const <bool>[true, false]) ...<SingleActivator, String>{
      SingleActivator(LogicalKeyboardKey.backspace, shift: pressShift): 'deleteBackward:',
      SingleActivator(LogicalKeyboardKey.backspace, alt: true, shift: pressShift): 'deleteWordBackward:',
      SingleActivator(LogicalKeyboardKey.backspace, meta: true, shift: pressShift): 'deleteToBeginningOfLine:',
      SingleActivator(LogicalKeyboardKey.delete, shift: pressShift): 'deleteForward:',
      SingleActivator(LogicalKeyboardKey.delete, alt: true, shift: pressShift): 'deleteWordForward:',
      SingleActivator(LogicalKeyboardKey.delete, meta: true, shift: pressShift): 'deleteToEndOfLine:',
    },
    const SingleActivator(LogicalKeyboardKey.arrowLeft): 'moveLeft:',
    const SingleActivator(LogicalKeyboardKey.arrowRight): 'moveRight:',
    const SingleActivator(LogicalKeyboardKey.arrowUp): 'moveUp:',
    const SingleActivator(LogicalKeyboardKey.arrowDown): 'moveDown:',
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): 'moveLeftAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): 'moveRightAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): 'moveUpAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): 'moveDownAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): 'moveWordLeft:',
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): 'moveWordRight:',
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): 'moveToBeginningOfParagraph:',
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): 'moveToEndOfParagraph:',
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true, shift: true): 'moveWordLeftAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true, shift: true): 'moveWordRightAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true, shift: true): 'moveParagraphBackwardAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true, shift: true): 'moveParagraphForwardAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true): 'moveToLeftEndOfLine:',
    const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true): 'moveToRightEndOfLine:',
    const SingleActivator(LogicalKeyboardKey.arrowUp, meta: true): 'moveToBeginningOfDocument:',
    const SingleActivator(LogicalKeyboardKey.arrowDown, meta: true): 'moveToEndOfDocument:',
    const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true, shift: true): 'moveToLeftEndOfLineAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true, shift: true): 'moveToRightEndOfLineAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowUp, meta: true, shift: true): 'moveToBeginningOfDocumentAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.arrowDown, meta: true, shift: true): 'moveToEndOfDocumentAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.keyA, control: true, shift: true): 'moveToBeginningOfParagraphAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.keyA, control: true): 'moveToBeginningOfParagraph:',
    const SingleActivator(LogicalKeyboardKey.keyB, control: true, shift: true): 'moveBackwardAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.keyB, control: true): 'moveBackward:',
    const SingleActivator(LogicalKeyboardKey.keyE, control: true, shift: true): 'moveToEndOfParagraphAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.keyE, control: true): 'moveToEndOfParagraph:',
    const SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true): 'moveForwardAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.keyF, control: true): 'moveForward:',
    const SingleActivator(LogicalKeyboardKey.keyK, control: true): 'deleteToEndOfParagraph',
    const SingleActivator(LogicalKeyboardKey.keyL, control: true): 'centerSelectionInVisibleArea',
    const SingleActivator(LogicalKeyboardKey.keyN, control: true): 'moveDown:',
    const SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true): 'moveDownAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.keyO, control: true): 'insertNewlineIgnoringFieldEditor:',
    const SingleActivator(LogicalKeyboardKey.keyP, control: true): 'moveUp:',
    const SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true): 'moveUpAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.keyT, control: true): 'transpose:',
    const SingleActivator(LogicalKeyboardKey.keyV, control: true): 'pageDown:',
    const SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true): 'pageDownAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.keyY, control: true): 'yank:',
    const SingleActivator(LogicalKeyboardKey.quoteSingle, control: true): 'insertSingleQuoteIgnoringSubstitution:',
    const SingleActivator(LogicalKeyboardKey.quote, control: true): 'insertDoubleQuoteIgnoringSubstitution:',
    const SingleActivator(LogicalKeyboardKey.home): 'scrollToBeginningOfDocument:',
    const SingleActivator(LogicalKeyboardKey.end): 'scrollToEndOfDocument:',
    const SingleActivator(LogicalKeyboardKey.home, shift: true): 'moveToBeginningOfDocumentAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.end, shift: true): 'moveToEndOfDocumentAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.pageUp): 'scrollPageUp:',
    const SingleActivator(LogicalKeyboardKey.pageDown): 'scrollPageDown:',
    const SingleActivator(LogicalKeyboardKey.pageUp, shift: true): 'pageUpAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.pageDown, shift: true): 'pageDownAndModifySelection:',
    const SingleActivator(LogicalKeyboardKey.escape): 'cancelOperation:',
    const SingleActivator(LogicalKeyboardKey.enter): 'insertNewline:',
    const SingleActivator(LogicalKeyboardKey.enter, alt: true): 'insertNewlineIgnoringFieldEditor:',
    const SingleActivator(LogicalKeyboardKey.enter, control: true): 'insertLineBreak:',
    const SingleActivator(LogicalKeyboardKey.tab): 'insertTab:',
    const SingleActivator(LogicalKeyboardKey.tab, alt: true): 'insertTabIgnoringFieldEditor:',
    const SingleActivator(LogicalKeyboardKey.tab, shift: true): 'insertBacktab:',
  };

  @override
  Future<void> handleKeyDownEvent(LogicalKeyboardKey key) async {
    if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      _shift = true;
    } else if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      _alt = true;
    } else if (key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      _meta = true;
    } else {
      for (final MapEntry<SingleActivator, String> entry in _macOSActivatorToSelector.entries) {
        final SingleActivator activator = entry.key;
        if (activator.triggers.first == key &&
            activator.shift == _shift &&
            activator.alt == _alt &&
            activator.meta == _meta) {
          final String selector = entry.value;
          await _sendSelector(selector);
          return;
        }
      }
    }
  }

  @override
  Future<void> handleKeyUpEvent(LogicalKeyboardKey key) async {
    if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      _shift = false;
    } else if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      _alt = false;
    } else if (key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      _meta = false;
    }
  }

  bool _shift = false;
  bool _alt = false;
  bool _meta = false;
}
