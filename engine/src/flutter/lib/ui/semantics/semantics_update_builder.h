// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_BUILDER_H_
#define FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_BUILDER_H_

#include "flutter/lib/ui/semantics/semantics_update.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/typed_data/float64_list.h"
#include "lib/tonic/typed_data/int32_list.h"

namespace blink {

class SemanticsUpdateBuilder
    : public fxl::RefCountedThreadSafe<SemanticsUpdateBuilder>,
      public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(SemanticsUpdateBuilder);

 public:
  static fxl::RefPtr<SemanticsUpdateBuilder> create() {
    return fxl::MakeRefCounted<SemanticsUpdateBuilder>();
  }

  ~SemanticsUpdateBuilder() override;

  void updateNode(int id,
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
                  int nextNodeId,
                  const tonic::Float64List& transform,
                  const tonic::Int32List& children);

  fxl::RefPtr<SemanticsUpdate> build();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit SemanticsUpdateBuilder();

  std::vector<SemanticsNode> nodes_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_BUILDER_H_
