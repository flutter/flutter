// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

/// The possible actions that can be conveyed from the operating system
/// accessibility APIs to a semantics node.
//
// > [!Warning]
// > When changes are made to this class, the equivalent APIs in
// > `lib/ui/semantics/semantics_node.h` and in each of the embedders
// > *must* be updated.
class SemanticsAction {
  const SemanticsAction._(this.index, this.name);

  /// The numerical value for this action.
  ///
  /// Each action has one bit set in this bit field.
  final int index;

  /// A human-readable name for this flag, used for debugging purposes.
  final String name;

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
  static const int _kDidGainAccessibilityFocusIndex = 1 << 15;
  static const int _kDidLoseAccessibilityFocusIndex = 1 << 16;
  static const int _kCustomActionIndex = 1 << 17;
  static const int _kDismissIndex = 1 << 18;
  static const int _kMoveCursorForwardByWordIndex = 1 << 19;
  static const int _kMoveCursorBackwardByWordIndex = 1 << 20;
  static const int _kSetTextIndex = 1 << 21;
  static const int _kFocusIndex = 1 << 22;
  static const int _kScrollToOffsetIndex = 1 << 23;
  static const int _kExpandIndex = 1 << 24;
  static const int _kCollapseIndex = 1 << 25;
  // READ THIS:
  // - The maximum supported bit index on the web (in JS mode) is 1 << 31.
  // - If you add an action here, you MUST update the numSemanticsActions value
  //   in testing/dart/semantics_test.dart and
  //   lib/web_ui/test/engine/semantics/semantics_api_test.dart, or tests will
  //   fail.

  /// The equivalent of a user briefly tapping the screen with the finger
  /// without moving it.
  static const SemanticsAction tap = SemanticsAction._(_kTapIndex, 'tap');

  /// The equivalent of a user pressing and holding the screen with the finger
  /// for a few seconds without moving it.
  static const SemanticsAction longPress = SemanticsAction._(_kLongPressIndex, 'longPress');

  /// The equivalent of a user moving their finger across the screen from right
  /// to left.
  ///
  /// This action should be recognized by controls that are horizontally
  /// scrollable.
  static const SemanticsAction scrollLeft = SemanticsAction._(_kScrollLeftIndex, 'scrollLeft');

  /// The equivalent of a user moving their finger across the screen from left
  /// to right.
  ///
  /// This action should be recognized by controls that are horizontally
  /// scrollable.
  static const SemanticsAction scrollRight = SemanticsAction._(_kScrollRightIndex, 'scrollRight');

  /// The equivalent of a user moving their finger across the screen from
  /// bottom to top.
  ///
  /// This action should be recognized by controls that are vertically
  /// scrollable.
  static const SemanticsAction scrollUp = SemanticsAction._(_kScrollUpIndex, 'scrollUp');

  /// The equivalent of a user moving their finger across the screen from top
  /// to bottom.
  ///
  /// This action should be recognized by controls that are vertically
  /// scrollable.
  static const SemanticsAction scrollDown = SemanticsAction._(_kScrollDownIndex, 'scrollDown');

  /// A request to scroll the scrollable container to a given scroll offset.
  ///
  /// The payload of this [SemanticsAction] is a flutter-standard-encoded
  /// [Float64List] of length 2 containing the target horizontal and vertical
  /// offsets (in logical pixels) the receiving scrollable container should
  /// scroll to.
  ///
  /// This action is used by iOS Full Keyboard Access to reveal contents that
  /// are currently not visible in the viewport.
  static const SemanticsAction scrollToOffset = SemanticsAction._(
    _kScrollToOffsetIndex,
    'scrollToOffset',
  );

  /// A request to increase the value represented by the semantics node.
  ///
  /// For example, this action might be recognized by a slider control.
  static const SemanticsAction increase = SemanticsAction._(_kIncreaseIndex, 'increase');

  /// A request to decrease the value represented by the semantics node.
  ///
  /// For example, this action might be recognized by a slider control.
  static const SemanticsAction decrease = SemanticsAction._(_kDecreaseIndex, 'decrease');

  /// A request to fully show the semantics node on screen.
  ///
  /// For example, this action might be send to a node in a scrollable list that
  /// is partially off screen to bring it on screen.
  static const SemanticsAction showOnScreen = SemanticsAction._(
    _kShowOnScreenIndex,
    'showOnScreen',
  );

  /// Move the cursor forward by one character.
  ///
  /// This is for example used by the cursor control in text fields.
  ///
  /// The action includes a boolean argument, which indicates whether the cursor
  /// movement should extend (or start) a selection.
  static const SemanticsAction moveCursorForwardByCharacter = SemanticsAction._(
    _kMoveCursorForwardByCharacterIndex,
    'moveCursorForwardByCharacter',
  );

  /// Move the cursor backward by one character.
  ///
  /// This is for example used by the cursor control in text fields.
  ///
  /// The action includes a boolean argument, which indicates whether the cursor
  /// movement should extend (or start) a selection.
  static const SemanticsAction moveCursorBackwardByCharacter = SemanticsAction._(
    _kMoveCursorBackwardByCharacterIndex,
    'moveCursorBackwardByCharacter',
  );

  /// Replaces the current text in the text field.
  ///
  /// This is for example used by the text editing in voice access.
  ///
  /// The action includes a string argument, which is the new text to
  /// replace.
  static const SemanticsAction setText = SemanticsAction._(_kSetTextIndex, 'setText');

  /// Set the text selection to the given range.
  ///
  /// The provided argument is a Map<String, int> which includes the keys `base`
  /// and `extent` indicating where the selection within the `value` of the
  /// semantics node should start and where it should end. Values for both
  /// keys can range from 0 to length of `value` (inclusive).
  ///
  /// Setting `base` and `extent` to the same value will move the cursor to
  /// that position (without selecting anything).
  static const SemanticsAction setSelection = SemanticsAction._(
    _kSetSelectionIndex,
    'setSelection',
  );

  /// Copy the current selection to the clipboard.
  static const SemanticsAction copy = SemanticsAction._(_kCopyIndex, 'copy');

  /// Cut the current selection and place it in the clipboard.
  static const SemanticsAction cut = SemanticsAction._(_kCutIndex, 'cut');

  /// Paste the current content of the clipboard.
  static const SemanticsAction paste = SemanticsAction._(_kPasteIndex, 'paste');

  /// Indicates that the node has gained accessibility focus.
  ///
  /// This handler is invoked when the node annotated with this handler gains
  /// the accessibility focus. The accessibility focus is the
  /// green (on Android with TalkBack) or black (on iOS with VoiceOver)
  /// rectangle shown on screen to indicate what element an accessibility
  /// user is currently interacting with.
  ///
  /// The accessibility focus is different from the input focus. The input focus
  /// is usually held by the element that currently responds to keyboard inputs.
  /// Accessibility focus and input focus can be held by two different nodes!
  ///
  /// See also:
  ///
  ///    * [focus], which controls the input focus.
  static const SemanticsAction didGainAccessibilityFocus = SemanticsAction._(
    _kDidGainAccessibilityFocusIndex,
    'didGainAccessibilityFocus',
  );

  /// Indicates that the node has lost accessibility focus.
  ///
  /// This handler is invoked when the node annotated with this handler
  /// loses the accessibility focus. The accessibility focus is
  /// the green (on Android with TalkBack) or black (on iOS with VoiceOver)
  /// rectangle shown on screen to indicate what element an accessibility
  /// user is currently interacting with.
  ///
  /// The accessibility focus is different from the input focus. The input focus
  /// is usually held by the element that currently responds to keyboard inputs.
  /// Accessibility focus and input focus can be held by two different nodes!
  static const SemanticsAction didLoseAccessibilityFocus = SemanticsAction._(
    _kDidLoseAccessibilityFocusIndex,
    'didLoseAccessibilityFocus',
  );

  /// Indicates that the user has invoked a custom accessibility action.
  ///
  /// This handler is added automatically whenever a custom accessibility
  /// action is added to a semantics node.
  static const SemanticsAction customAction = SemanticsAction._(
    _kCustomActionIndex,
    'customAction',
  );

  /// A request that the node should be dismissed.
  ///
  /// A [SnackBar], for example, may have a dismiss action to indicate to the
  /// user that it can be removed after it is no longer relevant. On Android,
  /// (with TalkBack) special hint text is spoken when focusing the node and
  /// a custom action is available in the local context menu. On iOS,
  /// (with VoiceOver) users can perform a standard gesture to dismiss it.
  static const SemanticsAction dismiss = SemanticsAction._(_kDismissIndex, 'dismiss');

  /// Move the cursor forward by one word.
  ///
  /// This is for example used by the cursor control in text fields.
  ///
  /// The action includes a boolean argument, which indicates whether the cursor
  /// movement should extend (or start) a selection.
  static const SemanticsAction moveCursorForwardByWord = SemanticsAction._(
    _kMoveCursorForwardByWordIndex,
    'moveCursorForwardByWord',
  );

  /// Move the cursor backward by one word.
  ///
  /// This is for example used by the cursor control in text fields.
  ///
  /// The action includes a boolean argument, which indicates whether the cursor
  /// movement should extend (or start) a selection.
  static const SemanticsAction moveCursorBackwardByWord = SemanticsAction._(
    _kMoveCursorBackwardByWordIndex,
    'moveCursorBackwardByWord',
  );

  /// Move the input focus to the respective widget.
  ///
  /// Most commonly, the input focus determines which widget will receive
  /// keyboard input. Semantics nodes that can receive this action are expected
  /// to have [SemanticsFlag.isFocusable] set. Examples of such focusable
  /// widgets include buttons, checkboxes, switches, and text fields.
  ///
  /// Upon receiving this action, the corresponding widget must move input focus
  /// to itself. Doing otherwise is likely to lead to a poor user experience,
  /// such as user input routed to a wrong widget. Text fields in particular,
  /// must immediately become editable, opening a virtual keyboard, if needed.
  /// Buttons must respond to tap/click events from the keyboard.
  ///
  /// Widget reaction to this action must be idempotent. It is possible to
  /// receive this action more than once, or when the widget is already focused.
  ///
  /// Focus behavior is specific to the platform and to the assistive technology
  /// used. Typically on desktop operating systems, such as Windows, macOS, and
  /// Linux, moving accessibility focus will also move the input focus. On
  /// mobile it is more common for the accessibility focus to be detached from
  /// the input focus. In order to synchronize the two, a user takes an explicit
  /// action (e.g. double-tap to activate). Sometimes this behavior is
  /// configurable. For example, VoiceOver on macOS can be configured in the
  /// global OS user settings to either move the input focus together with the
  /// VoiceOver focus, or to keep the two detached. For this reason, widgets
  /// should not expect to receive [didGainAccessibilityFocus] and [focus]
  /// actions to be reported in any particular combination or order.
  ///
  /// On the web, the DOM "focus" event is equivalent to
  /// [SemanticsAction.focus]. Accessibility focus is not observable from within
  /// the browser. Instead, the browser, based on the platform features and user
  /// preferences, makes the determination on whether input focus should be
  /// moved to an element and, if so, fires a DOM "focus" event. This event is
  /// forwarded to the framework as [SemanticsAction.focus]. For this reason, on
  /// the web, the engine never sends [didGainAccessibilityFocus].
  ///
  /// On Android input focus is observable as `AccessibilityAction#ACTION_FOCUS`
  /// and is separate from accessibility focus, which is observed as
  /// `AccessibilityAction#ACTION_ACCESSIBILITY_FOCUS`.
  ///
  /// See also:
  ///
  ///    * [didGainAccessibilityFocus], which informs the framework about
  ///      accessibility focus ring, such as the TalkBack (Android) and
  ///      VoiceOver (iOS), moving which does not move the input focus.
  static const SemanticsAction focus = SemanticsAction._(_kFocusIndex, 'focus');

  /// A request that the node should be expanded.
  ///
  /// For example, this action might be recognized by a dropdown.
  static const SemanticsAction expand = SemanticsAction._(_kExpandIndex, 'expand');

  /// A request that the node should be collapsed.
  ///
  /// For example, this action might be recognized by a dropdown.
  static const SemanticsAction collapse = SemanticsAction._(_kCollapseIndex, 'collapse');

  /// The possible semantics actions.
  ///
  /// The map's key is the [index] of the action and the value is the action
  /// itself.
  static const Map<int, SemanticsAction> _kActionById = <int, SemanticsAction>{
    _kTapIndex: tap,
    _kLongPressIndex: longPress,
    _kScrollLeftIndex: scrollLeft,
    _kScrollRightIndex: scrollRight,
    _kScrollUpIndex: scrollUp,
    _kScrollDownIndex: scrollDown,
    _kScrollToOffsetIndex: scrollToOffset,
    _kIncreaseIndex: increase,
    _kDecreaseIndex: decrease,
    _kShowOnScreenIndex: showOnScreen,
    _kMoveCursorForwardByCharacterIndex: moveCursorForwardByCharacter,
    _kMoveCursorBackwardByCharacterIndex: moveCursorBackwardByCharacter,
    _kSetSelectionIndex: setSelection,
    _kCopyIndex: copy,
    _kCutIndex: cut,
    _kPasteIndex: paste,
    _kDidGainAccessibilityFocusIndex: didGainAccessibilityFocus,
    _kDidLoseAccessibilityFocusIndex: didLoseAccessibilityFocus,
    _kCustomActionIndex: customAction,
    _kDismissIndex: dismiss,
    _kMoveCursorForwardByWordIndex: moveCursorForwardByWord,
    _kMoveCursorBackwardByWordIndex: moveCursorBackwardByWord,
    _kSetTextIndex: setText,
    _kFocusIndex: focus,
    _kExpandIndex: expand,
    _kCollapseIndex: collapse,
  };

  // TODO(matanlurey): have original authors document; see https://github.com/flutter/flutter/issues/151917.
  // ignore: public_member_api_docs
  static List<SemanticsAction> get values => _kActionById.values.toList(growable: false);

  // TODO(matanlurey): have original authors document; see https://github.com/flutter/flutter/issues/151917.
  // ignore: public_member_api_docs
  static SemanticsAction? fromIndex(int index) => _kActionById[index];

  @override
  String toString() => 'SemanticsAction.$name';
}

/// An enum to describe the role for a semantics node.
///
/// The roles are translated into native accessibility roles in each platform.
enum SemanticsRole {
  /// Does not represent any role.
  none,

  /// A tab button.
  ///
  /// See also:
  ///
  ///  * [tabBar], which is the role for containers of tab buttons.
  tab,

  /// Contains tab buttons.
  ///
  /// See also:
  ///
  ///  * [tab], which is the role for tab buttons.
  tabBar,

  /// The main display for a tab.
  tabPanel,

  /// A pop up dialog.
  dialog,

  /// An alert dialog.
  alertDialog,

  /// A table structure containing data arranged in rows and columns.
  ///
  /// See also:
  ///
  /// * [cell], [row], [columnHeader] for table related roles.
  table,

  /// A cell in a [table] that does not contain column or row header information.
  ///
  /// See also:
  ///
  /// * [table],[row], [columnHeader] for table related roles.
  cell,

  /// A row of [cell]s or or [columnHeader]s in a [table].
  ///
  /// See also:
  ///
  /// * [table] ,[cell],[columnHeader] for table related roles.
  row,

  /// A cell in a [table] contains header information for a column.
  ///
  /// See also:
  ///
  /// * [table] ,[cell], [row] for table related roles.
  columnHeader,

  /// A control used for dragging across content.
  ///
  /// For example, the drag handle of [ReorderableList].
  dragHandle,

  /// A control to cycle through content on tap.
  ///
  /// For example, the next and previous month button of a [CalendarDatePicker].
  spinButton,

  /// A input field with a dropdown list box attached.
  ///
  /// For example, a [DropdownMenu]
  comboBox,

  /// A presentation of [menu] that usually remains visible and is usually
  /// presented horizontally.
  ///
  /// For example, a [MenuBar].
  menuBar,

  /// A permanently visible list of controls or a widget that can be made to
  /// open and close.
  ///
  /// For example, a [MenuAnchor] or [DropdownButton].
  menu,

  /// An item in a dropdown created by [menu] or [menuBar].
  ///
  /// See also:
  ///
  /// * [menuItemCheckbox], a menu item with a checkbox. The [menuItemCheckbox]
  ///  can also be used within [menu] and [menuBar].
  /// * [menuItemRadio], a menu item with a radio button. This role is used by
  /// [menu] or [menuBar] as well.
  menuItem,

  /// An item with a checkbox in a dropdown created by [menu] or [menuBar].
  ///
  /// See also:
  ///
  /// * [menuItem] and [menuItemRadio] for menu related roles.
  menuItemCheckbox,

  /// An item with a radio button in a dropdown created by [menu] or [menuBar].
  ///
  /// See also:
  ///
  /// * [menuItem] and [menuItemCheckbox] for menu related roles.
  menuItemRadio,

  /// A container to display multiple [listItem]s in vertical or horizontal
  /// layout.
  ///
  /// For example, a [LisView] or [Column].
  list,

  /// An item in a [list].
  listItem,

  /// An area that represents a form.
  form,

  /// A pop up displayed when hovering over a component to provide contextual
  /// explanation.
  tooltip,

  /// A graphic object that spins to indicate the application is busy.
  ///
  /// For example, a [CircularProgressIndicator].
  loadingSpinner,

  /// A graphic object that shows progress with a numeric number.
  ///
  /// For example, a [LinearProgressIndicator].
  progressBar,

  /// A keyboard shortcut field that allows the user to enter a combination or
  /// sequence of keystrokes.
  ///
  /// For example, [Shortcuts].
  hotKey,

  /// A group of radio buttons.
  radioGroup,

  /// A component to provide advisory information that is not important to
  /// justify an [alert].
  ///
  /// For example, a loading message for a web page.
  status,

  /// A component to provide important and usually time-sensitive information.
  ///
  /// The alert role should only be used for information that requires the
  /// user's immediate attention, for example:
  ///
  /// * An invalid value was entered into a form field.
  /// * The user's login session is about to expire.
  /// * The connection to the server was lost so local changes will not be
  ///   saved.
  alert,

  /// A supporting section that relates to the main content.
  ///
  /// The compelementary role is one of landmark roles. This role can be used to
  /// describe sidebars, or call-out boxes.
  ///
  /// For more information, see: https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/complementary_role
  complementary,

  /// A section for a footer, containing identifying information such as
  /// copyright information, navigation links and privacy statements.
  ///
  /// The contentInfo role is one of landmark roles. For more information, see:
  /// https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/contentinfo_role
  contentInfo,

  /// The primary content of a document.
  ///
  /// The section consists of content that is directly related to or expands on
  /// the central topic of a document, or the main function of an application.
  ///
  /// This role is one of landmark roles. For more information, see:
  /// https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/main_role
  main,

  /// A region of a web page that contains navigation links.
  ///
  /// This role is one of landmark roles. For more information, see:
  /// https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/navigation_role
  navigation,

  /// A section of content sufficiently important but cannot be descrived by one
  /// of the other landmark roles, such as main, contentinfo, complementary, or
  /// navigation.
  ///
  /// For more information, see:
  /// https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/region_role
  region,
}

/// Describe the type of data for an input field.
///
/// This is typically used to complement text fields.
enum SemanticsInputType {
  /// The default for non text field.
  none,

  /// Describes a generic text field.
  text,

  /// Describes a url text field.
  url,

  /// Describes a text field for phone input.
  phone,

  /// Describes a text field that act as a search box.
  search,

  /// Describes a text field for email input.
  email,
}

/// A Boolean value that can be associated with a semantics node.
//
// When changes are made to this class, the equivalent APIs in
// `lib/ui/semantics/semantics_node.h` and in each of the embedders *must* be
// updated. If the change affects the visibility of a [SemanticsNode] to
// accessibility services, `flutter_test/controller.dart#SemanticsController._importantFlags`
// must be updated as well.
class SemanticsFlag {
  const SemanticsFlag._(this.index, this.name);

  /// The numerical value for this flag.
  ///
  /// Each flag has one bit set in this bit field.
  final int index;

  /// A human-readable name for this flag, used for debugging purposes.
  final String name;

  static const int _kHasCheckedStateIndex = 1 << 0;
  static const int _kIsCheckedIndex = 1 << 1;
  static const int _kIsSelectedIndex = 1 << 2;
  static const int _kIsButtonIndex = 1 << 3;
  static const int _kIsTextFieldIndex = 1 << 4;
  static const int _kIsFocusedIndex = 1 << 5;
  static const int _kHasEnabledStateIndex = 1 << 6;
  static const int _kIsEnabledIndex = 1 << 7;
  static const int _kIsInMutuallyExclusiveGroupIndex = 1 << 8;
  static const int _kIsHeaderIndex = 1 << 9;
  static const int _kIsObscuredIndex = 1 << 10;
  static const int _kScopesRouteIndex = 1 << 11;
  static const int _kNamesRouteIndex = 1 << 12;
  static const int _kIsHiddenIndex = 1 << 13;
  static const int _kIsImageIndex = 1 << 14;
  static const int _kIsLiveRegionIndex = 1 << 15;
  static const int _kHasToggledStateIndex = 1 << 16;
  static const int _kIsToggledIndex = 1 << 17;
  static const int _kHasImplicitScrollingIndex = 1 << 18;
  static const int _kIsMultilineIndex = 1 << 19;
  static const int _kIsReadOnlyIndex = 1 << 20;
  static const int _kIsFocusableIndex = 1 << 21;
  static const int _kIsLinkIndex = 1 << 22;
  static const int _kIsSliderIndex = 1 << 23;
  static const int _kIsKeyboardKeyIndex = 1 << 24;
  static const int _kIsCheckStateMixedIndex = 1 << 25;
  static const int _kHasExpandedStateIndex = 1 << 26;
  static const int _kIsExpandedIndex = 1 << 27;
  static const int _kHasSelectedStateIndex = 1 << 28;
  static const int _kHasRequiredStateIndex = 1 << 29;
  static const int _kIsRequiredIndex = 1 << 30;
  // READ THIS: if you add a flag here, you MUST update the following:
  //
  // - The maximum supported bit index on the web (in JS mode) is 1 << 31.
  // - Add an appropriately named and documented `static const SemanticsFlag`
  //   field to this class.
  // - Add the new flag to `_kFlagById` in this file.
  // - Make changes in lib/web_ui/lib/semantics.dart in the web engine that mirror
  //   the changes in this file (i.e. `_k*Index`, `static const SemanticsFlag`,
  //   `_kFlagById`).
  // - Increment the `numSemanticsFlags` value in testing/dart/semantics_test.dart
  //   and in lib/web_ui/test/engine/semantics/semantics_api_test.dart.
  // - Add the new flag to platform-specific enums:
  //   - The `Flag` enum in flutter/shell/platform/android/io/flutter/view/AccessibilityBridge.java.
  //   - The `SemanticsFlags` enum in lib/ui/semantics/semantics_node.h.
  //   - The `FlutterSemanticsFlag` enum in shell/platform/embedder/embedder.h.
  // - If the new flag affects the visibility of a [SemanticsNode] to accessibility services,
  //   update `flutter_test/controller.dart#SemanticsController._importantFlags`
  //   accordingly.
  // - If the new flag affects focusability of a semantics node, also update the
  //   value of `AccessibilityBridge.FOCUSABLE_FLAGS` in
  //   flutter/shell/platform/android/io/flutter/view/AccessibilityBridge.java.

  /// {@template dart.ui.semantics.hasCheckedState}
  /// The semantics node has the quality of either being "checked" or "unchecked".
  ///
  /// This flag is mutually exclusive with [hasToggledState].
  ///
  /// For example, a checkbox or a radio button widget has checked state.
  ///
  /// See also:
  ///
  ///   * [SemanticsFlag.isChecked], which controls whether the node is "checked" or "unchecked".
  /// {@endtemplate}
  static const SemanticsFlag hasCheckedState = SemanticsFlag._(
    _kHasCheckedStateIndex,
    'hasCheckedState',
  );

  /// {@template dart.ui.semantics.isChecked}
  /// Whether a semantics node that [hasCheckedState] is checked.
  ///
  /// If true, the semantics node is "checked". If false, the semantics node is
  /// "unchecked".
  ///
  /// For example, if a checkbox has a visible checkmark, [isChecked] is true.
  ///
  /// See also:
  ///
  ///   * [SemanticsFlag.hasCheckedState], which enables a checked state.
  /// {@endtemplate}
  ///
  static const SemanticsFlag isChecked = SemanticsFlag._(_kIsCheckedIndex, 'isChecked');

  /// {@template dart.ui.semantics.isCheckStateMixed}
  /// Whether a tristate checkbox is in its mixed state.
  ///
  /// If this is true, the check box this semantics node represents
  /// is in a mixed state.
  ///
  /// For example, a [Checkbox] with [Checkbox.tristate] set to true
  /// can have checked,  unchecked, or mixed state.
  ///
  /// Must be false when the checkbox is either checked or unchecked.
  /// {@endtemplate}
  static const SemanticsFlag isCheckStateMixed = SemanticsFlag._(
    _kIsCheckStateMixedIndex,
    'isCheckStateMixed',
  );

  /// {@template dart.ui.semantics.hasSelectedState}
  /// The semantics node has the quality of either being "selected" or "unselected".
  ///
  /// Whether the widget corresponding to this node is currently selected or not
  /// is determined by the [isSelected] flag.
  ///
  /// When this flag is not set, the corresponding widget cannot be selected by
  /// the user, and the presence or the lack of [isSelected] does not carry any
  /// meaning.
  /// {@endtemplate}
  static const SemanticsFlag hasSelectedState = SemanticsFlag._(
    _kHasSelectedStateIndex,
    'hasSelectedState',
  );

  /// {@template dart.ui.semantics.isSelected}
  /// Whether a semantics node is selected.
  ///
  /// This flag only has meaning in nodes that have [hasSelectedState] flag set.
  ///
  /// If true, the semantics node is "selected". If false, the semantics node is
  /// "unselected".
  ///
  /// For example, the active tab in a tab bar has [isSelected] set to true.
  /// {@endtemplate}
  static const SemanticsFlag isSelected = SemanticsFlag._(_kIsSelectedIndex, 'isSelected');

  /// {@template dart.ui.semantics.isButton}
  /// Whether the semantic node represents a button.
  ///
  /// Platforms have special handling for buttons, for example Android's TalkBack
  /// and iOS's VoiceOver provides an additional hint when the focused object is
  /// a button.
  /// {@endtemplate}
  static const SemanticsFlag isButton = SemanticsFlag._(_kIsButtonIndex, 'isButton');

  /// {@template dart.ui.semantics.isTextField}
  /// Whether the semantic node represents a text field.
  ///
  /// Text fields are announced as such and allow text input via accessibility
  /// affordances.
  /// {@endtemplate}
  static const SemanticsFlag isTextField = SemanticsFlag._(_kIsTextFieldIndex, 'isTextField');

  /// {@template dart.ui.semantics.isSlider}
  /// Whether the semantic node represents a slider.
  /// {@endtemplate}
  static const SemanticsFlag isSlider = SemanticsFlag._(_kIsSliderIndex, 'isSlider');

  /// {@template dart.ui.semantics.isKeyboardKey}
  /// Whether the semantic node represents a keyboard key.
  /// {@endtemplate}
  static const SemanticsFlag isKeyboardKey = SemanticsFlag._(_kIsKeyboardKeyIndex, 'isKeyboardKey');

  /// {@template dart.ui.semantics.isReadOnly}
  /// Whether the semantic node is read only.
  ///
  /// Only applicable when [isTextField] is true.
  /// {@endtemplate}
  static const SemanticsFlag isReadOnly = SemanticsFlag._(_kIsReadOnlyIndex, 'isReadOnly');

  /// {@template dart.ui.semantics.isLink}
  /// Whether the semantic node is an interactive link.
  ///
  /// Platforms have special handling for links, for example iOS's VoiceOver
  /// provides an additional hint when the focused object is a link, as well as
  /// the ability to parse the links through another navigation menu.
  /// {@endtemplate}
  static const SemanticsFlag isLink = SemanticsFlag._(_kIsLinkIndex, 'isLink');

  /// {@template dart.ui.semantics.isFocusable}
  /// Whether the semantic node is able to hold the user's focus.
  ///
  /// The focused element is usually the current receiver of keyboard inputs.
  /// {@endtemplate}
  static const SemanticsFlag isFocusable = SemanticsFlag._(_kIsFocusableIndex, 'isFocusable');

  /// {@template dart.ui.semantics.isFocused}
  /// Whether the semantic node currently holds the user's focus.
  ///
  /// The focused element is usually the current receiver of keyboard inputs.
  /// {@endtemplate}
  static const SemanticsFlag isFocused = SemanticsFlag._(_kIsFocusedIndex, 'isFocused');

  /// {@template dart.ui.semantics.hasEnabledState}
  /// The semantics node has the quality of either being "enabled" or
  /// "disabled".
  ///
  /// For example, a button can be enabled or disabled and therefore has an
  /// "enabled" state. Static text is usually neither enabled nor disabled and
  /// therefore does not have an "enabled" state.
  /// {@endtemplate}
  static const SemanticsFlag hasEnabledState = SemanticsFlag._(
    _kHasEnabledStateIndex,
    'hasEnabledState',
  );

  /// {@template dart.ui.semantics.isEnabled}
  /// Whether a semantic node that [hasEnabledState] is currently enabled.
  ///
  /// A disabled element does not respond to user interaction. For example, a
  /// button that currently does not respond to user interaction should be
  /// marked as disabled.
  /// {@endtemplate}
  static const SemanticsFlag isEnabled = SemanticsFlag._(_kIsEnabledIndex, 'isEnabled');

  /// {@template dart.ui.semantics.isInMutuallyExclusiveGroup}
  /// Whether a semantic node is in a mutually exclusive group.
  ///
  /// For example, a radio button is in a mutually exclusive group because
  /// only one radio button in that group can be marked as [isChecked].
  /// {@endtemplate}
  static const SemanticsFlag isInMutuallyExclusiveGroup = SemanticsFlag._(
    _kIsInMutuallyExclusiveGroupIndex,
    'isInMutuallyExclusiveGroup',
  );

  /// {@template dart.ui.semantics.isHeader}
  /// Whether a semantic node is a header that divides content into sections.
  ///
  /// For example, headers can be used to divide a list of alphabetically
  /// sorted words into the sections A, B, C, etc. as can be found in many
  /// address book applications.
  /// {@endtemplate}
  static const SemanticsFlag isHeader = SemanticsFlag._(_kIsHeaderIndex, 'isHeader');

  /// {@template dart.ui.semantics.isObscured}
  /// Whether the value of the semantics node is obscured.
  ///
  /// This is usually used for text fields to indicate that its content
  /// is a password or contains other sensitive information.
  /// {@endtemplate}
  static const SemanticsFlag isObscured = SemanticsFlag._(_kIsObscuredIndex, 'isObscured');

  /// {@template dart.ui.semantics.isMultiline}
  /// Whether the value of the semantics node is coming from a multi-line text
  /// field.
  ///
  /// This is used for text fields to distinguish single-line text fields from
  /// multi-line ones.
  /// {@endtemplate}
  static const SemanticsFlag isMultiline = SemanticsFlag._(_kIsMultilineIndex, 'isMultiline');

  /// {@template dart.ui.semantics.scopesRoute}
  /// Whether the semantics node is the root of a subtree for which a route name
  /// should be announced.
  ///
  /// When a node with this flag is removed from the semantics tree, the
  /// framework will select the last in depth-first, paint order node with this
  /// flag.  When a node with this flag is added to the semantics tree, it is
  /// selected automatically, unless there were multiple nodes with this flag
  /// added.  In this case, the last added node in depth-first, paint order
  /// will be selected.
  ///
  /// From this selected node, the framework will search in depth-first, paint
  /// order for the first node with a [namesRoute] flag and a non-null,
  /// non-empty label. The [namesRoute] and [scopesRoute] flags may be on the
  /// same node. The label of the found node will be announced as an edge
  /// transition. If no non-empty, non-null label is found then:
  ///
  ///   * VoiceOver will make a chime announcement.
  ///   * TalkBack will make no announcement
  ///
  /// Semantic nodes annotated with this flag are generally not a11y focusable.
  ///
  /// This is used in widgets such as Routes, Drawers, and Dialogs to
  /// communicate significant changes in the visible screen.
  /// {@endtemplate}
  static const SemanticsFlag scopesRoute = SemanticsFlag._(_kScopesRouteIndex, 'scopesRoute');

  /// {@template dart.ui.semantics.namesRoute}
  /// Whether the semantics node label is the name of a visually distinct
  /// route.
  ///
  /// This is used by certain widgets like Drawers and Dialogs, to indicate
  /// that the node's semantic label can be used to announce an edge triggered
  /// semantics update.
  ///
  /// Semantic nodes annotated with this flag will still receive a11y focus.
  ///
  /// Updating this label within the same active route subtree will not cause
  /// additional announcements.
  /// {@endtemplate}
  static const SemanticsFlag namesRoute = SemanticsFlag._(_kNamesRouteIndex, 'namesRoute');

  /// {@template dart.ui.semantics.isHidden}
  /// Whether the semantics node is considered hidden.
  ///
  /// Hidden elements are currently not visible on screen. They may be covered
  /// by other elements or positioned outside of the visible area of a viewport.
  ///
  /// Hidden elements cannot gain accessibility focus though regular touch. The
  /// only way they can be focused is by moving the focus to them via linear
  /// navigation.
  ///
  /// Platforms are free to completely ignore hidden elements and new platforms
  /// are encouraged to do so.
  ///
  /// Instead of marking an element as hidden it should usually be excluded from
  /// the semantics tree altogether. Hidden elements are only included in the
  /// semantics tree to work around platform limitations and they are mainly
  /// used to implement accessibility scrolling on iOS.
  ///
  /// See also:
  ///
  /// * [RenderObject.describeSemanticsClip]
  /// {@endtemplate}
  static const SemanticsFlag isHidden = SemanticsFlag._(_kIsHiddenIndex, 'isHidden');

  /// {@template dart.ui.semantics.isImage}
  /// Whether the semantics node represents an image.
  ///
  /// Both TalkBack and VoiceOver will inform the user the semantics node
  /// represents an image.
  /// {@endtemplate}
  static const SemanticsFlag isImage = SemanticsFlag._(_kIsImageIndex, 'isImage');

  /// {@template dart.ui.semantics.isLiveRegion}
  /// Whether the semantics node is a live region.
  ///
  /// A live region indicates that updates to semantics node are important.
  /// Platforms may use this information to make polite announcements to the
  /// user to inform them of updates to this node.
  ///
  /// An example of a live region is a [SnackBar] widget. On Android and iOS,
  /// live region causes a polite announcement to be generated automatically,
  /// even if the widget does not have accessibility focus. This announcement
  /// may not be spoken if the OS accessibility services are already
  /// announcing something else, such as reading the label of a focused
  /// widget or providing a system announcement.
  /// {@endtemplate}
  static const SemanticsFlag isLiveRegion = SemanticsFlag._(_kIsLiveRegionIndex, 'isLiveRegion');

  /// {@template dart.ui.semantics.hasToggledState}
  /// The semantics node has the quality of either being "on" or "off".
  ///
  /// This flag is mutually exclusive with [hasCheckedState].
  ///
  /// For example, a switch has toggled state.
  ///
  /// See also:
  ///
  ///    * [SemanticsFlag.isToggled], which controls whether the node is "on" or "off".
  /// {@endtemplate}
  static const SemanticsFlag hasToggledState = SemanticsFlag._(
    _kHasToggledStateIndex,
    'hasToggledState',
  );

  /// {@template dart.ui.semantics.isToggled}
  /// If true, the semantics node is "on". If false, the semantics node is
  /// "off".
  ///
  /// For example, if a switch is in the on position, [isToggled] is true.
  ///
  /// See also:
  ///
  ///   * [SemanticsFlag.hasToggledState], which enables a toggled state.
  /// {@endtemplate}
  static const SemanticsFlag isToggled = SemanticsFlag._(_kIsToggledIndex, 'isToggled');

  /// {@template dart.ui.semantics.hasImplicitScrolling}
  /// Whether the platform can scroll the semantics node when the user attempts
  /// to move focus to an offscreen child.
  ///
  /// For example, a [ListView] widget has implicit scrolling so that users can
  /// easily move the accessibility focus to the next set of children. A
  /// [PageView] widget does not have implicit scrolling, so that users don't
  /// navigate to the next page when reaching the end of the current one.
  /// {@endtemplate}
  static const SemanticsFlag hasImplicitScrolling = SemanticsFlag._(
    _kHasImplicitScrollingIndex,
    'hasImplicitScrolling',
  );

  /// {@template dart.ui.semantics.hasExpandedState}
  /// The semantics node has the quality of either being "expanded" or "collapsed".
  ///
  /// For example, a [SubmenuButton] widget has expanded state.
  ///
  /// See also:
  ///
  ///   * [SemanticsFlag.isExpanded], which controls whether the node is "expanded" or "collapsed".
  /// {@endtemplate}
  static const SemanticsFlag hasExpandedState = SemanticsFlag._(
    _kHasExpandedStateIndex,
    'hasExpandedState',
  );

  /// {@template dart.ui.semantics.isExpanded}
  /// Whether a semantics node is expanded.
  ///
  /// If true, the semantics node is "expanded". If false, the semantics node is
  /// "collapsed".
  ///
  /// For example, if a [SubmenuButton] shows its children, [isExpanded] is true.
  ///
  /// See also:
  ///
  ///   * [SemanticsFlag.hasExpandedState], which enables an expanded/collapsed state.
  /// {@endtemplate}
  static const SemanticsFlag isExpanded = SemanticsFlag._(_kIsExpandedIndex, 'isExpanded');

  /// {@template dart.ui.semantics.hasRequiredState}
  /// The semantics node has the quality of either being required or not.
  ///
  /// See also:
  ///
  ///   * [SemanticsFlag.isRequired], which controls whether the node is required.
  /// {@endtemplate}
  static const SemanticsFlag hasRequiredState = SemanticsFlag._(
    _kHasRequiredStateIndex,
    'hasRequiredState',
  );

  /// {@template dart.ui.semantics.isRequired}
  /// Whether a semantics node is required.
  ///
  /// If true, user input is required on the semantics node before a form can
  /// be submitted.
  ///
  /// For example, a login form requires its email text field to be non-empty.
  ///
  /// See also:
  ///
  ///   * [SemanticsFlag.hasRequiredState], which enables a required state state.
  /// {@endtemplate}
  static const SemanticsFlag isRequired = SemanticsFlag._(_kIsRequiredIndex, 'isRequired');

  /// The possible semantics flags.
  ///
  /// The map's key is the [index] of the flag and the value is the flag itself.
  static const Map<int, SemanticsFlag> _kFlagById = <int, SemanticsFlag>{
    _kHasCheckedStateIndex: hasCheckedState,
    _kIsCheckedIndex: isChecked,
    _kHasSelectedStateIndex: hasSelectedState,
    _kIsSelectedIndex: isSelected,
    _kIsButtonIndex: isButton,
    _kIsTextFieldIndex: isTextField,
    _kIsFocusedIndex: isFocused,
    _kHasEnabledStateIndex: hasEnabledState,
    _kIsEnabledIndex: isEnabled,
    _kIsInMutuallyExclusiveGroupIndex: isInMutuallyExclusiveGroup,
    _kIsHeaderIndex: isHeader,
    _kIsObscuredIndex: isObscured,
    _kScopesRouteIndex: scopesRoute,
    _kNamesRouteIndex: namesRoute,
    _kIsHiddenIndex: isHidden,
    _kIsImageIndex: isImage,
    _kIsLiveRegionIndex: isLiveRegion,
    _kHasToggledStateIndex: hasToggledState,
    _kIsToggledIndex: isToggled,
    _kHasImplicitScrollingIndex: hasImplicitScrolling,
    _kIsMultilineIndex: isMultiline,
    _kIsReadOnlyIndex: isReadOnly,
    _kIsFocusableIndex: isFocusable,
    _kIsLinkIndex: isLink,
    _kIsSliderIndex: isSlider,
    _kIsKeyboardKeyIndex: isKeyboardKey,
    _kIsCheckStateMixedIndex: isCheckStateMixed,
    _kHasExpandedStateIndex: hasExpandedState,
    _kIsExpandedIndex: isExpanded,
    _kHasRequiredStateIndex: hasRequiredState,
    _kIsRequiredIndex: isRequired,
  };

  // TODO(matanlurey): have original authors document; see https://github.com/flutter/flutter/issues/151917.
  // ignore: public_member_api_docs
  static List<SemanticsFlag> get values => _kFlagById.values.toList(growable: false);

  // TODO(matanlurey): have original authors document; see https://github.com/flutter/flutter/issues/151917.
  // ignore: public_member_api_docs
  static SemanticsFlag? fromIndex(int index) => _kFlagById[index];

  @override
  String toString() => 'SemanticsFlag.$name';
}

/// Checked state of a semantics node.
enum CheckedState {
  /// The semantics node does not have a check state.
  none(0),

  /// The semantics node is checked.
  isTrue(1),

  /// The semantics node is not checked.
  isFalse(2),

  /// The semantics node represents a tristate checkbox in a mixed state.
  mixed(3);

  /// The Constructor of the flag.
  const CheckedState(this.value);

  /// The value of the flag.
  final int value;

  /// If two semantics nodes both have check state, they have conflict and can't be merged.
  bool hasConflict(CheckedState other) => this != CheckedState.none && other != CheckedState.none;

  /// Semanitcs nodes  will only be merged when they are not in conflict.
  CheckedState merge(CheckedState other) {
    if (this == CheckedState.mixed || other == CheckedState.mixed) {
      return CheckedState.mixed;
    }
    if (this == CheckedState.isTrue || other == CheckedState.isTrue) {
      return CheckedState.isTrue;
    }
    if (this == CheckedState.isFalse || other == CheckedState.isFalse) {
      return CheckedState.isFalse;
    }
    return CheckedState.none;
  }
}

/// Tristate flags for a semantics not
enum Tristate {
  /// The property is not applicable to this semantics node.
  none(0),

  /// The property is applicable and its state is "true" or "on".
  isTrue(1),

  /// The property is applicable and its state is "false" or "off".
  isFalse(2);

  /// The Constructor of the flag.
  const Tristate(this.value);

  /// The value of the flag.
  final int value;

  /// If two semantics nodes both have this property, they have conflict and can't be merged.
  bool hasConflict(Tristate other) => this != Tristate.none && other != Tristate.none;

  /// Semanitcs nodes  will only be merged when they are not in conflict.
  Tristate merge(Tristate other) {
    if (this == Tristate.isTrue || other == Tristate.isTrue) {
      return Tristate.isTrue;
    }
    if (this == Tristate.isFalse || other == Tristate.isFalse) {
      return Tristate.isFalse;
    }
    return Tristate.none;
  }

  /// Convert a Tristate flag to bool or null.
  bool? toBoolOrNull() {
    switch (this) {
      case Tristate.none:
        return null;
      case Tristate.isTrue:
        return true;
      case Tristate.isFalse:
        return false;
    }
  }
}

/// Describes how a semantic node should behave during hit testing.
///
/// This enum allows the framework to communicate pointer event handling
/// behavior to the platform's accessibility layer. Different platforms
/// may implement this behavior differently based on their accessibility
/// infrastructure.
///
/// See also:
///  * [SemanticsUpdateBuilder.updateNode], which accepts this enum.
enum SemanticsHitTestBehavior {
  /// Defer to the platform's default hit test behavior inference.
  ///
  /// When set to defer, the platform will infer the appropriate behavior
  /// based on the semantic node's properties such as interactive behaviors,
  /// route scoping, etc.
  ///
  /// On the web, the default inferred behavior is `transparent` for
  /// non-interactive semantic nodes, allowing pointer events to pass through.
  ///
  /// This is the default value and provides backward compatibility.
  defer,

  /// The semantic element is opaque to hit testing, consuming any pointer
  /// events within its bounds and preventing them from reaching elements
  /// behind it in Z-order (siblings and ancestors).
  ///
  /// Children of this node can still receive pointer events normally.
  /// Only elements that are visually behind this node (lower in the stacking
  /// order) will be blocked from receiving events.
  ///
  /// This is typically used for modal surfaces like dialogs, bottom sheets,
  /// and drawers that should block interaction with content behind them while
  /// still allowing interaction with their own content.
  ///
  /// Platform implementations:
  ///  * On the web, this results in `pointer-events: all` CSS property.
  opaque,

  /// The semantic element is transparent to hit testing.
  ///
  /// Transparent nodes do not receive hit test events and allow events to pass
  /// through to elements behind them.
  ///
  /// Note: This differs from the framework's `HitTestBehavior.translucent`,
  /// which receives events while also allowing pass-through. Web's binary
  /// `pointer-events` property (all or none) cannot support true translucent
  /// behavior.
  ///
  /// Platform implementations:
  ///  * On the web, this results in `pointer-events: none` CSS property.
  transparent,
}

/// Represents a collection of boolean flags that convey semantic information
/// about a widget's accessibility state and properties.
///
/// For example, These flags can indicate if an element is
/// checkable, currently checked, selectable, or functions as a button.
class SemanticsFlags extends NativeFieldWrapperClass1 {
  /// Creates a set of semantics flags that describe various states of a widget.
  /// All flags default to `false` unless specified.
  SemanticsFlags({
    this.isChecked = CheckedState.none,
    this.isSelected = Tristate.none,
    this.isEnabled = Tristate.none,
    this.isToggled = Tristate.none,
    this.isExpanded = Tristate.none,
    this.isRequired = Tristate.none,
    this.isFocused = Tristate.none,
    this.isButton = false,
    this.isTextField = false,
    this.isInMutuallyExclusiveGroup = false,
    this.isHeader = false,
    this.isObscured = false,
    this.scopesRoute = false,
    this.namesRoute = false,
    this.isHidden = false,
    this.isImage = false,
    this.isLiveRegion = false,
    this.hasImplicitScrolling = false,
    this.isMultiline = false,
    this.isReadOnly = false,
    this.isLink = false,
    this.isSlider = false,
    this.isKeyboardKey = false,
    this.isAccessibilityFocusBlocked = false,
  }) {
    _initSemanticsFlags(
      this,
      isChecked.value,
      isSelected.value,
      isEnabled.value,
      isToggled.value,
      isExpanded.value,
      isRequired.value,
      isFocused.value,
      isButton,
      isTextField,
      isInMutuallyExclusiveGroup,
      isHeader,
      isObscured,
      scopesRoute,
      namesRoute,
      isHidden,
      isImage,
      isLiveRegion,
      hasImplicitScrolling,
      isMultiline,
      isReadOnly,
      isLink,
      isSlider,
      isKeyboardKey,
      isAccessibilityFocusBlocked,
    );
  }

  @Native<
    Void Function(
      Handle,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
      Bool,
    )
  >(symbol: 'NativeSemanticsFlags::initSemanticsFlags')
  external static void _initSemanticsFlags(
    SemanticsFlags instance,
    int isChecked,
    int isSelected,
    int isEnabled,
    int isToggled,
    int isExpanded,
    int isRequired,
    int isFocused,
    bool isButton,
    bool isTextField,
    bool isInMutuallyExclusiveGroup,
    bool isHeader,
    bool isObscured,
    bool scopesRoute,
    bool namesRoute,
    bool isHidden,
    bool isImage,
    bool isLiveRegion,
    bool hasImplicitScrolling,
    bool isMultiline,
    bool isReadOnly,
    bool isLink,
    bool isSlider,
    bool isKeyboardKey,
    bool isAccessibilityFocusBlocked,
  );

  /// The set of semantics flags with every flag set to false.
  static SemanticsFlags none = SemanticsFlags();

  /// {@macro dart.ui.semantics.hasCheckedState}
  final CheckedState isChecked;

  /// {@macro dart.ui.semantics.isSelected}
  final Tristate isSelected;

  /// {@macro dart.ui.semantics.isEnabled}
  final Tristate isEnabled;

  /// {@macro dart.ui.semantics.isToggled}
  final Tristate isToggled;

  /// {@macro dart.ui.semantics.isExpanded}
  final Tristate isExpanded;

  /// {@macro dart.ui.semantics.isRequired}
  final Tristate isRequired;

  /// {@macro dart.ui.semantics.isFocused}
  final Tristate isFocused;

  /// whether this node's accessibility focus is blocked.
  ///
  /// If `true`, this node is not accessibility focusable.
  /// If `false`, the a11y focusability is determined based on
  /// the node's role and other properties, such as whether it is a button.
  ///
  /// This is for accessibility focus, which is the focus used by screen readers
  /// like TalkBack and VoiceOver. It is different from input focus, which is
  /// usually held by the element that currently responds to keyboard inputs.
  final bool isAccessibilityFocusBlocked;

  /// {@macro dart.ui.semantics.isButton}
  final bool isButton;

  /// {@macro dart.ui.semantics.isTextField}
  final bool isTextField;

  /// {@macro dart.ui.semantics.isInMutuallyExclusiveGroup}
  final bool isInMutuallyExclusiveGroup;

  /// {@macro dart.ui.semantics.isHeader}
  final bool isHeader;

  /// {@macro dart.ui.semantics.isObscured}
  final bool isObscured;

  /// {@macro dart.ui.semantics.scopesRoute}
  final bool scopesRoute;

  /// {@macro dart.ui.semantics.namesRoute}
  final bool namesRoute;

  /// {@macro dart.ui.semantics.isHidden}
  final bool isHidden;

  /// {@macro dart.ui.semantics.isImage}
  final bool isImage;

  /// {@macro dart.ui.semantics.isLiveRegion}
  final bool isLiveRegion;

  /// {@macro dart.ui.semantics.hasImplicitScrolling}
  final bool hasImplicitScrolling;

  /// {@macro dart.ui.semantics.isMultiline}
  final bool isMultiline;

  /// {@macro dart.ui.semantics.isReadOnly}
  final bool isReadOnly;

  /// {@macro dart.ui.semantics.isLink}
  final bool isLink;

  /// {@macro dart.ui.semantics.isSlider}
  final bool isSlider;

  /// {@macro dart.ui.semantics.isKeyboardKey}
  final bool isKeyboardKey;

  /// Combines two sets of flags, such that if a flag it set to true in any of the two sets, the resulting set contains that flag set to true.
  SemanticsFlags merge(SemanticsFlags other) {
    return SemanticsFlags(
      isChecked: isChecked.merge(other.isChecked),
      isSelected: isSelected.merge(other.isSelected),
      isEnabled: isEnabled.merge(other.isEnabled),
      isToggled: isToggled.merge(other.isToggled),
      isExpanded: isExpanded.merge(other.isExpanded),
      isRequired: isRequired.merge(other.isRequired),
      isFocused: isFocused.merge(other.isFocused),
      isButton: isButton || other.isButton,
      isTextField: isTextField || other.isTextField,
      isInMutuallyExclusiveGroup: isInMutuallyExclusiveGroup || other.isInMutuallyExclusiveGroup,
      isHeader: isHeader || other.isHeader,
      isObscured: isObscured || other.isObscured,
      scopesRoute: scopesRoute || other.scopesRoute,
      namesRoute: namesRoute || other.namesRoute,
      isHidden: isHidden || other.isHidden,
      isImage: isImage || other.isImage,
      isLiveRegion: isLiveRegion || other.isLiveRegion,
      hasImplicitScrolling: hasImplicitScrolling || other.hasImplicitScrolling,
      isMultiline: isMultiline || other.isMultiline,
      isReadOnly: isReadOnly || other.isReadOnly,
      isLink: isLink || other.isLink,
      isSlider: isSlider || other.isSlider,
      isKeyboardKey: isKeyboardKey || other.isKeyboardKey,
      isAccessibilityFocusBlocked: isAccessibilityFocusBlocked || other.isAccessibilityFocusBlocked,
    );
  }

  /// Copy the semantics flags, with some of them optionally replaced.
  SemanticsFlags copyWith({
    CheckedState? isChecked,
    Tristate? isSelected,
    Tristate? isEnabled,
    Tristate? isToggled,
    Tristate? isExpanded,
    Tristate? isRequired,
    Tristate? isFocused,
    bool? isButton,
    bool? isTextField,
    bool? isInMutuallyExclusiveGroup,
    bool? isHeader,
    bool? isObscured,
    bool? scopesRoute,
    bool? namesRoute,
    bool? isHidden,
    bool? isImage,
    bool? isLiveRegion,
    bool? hasImplicitScrolling,
    bool? isMultiline,
    bool? isReadOnly,
    bool? isLink,
    bool? isSlider,
    bool? isKeyboardKey,
    bool? isAccessibilityFocusBlocked,
  }) {
    return SemanticsFlags(
      isChecked: isChecked ?? this.isChecked,
      isSelected: isSelected ?? this.isSelected,
      isButton: isButton ?? this.isButton,
      isTextField: isTextField ?? this.isTextField,
      isFocused: isFocused ?? this.isFocused,
      isEnabled: isEnabled ?? this.isEnabled,
      isInMutuallyExclusiveGroup: isInMutuallyExclusiveGroup ?? this.isInMutuallyExclusiveGroup,
      isHeader: isHeader ?? this.isHeader,
      isObscured: isObscured ?? this.isObscured,
      scopesRoute: scopesRoute ?? this.scopesRoute,
      namesRoute: namesRoute ?? this.namesRoute,
      isHidden: isHidden ?? this.isHidden,
      isImage: isImage ?? this.isImage,
      isLiveRegion: isLiveRegion ?? this.isLiveRegion,
      isToggled: isToggled ?? this.isToggled,
      hasImplicitScrolling: hasImplicitScrolling ?? this.hasImplicitScrolling,
      isMultiline: isMultiline ?? this.isMultiline,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isLink: isLink ?? this.isLink,
      isSlider: isSlider ?? this.isSlider,
      isKeyboardKey: isKeyboardKey ?? this.isKeyboardKey,
      isExpanded: isExpanded ?? this.isExpanded,
      isRequired: isRequired ?? this.isRequired,
      isAccessibilityFocusBlocked: isAccessibilityFocusBlocked ?? this.isAccessibilityFocusBlocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticsFlags &&
          runtimeType == other.runtimeType &&
          isChecked == other.isChecked &&
          isSelected == other.isSelected &&
          isEnabled == other.isEnabled &&
          isToggled == other.isToggled &&
          isExpanded == other.isExpanded &&
          isRequired == other.isRequired &&
          isFocused == other.isFocused &&
          isButton == other.isButton &&
          isTextField == other.isTextField &&
          isInMutuallyExclusiveGroup == other.isInMutuallyExclusiveGroup &&
          isHeader == other.isHeader &&
          isObscured == other.isObscured &&
          scopesRoute == other.scopesRoute &&
          namesRoute == other.namesRoute &&
          isHidden == other.isHidden &&
          isImage == other.isImage &&
          isLiveRegion == other.isLiveRegion &&
          hasImplicitScrolling == other.hasImplicitScrolling &&
          isMultiline == other.isMultiline &&
          isReadOnly == other.isReadOnly &&
          isLink == other.isLink &&
          isSlider == other.isSlider &&
          isKeyboardKey == other.isKeyboardKey &&
          isAccessibilityFocusBlocked == other.isAccessibilityFocusBlocked;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    isChecked,
    isSelected,
    isEnabled,
    isToggled,
    isExpanded,
    isRequired,
    isFocused,
    isButton,
    isTextField,
    isInMutuallyExclusiveGroup,
    isHeader,
    isObscured,
    scopesRoute,
    namesRoute,
    isHidden,
    isImage,
    isLiveRegion,
    hasImplicitScrolling,
    isMultiline,
    isReadOnly,
    isLink,
    isSlider,
    isKeyboardKey,
    isAccessibilityFocusBlocked,
  ]);

  /// Convert flags to a list of string.
  List<String> toStrings() {
    return <String>[
      if (isChecked != CheckedState.none) 'hasCheckedState',
      if (isChecked == CheckedState.isTrue) 'isChecked',
      if (isSelected == Tristate.isTrue) 'isSelected',
      if (isButton) 'isButton',
      if (isTextField) 'isTextField',
      if (isFocused == Tristate.isTrue) 'isFocused',
      if (isEnabled != Tristate.none) 'hasEnabledState',
      if (isEnabled == Tristate.isTrue) 'isEnabled',
      if (isInMutuallyExclusiveGroup) 'isInMutuallyExclusiveGroup',
      if (isHeader) 'isHeader',
      if (isObscured) 'isObscured',
      if (scopesRoute) 'scopesRoute',
      if (namesRoute) 'namesRoute',
      if (isHidden) 'isHidden',
      if (isImage) 'isImage',
      if (isLiveRegion) 'isLiveRegion',
      if (isToggled != Tristate.none) 'hasToggledState',
      if (isToggled == Tristate.isTrue) 'isToggled',
      if (hasImplicitScrolling) 'hasImplicitScrolling',
      if (isMultiline) 'isMultiline',
      if (isReadOnly) 'isReadOnly',
      if (isFocused != Tristate.none) 'isFocusable',
      if (isAccessibilityFocusBlocked) 'isAccessibilityFocusBlocked',
      if (isLink) 'isLink',
      if (isSlider) 'isSlider',
      if (isKeyboardKey) 'isKeyboardKey',
      if (isChecked == CheckedState.mixed) 'isCheckStateMixed',
      if (isExpanded != Tristate.none) 'hasExpandedState',
      if (isExpanded == Tristate.isTrue) 'isExpanded',
      if (isSelected != Tristate.none) 'hasSelectedState',
      if (isRequired != Tristate.none) 'hasRequiredState',
      if (isRequired == Tristate.isTrue) 'isRequired',
    ];
  }

  @Deprecated(
    'Use hasConflictingFlags instead.'
    'This feature was deprecated after v3.39.0-0.0.pre',
  )
  /// Checks if any of the boolean semantic flags are set to true
  /// in both this instance and the [other] instance.
  bool hasRepeatedFlags(SemanticsFlags other) {
    return isChecked.hasConflict(other.isChecked) ||
        isSelected.hasConflict(other.isSelected) ||
        isEnabled.hasConflict(other.isEnabled) ||
        isToggled.hasConflict(other.isToggled) ||
        isEnabled.hasConflict(other.isEnabled) ||
        isExpanded.hasConflict(other.isExpanded) ||
        isRequired.hasConflict(other.isRequired) ||
        isFocused.hasConflict(other.isFocused) ||
        (isButton && other.isButton) ||
        (isTextField && other.isTextField) ||
        (isInMutuallyExclusiveGroup && other.isInMutuallyExclusiveGroup) ||
        (isHeader && other.isHeader) ||
        (isObscured && other.isObscured) ||
        (scopesRoute && other.scopesRoute) ||
        (namesRoute && other.namesRoute) ||
        (isHidden && other.isHidden) ||
        (isImage && other.isImage) ||
        (isLiveRegion && other.isLiveRegion) ||
        (hasImplicitScrolling && other.hasImplicitScrolling) ||
        (isMultiline && other.isMultiline) ||
        (isReadOnly && other.isReadOnly) ||
        (isLink && other.isLink) ||
        (isSlider && other.isSlider) ||
        (isKeyboardKey && other.isKeyboardKey);
  }

  /// Checks if any flags are conflicted in this instance and the [other] instance.
  bool hasConflictingFlags(SemanticsFlags other) {
    return isChecked.hasConflict(other.isChecked) ||
        isSelected.hasConflict(other.isSelected) ||
        isEnabled.hasConflict(other.isEnabled) ||
        isToggled.hasConflict(other.isToggled) ||
        isEnabled.hasConflict(other.isEnabled) ||
        isExpanded.hasConflict(other.isExpanded) ||
        isRequired.hasConflict(other.isRequired) ||
        isFocused.hasConflict(other.isFocused) ||
        (isButton && other.isButton) ||
        (isTextField && other.isTextField) ||
        (isInMutuallyExclusiveGroup && other.isInMutuallyExclusiveGroup) ||
        (isHeader && other.isHeader) ||
        (isObscured && other.isObscured) ||
        (scopesRoute && other.scopesRoute) ||
        (namesRoute && other.namesRoute) ||
        (isHidden && other.isHidden) ||
        (isImage && other.isImage) ||
        (isLiveRegion && other.isLiveRegion) ||
        (hasImplicitScrolling && other.hasImplicitScrolling) ||
        (isMultiline && other.isMultiline) ||
        (isReadOnly && other.isReadOnly) ||
        (isLink && other.isLink) ||
        (isSlider && other.isSlider) ||
        (isKeyboardKey && other.isKeyboardKey) ||
        (isAccessibilityFocusBlocked != other.isAccessibilityFocusBlocked);
  }
}

/// The validation result of a form field.
///
/// The type, shape, and correctness of the value is specific to the kind of
/// form field used. For example, a phone number text field may check that the
/// value is a properly formatted phone number, and/or that the phone number has
/// the right area code. A group of radio buttons may validate that the user
/// selected at least one radio option.
enum SemanticsValidationResult {
  /// The node has no validation information attached to it.
  ///
  /// This is the default value. Most semantics nodes do not contain validation
  /// information. Typically, only nodes that are part of an input form - text
  /// fields, checkboxes, radio buttons, dropdowns - are validated and attach
  /// validation results to their corresponding semantics nodes.
  none,

  /// The entered value is valid, and no error should be displayed to the user.
  valid,

  /// The entered value is invalid, and an error message should be communicated
  /// to the user.
  invalid,
}

// When adding a new StringAttribute, the classes in these files must be
// updated as well.
//  * engine/src/flutter/lib/web_ui/lib/semantics.dart
//  * engine/src/flutter/lib/ui/semantics/string_attribute.h
//  * engine/src/flutter/shell/platform/android/io/flutter/view/AccessibilityBridge.java
//  * engine/src/flutter/lib/web_ui/test/engine/semantics/semantics_api_test.dart
//  * engine/src/flutter/testing/dart/semantics_test.dart

/// An abstract interface for string attributes that affects how assistive
/// technologies, e.g. VoiceOver or TalkBack, treat the text.
///
/// See also:
///
///  * [AttributedString], where the string attributes are used.
///  * [SpellOutStringAttribute], which causes the assistive technologies to
///    spell out the string character by character when announcing the string.
///  * [LocaleStringAttribute], which causes the assistive technologies to
///    treat the string in the specific language.
abstract base class StringAttribute extends NativeFieldWrapperClass1 {
  StringAttribute._({required this.range});

  /// The range of the text to which this attribute applies.
  final TextRange range;

  /// Creates a new attribute with all properties copied except for range, which
  /// is updated to the specified value.
  ///
  /// For example, the [LocaleStringAttribute] specifies a [Locale] for its
  /// range of characters. Copying it will result in a new
  /// [LocaleStringAttribute] that has the same locale but an updated
  /// [TextRange].
  StringAttribute copy({required TextRange range});
}

/// A string attribute that causes the assistive technologies, e.g. VoiceOver,
/// to spell out the string character by character.
///
/// See also:
///
///  * [AttributedString], where the string attributes are used.
///  * [LocaleStringAttribute], which causes the assistive technologies to
///    treat the string in the specific language.
base class SpellOutStringAttribute extends StringAttribute {
  /// Creates a string attribute that denotes the text in [range] must be
  /// spell out when the assistive technologies announce the string.
  SpellOutStringAttribute({required TextRange range}) : super._(range: range) {
    _initSpellOutStringAttribute(this, range.start, range.end);
  }

  @Native<Void Function(Handle, Int32, Int32)>(
    symbol: 'NativeStringAttribute::initSpellOutStringAttribute',
  )
  external static void _initSpellOutStringAttribute(
    SpellOutStringAttribute instance,
    int start,
    int end,
  );

  @override
  StringAttribute copy({required TextRange range}) {
    return SpellOutStringAttribute(range: range);
  }

  @override
  String toString() {
    return 'SpellOutStringAttribute($range)';
  }
}

/// A string attribute that causes the assistive technologies, e.g. VoiceOver,
/// to treat string as a certain language.
///
/// See also:
///
///  * [AttributedString], where the string attributes are used.
///  * [SpellOutStringAttribute], which causes the assistive technologies to
///    spell out the string character by character when announcing the string.
base class LocaleStringAttribute extends StringAttribute {
  /// Creates a string attribute that denotes the text in [range] must be
  /// treated as the language specified by the [locale] when the assistive
  /// technologies announce the string.
  LocaleStringAttribute({required TextRange range, required this.locale}) : super._(range: range) {
    _initLocaleStringAttribute(this, range.start, range.end, locale.toLanguageTag());
  }

  /// The language of this attribute.
  final Locale locale;

  @Native<Void Function(Handle, Int32, Int32, Handle)>(
    symbol: 'NativeStringAttribute::initLocaleStringAttribute',
  )
  external static void _initLocaleStringAttribute(
    LocaleStringAttribute instance,
    int start,
    int end,
    String locale,
  );

  @override
  StringAttribute copy({required TextRange range}) {
    return LocaleStringAttribute(range: range, locale: locale);
  }

  @override
  String toString() {
    return 'LocaleStringAttribute($range, ${locale.toLanguageTag()})';
  }
}

/// An object that creates [SemanticsUpdate] objects.
///
/// Once created, the [SemanticsUpdate] objects can be passed to
/// [PlatformDispatcher.updateSemantics] to update the semantics conveyed to the
/// user.
abstract class SemanticsUpdateBuilder {
  /// Creates an empty [SemanticsUpdateBuilder] object.
  factory SemanticsUpdateBuilder() = _NativeSemanticsUpdateBuilder;

  /// Update the information associated with the node with the given `id`.
  ///
  /// The semantics nodes form a tree, with the root of the tree always having
  /// an id of zero. The `childrenInTraversalOrder` and `childrenInHitTestOrder`
  /// are the ids of the nodes that are immediate children of this node. The
  /// former enumerates children in traversal order, and the latter enumerates
  /// the same children in the hit test order. The two lists must have the same
  /// length and contain the same ids. They may only differ in the order the
  /// ids are listed in. For more information about different child orders, see
  /// [DebugSemanticsDumpOrder].
  ///
  /// The system retains the nodes that are currently reachable from the root.
  /// A given update need not contain information for nodes that do not change
  /// in the update. If a node is not reachable from the root after an update,
  /// the node will be discarded from the tree.
  ///
  /// The `flags` are a bit field of [SemanticsFlag]s that apply to this node.
  ///
  /// The `actions` are a bit field of [SemanticsAction]s that can be undertaken
  /// by this node. If the user wishes to undertake one of these actions on this
  /// node, the [PlatformDispatcher.onSemanticsActionEvent] will be called with
  /// a [SemanticsActionEvent] specifying the action to be performed. Because
  /// the semantics tree is maintained asynchronously, the
  /// [PlatformDispatcher.onSemanticsActionEvent] callback might be called with
  /// an action that is no longer possible.
  ///
  /// The `identifier` is a string that describes the node for UI automation
  /// tools that work by querying the accessibility hierarchy, such as Android
  /// UI Automator, iOS XCUITest, or Appium. It's not exposed to users.
  ///
  /// The `label` is a string that describes this node. The `value` property
  /// describes the current value of the node as a string. The `increasedValue`
  /// string will become the `value` string after a [SemanticsAction.increase]
  /// action is performed. The `decreasedValue` string will become the `value`
  /// string after a [SemanticsAction.decrease] action is performed. The `hint`
  /// string describes what result an action performed on this node has. The
  /// reading direction of all these strings is given by `textDirection`.
  ///
  /// The `labelAttributes`, `valueAttributes`, `hintAttributes`,
  /// `increasedValueAttributes`, and `decreasedValueAttributes` are the lists of
  /// [StringAttribute] carried by the `label`, `value`, `hint`, `increasedValue`,
  /// and `decreasedValue` respectively. Their contents must not be changed during
  /// the semantics update.
  ///
  /// The `tooltip` is a string that describe additional information when user
  /// hover or long press on the backing widget of this semantics node.
  ///
  /// The fields `textSelectionBase` and `textSelectionExtent` describe the
  /// currently selected text within `value`. A value of -1 indicates no
  /// current text selection base or extent.
  ///
  /// The field `maxValueLength` is used to indicate that an editable text
  /// field has a limit on the number of characters entered. If it is -1 there
  /// is no limit on the number of characters entered. The field
  /// `currentValueLength` indicates how much of that limit has already been
  /// used up. When `maxValueLength` is >= 0, `currentValueLength` must also be
  /// >= 0, otherwise it should be specified to be -1.
  ///
  /// The field `platformViewId` references the platform view, whose semantics
  /// nodes will be added as children to this node. If a platform view is
  /// specified, `childrenInHitTestOrder` and `childrenInTraversalOrder` must
  /// be empty. A value of -1 indicates that this node is not associated with a
  /// platform view.
  ///
  /// For scrollable nodes `scrollPosition` describes the current scroll
  /// position in logical pixel. `scrollExtentMax` and `scrollExtentMin`
  /// describe the maximum and minimum in-range values that `scrollPosition` can
  /// be. Both or either may be infinity to indicate unbound scrolling. The
  /// value for `scrollPosition` can (temporarily) be outside this range, for
  /// example during an overscroll. `scrollChildren` is the count of the
  /// total number of child nodes that contribute semantics and `scrollIndex`
  /// is the index of the first visible child node that contributes semantics.
  ///
  /// The `traversalParent` specifies the ID of the semantics node that serves as
  /// the logical parent of this node for accessibility traversal. This
  /// parameter is only used by the web engine to establish parent-child
  /// relationships between nodes that are not directly connected in paint order.
  /// To ensure correct accessibility traversal, `traversalParent` should be set
  /// to the logical traversal parent node ID. This parameter is web-specific
  /// because other platforms can complete grafting when generating the
  /// semantics tree in traversal order. After grafting, the traversal order and
  /// hit-test order will be different, which is acceptable for other platforms.
  /// However, the web engine assumes these two orders are exactly the same, so
  /// grafting cannot be performed ahead of time on web. Instead, the traversal
  /// order is updated in the web engine by setting the `aria-owns` attribute
  /// through this parameter. A value of -1 indicates no special traversal
  /// parent. This parameter has no effect on other platforms.
  ///
  /// The `rect` is the region occupied by this node in its own coordinate
  /// system.
  ///
  /// The `transform` is a matrix that maps this node's coordinate system into
  /// its parent's coordinate system.
  ///
  /// The `headingLevel` describes that this node is a heading and the hierarchy
  /// level this node represents as a heading. A value of 0 indicates that this
  /// node is not a heading. A value of 1 or greater indicates that this node is
  /// a heading at the specified level. The valid value range is from 1 to 6,
  /// inclusive. This attribute is only used for Web platform, and it will have
  /// no effect on other platforms.
  ///
  /// The `linkUrl` describes the URI that this node links to. If the node is
  /// not a link, this should be an empty string.
  ///
  /// The `role` describes the role of this node. Defaults to
  /// [SemanticsRole.none] if not set.
  ///
  /// The `locale` describes the language of the content in this node. i.e.
  /// label, value, and hint.
  ///
  /// If `validationResult` is not null, indicates the result of validating a
  /// form field. If null, indicates that the node is not being validated, or
  /// that the result is unknown. Form fields that validate user input but do
  /// not use this argument should use other ways to communicate validation
  /// errors to the user, such as embedding validation error text in the label.
  ///
  /// The `hitTestBehavior` describes how this node should behave during hit
  /// testing. When set to [SemanticsHitTestBehavior.defer] (the default), the
  /// platform will infer appropriate behavior based on other semantic properties
  /// of the node itself (not inherited from parent). Different platforms may
  /// implement this differently.
  ///
  /// For example, modal surfaces like dialogs can set this to
  /// [SemanticsHitTestBehavior.opaque] to block pointer events from reaching
  /// content behind them, while non-interactive decorative elements can set it
  /// to [SemanticsHitTestBehavior.transparent] to allow pointer events to pass
  /// through.
  ///
  /// See also:
  ///
  ///  * https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/heading_role
  ///  * https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-level
  ///  * [SemanticsValidationResult], that describes possible values for the
  ///    `validationResult` argument.
  ///  * [SemanticsHitTestBehavior], which describes how hit testing behaves.
  void updateNode({
    required int id,
    required SemanticsFlags flags,
    required int actions,
    required int maxValueLength,
    required int currentValueLength,
    required int textSelectionBase,
    required int textSelectionExtent,
    required int platformViewId,
    required int scrollChildren,
    required int scrollIndex,
    required int traversalParent,
    required double scrollPosition,
    required double scrollExtentMax,
    required double scrollExtentMin,
    required Rect rect,
    required String identifier,
    required String label,
    required List<StringAttribute> labelAttributes,
    required String value,
    required List<StringAttribute> valueAttributes,
    required String increasedValue,
    required List<StringAttribute> increasedValueAttributes,
    required String decreasedValue,
    required List<StringAttribute> decreasedValueAttributes,
    required String hint,
    required List<StringAttribute> hintAttributes,
    required String tooltip,
    required TextDirection? textDirection,
    required Float64List transform,
    required Float64List hitTestTransform,
    required Int32List childrenInTraversalOrder,
    required Int32List childrenInHitTestOrder,
    required Int32List additionalActions,
    int headingLevel = 0,
    String linkUrl = '',
    SemanticsRole role = SemanticsRole.none,
    required List<String>? controlsNodes,
    SemanticsValidationResult validationResult = SemanticsValidationResult.none,
    SemanticsHitTestBehavior hitTestBehavior = SemanticsHitTestBehavior.defer,
    required SemanticsInputType inputType,
    required Locale? locale,
    required String minValue,
    required String maxValue,
  });

  /// Update the custom semantics action associated with the given `id`.
  ///
  /// The name of the action exposed to the user is the `label`. For overridden
  /// standard actions this value is ignored.
  ///
  /// The `hint` should describe what happens when an action occurs, not the
  /// manner in which a tap is accomplished. For example, use "delete" instead
  /// of "double tap to delete".
  ///
  /// The text direction of the `hint` and `label` is the same as the global
  /// window.
  ///
  /// For overridden standard actions, `overrideId` corresponds with a
  /// [SemanticsAction.index] value. For custom actions this argument should not be
  /// provided.
  void updateCustomAction({required int id, String? label, String? hint, int overrideId = -1});

  /// Creates a [SemanticsUpdate] object that encapsulates the updates recorded
  /// by this object.
  ///
  /// The returned object can be passed to [PlatformDispatcher.updateSemantics]
  /// to actually update the semantics retained by the system.
  ///
  /// This object is unusable after calling build.
  SemanticsUpdate build();
}

base class _NativeSemanticsUpdateBuilder extends NativeFieldWrapperClass1
    implements SemanticsUpdateBuilder {
  _NativeSemanticsUpdateBuilder() {
    _constructor();
  }

  @Native<Void Function(Handle)>(symbol: 'SemanticsUpdateBuilder::Create')
  external void _constructor();

  @override
  void updateNode({
    required int id,
    required SemanticsFlags flags,
    required int actions,
    required int maxValueLength,
    required int currentValueLength,
    required int textSelectionBase,
    required int textSelectionExtent,
    required int platformViewId,
    required int scrollChildren,
    required int scrollIndex,
    required int traversalParent,
    required double scrollPosition,
    required double scrollExtentMax,
    required double scrollExtentMin,
    required Rect rect,
    required String identifier,
    required String label,
    required List<StringAttribute> labelAttributes,
    required String value,
    required List<StringAttribute> valueAttributes,
    required String increasedValue,
    required List<StringAttribute> increasedValueAttributes,
    required String decreasedValue,
    required List<StringAttribute> decreasedValueAttributes,
    required String hint,
    required List<StringAttribute> hintAttributes,
    required String tooltip,
    required TextDirection? textDirection,
    required Float64List transform,
    required Float64List hitTestTransform,
    required Int32List childrenInTraversalOrder,
    required Int32List childrenInHitTestOrder,
    required Int32List additionalActions,
    int headingLevel = 0,
    String linkUrl = '',
    SemanticsRole role = SemanticsRole.none,
    required List<String>? controlsNodes,
    SemanticsValidationResult validationResult = SemanticsValidationResult.none,
    SemanticsHitTestBehavior hitTestBehavior = SemanticsHitTestBehavior.defer,
    required SemanticsInputType inputType,
    required Locale? locale,
    required String minValue,
    required String maxValue,
  }) {
    assert(_matrix4IsValid(transform));
    assert(
      headingLevel >= 0 && headingLevel <= 6,
      'Heading level must be between 1 and 6, or 0 to indicate that this node is not a heading.',
    );
    _updateNode(
      id,
      flags,
      actions,
      maxValueLength,
      currentValueLength,
      textSelectionBase,
      textSelectionExtent,
      platformViewId,
      scrollChildren,
      scrollIndex,
      traversalParent,
      scrollPosition,
      scrollExtentMax,
      scrollExtentMin,
      rect.left,
      rect.top,
      rect.right,
      rect.bottom,
      identifier,
      label,
      labelAttributes,
      value,
      valueAttributes,
      increasedValue,
      increasedValueAttributes,
      decreasedValue,
      decreasedValueAttributes,
      hint,
      hintAttributes,
      tooltip,
      textDirection != null ? textDirection.index + 1 : 0,
      transform,
      hitTestTransform,
      childrenInTraversalOrder,
      childrenInHitTestOrder,
      additionalActions,
      headingLevel,
      linkUrl,
      role.index,
      controlsNodes,
      validationResult.index,
      hitTestBehavior.index,
      inputType.index,
      locale?.toLanguageTag() ?? '',
      minValue,
      maxValue,
    );
  }

  @Native<
    Void Function(
      Pointer<Void>,
      Int32,
      Handle,
      Int32,
      Int32,
      Int32,
      Int32,
      Int32,
      Int32,
      Int32,
      Int32,
      Int32,
      Double,
      Double,
      Double,
      Double,
      Double,
      Double,
      Double,
      Handle,
      Handle,
      Handle,
      Handle,
      Handle,
      Handle,
      Handle,
      Handle,
      Handle,
      Handle,
      Handle,
      Handle,
      Int32,
      Handle,
      Handle,
      Handle,
      Handle,
      Handle,
      Int32,
      Handle,
      Int32,
      Handle,
      Int32,
      Int32,
      Int32,
      Handle,
      Handle,
      Handle,
    )
  >(symbol: 'SemanticsUpdateBuilder::updateNode')
  external void _updateNode(
    int id,
    SemanticsFlags flags,
    int actions,
    int maxValueLength,
    int currentValueLength,
    int textSelectionBase,
    int textSelectionExtent,
    int platformViewId,
    int scrollChildren,
    int scrollIndex,
    int traversalParent,
    double scrollPosition,
    double scrollExtentMax,
    double scrollExtentMin,
    double left,
    double top,
    double right,
    double bottom,
    String? identifier,
    String label,
    List<StringAttribute> labelAttributes,
    String value,
    List<StringAttribute> valueAttributes,
    String increasedValue,
    List<StringAttribute> increasedValueAttributes,
    String decreasedValue,
    List<StringAttribute> decreasedValueAttributes,
    String hint,
    List<StringAttribute> hintAttributes,
    String tooltip,
    int textDirection,
    Float64List transform,
    Float64List hitTestTransform,
    Int32List childrenInTraversalOrder,
    Int32List childrenInHitTestOrder,
    Int32List additionalActions,
    int headingLevel,
    String linkUrl,
    int role,
    List<String>? controlsNodes,
    int validationResultIndex,
    int hitTestBehaviorIndex,
    int inputType,
    String locale,
    String minValue,
    String maxValue,
  );

  @override
  void updateCustomAction({required int id, String? label, String? hint, int overrideId = -1}) {
    _updateCustomAction(id, label ?? '', hint ?? '', overrideId);
  }

  @Native<Void Function(Pointer<Void>, Int32, Handle, Handle, Int32)>(
    symbol: 'SemanticsUpdateBuilder::updateCustomAction',
  )
  external void _updateCustomAction(int id, String label, String hint, int overrideId);

  @override
  SemanticsUpdate build() {
    final semanticsUpdate = _NativeSemanticsUpdate._();
    _build(semanticsUpdate);
    return semanticsUpdate;
  }

  @Native<Void Function(Pointer<Void>, Handle)>(symbol: 'SemanticsUpdateBuilder::build')
  external void _build(_NativeSemanticsUpdate outSemanticsUpdate);

  @override
  String toString() => 'SemanticsUpdateBuilder';
}

/// An opaque object representing a batch of semantics updates.
///
/// To create a SemanticsUpdate object, use a [SemanticsUpdateBuilder].
///
/// Semantics updates can be applied to the system's retained semantics tree
/// using the [PlatformDispatcher.updateSemantics] method.
abstract class SemanticsUpdate {
  /// Releases the resources used by this semantics update.
  ///
  /// After calling this function, the semantics update is cannot be used
  /// further.
  ///
  /// This can't be a leaf call because the native function calls Dart API
  /// (Dart_SetNativeInstanceField).
  void dispose();
}

base class _NativeSemanticsUpdate extends NativeFieldWrapperClass1 implements SemanticsUpdate {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a SemanticsUpdate object, use a [SemanticsUpdateBuilder].
  _NativeSemanticsUpdate._();

  @override
  @Native<Void Function(Pointer<Void>)>(symbol: 'SemanticsUpdate::dispose')
  external void dispose();

  @override
  String toString() => 'SemanticsUpdate';
}
