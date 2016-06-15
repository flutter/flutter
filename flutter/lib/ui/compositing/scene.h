// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_H_

#include <stdint.h>
#include <memory>

#include "base/memory/ref_counted.h"
#include "flow/layers/layer_tree.h"
#include "flutter/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class DartLibraryNatives;

class Scene : public base::RefCountedThreadSafe<Scene>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  ~Scene() override;
  static scoped_refptr<Scene> create(
      std::unique_ptr<flow::Layer> rootLayer,
      uint32_t rasterizerTracingThreshold);

  std::unique_ptr<flow::LayerTree> takeLayerTree();

  void dispose();

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  explicit Scene(std::unique_ptr<flow::Layer> rootLayer,
                 uint32_t rasterizerTracingThreshold);

  std::unique_ptr<flow::LayerTree> m_layerTree;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_H_
