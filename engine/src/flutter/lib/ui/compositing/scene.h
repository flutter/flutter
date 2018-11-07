// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_H_

#include <stdint.h>
#include <memory>

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class Scene : public RefCountedDartWrappable<Scene> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Scene);

 public:
  ~Scene() override;
  static fml::RefPtr<Scene> create(std::shared_ptr<flow::Layer> rootLayer,
                                   uint32_t rasterizerTracingThreshold,
                                   bool checkerboardRasterCacheImages,
                                   bool checkerboardOffscreenLayers);

  std::unique_ptr<flow::LayerTree> takeLayerTree();

  Dart_Handle toImage(uint32_t width,
                      uint32_t height,
                      Dart_Handle image_callback);

  void dispose();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit Scene(std::shared_ptr<flow::Layer> rootLayer,
                 uint32_t rasterizerTracingThreshold,
                 bool checkerboardRasterCacheImages,
                 bool checkerboardOffscreenLayers);

  std::unique_ptr<flow::LayerTree> m_layerTree;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_H_
