// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/semantics/semantics_update_builder.h"

#include <utility>

#include "flutter/lib/ui/floating_point.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/skia/include/core/SkScalar.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

void pushStringAttributes(
    StringAttributes& destination,
    const std::vector<NativeStringAttribute*>& native_attributes) {
  for (const auto& native_attribute : native_attributes) {
    destination.push_back(native_attribute->GetAttribute());
  }
}

IMPLEMENT_WRAPPERTYPEINFO(ui, SemanticsUpdateBuilder);

SemanticsUpdateBuilder::SemanticsUpdateBuilder() = default;

SemanticsUpdateBuilder::~SemanticsUpdateBuilder() = default;

SemanticsFlags2 vectorBoolToSemanticsFlags2(const std::vector<bool>& vec) {
  SemanticsFlags2 flags = {};
  flags.hasCheckedState = vec[0];
  flags.isChecked = vec[1];
  flags.isSelected = vec[2];
  flags.isButton = vec[3];
  flags.isTextField = vec[4];
  flags.isFocused = vec[5];
  flags.hasEnabledState = vec[6];
  flags.isEnabled = vec[7];
  flags.isInMutuallyExclusiveGroup = vec[8];
  flags.isHeader = vec[9];
  flags.isObscured = vec[10];
  flags.scopesRoute = vec[11];
  flags.namesRoute = vec[12];
  flags.isHidden = vec[13];
  flags.isImage = vec[14];
  flags.isLiveRegion = vec[15];
  flags.hasToggledState = vec[16];
  flags.isToggled = vec[17];
  flags.hasImplicitScrolling = vec[18];
  flags.isMultiline = vec[19];
  flags.isReadOnly = vec[20];
  flags.isFocusable = vec[21];
  flags.isLink = vec[22];
  flags.isSlider = vec[23];
  flags.isKeyboardKey = vec[24];
  flags.isCheckStateMixed = vec[25];
  flags.hasExpandedState = vec[26];
  flags.isExpanded = vec[27];
  flags.hasSelectedState = vec[28];
  flags.hasRequiredState = vec[29];
  flags.isRequired = vec[30];

  // 4. Return the populated struct
  return flags;
}

void SemanticsUpdateBuilder::updateNode(
    int id,
    const std::vector<bool>& flags,
    int actions,
    int maxValueLength,
    int currentValueLength,
    int textSelectionBase,
    int textSelectionExtent,
    int platformViewId,
    int scrollChildren,
    int scrollIndex,
    double scrollPosition,
    double scrollExtentMax,
    double scrollExtentMin,
    double left,
    double top,
    double right,
    double bottom,
    double elevation,
    double thickness,
    std::string identifier,
    std::string label,
    const std::vector<NativeStringAttribute*>& labelAttributes,
    std::string value,
    const std::vector<NativeStringAttribute*>& valueAttributes,
    std::string increasedValue,
    const std::vector<NativeStringAttribute*>& increasedValueAttributes,
    std::string decreasedValue,
    const std::vector<NativeStringAttribute*>& decreasedValueAttributes,
    std::string hint,
    const std::vector<NativeStringAttribute*>& hintAttributes,
    std::string tooltip,
    int textDirection,
    const tonic::Float64List& transform,
    const tonic::Int32List& childrenInTraversalOrder,
    const tonic::Int32List& childrenInHitTestOrder,
    const tonic::Int32List& localContextActions,
    int headingLevel,
    std::string linkUrl,
    int role,
    const std::vector<std::string>& controlsNodes,
    int validationResult) {
  FML_CHECK(scrollChildren == 0 ||
            (scrollChildren > 0 && childrenInHitTestOrder.data()))
      << "Semantics update contained scrollChildren but did not have "
         "childrenInHitTestOrder";
  SemanticsNode node;
  node.id = id;
  node.flags = vectorBoolToSemanticsFlags2(flags);
  node.actions = actions;
  node.maxValueLength = maxValueLength;
  node.currentValueLength = currentValueLength;
  node.textSelectionBase = textSelectionBase;
  node.textSelectionExtent = textSelectionExtent;
  node.platformViewId = platformViewId;
  node.scrollChildren = scrollChildren;
  node.scrollIndex = scrollIndex;
  node.scrollPosition = scrollPosition;
  node.scrollExtentMax = scrollExtentMax;
  node.scrollExtentMin = scrollExtentMin;
  node.rect = SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top),
                               SafeNarrow(right), SafeNarrow(bottom));
  node.elevation = elevation;
  node.thickness = thickness;
  node.identifier = std::move(identifier);
  node.label = std::move(label);
  pushStringAttributes(node.labelAttributes, labelAttributes);
  node.value = std::move(value);
  pushStringAttributes(node.valueAttributes, valueAttributes);
  node.increasedValue = std::move(increasedValue);
  pushStringAttributes(node.increasedValueAttributes, increasedValueAttributes);
  node.decreasedValue = std::move(decreasedValue);
  pushStringAttributes(node.decreasedValueAttributes, decreasedValueAttributes);
  node.hint = std::move(hint);
  pushStringAttributes(node.hintAttributes, hintAttributes);
  node.tooltip = std::move(tooltip);
  node.textDirection = textDirection;
  SkScalar scalarTransform[16];
  for (int i = 0; i < 16; ++i) {
    scalarTransform[i] = SafeNarrow(transform.data()[i]);
  }
  node.transform = SkM44::ColMajor(scalarTransform);
  node.childrenInTraversalOrder =
      std::vector<int32_t>(childrenInTraversalOrder.data(),
                           childrenInTraversalOrder.data() +
                               childrenInTraversalOrder.num_elements());
  node.childrenInHitTestOrder = std::vector<int32_t>(
      childrenInHitTestOrder.data(),
      childrenInHitTestOrder.data() + childrenInHitTestOrder.num_elements());
  node.customAccessibilityActions = std::vector<int32_t>(
      localContextActions.data(),
      localContextActions.data() + localContextActions.num_elements());
  node.headingLevel = headingLevel;
  node.linkUrl = std::move(linkUrl);
  node.role = static_cast<SemanticsRole>(role);
  node.validationResult =
      static_cast<SemanticsValidationResult>(validationResult);

  nodes_[id] = node;
}

void SemanticsUpdateBuilder::updateCustomAction(int id,
                                                std::string label,
                                                std::string hint,
                                                int overrideId) {
  CustomAccessibilityAction action;
  action.id = id;
  action.overrideId = overrideId;
  action.label = std::move(label);
  action.hint = std::move(hint);
  actions_[id] = action;
}

void SemanticsUpdateBuilder::build(Dart_Handle semantics_update_handle) {
  SemanticsUpdate::create(semantics_update_handle, std::move(nodes_),
                          std::move(actions_));
  ClearDartWrapper();
}

}  // namespace flutter
