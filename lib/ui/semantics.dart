// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

/// The possible actions that can be conveyed from the operating system
/// accessibility APIs to a semantics node.
class SemanticsAction {
  const SemanticsAction._(this.index);

  static const int _kTapIndex = 1 << 0;
  static const int _kLongPressIndex = 1 << 1;
  static const int _kScrollLeftIndex = 1 << 2;
  static const int _kScrollRightIndex = 1 << 3;
  static const int _kScrollUpIndex = 1 << 4;
  static const int _kScrollDownIndex = 1 << 5;
  static const int _kIncreaseIndex = 1 << 6;
  static const int _kDecreaseIndex = 1 << 7;
  static const int _kShowOnScreenIndex = 1 << 8;
  static const int _kMoveCursorForwardByCharacterIndex = 1 << 9;
  static const int _kMoveCursorBackwardByCharacterIndex = 1 << 10;
  static const int _kSetSelectionIndex = 1 << 11;
  static const int _kCopyIndex = 1 << 12;
  static const int _kCutIndex = 1 << 13;
  static const int _kPasteIndex = 1 << 14;

  /// The numerical value for this action.
  ///
  /// Each action has one bit set in this bit field.
  final int index;

  /// The equivalent of a user briefly tapping the screen with the finger
  /// without moving it.
  static const SemanticsAction tap = const SemanticsAction._(_kTapIndex);

  /// The equivalent of a user pressing and holding the screen with the finger
  /// for a few seconds without moving it.
  static const SemanticsAction longPress = const SemanticsAction._(_kLongPressIndex);

  /// The equivalent of a user moving their finger across the screen from right
  /// to left.
  ///
  /// This action should be recognized by controls that are horizontally
  /// scrollable.
  static const SemanticsAction scrollLeft = const SemanticsAction._(_kScrollLeftIndex);

  /// The equivalent of a user moving their finger across the screen from left
  /// to right.
  ///
  /// This action should be recognized by controls that are horizontally
  /// scrollable.
  static const SemanticsAction scrollRight = const SemanticsAction._(_kScrollRightIndex);

  /// The equivalent of a user moving their finger across the screen from
  /// bottom to top.
  ///
  /// This action should be recognized by controls that are vertically
  /// scrollable.
  static const SemanticsAction scrollUp = const SemanticsAction._(_kScrollUpIndex);

  /// The equivalent of a user moving their finger across the screen from top
  /// to bottom.
  ///
  /// This action should be recognized by controls that are vertically
  /// scrollable.
  static const SemanticsAction scrollDown = const SemanticsAction._(_kScrollDownIndex);

  /// A request to increase the value represented by the semantics node.
  ///
  /// For example, this action might be recognized by a slider control.
  static const SemanticsAction increase = const SemanticsAction._(_kIncreaseIndex);

  /// A request to decrease the value represented by the semantics node.
  ///
  /// For example, this action might be recognized by a slider control.
  static const SemanticsAction decrease = const SemanticsAction._(_kDecreaseIndex);

  /// A request to fully show the semantics node on screen.
  ///
  /// For example, this action might be send to a node in a scrollable list that
  /// is partially off screen to bring it on screen.
  static const SemanticsAction showOnScreen = const SemanticsAction._(_kShowOnScreenIndex);

  /// Move the cursor forward by one character.
  ///
  /// This is for example used by the cursor control in text fields.
  ///
  /// The action includes a boolean argument, which indicates whether the cursor
  /// movement should extend (or start) a selection.
  static const SemanticsAction moveCursorForwardByCharacter = const SemanticsAction._(_kMoveCursorForwardByCharacterIndex);

  /// Move the cursor backward by one character.
  ///
  /// This is for example used by the cursor control in text fields.
  ///
  /// The action includes a boolean argument, which indicates whether the cursor
  /// movement should extend (or start) a selection.
  static const SemanticsAction moveCursorBackwardByCharacter = const SemanticsAction._(_kMoveCursorBackwardByCharacterIndex);

  /// Set the text selection to the given range.
  ///
  /// The provided argument is a Map<String, int> which includes the keys `base`
  /// and `extent` indicating where the selection within the `value` of the
  /// semantics node should start and where it should end. Values for both
  /// keys can range from 0 to length of `value` (inclusive).
  ///
  /// Setting `base` and `extent` to the same value will move the cursor to
  /// that position (without selecting anything).
  static const SemanticsAction setSelection = const SemanticsAction._(_kSetSelectionIndex);

  /// Copy the current selection to the clipboard.
  static const SemanticsAction copy = const SemanticsAction._(_kCopyIndex);

  /// Cut the current selection and place it in the clipboard.
  static const SemanticsAction cut = const SemanticsAction._(_kCutIndex);

  /// Paste the current content of the clipboard.
  static const SemanticsAction paste = const SemanticsAction._(_kPasteIndex);

  /// The possible semantics actions.
  ///
  /// The map's key is the [index] of the action and the value is the action
  /// itself.
  static final Map<int, SemanticsAction> values = const <int, SemanticsAction>{
    _kTapIndex: tap,
    _kLongPressIndex: longPress,
    _kScrollLeftIndex: scrollLeft,
    _kScrollRightIndex: scrollRight,
    _kScrollUpIndex: scrollUp,
    _kScrollDownIndex: scrollDown,
    _kIncreaseIndex: increase,
    _kDecreaseIndex: decrease,
    _kShowOnScreenIndex: showOnScreen,
    _kMoveCursorForwardByCharacterIndex: moveCursorForwardByCharacter,
    _kMoveCursorBackwardByCharacterIndex: moveCursorBackwardByCharacter,
    _kSetSelectionIndex: setSelection,
    _kCopyIndex: copy,
    _kCutIndex: cut,
    _kPasteIndex: paste,
  };

  @override
  String toString() {
    switch (index) {
      case _kTapIndex:
        return 'SemanticsAction.tap';
      case _kLongPressIndex:
        return 'SemanticsAction.longPress';
      case _kScrollLeftIndex:
        return 'SemanticsAction.scrollLeft';
      case _kScrollRightIndex:
        return 'SemanticsAction.scrollRight';
      case _kScrollUpIndex:
        return 'SemanticsAction.scrollUp';
      case _kScrollDownIndex:
        return 'SemanticsAction.scrollDown';
      case _kIncreaseIndex:
        return 'SemanticsAction.increase';
      case _kDecreaseIndex:
        return 'SemanticsAction.decrease';
      case _kShowOnScreenIndex:
        return 'SemanticsAction.showOnScreen';
      case _kMoveCursorForwardByCharacterIndex:
        return 'SemanticsAction.moveCursorForwardByCharacter';
      case _kMoveCursorBackwardByCharacterIndex:
        return 'SemanticsAction.moveCursorBackwardByCharacter';
      case _kSetSelectionIndex:
        return 'SemanticsAction.setSelection';
      case _kCopyIndex:
        return 'SemanticsAction.copy';
      case _kCutIndex:
        return 'SemanticsAction.cut';
      case _kPasteIndex:
        return 'SemanticsAction.paste';
    }
    return null;
  }
}

/// A Boolean value that can be associated with a semantics node.
class SemanticsFlag {
  static const int _kHasCheckedStateIndex = 1 << 0;
  static const int _kIsCheckedIndex = 1 << 1;
  static const int _kIsSelectedIndex = 1 << 2;
  static const int _kIsButtonIndex = 1 << 3;
  static const int _kIsTextFieldIndex = 1 << 4;
  static const int _kIsFocusedIndex = 1 << 5;
  static const int _kHasEnabledStateIndex = 1 << 6;
  static const int _kIsEnabledIndex = 1 << 7;
  static const int _kIsInMutuallyExclusiveGroupIndex = 1 << 8;

  const SemanticsFlag._(this.index);

  /// The numerical value for this flag.
  ///
  /// Each flag has one bit set in this bit field.
  final int index;

  /// The semantics node has the quality of either being "checked" or "unchecked".
  ///
  /// For example, a checkbox or a radio button widget has checked state.
  static const SemanticsFlag hasCheckedState = const SemanticsFlag._(_kHasCheckedStateIndex);

  /// Whether a semantics node that [hasCheckedState] is checked.
  ///
  /// If true, the semantics node is "checked". If false, the semantics node is
  /// "unchecked".
  ///
  /// For example, if a checkbox has a visible checkmark, [isChecked] is true.
  static const SemanticsFlag isChecked = const SemanticsFlag._(_kIsCheckedIndex);


  /// Whether a semantics node is selected.
  ///
  /// If true, the semantics node is "selected". If false, the semantics node is
  /// "unselected".
  ///
  /// For example, the active tab in a tab bar has [isSelected] set to true.
  static const SemanticsFlag isSelected = const SemanticsFlag._(_kIsSelectedIndex);

  /// Whether the semantic node represents a button.
  ///
  /// Platforms has special handling for buttons, for example Android's TalkBack
  /// and iOS's VoiceOver provides an additional hint when the focused object is
  /// a button.
  static const SemanticsFlag isButton = const SemanticsFlag._(_kIsButtonIndex);

  /// Whether the semantic node represents a text field.
  ///
  /// Text fields are announced as such and allow text input via accessibility
  /// affordances.
  static const SemanticsFlag isTextField = const SemanticsFlag._(_kIsTextFieldIndex);

  /// Whether the semantic node currently holds the user's focus.
  ///
  /// The focused element is usually the current receiver of keyboard inputs.
  static const SemanticsFlag isFocused = const SemanticsFlag._(_kIsFocusedIndex);

  /// The semantics node has the quality of either being "enabled" or
  /// "disabled".
  ///
  /// For example, a button can be enabled or disabled and therefore has an
  /// "enabled" state. Static text is usually neither enabled nor disabled and
  /// therefore does not have an "enabled" state.
  static const SemanticsFlag hasEnabledState = const SemanticsFlag._(_kHasEnabledStateIndex);

  /// Whether a semantic node that [hasEnabledState] is currently enabled.
  ///
  /// A disabled element does not respond to user interaction. For example, a
  /// button that currently does not respond to user interaction should be
  /// marked as disabled.
  static const SemanticsFlag isEnabled = const SemanticsFlag._(_kIsEnabledIndex);

  /// Whether a semantic node is in a mutually exclusive group.
  ///
  /// For example, a radio button is in a mutually exclusive group because
  /// only one radio button in that group can be marked as [isChecked].
  static const SemanticsFlag isInMutuallyExclusiveGroup = const SemanticsFlag._(_kIsInMutuallyExclusiveGroupIndex);

  /// The possible semantics flags.
  ///
  /// The map's key is the [index] of the flag and the value is the flag itself.
  static final Map<int, SemanticsFlag> values = const <int, SemanticsFlag>{
    _kHasCheckedStateIndex: hasCheckedState,
    _kIsCheckedIndex: isChecked,
    _kIsSelectedIndex: isSelected,
    _kIsButtonIndex: isButton,
    _kIsTextFieldIndex: isTextField,
    _kIsFocusedIndex: isFocused,
    _kHasEnabledStateIndex: hasEnabledState,
    _kIsEnabledIndex: isEnabled,
    _kIsInMutuallyExclusiveGroupIndex: isInMutuallyExclusiveGroup,
  };

  @override
  String toString() {
    switch (index) {
      case _kHasCheckedStateIndex:
        return 'SemanticsFlag.hasCheckedState';
      case _kIsCheckedIndex:
        return 'SemanticsFlag.isChecked';
      case _kIsSelectedIndex:
        return 'SemanticsFlag.isSelected';
      case _kIsButtonIndex:
        return 'SemanticsFlag.isButton';
      case _kIsTextFieldIndex:
        return 'SemanticsFlag.isTextField';
      case _kIsFocusedIndex:
        return 'SemanticsFlag.isFocused';
      case _kHasEnabledStateIndex:
        return 'SemanticsFlag.hasEnabledState';
      case _kIsEnabledIndex:
        return 'SemanticsFlag.isEnabled';
      case _kIsInMutuallyExclusiveGroupIndex:
        return 'SemanticsFlag.isInMutuallyExclusiveGroup';
    }
    return null;
  }
}

/// An object that creates [SemanticsUpdate] objects.
///
/// Once created, the [SemanticsUpdate] objects can be passed to
/// [Window.updateSemantics] to update the semantics conveyed to the user.
class SemanticsUpdateBuilder extends NativeFieldWrapperClass2 {
  /// Creates an empty [SemanticsUpdateBuilder] object.
  SemanticsUpdateBuilder() { _constructor(); }
  void _constructor() native 'SemanticsUpdateBuilder_constructor';

  /// Update the information associated with the node with the given `id`.
  ///
  /// The semantics nodes form a tree, with the root of the tree always having
  /// an id of zero. The `children` are the ids of the nodes that are immediate
  /// children of this node. The system retains the nodes that are currently
  /// reachable from the root. A given update need not contain information for
  /// nodes that do not change in the update. If a node is not reachable from
  /// the root after an update, the node will be discarded from the tree.
  ///
  /// The `flags` are a bit field of [SemanticsFlag]s that apply to this node.
  ///
  /// The `actions` are a bit field of [SemanticsAction]s that can be undertaken
  /// by this node. If the user wishes to undertake one of these actions on this
  /// node, the [Window.onSemanticsAction] will be called with `id` and one of
  /// the possible [SemanticsAction]s. Because the semantics tree is maintained
  /// asynchronously, the [Window.onSemanticsAction] callback might be called
  /// with an action that is no longer possible.
  ///
  /// The `label` is a string that describes this node. The `value` property
  /// describes the current value of the node as a string. The `increasedValue`
  /// string will become the `value` string after a [SemanticsAction.increase]
  /// action is performed. The `decreasedValue` string will become the `value`
  /// string after a [SemanticsAction.decrease] action is performed. The `hint`
  /// string describes what result an action performed on this node has. The
  /// reading direction of all these strings is given by `textDirection`.
  ///
  /// The fields 'textSelectionBase' and 'textSelectionExtent' describe the
  /// currently selected text within `value`.
  ///
  /// For scrollable nodes `scrollPosition` describes the current scroll
  /// position in logical pixel. `scrollExtentMax` and `scrollExtentMin`
  /// describe the maximum and minimum in-rage values that `scrollPosition` can
  /// be. Both or either may be infinity to indicate unbound scrolling. The
  /// value for `scrollPosition` can (temporarily) be outside this range, for
  /// example during an overscroll.
  ///
  /// The `rect` is the region occupied by this node in its own coordinate
  /// system.
  ///
  /// The `transform` is a matrix that maps this node's coordinate system into
  /// its parent's coordinate system.
  void updateNode({
    int id,
    int flags,
    int actions,
    int textSelectionBase,
    int textSelectionExtent,
    double scrollPosition,
    double scrollExtentMax,
    double scrollExtentMin,
    Rect rect,
    String label,
    String hint,
    String value,
    String increasedValue,
    String decreasedValue,
    TextDirection textDirection,
    int nextNodeId,
    Float64List transform,
    Int32List children,
  }) {
    if (transform.length != 16)
      throw new ArgumentError('transform argument must have 16 entries.');
    _updateNode(id,
                flags,
                actions,
                textSelectionBase,
                textSelectionExtent,
                scrollPosition,
                scrollExtentMax,
                scrollExtentMin,
                rect.left,
                rect.top,
                rect.right,
                rect.bottom,
                label,
                hint,
                value,
                increasedValue,
                decreasedValue,
                textDirection != null ? textDirection.index + 1 : 0,
                nextNodeId ?? -1,
                transform,
                children,);
  }
  void _updateNode(
    int id,
    int flags,
    int actions,
    int textSelectionBase,
    int textSelectionExtent,
    double scrollPosition,
    double scrollExtentMax,
    double scrollExtentMin,
    double left,
    double top,
    double right,
    double bottom,
    String label,
    String hint,
    String value,
    String increasedValue,
    String decreasedValue,
    int textDirection,
    int nextNodeId,
    Float64List transform,
    Int32List children,
  ) native 'SemanticsUpdateBuilder_updateNode';

  /// Creates a [SemanticsUpdate] object that encapsulates the updates recorded
  /// by this object.
  ///
  /// The returned object can be passed to [Window.updateSemantics] to actually
  /// update the semantics retained by the system.
  SemanticsUpdate build() native 'SemanticsUpdateBuilder_build';
}

/// An opaque object representing a batch of semantics updates.
///
/// To create a SemanticsUpdate object, use a [SemanticsUpdateBuilder].
///
/// Semantics updates can be applied to the system's retained semantics tree
/// using the [Window.updateSemantics] method.
class SemanticsUpdate extends NativeFieldWrapperClass2 {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a SemanticsUpdate object, use a [SemanticsUpdateBuilder].
  SemanticsUpdate._();

  /// Releases the resources used by this semantics update.
  ///
  /// After calling this function, the semantics update is cannot be used
  /// further.
  void dispose() native 'SemanticsUpdateBuilder_dispose';
}
