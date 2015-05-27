// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_DRAWLOOPERLAYERINFO_H_
#define SKY_ENGINE_CORE_PAINTING_DRAWLOOPERLAYERINFO_H_

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "third_party/skia/include/effects/SkLayerDrawLooper.h"

namespace blink {

class DrawLooperLayerInfo : public RefCounted<DrawLooperLayerInfo>,
                            public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  static PassRefPtr<DrawLooperLayerInfo> create()
  {
    return adoptRef(new DrawLooperLayerInfo);
  }
  ~DrawLooperLayerInfo() override;

  void setPaintBits(unsigned bits) { layer_info_.fPaintBits = bits; }
  void setColorMode(unsigned mode) {
    layer_info_.fColorMode = static_cast<SkXfermode::Mode>(mode);
  }
  void setOffset(float x, float y) { layer_info_.fOffset.set(x, y); }
  void setPostTranslate(bool val) { layer_info_.fPostTranslate = val; }

  const SkLayerDrawLooper::LayerInfo& layer_info() const { return layer_info_; }

 private:
  DrawLooperLayerInfo();

  SkLayerDrawLooper::LayerInfo layer_info_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_DRAWLOOPERLAYERINFO_H_
