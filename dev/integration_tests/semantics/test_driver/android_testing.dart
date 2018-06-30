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
    return description;
  }

  @override
  bool matches(Object item, Map<Object, Object> matchState) {
    bool doesMatch = true;
    if (item is AndroidSemanticsNode) {
      if (text != null && text != item.text) {
        matchState['text'] = true;
        doesMatch = false;
      }
      if (className != null && className != item.className) {
        matchState['className'] = true;
        doesMatch = false;
      }
      if (id != null && id != item.id) {
        matchState['id'] = true;
        doesMatch = false;
      }
      if (rect != null && rect != item.getRect()) {
        matchState['rect'] = true;
        doesMatch = false;
      }
      if (size != null && size != item.getSize()) {
        matchState['size'] = true;
        doesMatch = false;
      }
      if (actions != null) {
        final List<AndroidSemanticsAction> itemActions = item.getActions();
        if (actions.length != itemActions.length) {
          doesMatch = false;
          matchState['actions'] = true;
        } else {
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
            doesMatch = false;
            matchState['actions'] = true;
          }
        }
      }
      if (isChecked != null && isChecked != item.isChecked) {
        matchState['isChecked'] = true;
        doesMatch = false;
      }
      if (isCheckable != null && isCheckable != item.isCheckable) {
        matchState['isCheckable'] = true;
        doesMatch = false;
      }
      if (isEditable != null && isEditable != item.isEditable) {
        matchState['isEditable'] = true;
        doesMatch = false;
      }
      if (isEnabled != null && isEnabled != item.isEnabled) {
        matchState['isEnabled'] = true;
        doesMatch = false;
      }
      if (isFocusable != null && isFocusable != item.isFocusable) {
        matchState['isFocusable'] = true;
        doesMatch = false;
      }
      if (isFocused != null && isFocusable != item.isFocusable) {
        matchState['isFocused'] = true;
        doesMatch = false;
      }
      if (isPassword != null && isPassword != item.isPassword) {
        matchState['isPassword'] = true;
        doesMatch = false;
      }
      if (isLongClickable != null && isLongClickable != item.isLongClickable) {
        matchState['isLongClickable'] = true;
        doesMatch = false;
      }
      return doesMatch;
    }
    return false;
  }

  @override
  Description describeMismatch(Object item, Description mismatchDescription,
      Map<Object, Object> matchState, bool verbose) {
    if (item is AndroidSemanticsNode) {
      if (matchState['text']) {
        mismatchDescription
            .add('Expected text:  ')
            .addDescriptionOf(text)
            .add(' but got ')
            .addDescriptionOf(item.text)
            .add('\n');
      }
      if (matchState['id']) {
        mismatchDescription
            .add('Expected id:  ')
            .addDescriptionOf(id)
            .add(' but got ')
            .addDescriptionOf(item.id)
            .add('\n');
      }
      if (matchState['className']) {
        mismatchDescription
            .add('Expected className: ')
            .addDescriptionOf(className)
            .add(' but got ')
            .addDescriptionOf(item.className)
            .add('\n');
      }
      if (matchState['rect']) {
        mismatchDescription
            .add('Expected rect:  ')
            .addDescriptionOf(rect)
            .add(' but got ')
            .addDescriptionOf(item.getRect())
            .add('\n');
      }
      if (matchState['size']) {
        mismatchDescription
            .add('Expected size:  ')
            .addDescriptionOf(size)
            .add(' but got ')
            .addDescriptionOf(item.getSize())
            .add('\n');
      }
      if (matchState['actions']) {
        mismatchDescription
            .add('Expected actions: ')
            .addDescriptionOf(actions)
            .add(' but got ')
            .addDescriptionOf(item.getActions())
            .add('\n');
      }
      if (matchState['isChecked']) {
        mismatchDescription
            .add('Expected isChecked: ')
            .addDescriptionOf(isChecked)
            .add(' but got ')
            .addDescriptionOf(item.isChecked)
            .add('\n');
      }
      if (matchState['isCheckable']) {
        mismatchDescription
            .add('Expected isCheckable: ')
            .addDescriptionOf(isCheckable)
            .add(' but got ')
            .addDescriptionOf(item.isCheckable)
            .add('\n');
      }
      if (matchState['isEditable']) {
        mismatchDescription
            .add('Expected isEditable: ')
            .addDescriptionOf(isEditable)
            .add(' but got ')
            .addDescriptionOf(item.isEditable)
            .add('\n');
      }
      if (matchState['isEnabled']) {
        mismatchDescription
            .add('Expected isEnabled: ')
            .addDescriptionOf(isEnabled)
            .add(' but got ')
            .addDescriptionOf(item.isEnabled)
            .add('\n');
      }
      if (matchState['isFocusable']) {
        mismatchDescription
            .add('Expected isFocusable: ')
            .addDescriptionOf(isFocusable)
            .add(' but got ')
            .addDescriptionOf(item.isFocusable)
            .add('\n');
      }
      if (matchState['isFocused']) {
        mismatchDescription
            .add('Expected isFocused: ')
            .addDescriptionOf(isFocused)
            .add(' but got ')
            .addDescriptionOf(item.isFocused)
            .add('\n');
      }
      if (matchState['isPassword']) {
        mismatchDescription
            .add('Expected isPassword: ')
            .addDescriptionOf(isPassword)
            .add(' but got ')
            .addDescriptionOf(item.isPassword)
            .add('\n');
      }
      if (matchState['isLongClickable']) {
        mismatchDescription
            .add('Expected isLongClickable: ')
            .addDescriptionOf(isLongClickable)
            .add(' but got ')
            .addDescriptionOf(item.isLongClickable)
            .add('\n');
      }
      return mismatchDescription;
    }
    return mismatchDescription
        .add('Expected AndroidSemanticsNode but found $item');
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