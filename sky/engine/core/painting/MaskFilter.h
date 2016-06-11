// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_MASKFILTER_H_
#define SKY_ENGINE_CORE_PAINTING_MASKFILTER_H_

#include "base/memory/ref_counted.h"
#include "flutter/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkMaskFilter.h"

class SkMaskFilter;

namespace blink {
class DartLibraryNatives;

class MaskFilter : public base::RefCountedThreadSafe<MaskFilter>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~MaskFilter() override;
  static scoped_refptr<MaskFilter> create(
      unsigned style, double sigma, unsigned flags);

  sk_sp<SkMaskFilter> filter() { return filter_; }

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  MaskFilter(sk_sp<SkMaskFilter> filter);

  sk_sp<SkMaskFilter> filter_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_MASKFILTER_H_
