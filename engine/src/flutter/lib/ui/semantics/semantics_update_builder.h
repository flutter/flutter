// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_BUILDER_H_
#define FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_BUILDER_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/semantics/semantics_update.h"
#include "third_party/tonic/typed_data/float64_list.h"
#include "third_party/tonic/typed_data/int32_list.h"

namespace blink {

class SemanticsUpdateBuilder
    : public RefCountedDartWrappable<SemanticsUpdateBuilder> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(SemanticsUpdateBuilder);

 public:
  static fml::RefPtr<SemanticsUpdateBuilder> create() {
    return fml::MakeRefCounted<SemanticsUpdateBuilder>();
  }

  ~SemanticsUpdateBuilder() override;

  void updateNode(int id,
                  int flags,
                  int actions,
                  int textSelectionBase,
                  int textSelectionExtent,
                  int scrollChildren,
                  int scrollIndex,
                  double scrollPosition,
                  double scrollExtentMax,
                  double scrollExtentMin,
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
                  const tonic::Int32List& childrenInTraversalOrder,
                  const tonic::Int32List& childrenInHitTestOrder,
                  const tonic::Int32List& customAccessibilityActions);

  void updateCustomAction(int id,
                          std::string label,
                          std::string hint,
                          int overrideId);

  fml::RefPtr<SemanticsUpdate> build();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit SemanticsUpdateBuilder();

  SemanticsNodeUpdates nodes_;
  CustomAccessibilityActionUpdates actions_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_BUILDER_H_
