// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_H_

#include <cstdint>
#include <memory>

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

class Scene : public RefCountedDartWrappable<Scene> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Scene);

 public:
  ~Scene() override;
  static void create(Dart_Handle scene_handle,
                     std::shared_ptr<flutter::Layer> rootLayer,
                     uint32_t rasterizerTracingThreshold,
                     bool checkerboardRasterCacheImages,
                     bool checkerboardOffscreenLayers);

  std::unique_ptr<flutter::LayerTree> takeLayerTree();

  Dart_Handle toImage(uint32_t width,
                      uint32_t height,
                      Dart_Handle image_callback);

  void dispose();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit Scene(std::shared_ptr<flutter::Layer> rootLayer,
                 uint32_t rasterizerTracingThreshold,
                 bool checkerboardRasterCacheImages,
                 bool checkerboardOffscreenLayers);

  std::unique_ptr<flutter::LayerTree> layer_tree_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_H_
