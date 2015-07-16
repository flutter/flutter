// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_LAYERDRAWLOOPERBUILDER_H_
#define SKY_ENGINE_CORE_PAINTING_LAYERDRAWLOOPERBUILDER_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/effects/SkLayerDrawLooper.h"

namespace blink {

class DrawLooper;
class DrawLooperAddLayerCallback;
class DrawLooperLayerInfo;

class LayerDrawLooperBuilder : public RefCounted<LayerDrawLooperBuilder>,
                               public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~LayerDrawLooperBuilder() override;
  static PassRefPtr<LayerDrawLooperBuilder> create() {
    return adoptRef(new LayerDrawLooperBuilder);
  }

  PassRefPtr<DrawLooper> build();
  void addLayerOnTop(DrawLooperLayerInfo* layer_info,
                     PassOwnPtr<DrawLooperAddLayerCallback>);

 private:
  LayerDrawLooperBuilder();

  SkLayerDrawLooper::Builder draw_looper_builder_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_LAYERDRAWLOOPERBUILDER_H_
