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

void SemanticsUpdateBuilder::updateNode(
    int id,
    Dart_Handle flags,
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
    const tonic::Float64List& hitTestTransform,
    const tonic::Int32List& childrenInTraversalOrder,
    const tonic::Int32List& childrenInHitTestOrder,
    const tonic::Int32List& localContextActions,
    int headingLevel,
    std::string linkUrl,
    int role,
    const std::vector<std::string>& controlsNodes,
    int validationResult,
    int hitTestBehavior,
    int inputType,
    std::string locale,
    std::string minValue,
    std::string maxValue) {
  FML_CHECK(scrollChildren == 0 ||
            (scrollChildren > 0 && childrenInHitTestOrder.data()))
      << "Semantics update contained scrollChildren but did not have "
         "childrenInHitTestOrder";
  SemanticsNode node;
  node.id = id;
  auto* flags_object =
      tonic::DartConverter<flutter::NativeSemanticsFlags*>::FromDart(flags);
  node.flags = flags_object->GetFlags();
  node.actions = actions;
  node.maxValueLength = maxValueLength;
  node.currentValueLength = currentValueLength;
  node.textSelectionBase = textSelectionBase;
  node.textSelectionExtent = textSelectionExtent;
  node.platformViewId = platformViewId;
  node.scrollChildren = scrollChildren;
  node.scrollIndex = scrollIndex;
  node.traversalParent = traversalParent;
  node.scrollPosition = scrollPosition;
  node.scrollExtentMax = scrollExtentMax;
  node.scrollExtentMin = scrollExtentMin;
  node.minValue = std::move(minValue);
  node.maxValue = std::move(maxValue);
  node.rect = SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top),
                               SafeNarrow(right), SafeNarrow(bottom));
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
  SkScalar scalarHitTestTransform[16];
  for (int i = 0; i < 16; ++i) {
    scalarHitTestTransform[i] = SafeNarrow(hitTestTransform.data()[i]);
  }
  node.hitTestTransform = SkM44::ColMajor(scalarHitTestTransform);
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
  node.locale = std::move(locale);

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
