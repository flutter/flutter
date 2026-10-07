// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_DISPLAY_LIST_TESTING_DEFAULT_ANTI_ALIASED_DL_PAINT_H_
#define FLUTTER_IMPELLER_DISPLAY_LIST_TESTING_DEFAULT_ANTI_ALIASED_DL_PAINT_H_

#include "flutter/display_list/dl_paint.h"

namespace impeller {
namespace testing {

/// A flutter::DlPaint whose anti-alias attribute defaults to true.
///
/// flutter::DlPaint defaults to non-anti-aliased, but Impeller's SDF rendering
/// path is only used for anti-aliased paints. Rendering test files alias this
/// class as |DlPaint| (`using DlPaint =
/// impeller::testing::DefaultAntiAliasedDlPaint;`) so that the SDF playground
/// backends exercise the SDF path without every test opting in explicitly.
/// Only the default changes; setAntiAlias(false) works as usual.
class DefaultAntiAliasedDlPaint : public flutter::DlPaint {
 public:
  DefaultAntiAliasedDlPaint()
      : DefaultAntiAliasedDlPaint(flutter::DlPaint::kDefaultColor) {}
  explicit DefaultAntiAliasedDlPaint(flutter::DlColor color)
      : flutter::DlPaint(color) {
    setAntiAlias(true);
  }
  // Implicit so that chained setters, which return flutter::DlPaint&, can
  // initialize a DefaultAntiAliasedDlPaint.
  // NOLINTNEXTLINE(google-explicit-constructor)
  DefaultAntiAliasedDlPaint(const flutter::DlPaint& paint)
      : flutter::DlPaint(paint) {}
};

}  // namespace testing
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_DISPLAY_LIST_TESTING_DEFAULT_ANTI_ALIASED_DL_PAINT_H_
