// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';
import 'constants.dart';

/// A semantics node created from Android accessibility information.
///
/// This object represents Android accessibility information derived from an
/// [AccessibilityNodeInfo](https://developer.android.com/reference/android/view/accessibility/AccessibilityNodeInfo)
/// object. The purpose is to verify in integration
/// tests that our semantics framework produces the correct accessibility info
/// on Android.
///
/// See also:
///
///   * [AccessibilityNodeInfo](https://developer.android.com/reference/android/view/accessibility/AccessibilityNodeInfo)
class AndroidSemanticsNode  {
  AndroidSemanticsNode._(this._values);

  /// Deserializes a new [AndroidSemanticsNode] from a json map.
  ///
  /// The structure of the JSON:
  ///
  ///     {
  ///       "flags": {
  ///         "isChecked": bool,
  ///         "isCheckable": bool,
  ///         "isEditable": bool,
  ///         "isEnabled": bool,
  ///         "isFocusable": bool,
  ///         "isFocused": bool,
  ///         "isPassword": bool,
  ///         "isLongClickable": bool,
  ///       },
  ///       "text": String,
  ///       "contentDescription": String,
  ///       "className": String,
  ///       "id": int,
  ///       "rect": {
  ///         left: int,
  ///         top: int,
  ///         right: int,
  ///         bottom: int,
  ///       },
  ///       actions: [
  ///         int,
  ///       ]
  ///     }
  factory AndroidSemanticsNode.deserialize(String value) {
    return AndroidSemanticsNode._(json.decode(value));
  }

  final Map<String, Object> _values;
  final List<AndroidSemanticsNode> _children = <AndroidSemanticsNode>[];

  Map<String, Object> get _flags => _values['flags'];

  /// The text value of the semantics node.
  ///
  /// This is produced by combining the value, label, and hint fields from
  /// the Flutter [SemanticsNode].
  String get text => _values['text'];

  /// The contentDescription of the semantics node.
  ///
  /// This field is used for the Switch, Radio, and Checkbox widgets
  /// instead of [text]. If the text property is used for these, TalkBack
  /// will not read out the "checked" or "not checked" label by default.
  ///
  /// This is produced by combining the value, label, and hint fields from
  /// the Flutter [SemanticsNode].
  String get contentDescription => _values['contentDescription'];

  /// The className of the semantics node.
  ///
  /// Certain kinds of Flutter semantics are mapped to Android classes to
  /// use their default semantic behavior, such as checkboxes and images.
  ///
  /// If a more specific value isn't provided, it defaults to
  /// "android.view.View".
  String get className => _values['className'];

  /// The identifier for this semantics node.
  int get id => _values['id'];

  /// The children of this semantics node.
  List<AndroidSemanticsNode> get children => _children;

  /// Whether the node is currently in a checked state.
  ///
  /// Equivalent to [SemanticsFlag.isChecked].
  bool get isChecked => _flags['isChecked'];

  /// Whether the node can be in a checked state.
  ///
  /// Equivalent to [SemanticsFlag.hasCheckedState]
  bool get isCheckable => _flags['isCheckable'];

  /// Whether the node is editable.
  ///
  /// This is usually only applied to text fields, which map
  /// to "android.widget.EditText".
  bool get isEditable => _flags['isEditable'];

  /// Whether the node is enabled.
  bool get isEnabled => _flags['isEnabled'];

  /// Whether the node is focusable.
  bool get isFocusable => _flags['isFocusable'];

  /// Whether the node is focused.
  bool get isFocused => _flags['isFocused'];

  /// Whether the node represents a password field.
  ///
  /// Equivalent to [SemanticsFlag.isObscured].
  bool get isPassword => _flags['isPassword'];

  /// Whether the node is long clickable.
  ///
  /// Equivalent to having [SemanticsAction.longPress].
  bool get isLongClickable => _flags['isLongClickable'];

  /// Gets a [Rect] which defines the position and size of the semantics node.
  Rect getRect() {
    final Map<String, Object> rawRect = _values['rect'];
    final Map<String, int> rect = rawRect.cast<String, int>();
    return Rect.fromLTRB(
      rect['left'].toDouble(),
      rect['top'].toDouble(),
      rect['right'].toDouble(),
      rect['bottom'].toDouble(),
    );
  }

  /// Gets a [Size] which defines the size of the semantics node.
  Size getSize() {
    final Rect rect = getRect();
    return Size(rect.bottom - rect.top, rect.right - rect.left);
  }

  /// Gets a list of [AndroidSemanticsActions] which are defined for the node.
  List<AndroidSemanticsAction> getActions() {
    final List<AndroidSemanticsAction> result = <AndroidSemanticsAction>[];
    for (int id in _values['actions']) {
      result.add(AndroidSemanticsAction.deserialize(id));
    }
    return result;
  }

  @override
  String toString() {
    return _values.toString();
  }
}


/// A Dart VM implementation of a rectangle.
///
/// Created to mirror the implementation of [ui.Rect].
@immutable
class Rect {
  /// Creates a new rectangle.
  ///
  /// All values are required.
  const Rect.fromLTRB(this.left, this.top, this.right, this.bottom);

  /// The top side of the rectangle.
  final double top;

  /// The left side of the rectangle.
  final double left;

  /// The right side of the rectangle.
  final double right;

  /// The bottom side of the rectangle.
  final double bottom;

  @override
  int get hashCode =>
      top.hashCode ^ left.hashCode ^ right.hashCode ^ bottom.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    final Rect typedOther = other;
    return typedOther.top == top &&
        typedOther.left == left &&
        typedOther.right == right &&
        typedOther.bottom == bottom;
  }

  @override
  String toString() => 'Rect.fromLTRB($left, $top, $right, $bottom)';
}

/// A Dart VM implementation of a Size.
///
/// Created to mirror the implementation [ui.Size].
@immutable
class Size {
  /// Creates a new [Size] object.
  const Size(this.width, this.height);

  /// The width of some object.
  final double width;

  /// The height of some object.
  final double height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    final Size typedOther = other;
    return typedOther.width == width && typedOther.height == height;
  }

  @override
  String toString() => 'Size{$width, $height}';
}
