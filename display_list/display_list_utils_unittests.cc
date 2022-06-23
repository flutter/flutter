// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_utils.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

class MockDispatchHelper final : public virtual Dispatcher,
                                 public virtual SkPaintDispatchHelper,
                                 public virtual SkMatrixDispatchHelper,
                                 public virtual ClipBoundsDispatchHelper,
                                 public virtual IgnoreDrawDispatchHelper {
 public:
  void save() override {
    SkPaintDispatchHelper::save_opacity(0.5f);
    SkMatrixDispatchHelper::save();
    ClipBoundsDispatchHelper::save();
  }

  void restore() override {
    SkPaintDispatchHelper::restore_opacity();
    SkMatrixDispatchHelper::restore();
    ClipBoundsDispatchHelper::restore();
  }
};

// Regression test for https://github.com/flutter/flutter/issues/100176.
TEST(DisplayListUtils, OverRestore) {
  MockDispatchHelper helper;
  helper.save();
  helper.restore();
  // There should be a protection here for over-restore to keep the program from
  // crashing.
  helper.restore();
}

}  // namespace testing
}  // namespace flutter
