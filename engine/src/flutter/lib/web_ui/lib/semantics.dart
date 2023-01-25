// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

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
  static const int _kDidGainAccessibilityFocusIndex = 1 << 15;
  static const int _kDidLoseAccessibilityFocusIndex = 1 << 16;
  static const int _kCustomActionIndex = 1 << 17;
  static const int _kDismissIndex = 1 << 18;
  static const int _kMoveCursorForwardByWordIndex = 1 << 19;
  static const int _kMoveCursorBackwardByWordIndex = 1 << 20;
  static const int _kSetTextIndex = 1 << 21;

  final int index;

  static const SemanticsAction tap = SemanticsAction._(_kTapIndex);
  static const SemanticsAction longPress = SemanticsAction._(_kLongPressIndex);
  static const SemanticsAction scrollLeft = SemanticsAction._(_kScrollLeftIndex);
  static const SemanticsAction scrollRight = SemanticsAction._(_kScrollRightIndex);
  static const SemanticsAction scrollUp = SemanticsAction._(_kScrollUpIndex);
  static const SemanticsAction scrollDown = SemanticsAction._(_kScrollDownIndex);
  static const SemanticsAction increase = SemanticsAction._(_kIncreaseIndex);
  static const SemanticsAction decrease = SemanticsAction._(_kDecreaseIndex);
  static const SemanticsAction showOnScreen = SemanticsAction._(_kShowOnScreenIndex);
  static const SemanticsAction moveCursorForwardByCharacter = SemanticsAction._(_kMoveCursorForwardByCharacterIndex);
  static const SemanticsAction moveCursorBackwardByCharacter = SemanticsAction._(_kMoveCursorBackwardByCharacterIndex);
  static const SemanticsAction setText = SemanticsAction._(_kSetTextIndex);
  static const SemanticsAction setSelection = SemanticsAction._(_kSetSelectionIndex);
  static const SemanticsAction copy = SemanticsAction._(_kCopyIndex);
  static const SemanticsAction cut = SemanticsAction._(_kCutIndex);
  static const SemanticsAction paste = SemanticsAction._(_kPasteIndex);
  static const SemanticsAction didGainAccessibilityFocus = SemanticsAction._(_kDidGainAccessibilityFocusIndex);
  static const SemanticsAction didLoseAccessibilityFocus = SemanticsAction._(_kDidLoseAccessibilityFocusIndex);
  static const SemanticsAction customAction = SemanticsAction._(_kCustomActionIndex);
  static const SemanticsAction dismiss = SemanticsAction._(_kDismissIndex);
  static const SemanticsAction moveCursorForwardByWord = SemanticsAction._(_kMoveCursorForwardByWordIndex);
  static const SemanticsAction moveCursorBackwardByWord = SemanticsAction._(_kMoveCursorBackwardByWordIndex);

  static const Map<int, SemanticsAction> values = <int, SemanticsAction>{
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
    _kDidGainAccessibilityFocusIndex: didGainAccessibilityFocus,
    _kDidLoseAccessibilityFocusIndex: didLoseAccessibilityFocus,
    _kCustomActionIndex: customAction,
    _kDismissIndex: dismiss,
    _kMoveCursorForwardByWordIndex: moveCursorForwardByWord,
    _kMoveCursorBackwardByWordIndex: moveCursorBackwardByWord,
    _kSetTextIndex: setText,
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
      case _kDidGainAccessibilityFocusIndex:
        return 'SemanticsAction.didGainAccessibilityFocus';
      case _kDidLoseAccessibilityFocusIndex:
        return 'SemanticsAction.didLoseAccessibilityFocus';
      case _kCustomActionIndex:
        return 'SemanticsAction.customAction';
      case _kDismissIndex:
        return 'SemanticsAction.dismiss';
      case _kMoveCursorForwardByWordIndex:
        return 'SemanticsAction.moveCursorForwardByWord';
      case _kMoveCursorBackwardByWordIndex:
        return 'SemanticsAction.moveCursorBackwardByWord';
      case _kSetTextIndex:
        return 'SemanticsAction.setText';
    }
    assert(false, 'Unhandled index: $index (0x${index.toRadixString(8).padLeft(4, "0")})');
    return '';
  }
}

class SemanticsFlag {
  const SemanticsFlag._(this.index);

  final int index;

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

  static const SemanticsFlag hasCheckedState = SemanticsFlag._(_kHasCheckedStateIndex);
  static const SemanticsFlag isChecked = SemanticsFlag._(_kIsCheckedIndex);
  static const SemanticsFlag isSelected = SemanticsFlag._(_kIsSelectedIndex);
  static const SemanticsFlag isButton = SemanticsFlag._(_kIsButtonIndex);
  static const SemanticsFlag isTextField = SemanticsFlag._(_kIsTextFieldIndex);
  static const SemanticsFlag isSlider = SemanticsFlag._(_kIsSliderIndex);
  static const SemanticsFlag isKeyboardKey = SemanticsFlag._(_kIsKeyboardKeyIndex);
  static const SemanticsFlag isReadOnly = SemanticsFlag._(_kIsReadOnlyIndex);
  static const SemanticsFlag isLink = SemanticsFlag._(_kIsLinkIndex);
  static const SemanticsFlag isFocusable = SemanticsFlag._(_kIsFocusableIndex);
  static const SemanticsFlag isFocused = SemanticsFlag._(_kIsFocusedIndex);
  static const SemanticsFlag hasEnabledState = SemanticsFlag._(_kHasEnabledStateIndex);
  static const SemanticsFlag isEnabled = SemanticsFlag._(_kIsEnabledIndex);
  static const SemanticsFlag isInMutuallyExclusiveGroup = SemanticsFlag._(_kIsInMutuallyExclusiveGroupIndex);
  static const SemanticsFlag isHeader = SemanticsFlag._(_kIsHeaderIndex);
  static const SemanticsFlag isObscured = SemanticsFlag._(_kIsObscuredIndex);
  static const SemanticsFlag isMultiline = SemanticsFlag._(_kIsMultilineIndex);
  static const SemanticsFlag scopesRoute = SemanticsFlag._(_kScopesRouteIndex);
  static const SemanticsFlag namesRoute = SemanticsFlag._(_kNamesRouteIndex);
  static const SemanticsFlag isHidden = SemanticsFlag._(_kIsHiddenIndex);
  static const SemanticsFlag isImage = SemanticsFlag._(_kIsImageIndex);
  static const SemanticsFlag isLiveRegion = SemanticsFlag._(_kIsLiveRegionIndex);
  static const SemanticsFlag hasToggledState = SemanticsFlag._(_kHasToggledStateIndex);
  static const SemanticsFlag isToggled = SemanticsFlag._(_kIsToggledIndex);
  static const SemanticsFlag hasImplicitScrolling = SemanticsFlag._(_kHasImplicitScrollingIndex);
  static const SemanticsFlag isCheckStateMixed = SemanticsFlag._(_kIsCheckStateMixedIndex);

  static const Map<int, SemanticsFlag> values = <int, SemanticsFlag>{
    _kHasCheckedStateIndex: hasCheckedState,
    _kIsCheckedIndex: isChecked,
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
      case _kIsHeaderIndex:
        return 'SemanticsFlag.isHeader';
      case _kIsObscuredIndex:
        return 'SemanticsFlag.isObscured';
      case _kScopesRouteIndex:
        return 'SemanticsFlag.scopesRoute';
      case _kNamesRouteIndex:
        return 'SemanticsFlag.namesRoute';
      case _kIsHiddenIndex:
        return 'SemanticsFlag.isHidden';
      case _kIsImageIndex:
        return 'SemanticsFlag.isImage';
      case _kIsLiveRegionIndex:
        return 'SemanticsFlag.isLiveRegion';
      case _kHasToggledStateIndex:
        return 'SemanticsFlag.hasToggledState';
      case _kIsToggledIndex:
        return 'SemanticsFlag.isToggled';
      case _kHasImplicitScrollingIndex:
        return 'SemanticsFlag.hasImplicitScrolling';
      case _kIsMultilineIndex:
        return 'SemanticsFlag.isMultiline';
      case _kIsReadOnlyIndex:
        return 'SemanticsFlag.isReadOnly';
      case _kIsFocusableIndex:
        return 'SemanticsFlag.isFocusable';
      case _kIsLinkIndex:
        return 'SemanticsFlag.isLink';
      case _kIsSliderIndex:
        return 'SemanticsFlag.isSlider';
      case _kIsKeyboardKeyIndex:
        return 'SemanticsFlag.isKeyboardKey';
      case _kIsCheckStateMixedIndex:
        return 'SemanticsFlag.isCheckStateMixed';
    }
    assert(false, 'Unhandled index: $index (0x${index.toRadixString(8).padLeft(4, "0")})');
    return '';
  }
}

// When adding a new StringAttributeType, the classes in these file must be
// updated as well.
//  * engine/src/flutter/lib/ui/semantics.dart
//  * engine/src/flutter/lib/ui/semantics/string_attribute.h
//  * engine/src/flutter/shell/platform/android/io/flutter/view/AccessibilityBridge.java
//  * engine/src/flutter/lib/web_ui/test/engine/semantics/semantics_api_test.dart
//  * engine/src/flutter/testing/dart/semantics_test.dart

abstract class StringAttribute {
  StringAttribute._({
    required this.range,
  });

  final TextRange range;

  StringAttribute copy({required TextRange range});
}

class SpellOutStringAttribute extends StringAttribute {
  SpellOutStringAttribute({
    required super.range,
  }) : super._();

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
  LocaleStringAttribute({
    required super.range,
    required this.locale,
  }) : super._();

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

class SemanticsUpdateBuilder {
  SemanticsUpdateBuilder();

  final List<engine.SemanticsNodeUpdate> _nodeUpdates = <engine.SemanticsNodeUpdate>[];
  void updateNode({
    required int id,
    required int flags,
    required int actions,
    required int maxValueLength,
    required int currentValueLength,
    required int textSelectionBase,
    required int textSelectionExtent,
    required int platformViewId,
    required int scrollChildren,
    required int scrollIndex,
    required double scrollPosition,
    required double scrollExtentMax,
    required double scrollExtentMin,
    required double elevation,
    required double thickness,
    required Rect rect,
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
    required Int32List childrenInTraversalOrder,
    required Int32List childrenInHitTestOrder,
    required Int32List additionalActions,
  }) {
    if (transform.length != 16) {
      throw ArgumentError('transform argument must have 16 entries.');
    }
    _nodeUpdates.add(engine.SemanticsNodeUpdate(
      id: id,
      flags: flags,
      actions: actions,
      maxValueLength: maxValueLength,
      currentValueLength: currentValueLength,
      textSelectionBase: textSelectionBase,
      textSelectionExtent: textSelectionExtent,
      scrollChildren: scrollChildren,
      scrollIndex: scrollIndex,
      scrollPosition: scrollPosition,
      scrollExtentMax: scrollExtentMax,
      scrollExtentMin: scrollExtentMin,
      rect: rect,
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
      elevation: elevation,
      thickness: thickness,
      childrenInTraversalOrder: childrenInTraversalOrder,
      childrenInHitTestOrder: childrenInHitTestOrder,
      additionalActions: additionalActions,
      platformViewId: platformViewId,
    ));
  }

  void updateCustomAction({
    required int id,
    String? label,
    String? hint,
    int overrideId = -1,
  }) {
    // TODO(yjbanov): implement.
  }
  SemanticsUpdate build() {
    return SemanticsUpdate._(
      nodeUpdates: _nodeUpdates,
    );
  }
}

abstract class SemanticsUpdate {
  factory SemanticsUpdate._({List<engine.SemanticsNodeUpdate>? nodeUpdates}) =
      engine.SemanticsUpdate;
  void dispose();
}
