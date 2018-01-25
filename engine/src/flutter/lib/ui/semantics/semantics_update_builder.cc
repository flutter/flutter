// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/semantics/semantics_update_builder.h"

#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

namespace blink {

static void SemanticsUpdateBuilder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&SemanticsUpdateBuilder::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, SemanticsUpdateBuilder);

#define FOR_EACH_BINDING(V)             \
  V(SemanticsUpdateBuilder, updateNode) \
  V(SemanticsUpdateBuilder, build)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void SemanticsUpdateBuilder::RegisterNatives(
    tonic::DartLibraryNatives* natives) {
  natives->Register({{"SemanticsUpdateBuilder_constructor",
                      SemanticsUpdateBuilder_constructor, 1, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

SemanticsUpdateBuilder::SemanticsUpdateBuilder() = default;

SemanticsUpdateBuilder::~SemanticsUpdateBuilder() = default;

void SemanticsUpdateBuilder::updateNode(int id,
                                        int flags,
                                        int actions,
                                        int textSelectionBase,
                                        int textSelectionExtent,
                                        double left,
                                        double top,
                                        double right,
                                        double bottom,
                                        std::string label,
                                        std::string hint,
                                        std::string value,
                                        std::string increasedValue,
                                        std::string decreasedValue,
                                        int textDirection,
                                        const tonic::Float64List& transform,
                                        const tonic::Int32List& children) {
  SemanticsNode node;
  node.id = id;
  node.flags = flags;
  node.actions = actions;
  node.textSelectionBase = textSelectionBase;
  node.textSelectionExtent = textSelectionExtent;
  node.rect = SkRect::MakeLTRB(left, top, right, bottom);
  node.label = label;
  node.hint = hint;
  node.value = value;
  node.increasedValue = increasedValue;
  node.decreasedValue = decreasedValue;
  node.textDirection = textDirection;
  node.transform.setColMajord(transform.data());
  node.children = std::vector<int32_t>(
      children.data(), children.data() + children.num_elements());
  nodes_.push_back(node);
}

fxl::RefPtr<SemanticsUpdate> SemanticsUpdateBuilder::build() {
  return SemanticsUpdate::create(std::move(nodes_));
}

}  // namespace blink
