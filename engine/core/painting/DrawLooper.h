// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_DRAWLOOPER_H_
#define SKY_ENGINE_CORE_PAINTING_DRAWLOOPER_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkDrawLooper.h"

namespace blink {

class DrawLooper : public RefCounted<DrawLooper>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~DrawLooper() override;
  static PassRefPtr<DrawLooper> create(PassRefPtr<SkDrawLooper> looper) {
    return adoptRef(new DrawLooper(looper));
  }

  SkDrawLooper* looper() { return looper_.get(); }

 private:
  DrawLooper(PassRefPtr<SkDrawLooper> looper);

  RefPtr<SkDrawLooper> looper_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_DRAWLOOPER_H_
