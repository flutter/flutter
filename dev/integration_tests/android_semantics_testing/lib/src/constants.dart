// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Class name constants which correspond to the class names used by the
/// Android accessibility bridge.
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

  /// The class name used for toggle switches.
  static const String toggleSwitch = 'android.widget.Switch';

  /// The default className for buttons.
  static const String button = 'android.widget.Button';
}

/// Action constants which correspond to `AccessibilityAction` in Android.
@immutable
class AndroidSemanticsAction {
  const AndroidSemanticsAction._(this.id);

  /// The Android id of the action.
  final int id;

  static const int _kFocusIndex = 1 << 0;
  static const int _kClearFocusIndex = 1 << 1;
  static const int _kSelectIndex = 1 << 2;
  static const int _kClearSelectionIndex = 1 << 3;
  static const int _kClickIndex = 1 << 4;
  static const int _kLongClickIndex = 1 << 5;
  static const int _kAccessibilityFocusIndex = 1 << 6;
  static const int _kClearAccessibilityFocusIndex = 1 << 7;
  static const int _kNextAtMovementGranularityIndex = 1 << 8;
  static const int _kPreviousAtMovementGranularityIndex = 1 << 9;
  static const int _kNextHtmlElementIndex = 1 << 10;
  static const int _kPreviousHtmlElementIndex = 1 << 11;
  static const int _kScrollForwardIndex = 1 << 12;
  static const int _kScrollBackwardIndex = 1 << 13;
  static const int _kCutIndex = 1 << 14;
  static const int _kCopyIndex = 1 << 15;
  static const int _kPasteIndex = 1 << 16;
  static const int _kSetSelectionIndex = 1 << 17;
  static const int _kExpandIndex = 1 << 18;
  static const int _kCollapseIndex = 1 << 19;
  static const int _kSetText = 1 << 21;

  /// Matches `AccessibilityAction.ACTION_FOCUS`.
  static const AndroidSemanticsAction focus = AndroidSemanticsAction._(_kFocusIndex);

  /// Matches `AccessibilityAction.ACTION_CLEAR_FOCUS`.
  static const AndroidSemanticsAction clearFocus = AndroidSemanticsAction._(_kClearFocusIndex);

  /// Matches `AccessibilityAction.ACTION_SELECT`.
  static const AndroidSemanticsAction select = AndroidSemanticsAction._(_kSelectIndex);

  /// Matches `AccessibilityAction.ACTION_CLEAR_SELECTION`.
  static const AndroidSemanticsAction clearSelection = AndroidSemanticsAction._(_kClearSelectionIndex);

  /// Matches `AccessibilityAction.ACTION_CLICK`.
  static const AndroidSemanticsAction click = AndroidSemanticsAction._(_kClickIndex);

  /// Matches `AccessibilityAction.ACTION_LONG_CLICK`.
  static const AndroidSemanticsAction longClick = AndroidSemanticsAction._(_kLongClickIndex);

  /// Matches `AccessibilityAction.ACTION_ACCESSIBILITY_FOCUS`.
  static const AndroidSemanticsAction accessibilityFocus = AndroidSemanticsAction._(_kAccessibilityFocusIndex);

  /// Matches `AccessibilityAction.ACTION_CLEAR_ACCESSIBILITY_FOCUS`.
  static const AndroidSemanticsAction clearAccessibilityFocus = AndroidSemanticsAction._(_kClearAccessibilityFocusIndex);

  /// Matches `AccessibilityAction.ACTION_NEXT_AT_MOVEMENT_GRANULARITY`.
  static const AndroidSemanticsAction nextAtMovementGranularity = AndroidSemanticsAction._(_kNextAtMovementGranularityIndex);

  /// Matches `AccessibilityAction.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY`.
  static const AndroidSemanticsAction previousAtMovementGranularity = AndroidSemanticsAction._(_kPreviousAtMovementGranularityIndex);

  /// Matches `AccessibilityAction.ACTION_NEXT_HTML_ELEMENT`.
  static const AndroidSemanticsAction nextHtmlElement = AndroidSemanticsAction._(_kNextHtmlElementIndex);

  /// Matches `AccessibilityAction.ACTION_PREVIOUS_HTML_ELEMENT`.
  static const AndroidSemanticsAction previousHtmlElement = AndroidSemanticsAction._(_kPreviousHtmlElementIndex);

  /// Matches `AccessibilityAction.ACTION_SCROLL_FORWARD`.
  static const AndroidSemanticsAction scrollForward = AndroidSemanticsAction._(_kScrollForwardIndex);

  /// Matches `AccessibilityAction.ACTION_SCROLL_BACKWARD`.
  static const AndroidSemanticsAction scrollBackward = AndroidSemanticsAction._(_kScrollBackwardIndex);

  /// Matches `AccessibilityAction.ACTION_CUT`.
  static const AndroidSemanticsAction cut = AndroidSemanticsAction._(_kCutIndex);

  /// Matches `AccessibilityAction.ACTION_COPY`.
  static const AndroidSemanticsAction copy = AndroidSemanticsAction._(_kCopyIndex);

  /// Matches `AccessibilityAction.ACTION_PASTE`.
  static const AndroidSemanticsAction paste = AndroidSemanticsAction._(_kPasteIndex);

  /// Matches `AccessibilityAction.ACTION_SET_SELECTION`.
  static const AndroidSemanticsAction setSelection = AndroidSemanticsAction._(_kSetSelectionIndex);

  /// Matches `AccessibilityAction.ACTION_EXPAND`.
  static const AndroidSemanticsAction expand = AndroidSemanticsAction._(_kExpandIndex);

  /// Matches `AccessibilityAction.ACTION_COLLAPSE`.
  static const AndroidSemanticsAction collapse = AndroidSemanticsAction._(_kCollapseIndex);

  /// Matches `AccessibilityAction.SET_TEXT`.
  static const AndroidSemanticsAction setText = AndroidSemanticsAction._(_kSetText);

  @override
  String toString() {
    switch (id) {
      case _kFocusIndex:
        return 'AndroidSemanticsAction.focus';
      case _kClearFocusIndex:
        return 'AndroidSemanticsAction.clearFocus';
      case _kSelectIndex:
        return 'AndroidSemanticsAction.select';
      case _kClearSelectionIndex:
        return 'AndroidSemanticsAction.clearSelection';
      case _kClickIndex:
        return 'AndroidSemanticsAction.click';
      case _kLongClickIndex:
        return 'AndroidSemanticsAction.longClick';
      case _kAccessibilityFocusIndex:
        return 'AndroidSemanticsAction.accessibilityFocus';
      case _kClearAccessibilityFocusIndex:
        return 'AndroidSemanticsAction.clearAccessibilityFocus';
      case _kNextAtMovementGranularityIndex:
        return 'AndroidSemanticsAction.nextAtMovementGranularity';
      case _kPreviousAtMovementGranularityIndex:
        return 'AndroidSemanticsAction.previousAtMovementGranularity';
      case _kNextHtmlElementIndex:
        return 'AndroidSemanticsAction.nextHtmlElement';
      case _kPreviousHtmlElementIndex:
        return 'AndroidSemanticsAction.previousHtmlElement';
      case _kScrollForwardIndex:
        return 'AndroidSemanticsAction.scrollForward';
      case _kScrollBackwardIndex:
        return 'AndroidSemanticsAction.scrollBackward';
      case _kCutIndex:
        return 'AndroidSemanticsAction.cut';
      case _kCopyIndex:
        return 'AndroidSemanticsAction.copy';
      case _kPasteIndex:
        return 'AndroidSemanticsAction.paste';
      case _kSetSelectionIndex:
        return 'AndroidSemanticsAction.setSelection';
      case _kExpandIndex:
        return 'AndroidSemanticsAction.expand';
      case _kCollapseIndex:
        return 'AndroidSemanticsAction.collapse';
      case _kSetText:
        return 'AndroidSemanticsAction.setText';
      default:
        return null;
    }
  }

  static const Map<int, AndroidSemanticsAction> _kActionById = <int, AndroidSemanticsAction>{
    _kFocusIndex: focus,
    _kClearFocusIndex: clearFocus,
    _kSelectIndex: select,
    _kClearSelectionIndex: clearSelection,
    _kClickIndex: click,
    _kLongClickIndex: longClick,
    _kAccessibilityFocusIndex: accessibilityFocus,
    _kClearAccessibilityFocusIndex: clearAccessibilityFocus,
    _kNextAtMovementGranularityIndex: nextAtMovementGranularity,
    _kPreviousAtMovementGranularityIndex: previousAtMovementGranularity,
    _kNextHtmlElementIndex: nextHtmlElement,
    _kPreviousHtmlElementIndex: previousHtmlElement,
    _kScrollForwardIndex: scrollForward,
    _kScrollBackwardIndex: scrollBackward,
    _kCutIndex: cut,
    _kCopyIndex: copy,
    _kPasteIndex: paste,
    _kSetSelectionIndex: setSelection,
    _kExpandIndex: expand,
    _kCollapseIndex: collapse,
    _kSetText: setText,
  };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AndroidSemanticsAction
        && other.id == id;
  }

  /// Creates a new [AndroidSemanticsAction] from an integer `value`.
  ///
  /// Returns `null` if the id is not a known Android accessibility action.
  static AndroidSemanticsAction deserialize(int value) {
    return _kActionById[value];
  }
}
