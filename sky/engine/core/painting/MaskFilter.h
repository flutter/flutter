// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_MASKFILTER_H_
#define SKY_ENGINE_CORE_PAINTING_MASKFILTER_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/ThreadSafeRefCounted.h"

class SkMaskFilter;

namespace blink {
class DartLibraryNatives;

class MaskFilter : public ThreadSafeRefCounted<MaskFilter>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~MaskFilter() override;
  static PassRefPtr<MaskFilter> create(
      unsigned style, double sigma, unsigned flags);

  SkMaskFilter* filter() { return filter_.get(); }

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  MaskFilter(PassRefPtr<SkMaskFilter> filter);

  RefPtr<SkMaskFilter> filter_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_MASKFILTER_H_
