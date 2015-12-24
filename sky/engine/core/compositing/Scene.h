// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_COMPOSITING_SCENE_H_
#define SKY_ENGINE_CORE_COMPOSITING_SCENE_H_

#include <stdint.h>
#include <memory>

#include "sky/compositor/layer.h"
#include "sky/compositor/layer_tree.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class DartLibraryNatives;

class Scene : public RefCounted<Scene>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  ~Scene() override;
  static PassRefPtr<Scene> create(
      std::unique_ptr<sky::compositor::Layer> rootLayer,
      uint32_t rasterizerTracingThreshold);

  std::unique_ptr<sky::compositor::LayerTree> takeLayerTree();

  void dispose();

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  explicit Scene(std::unique_ptr<sky::compositor::Layer> rootLayer,
                 uint32_t rasterizerTracingThreshold);

  std::unique_ptr<sky::compositor::LayerTree> m_layerTree;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_COMPOSITING_SCENE_H_
