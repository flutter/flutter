// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_MASK_FILTER_H_
#define FLUTTER_LIB_UI_PAINTING_MASK_FILTER_H_

#include "lib/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkMaskFilter.h"

class SkMaskFilter;

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class MaskFilter : public fxl::RefCountedThreadSafe<MaskFilter>,
                   public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(MaskFilter);

 public:
  ~MaskFilter() override;
  static fxl::RefPtr<MaskFilter> Create(unsigned style, double sigma);

  const sk_sp<SkMaskFilter>& filter() { return filter_; }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  MaskFilter(sk_sp<SkMaskFilter> filter);

  sk_sp<SkMaskFilter> filter_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_MASK_FILTER_H_
