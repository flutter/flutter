// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

/// A [TextInputFormatter] can be optionally injected into an [EditableText] 
/// to provide as-you-type validation and formatting of the text being edited.
/// 
/// Text modification should only be applied when text is being committed by the
/// IME and not on text under composition (i.e. when 
/// [TextEditingValue.composing] is collapsed). 
/// 
/// A concrete [BlacklistingTextInputFormatter] which removes blacklisted 
/// characters upon edit commit is provided. 
/// 
/// To create custom formatters, extend the [TextInputFormatter] class and 
/// implement the [formatEditUpdate] method.
/// 
/// See also:
///  
///  * [EditableText] on which the formatting apply.
///  * [BlacklistingTextInputFormatter], a provided formatter for blacklisting
///    characters.
abstract class TextInputFormatter {
  /// Called when text is being typed or cut/copy/pasted in the [EditableText].
  /// 
  /// You can override the resulting text based on the previous text value and
  /// the incoming new text value.
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, 
    TextEditingValue newValue
  );
}

/// A [TextInputFormatter] that prevents the insertion of blacklisted.
/// 
/// Instances of blacklisted characters found in the new [TextEditingValue]s 
/// will be replaced with the [replacementString] which defaults to ``.
/// 
/// It attempts to preserve the existing [TextEditingValue.selection] to 
/// sensible values. 
/// 
/// See also:
///  
///  * [TextInputFormatter].
class BlacklistingTextInputFormatter extends TextInputFormatter {
  BlacklistingTextInputFormatter(
    this.blacklistedPattern, 
    {this.replacementString: ''}) : 
    assert(blacklistedPattern != null);

  /// A [Pattern] to match and replace incoming [TextEditingValue]s.
  final Pattern blacklistedPattern;
  /// String used to replace found patterns.
  final String replacementString;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, 
    TextEditingValue newValue
  ) {
    // Don't apply formatting to text still under composition.
    if (!newValue.composing.isCollapsed)
      return newValue;
    final int selectionStartIndex = newValue.selection.start;
    final int selectionEndIndex = newValue.selection.end;
    if (selectionStartIndex < 0 || selectionEndIndex < 0) {
      return new TextEditingValue(
        text: newValue.text.replaceAll(blacklistedPattern, replacementString),
        selection: const TextSelection.collapsed(offset: -1), 
        composing: TextRange.empty,
      );
    } else {
      final String beforeSelection = newValue.text
          .substring(0, selectionStartIndex)
          .replaceAll(blacklistedPattern, replacementString);
      final String inSelection = newValue.text
          .substring(selectionStartIndex, selectionEndIndex)
          .replaceAll(blacklistedPattern, replacementString);
      final String afterSelection = newValue.text
          .substring(selectionEndIndex)
          .replaceAll(blacklistedPattern, replacementString);
      return new TextEditingValue(
        text: beforeSelection + inSelection + afterSelection,
        selection: newValue.selection.copyWith(
          baseOffset: beforeSelection.length,
          extentOffset: beforeSelection.length + inSelection.length,
        ),
        composing: TextRange.empty,
      );
    }
  }

  /// A [BlacklistingTextInputFormatter] that forces input to be a single line.
  static final BlacklistingTextInputFormatter singleLineFormatter
      = new BlacklistingTextInputFormatter(new RegExp(r'\n'));
}
