// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/fml/macros.h"
#include "impeller/playground/playground_test.h"
#include "third_party/skia/include/core/SkFont.h"

namespace impeller {

class DlPlayground : public PlaygroundTest {
 public:
  using DisplayListPlaygroundCallback =
      std::function<sk_sp<flutter::DisplayList>()>;

  DlPlayground();

  ~DlPlayground();

  bool OpenPlaygroundHere(flutter::DisplayListBuilder& builder);

  bool OpenPlaygroundHere(sk_sp<flutter::DisplayList> list);

  bool OpenPlaygroundHere(DisplayListPlaygroundCallback callback);

  SkFont CreateTestFontOfSize(SkScalar scalar);

  SkFont CreateTestFont();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DlPlayground);
};

}  // namespace impeller
