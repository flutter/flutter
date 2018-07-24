// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Class name constants which correspond to the class names used by the
/// Android AccessibilityBridge.
class AndroidClassName {
  /// The class name used for checkboxes.
  static const String checkBox = 'android.widget.CheckBox';

  /// The default className if none is provided by flutter.
  static const String view = 'android.view.View';

  /// The class name used for radio buttons.
  static const String radio = 'android.widget.RadioButton';

  /// The class name used for editable text fields.
  static const String editText = 'android.widget.EditText';

  /// The class name used for read only text fields.
  static const String textView = 'android.widget.TextView';
}

/// Action constants which correspond to `AccessibilityAction` in Android.
@immutable
class AndroidSemanticsAction {
  const AndroidSemanticsAction._(this.id);

  /// The Android id of the action.
  final int id;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    final AndroidSemanticsAction typedOther = other;
    return id == typedOther.id;
  }

  /// Matches `AccessibilityAction.ACTION_FOCUS`.
  static const AndroidSemanticsAction focus = AndroidSemanticsAction._(0x1);

  /// Matches `AccessibilityAction.ACTION_CLEAR_FOCUS`.
  static const AndroidSemanticsAction clearFocus = AndroidSemanticsAction._(0x2);

  /// Matches `AccessibilityAction.ACTION_SELECT`.
  static const AndroidSemanticsAction select = AndroidSemanticsAction._(0x4);

  /// Matches `AccessibilityAction.ACTION_CLEAR_SELECTION`.
  static const AndroidSemanticsAction clearSelection = AndroidSemanticsAction._(0x8);

  /// Matches `AccessibilityAction.ACTION_CLICK`.
  static const AndroidSemanticsAction click = AndroidSemanticsAction._(0x10);

  /// Matches `AccessibilityAction.ACTION_LONG_CLICK`.
  static const AndroidSemanticsAction longClick = AndroidSemanticsAction._(0x20);

  /// Matches `AccessibilityAction.ACTION_ACCESSIBILITY_FOCUS`.
  static const AndroidSemanticsAction accessibilityFocus = AndroidSemanticsAction._(0x40);

  /// Matches `AccessibilityAction.ACTION_CLEAR_ACCESSIBILITY_FOCUS`.
  static const AndroidSemanticsAction clearAccessibilityFocus = AndroidSemanticsAction._(0x80);

  /// Matches `AccessibilityAction.ACTION_NEXT_AT_MOVEMENT_GRANULARITY`.
  static const AndroidSemanticsAction nextAtMovementGranularity = AndroidSemanticsAction._(0x100);

  /// Matches `AccessibilityAction.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY`.
  static const AndroidSemanticsAction previousAtMovementGranularity = AndroidSemanticsAction._(0x200);

  /// Matches `AccessibilityAction.ACTION_NEXT_HTML_ELEMENT`.
  static const AndroidSemanticsAction nextHtmlElement = AndroidSemanticsAction._(0x400);

  /// Matches `AccessibilityAction.ACTION_PREVIOUS_HTML_ELEMENT`.
  static const AndroidSemanticsAction previousHtmlElement = AndroidSemanticsAction._(0x800);

  /// Matches `AccessibilityAction.ACTION_SCROLL_FORWARD`.
  static const AndroidSemanticsAction scrollForward = AndroidSemanticsAction._(0x1000);

  /// Matches `AccessibilityAction.ACTION_SCROLL_BACKWARD`.
  static const AndroidSemanticsAction scrollBackward = AndroidSemanticsAction._(0x2000);

  /// Matches `AccessibilityAction.ACTION_CUT`.
  static const AndroidSemanticsAction cut = AndroidSemanticsAction._(0x4000);

  /// Matches `AccessibilityAction.ACTION_COPY`.
  static const AndroidSemanticsAction copy = AndroidSemanticsAction._(0x8000);

  /// Matches `AccessibilityAction.ACTION_PASTE`.
  static const AndroidSemanticsAction paste = AndroidSemanticsAction._(0x10000);

  /// Matches `AccessibilityAction.ACTION_SET_SELECTION`.
  static const AndroidSemanticsAction setSelection = AndroidSemanticsAction._(0x20000);

  /// Matches `AccessibilityAction.ACTION_EXPAND`.
  static const AndroidSemanticsAction expand = AndroidSemanticsAction._(0x40000);

  /// Matches `AccessibilityAction.ACTION_COLLAPSE`.
  static const AndroidSemanticsAction collapse = AndroidSemanticsAction._(0x80000);

  @override
  String toString() {
    switch (id) {
      case 0x1:
        return 'AndroidSemanticsAction.focus';
      case 0x2:
        return 'AndroidSemanticsAction.clearFoucs';
      case 0x4:
        return 'AndroidSemanticsAction.select';
      case 0x8:
        return 'AndroidSemanticsAction.clearSelection';
      case 0x10:
        return 'AndroidSemanticsAction.click';
      case 0x20:
        return 'AndroidSemanticsAction.longClick';
      case 0x40:
        return 'AndroidSemanticsAction.accessibilityFocus';
      case 0x80:
        return 'AndroidSemanticsAction.clearAccessibilityFocus';
      case 0x100:
        return 'AndroidSemanticsAction.nextAtMovementGranularity';
      case 0x200:
        return 'AndroidSemanticsAction.previousAtMovementGranularity';
      case 0x400:
        return 'AndroidSemanticsAction.nextHtmlElement';
      case 0x800:
        return 'AndroidSemanticsAction.previousHtmlElement';
      case 0x1000:
        return 'AndroidSemanticsAction.scrollForward';
      case 0x2000:
        return 'AndroidSemanticsAction.scrollBackward';
      case 0x4000:
        return 'AndroidSemanticsAction.cut';
      case 0x8000:
        return 'AndroidSemanticsAction.copy';
      case 0x10000:
        return 'AndroidSemanticsAction.paste';
      case 0x20000:
        return 'AndroidSemanticsAction.setSelection';
      case 0x40000:
        return 'AndroidSemanticsAction.expand';
      case 0x80000:
        return 'AndroidSemanticsAction.collapse';
      default:
        throw new UnsupportedError('Unknown semantics action: $id');
    }
  }

  /// Creates a new [AndroidSemanticsAction] from an integer [value].
  ///
  /// Throws [UnsupportedError] if the id is not a known Android accessibility
  /// action.s
  static AndroidSemanticsAction deserialize(int value) {
    final AndroidSemanticsAction action = new AndroidSemanticsAction._(value);
    action.toString();
    return action;
  }
}