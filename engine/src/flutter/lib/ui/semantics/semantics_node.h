// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_NODE_H_
#define FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_NODE_H_

#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include "third_party/skia/include/core/SkM44.h"
#include "third_party/skia/include/core/SkRect.h"

#include "flutter/lib/ui/semantics/semantics_flags.h"
#include "flutter/lib/ui/semantics/string_attribute.h"

namespace flutter {

// Must match the SemanticsAction enum in semantics.dart and in each of the
// embedders.
enum class SemanticsAction : int32_t {
  kTap = 1 << 0,
  kLongPress = 1 << 1,
  kScrollLeft = 1 << 2,
  kScrollRight = 1 << 3,
  kScrollUp = 1 << 4,
  kScrollDown = 1 << 5,
  kIncrease = 1 << 6,
  kDecrease = 1 << 7,
  kShowOnScreen = 1 << 8,
  kMoveCursorForwardByCharacter = 1 << 9,
  kMoveCursorBackwardByCharacter = 1 << 10,
  kSetSelection = 1 << 11,
  kCopy = 1 << 12,
  kCut = 1 << 13,
  kPaste = 1 << 14,
  kDidGainAccessibilityFocus = 1 << 15,
  kDidLoseAccessibilityFocus = 1 << 16,
  kCustomAction = 1 << 17,
  kDismiss = 1 << 18,
  kMoveCursorForwardByWord = 1 << 19,
  kMoveCursorBackwardByWord = 1 << 20,
  kSetText = 1 << 21,
  kFocus = 1 << 22,
  kScrollToOffset = 1 << 23,
  kExpand = 1 << 24,
  kCollapse = 1 << 25,
};

constexpr int kVerticalScrollSemanticsActions =
    static_cast<int32_t>(SemanticsAction::kScrollUp) |
    static_cast<int32_t>(SemanticsAction::kScrollDown);

constexpr int kHorizontalScrollSemanticsActions =
    static_cast<int32_t>(SemanticsAction::kScrollLeft) |
    static_cast<int32_t>(SemanticsAction::kScrollRight);

constexpr int kScrollableSemanticsActions =
    kVerticalScrollSemanticsActions | kHorizontalScrollSemanticsActions;

/// The following actions are not user-initiated.
constexpr int kSystemActions =
    static_cast<int32_t>(SemanticsAction::kDidGainAccessibilityFocus) |
    static_cast<int32_t>(SemanticsAction::kDidLoseAccessibilityFocus);

/// C/C++ representation of `SemanticsRole` defined in
/// `lib/ui/semantics.dart`.
///\warning This must match the `SemanticsRole` enum in
///         `lib/ui/semantics.dart`.
/// See also:
///   - file://./../../../lib/ui/semantics.dart
enum class SemanticsRole : int32_t {
  kNone = 0,
  kTab = 1,
  kTabBar = 2,
  kTabPanel = 3,
  kDialog = 4,
  kAlertDialog = 5,
  kTable = 6,
  kCell = 7,
  kRow = 8,
  kColumnHeader = 9,
  kDragHandle = 10,
  kSpinButton = 11,
  kComboBox = 12,
  kMenuBar = 13,
  kMenu = 14,
  kMenuItem = 15,
  kMenuItemCheckbox = 16,
  kMenuItemRadio = 17,
  kList = 18,
  kListItem = 19,
  kForm = 20,
  kTooltip = 21,
  kLoadingSpinner = 22,
  kProgressBar = 23,
  kHotKey = 24,
  kRadioGroup = 25,
  kStatus = 26,
  kAlert = 27,
  kComplementary = 28,
  kContentInfo = 29,
  kMain = 30,
  kNavigation = 31,
  kRegion = 32,
};

/// C/C++ representation of `SemanticsValidationResult` defined in
/// `lib/ui/semantics.dart`.
///\warning This must match the `SemanticsValidationResult` enum in
///         `lib/ui/semantics.dart`.
/// See also:
///   - file://./../../../lib/ui/semantics.dart
enum class SemanticsValidationResult : int32_t {
  kNone = 0,
  kValid = 1,
  kInvalid = 2,
};

struct SemanticsNode {
  SemanticsNode();

  SemanticsNode(const SemanticsNode& other);

  ~SemanticsNode();

  bool HasAction(SemanticsAction action) const;

  // Whether this node is for embedded platform views.
  bool IsPlatformViewNode() const;

  int32_t id = 0;
  SemanticsFlags flags;
  int32_t actions = 0;
  int32_t maxValueLength = -1;
  int32_t currentValueLength = -1;
  int32_t textSelectionBase = -1;
  int32_t textSelectionExtent = -1;
  int32_t platformViewId = -1;
  int32_t scrollChildren = 0;
  int32_t scrollIndex = 0;
  int32_t traversalParent = 0;
  double scrollPosition = std::nan("");
  double scrollExtentMax = std::nan("");
  double scrollExtentMin = std::nan("");
  std::string identifier;
  std::string label;
  StringAttributes labelAttributes;
  std::string hint;
  StringAttributes hintAttributes;
  std::string value;
  StringAttributes valueAttributes;
  std::string increasedValue;
  StringAttributes increasedValueAttributes;
  std::string decreasedValue;
  StringAttributes decreasedValueAttributes;
  std::string tooltip;
  int32_t textDirection = 0;  // 0=unknown, 1=rtl, 2=ltr

  SkRect rect = SkRect::MakeEmpty();  // Local space, relative to parent.
  SkM44 transform = SkM44{};          // Identity
  SkM44 hitTestTransform = SkM44{};   // Identity
  std::vector<int32_t> childrenInTraversalOrder;
  std::vector<int32_t> childrenInHitTestOrder;
  std::vector<int32_t> customAccessibilityActions;
  int32_t headingLevel = 0;

  std::string linkUrl;
  SemanticsRole role;
  SemanticsValidationResult validationResult = SemanticsValidationResult::kNone;
  // A locale string in BCP 47 format
  std::string locale;
};

// Contains semantic nodes that need to be updated.
//
// The keys in the map are stable node IDd, and the values contain
// semantic information for the node corresponding to the ID.
using SemanticsNodeUpdates = std::unordered_map<int32_t, SemanticsNode>;

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_NODE_H_
