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
    : public ftl::RefCountedThreadSafe<SemanticsUpdateBuilder>,
      public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(SemanticsUpdateBuilder);

 public:
  static ftl::RefPtr<SemanticsUpdateBuilder> create() {
    return ftl::MakeRefCounted<SemanticsUpdateBuilder>();
  }

  ~SemanticsUpdateBuilder() override;

  void updateNode(int id,
                  int flags,
                  int actions,
                  double left,
                  double top,
                  double right,
                  double bottom,
                  std::string label,
                  int textDirection,
                  const tonic::Float64List& transform,
                  const tonic::Int32List& children);

  ftl::RefPtr<SemanticsUpdate> build();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit SemanticsUpdateBuilder();

  std::vector<SemanticsNode> nodes_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_BUILDER_H_
