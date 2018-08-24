// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';


/// ClassName constants used by Flutter semantics.
class AndroidClassName {
  /// A checkbox widget.
  static const String checkBox = 'android.widget.CheckBox';

  /// The default className if none is provided by flutter.
  static const String view = 'android.view.View';

  /// A radio widget.
  static const String radio = 'android.widget.RadioButton';

  /// An editable text widget.
  static const String editText = 'android.widget.EditText';

  /// A read-only text widget.
  static const String textView = 'android.widget.TextView';
}

/// Action constants Taken from [AccessibilityAction].
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

  /// Taken from [AccessibilityAction.ACTION_FOCUS].
  static const AndroidSemanticsAction focus =
      const AndroidSemanticsAction._(0x1);

  /// Taken from [AccessibilityAction.ACTION_CLEAR_FOCUS].
  static const AndroidSemanticsAction clearFocus =
      const AndroidSemanticsAction._(0x2);

  /// Taken from [AccessibilityAction.ACTION_SELECT].
  static const AndroidSemanticsAction select =
      const AndroidSemanticsAction._(0x4);

  /// Taken from [AccessibilityAction.ACTION_CLEAR_SELECTION].
  static const AndroidSemanticsAction clearSelection =
      const AndroidSemanticsAction._(0x8);

  /// Taken from [AccessibilityAction.ACTION_CLICK].
  static const AndroidSemanticsAction click =
      const AndroidSemanticsAction._(0x10);

  /// Taken from [AccessibilityAction.ACTION_LONG_CLICK].
  static const AndroidSemanticsAction longClick =
      const AndroidSemanticsAction._(0x20);

  /// Taken from [AccessibilityAction.ACTION_ACCESSIBILITY_FOCUS].
  static const AndroidSemanticsAction accessibilityFocus =
      const AndroidSemanticsAction._(0x40);

  /// Taken from [AccessibilityAction.ACTION_CLEAR_ACCESSIBILITY_FOCUS].
  static const AndroidSemanticsAction clearAccessibilityFocus =
      const AndroidSemanticsAction._(0x80);

  /// Taken from [AccessibilityAction.ACTION_NEXT_AT_MOVEMENT_GRANULARITY].
  static const AndroidSemanticsAction nextAtMovementGranularity =
      const AndroidSemanticsAction._(0x100);

  /// Taken from [AccessibilityAction.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY].
  static const AndroidSemanticsAction previousAtMovementGranularity =
      const AndroidSemanticsAction._(0x200);

  /// Taken from [AccessibilityAction.ACTION_NEXT_HTML_ELEMENT].
  static const AndroidSemanticsAction nextHtmlElement =
      const AndroidSemanticsAction._(0x400);

  /// Taken from [AccessibilityAction.ACTION_PREVIOUS_HTML_ELEMENT].
  static const AndroidSemanticsAction previousHtmlElement =
      const AndroidSemanticsAction._(0x800);

  /// Taken from [AccessibilityAction.ACTION_SCROLL_FORWARD].
  static const AndroidSemanticsAction scrollForward =
      const AndroidSemanticsAction._(0x1000);

  /// Taken from [AccessibilityAction.ACTION_SCROLL_BACKWARD].
  static const AndroidSemanticsAction scrollBackward =
      const AndroidSemanticsAction._(0x2000);

  /// Taken from [AccessibilityAction.ACTION_CUT].
  static const AndroidSemanticsAction cut =
      const AndroidSemanticsAction._(0x4000);

  /// Taken from [AccessibilityAction.ACTION_COPY].
  static const AndroidSemanticsAction copy =
      const AndroidSemanticsAction._(0x8000);

  /// Taken from [AccessibilityAction.ACTION_PASTE].
  static const AndroidSemanticsAction paste =
      const AndroidSemanticsAction._(0x10000);

  /// Taken from [AccessibilityAction.ACTION_SET_SELECTION].
  static const AndroidSemanticsAction setSelection =
      const AndroidSemanticsAction._(0x20000);

  /// Taken from [AccessibilityAction.ACTION_EXPANwD].
  static const AndroidSemanticsAction expand =
      const AndroidSemanticsAction._(0x40000);

  /// Taken from [AccessibilityAction.ACTION_COLLAPSE].
  static const AndroidSemanticsAction collapse =
      const AndroidSemanticsAction._(0x80000);

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
        return 'AndroidSemanticsAction.unknown';
    }
  }
}

/// A semantics node created from Android accessibility information.
///
/// See also:
///
///   * [AccessibilityNodeInfo](https://developer.android.com/reference/android/view/accessibility/AccessibilityNodeInfo)
class AndroidSemanticsNode  {
  /// Creates a new [AndroidSemanticsNode] from a json map.
  AndroidSemanticsNode(this._values);

  factory AndroidSemanticsNode.deserialize(String value) {
    return new AndroidSemanticsNode(json.decode(value));
  }

  final Map<String, Object> _values;
  final List<AndroidSemanticsNode> _children = <AndroidSemanticsNode>[];

  Map<String, Object> get _flags => _values['flags'];

  void addChild(AndroidSemanticsNode child) => _children.add(child);

  /// The text value of the semantics node.
  ///
  /// This is produced by combining the value, label, and hint fields from
  /// the Flutter [SemanticsNode].
  String get text => _values['text'];

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
  /// Equivalent to having [SemanticsAction.longPress]/
  bool get isLongClickable => _flags['isLongClickable'];

  /// Gets a [Rect] which defines the position and size of the semantics node.
  Rect getRect() {
    final Map<String, int> rect = _values['rect'];
    return new Rect.fromLTRB(
      rect['left'].toDouble(),
      rect['top'].toDouble(),
      rect['right'].toDouble(),
      rect['bottom'].toDouble(),
    );
  }

  /// Gets a [Size] which defines the size of the semantics node.
  Size getSize() {
    final Rect rect = getRect();
    return new Size(rect.bottom - rect.top, rect.right - rect.left);
  }

  /// Gets a list of [AndroidSemanticsActions] which are defined for the node.
  List<AndroidSemanticsAction> getActions() {
    final List<AndroidSemanticsAction> result = <AndroidSemanticsAction>[];
    for (int id in _values['actions']) {
      result.add(new AndroidSemanticsAction._(id));
    }
    return result;
  }

  @override
  String toString() {
    return _values.toString();
  }
}

/// Matches an [AndroidSemanticsNode].
///
/// Any properties which aren't supplied are ignored during the comparison.
Matcher hasAndroidSemantics({
  String text,
  String className,
  int id,
  Rect rect,
  Size size,
  List<AndroidSemanticsAction> actions,
  List<AndroidSemanticsNode> children,
  bool isChecked,
  bool isCheckable,
  bool isEditable,
  bool isEnabled,
  bool isFocusable,
  bool isFocused,
  bool isPassword,
  bool isLongClickable,
}) =>
    new _AndroidSemanticsMatcher(
      text: text,
      className: className,
      rect: rect,
      size: size,
      id: id,
      actions: actions,
      isChecked: isChecked,
      isCheckable: isCheckable,
      isEditable: isEditable,
      isEnabled: isEnabled,
      isFocusable: isFocusable,
      isFocused: isFocused,
      isPassword: isPassword,
      isLongClickable: isLongClickable,
    );

class _AndroidSemanticsMatcher extends Matcher {
  _AndroidSemanticsMatcher({
    this.text,
    this.className,
    this.id,
    this.actions,
    this.rect,
    this.size,
    this.isChecked,
    this.isCheckable,
    this.isEnabled,
    this.isEditable,
    this.isFocusable,
    this.isFocused,
    this.isPassword,
    this.isLongClickable,
  });

  final String text;
  final String className;
  final int id;
  final List<AndroidSemanticsAction> actions;
  final Rect rect;
  final Size size;
  final bool isChecked;
  final bool isCheckable;
  final bool isEditable;
  final bool isEnabled;
  final bool isFocusable;
  final bool isFocused;
  final bool isPassword;
  final bool isLongClickable;

  @override
  Description describe(Description description) {
    description.add('AndroidSemanticsNode');
    if (text != null)
      description.add(' with text: $text');
    if (className != null)
      description.add(' with className: $className');
    if (id != null)
      description.add(' with id: $id');
    if (actions != null)
      description.add(' with actions: $actions');
    if (rect != null)
      description.add(' with rect: $rect');
    if (size != null)
      description.add(' with size: $size');
    if (isChecked != null)
      description.add(' with flag isChecked: $isChecked');
    if (isEditable != null)
      description.add(' with flag isEditable: $isEditable');
    if (isEnabled != null)
      description.add(' with flag isEnabled: $isEnabled');
    if (isFocusable != null)
      description.add(' with flag isFocusable: $isFocusable');
    if (isFocused != null)
      description.add(' with flag isFocused: $isFocused');
    if (isPassword != null)
      description.add(' with flag isPassword: $isPassword');
    if (isLongClickable != null)
      description.add(' with flag isLongClickable: $isLongClickable');
    return description;
  }

  @override
  bool matches(covariant AndroidSemanticsNode item, Map<Object, Object> matchState) {
    if (text != null && text != item.text)
      return _failWithMessage('Expected text: $text', matchState);
    if (className != null && className != item.className)
      return _failWithMessage('Expected className: $className', matchState);
    if (id != null && id != item.id)
      return _failWithMessage('Expected id: $id', matchState);
    if (rect != null && rect != item.getRect())
      return _failWithMessage('Expected rect: $rect', matchState);
    if (size != null && size != item.getSize())
      return _failWithMessage('Expected size: $size', matchState);
    if (actions != null) {
      final List<AndroidSemanticsAction> itemActions = item.getActions();
      if (actions.length != itemActions.length) {
        return _failWithMessage('Expected actions: $actions', matchState);
      }
      final List<int> usedIds = <int>[];
      outer: for (int i = 0; i < actions.length; i++) {
        final AndroidSemanticsAction leftAction = actions[i];
        for (int j = 0; j < actions.length; j++) {
          if (usedIds.contains(j))
            continue;
          if (itemActions[j] == leftAction) {
            usedIds.add(j);
            continue outer;
          }
        }
        return _failWithMessage('Expected actions: $actions', matchState);
      }
    }
    if (isChecked != null && isChecked != item.isChecked)
      return _failWithMessage('Expected isChecked: $isChecked', matchState);
    if (isCheckable != null && isCheckable != item.isCheckable)
      return _failWithMessage('Expected isCheckable: $isCheckable', matchState);
    if (isEditable != null && isEditable != item.isEditable)
      return _failWithMessage('Expected isEditable: $isEditable', matchState);
    if (isEnabled != null && isEnabled != item.isEnabled)
      return _failWithMessage('Expected isEnabled: $isEnabled', matchState);
    if (isFocusable != null && isFocusable != item.isFocusable)
      return _failWithMessage('Expected isFocusable: $isFocusable', matchState);
    if (isFocused != null && isFocused != item.isFocused)
      return _failWithMessage('Expected isFocused: $isFocused', matchState);
    if (isPassword != null && isPassword != item.isPassword)
      return _failWithMessage('Expected isPassword: $isPassword', matchState);
    if (isLongClickable != null && isLongClickable != item.isLongClickable)
      return _failWithMessage('Expected longClickable: $isLongClickable', matchState);
    return true;
  }

  @override
  Description describeMismatch(Object item, Description mismatchDescription,
      Map<Object, Object> matchState, bool verbose) {
    return mismatchDescription.add(matchState['failure']);
  }

  bool _failWithMessage(String value, Map<dynamic, dynamic> matchState) {
    matchState['failure'] = value;
    return false;
  }
}

/// A Rectangle which mirrors the `dart:ui` implementation.
/// 
/// Created separately since flutter_driver runs on the VM.
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

/// A simplified implementation of [Size] from `dart:ui`.
///
/// Created separately since flutter_driver runs on the VM.
class Size {
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