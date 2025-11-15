// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

class SemanticsAction {
  const SemanticsAction._(this.index, this.name);

  final int index;
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

  static const SemanticsAction tap = SemanticsAction._(_kTapIndex, 'tap');
  static const SemanticsAction longPress = SemanticsAction._(_kLongPressIndex, 'longPress');
  static const SemanticsAction scrollLeft = SemanticsAction._(_kScrollLeftIndex, 'scrollLeft');
  static const SemanticsAction scrollRight = SemanticsAction._(_kScrollRightIndex, 'scrollRight');
  static const SemanticsAction scrollUp = SemanticsAction._(_kScrollUpIndex, 'scrollUp');
  static const SemanticsAction scrollDown = SemanticsAction._(_kScrollDownIndex, 'scrollDown');
  static const SemanticsAction scrollToOffset = SemanticsAction._(
    _kScrollToOffsetIndex,
    'scrollToOffset',
  );
  static const SemanticsAction increase = SemanticsAction._(_kIncreaseIndex, 'increase');
  static const SemanticsAction decrease = SemanticsAction._(_kDecreaseIndex, 'decrease');
  static const SemanticsAction showOnScreen = SemanticsAction._(
    _kShowOnScreenIndex,
    'showOnScreen',
  );
  static const SemanticsAction moveCursorForwardByCharacter = SemanticsAction._(
    _kMoveCursorForwardByCharacterIndex,
    'moveCursorForwardByCharacter',
  );
  static const SemanticsAction moveCursorBackwardByCharacter = SemanticsAction._(
    _kMoveCursorBackwardByCharacterIndex,
    'moveCursorBackwardByCharacter',
  );
  static const SemanticsAction setText = SemanticsAction._(_kSetTextIndex, 'setText');
  static const SemanticsAction setSelection = SemanticsAction._(
    _kSetSelectionIndex,
    'setSelection',
  );
  static const SemanticsAction copy = SemanticsAction._(_kCopyIndex, 'copy');
  static const SemanticsAction cut = SemanticsAction._(_kCutIndex, 'cut');
  static const SemanticsAction paste = SemanticsAction._(_kPasteIndex, 'paste');
  static const SemanticsAction didGainAccessibilityFocus = SemanticsAction._(
    _kDidGainAccessibilityFocusIndex,
    'didGainAccessibilityFocus',
  );
  static const SemanticsAction didLoseAccessibilityFocus = SemanticsAction._(
    _kDidLoseAccessibilityFocusIndex,
    'didLoseAccessibilityFocus',
  );
  static const SemanticsAction customAction = SemanticsAction._(
    _kCustomActionIndex,
    'customAction',
  );
  static const SemanticsAction dismiss = SemanticsAction._(_kDismissIndex, 'dismiss');
  static const SemanticsAction moveCursorForwardByWord = SemanticsAction._(
    _kMoveCursorForwardByWordIndex,
    'moveCursorForwardByWord',
  );
  static const SemanticsAction moveCursorBackwardByWord = SemanticsAction._(
    _kMoveCursorBackwardByWordIndex,
    'moveCursorBackwardByWord',
  );
  static const SemanticsAction focus = SemanticsAction._(_kFocusIndex, 'focus');
  static const SemanticsAction expand = SemanticsAction._(_kExpandIndex, 'expand');
  static const SemanticsAction collapse = SemanticsAction._(_kCollapseIndex, 'collapse');

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

  static List<SemanticsAction> get values => _kActionById.values.toList(growable: false);

  static SemanticsAction? fromIndex(int index) => _kActionById[index];

  @override
  String toString() => 'SemanticsAction.$name';
}

class SemanticsFlag {
  const SemanticsFlag._(this.index, this.name);

  final int index;
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
  // WARNING: JavaScript can only go up to 32 bits!

  static const SemanticsFlag hasCheckedState = SemanticsFlag._(
    _kHasCheckedStateIndex,
    'hasCheckedState',
  );
  static const SemanticsFlag isChecked = SemanticsFlag._(_kIsCheckedIndex, 'isChecked');
  static const SemanticsFlag hasSelectedState = SemanticsFlag._(
    _kHasSelectedStateIndex,
    'hasSelectedState',
  );
  static const SemanticsFlag isSelected = SemanticsFlag._(_kIsSelectedIndex, 'isSelected');
  static const SemanticsFlag isButton = SemanticsFlag._(_kIsButtonIndex, 'isButton');
  static const SemanticsFlag isTextField = SemanticsFlag._(_kIsTextFieldIndex, 'isTextField');
  static const SemanticsFlag isSlider = SemanticsFlag._(_kIsSliderIndex, 'isSlider');
  static const SemanticsFlag isKeyboardKey = SemanticsFlag._(_kIsKeyboardKeyIndex, 'isKeyboardKey');
  static const SemanticsFlag isReadOnly = SemanticsFlag._(_kIsReadOnlyIndex, 'isReadOnly');
  static const SemanticsFlag isLink = SemanticsFlag._(_kIsLinkIndex, 'isLink');
  static const SemanticsFlag isFocusable = SemanticsFlag._(_kIsFocusableIndex, 'isFocusable');
  static const SemanticsFlag isFocused = SemanticsFlag._(_kIsFocusedIndex, 'isFocused');
  static const SemanticsFlag hasEnabledState = SemanticsFlag._(
    _kHasEnabledStateIndex,
    'hasEnabledState',
  );
  static const SemanticsFlag isEnabled = SemanticsFlag._(_kIsEnabledIndex, 'isEnabled');
  static const SemanticsFlag isInMutuallyExclusiveGroup = SemanticsFlag._(
    _kIsInMutuallyExclusiveGroupIndex,
    'isInMutuallyExclusiveGroup',
  );
  static const SemanticsFlag isHeader = SemanticsFlag._(_kIsHeaderIndex, 'isHeader');
  static const SemanticsFlag isObscured = SemanticsFlag._(_kIsObscuredIndex, 'isObscured');
  static const SemanticsFlag isMultiline = SemanticsFlag._(_kIsMultilineIndex, 'isMultiline');
  static const SemanticsFlag scopesRoute = SemanticsFlag._(_kScopesRouteIndex, 'scopesRoute');
  static const SemanticsFlag namesRoute = SemanticsFlag._(_kNamesRouteIndex, 'namesRoute');
  static const SemanticsFlag isHidden = SemanticsFlag._(_kIsHiddenIndex, 'isHidden');
  static const SemanticsFlag isImage = SemanticsFlag._(_kIsImageIndex, 'isImage');
  static const SemanticsFlag isLiveRegion = SemanticsFlag._(_kIsLiveRegionIndex, 'isLiveRegion');
  static const SemanticsFlag hasToggledState = SemanticsFlag._(
    _kHasToggledStateIndex,
    'hasToggledState',
  );
  static const SemanticsFlag isToggled = SemanticsFlag._(_kIsToggledIndex, 'isToggled');
  static const SemanticsFlag hasImplicitScrolling = SemanticsFlag._(
    _kHasImplicitScrollingIndex,
    'hasImplicitScrolling',
  );
  static const SemanticsFlag isCheckStateMixed = SemanticsFlag._(
    _kIsCheckStateMixedIndex,
    'isCheckStateMixed',
  );
  static const SemanticsFlag hasExpandedState = SemanticsFlag._(
    _kHasExpandedStateIndex,
    'hasExpandedState',
  );
  static const SemanticsFlag isExpanded = SemanticsFlag._(_kIsExpandedIndex, 'isExpanded');
  static const SemanticsFlag hasRequiredState = SemanticsFlag._(
    _kHasRequiredStateIndex,
    'hasRequiredState',
  );
  static const SemanticsFlag isRequired = SemanticsFlag._(_kIsRequiredIndex, 'isRequired');

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

  static List<SemanticsFlag> get values => _kFlagById.values.toList(growable: false);

  static SemanticsFlag? fromIndex(int index) => _kFlagById[index];

  @override
  String toString() => 'SemanticsFlag.$name';
}

// Mirrors engine/src/flutter/lib/ui/semantics.dart
enum CheckedState {
  none(0),
  isTrue(1),
  isFalse(2),
  mixed(3);

  const CheckedState(this.value);
  final int value;

  bool hasConflict(CheckedState other) => this != CheckedState.none && other != CheckedState.none;

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

enum Tristate {
  none(0),
  isTrue(1),
  isFalse(2);

  const Tristate(this.value);
  final int value;

  bool hasConflict(Tristate other) => this != Tristate.none && other != Tristate.none;

  Tristate merge(Tristate other) {
    if (this == Tristate.isTrue || other == Tristate.isTrue) {
      return Tristate.isTrue;
    }
    if (this == Tristate.isFalse || other == Tristate.isFalse) {
      return Tristate.isFalse;
    }
    return Tristate.none;
  }

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

// Mirrors engine/src/flutter/lib/ui/semantics.dart
class SemanticsFlags {
  const SemanticsFlags({
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
  });
  static const SemanticsFlags none = SemanticsFlags();
  final CheckedState isChecked;
  final Tristate isSelected;
  final Tristate isEnabled;
  final Tristate isToggled;
  final Tristate isExpanded;
  final Tristate isRequired;
  final Tristate isFocused;
  final bool isButton;
  final bool isTextField;
  final bool isInMutuallyExclusiveGroup;
  final bool isHeader;
  final bool isObscured;
  final bool scopesRoute;
  final bool namesRoute;
  final bool isHidden;
  final bool isImage;
  final bool isLiveRegion;
  final bool hasImplicitScrolling;
  final bool isMultiline;
  final bool isReadOnly;
  final bool isLink;
  final bool isSlider;
  final bool isKeyboardKey;
  final bool isAccessibilityFocusBlocked;

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
  int get hashCode => Object.hashAll([
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

// Mirrors engine/src/flutter/lib/ui/semantics.dart
enum SemanticsRole {
  none,
  tab,
  tabBar,
  tabPanel,
  dialog,
  alertDialog,
  table,
  cell,
  row,
  columnHeader,
  dragHandle,
  spinButton,
  comboBox,
  menuBar,
  menu,
  menuItem,
  menuItemCheckbox,
  menuItemRadio,
  list,
  listItem,
  form,
  tooltip,
  loadingSpinner,
  progressBar,
  hotKey,
  radioGroup,
  status,
  alert,
  complementary,
  contentInfo,
  main,
  navigation,
  region,
}

// Mirrors engine/src/flutter/lib/ui/semantics.dart
enum SemanticsInputType { none, text, url, phone, search, email }

// When adding a new StringAttributeType, the classes in these file must be
// updated as well.
//  * engine/src/flutter/lib/ui/semantics.dart
//  * engine/src/flutter/lib/ui/semantics/string_attribute.h
//  * engine/src/flutter/shell/platform/android/io/flutter/view/AccessibilityBridge.java
//  * engine/src/flutter/lib/web_ui/test/engine/semantics/semantics_api_test.dart
//  * engine/src/flutter/testing/dart/semantics_test.dart

abstract class StringAttribute {
  StringAttribute._({required this.range});

  final TextRange range;

  StringAttribute copy({required TextRange range});
}

class SpellOutStringAttribute extends StringAttribute {
  SpellOutStringAttribute({required super.range}) : super._();

  @override
  StringAttribute copy({required TextRange range}) {
    return SpellOutStringAttribute(range: range);
  }

  @override
  String toString() {
    return 'SpellOutStringAttribute($range)';
  }
}

class LocaleStringAttribute extends StringAttribute {
  LocaleStringAttribute({required super.range, required this.locale}) : super._();

  final Locale locale;

  @override
  StringAttribute copy({required TextRange range}) {
    return LocaleStringAttribute(range: range, locale: locale);
  }

  @override
  String toString() {
    return 'LocaleStringAttribute($range, ${locale.toLanguageTag()})';
  }
}

enum SemanticsValidationResult { none, valid, invalid }

enum SemanticsHitTestBehavior { defer, opaque, transparent }

class SemanticsUpdateBuilder {
  SemanticsUpdateBuilder();

  final List<engine.SemanticsNodeUpdate> _nodeUpdates = <engine.SemanticsNodeUpdate>[];
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
    required int? traversalParent,
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
    String? tooltip,
    TextDirection? textDirection,
    required Float64List transform,
    required Float64List hitTestTransform,
    required Int32List childrenInTraversalOrder,
    required Int32List childrenInHitTestOrder,
    required Int32List additionalActions,
    int headingLevel = 0,
    String? linkUrl,
    SemanticsRole role = SemanticsRole.none,
    required List<String>? controlsNodes,
    SemanticsValidationResult validationResult = SemanticsValidationResult.none,
    SemanticsHitTestBehavior hitTestBehavior = SemanticsHitTestBehavior.defer,
    required SemanticsInputType inputType,
    required Locale? locale,
  }) {
    if (transform.length != 16) {
      throw ArgumentError('transform argument must have 16 entries.');
    }
    _nodeUpdates.add(
      engine.SemanticsNodeUpdate(
        id: id,
        flags: flags,
        actions: actions,
        maxValueLength: maxValueLength,
        currentValueLength: currentValueLength,
        textSelectionBase: textSelectionBase,
        textSelectionExtent: textSelectionExtent,
        scrollChildren: scrollChildren,
        scrollIndex: scrollIndex,
        traversalParent: traversalParent,
        scrollPosition: scrollPosition,
        scrollExtentMax: scrollExtentMax,
        scrollExtentMin: scrollExtentMin,
        rect: rect,
        identifier: identifier,
        label: label,
        labelAttributes: labelAttributes,
        value: value,
        valueAttributes: valueAttributes,
        increasedValue: increasedValue,
        increasedValueAttributes: increasedValueAttributes,
        decreasedValue: decreasedValue,
        decreasedValueAttributes: decreasedValueAttributes,
        hint: hint,
        hintAttributes: hintAttributes,
        tooltip: tooltip,
        textDirection: textDirection,
        transform: engine.toMatrix32(transform),
        hitTestTransform: engine.toMatrix32(hitTestTransform),
        childrenInTraversalOrder: childrenInTraversalOrder,
        childrenInHitTestOrder: childrenInHitTestOrder,
        additionalActions: additionalActions,
        platformViewId: platformViewId,
        headingLevel: headingLevel,
        linkUrl: linkUrl,
        role: role,
        controlsNodes: controlsNodes,
        validationResult: validationResult,
        hitTestBehavior: hitTestBehavior,
        inputType: inputType,
        locale: locale,
      ),
    );
  }

  void updateCustomAction({required int id, String? label, String? hint, int overrideId = -1}) {
    // TODO(yjbanov): implement.
  }
  SemanticsUpdate build() {
    return SemanticsUpdate._(nodeUpdates: _nodeUpdates);
  }
}

abstract class SemanticsUpdate {
  factory SemanticsUpdate._({List<engine.SemanticsNodeUpdate>? nodeUpdates}) =
      engine.SemanticsUpdate;
  void dispose();
}
