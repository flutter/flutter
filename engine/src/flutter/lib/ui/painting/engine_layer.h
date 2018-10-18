// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_ENGINE_LAYER_H_
#define FLUTTER_LIB_UI_PAINTING_ENGINE_LAYER_H_

#include "flutter/lib/ui/dart_wrapper.h"

#include "flutter/flow/layers/layer.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class EngineLayer;

class EngineLayer : public RefCountedDartWrappable<EngineLayer> {
  DEFINE_WRAPPERTYPEINFO();

 public:
  ~EngineLayer() override;

  size_t GetAllocationSize() override;

  static fml::RefPtr<EngineLayer> MakeRetained(
      std::shared_ptr<flow::ContainerLayer> layer) {
    return fml::MakeRefCounted<EngineLayer>(layer);
  }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

  std::shared_ptr<flow::ContainerLayer> Layer() const { return layer_; }

 private:
  explicit EngineLayer(std::shared_ptr<flow::ContainerLayer> layer)
      : layer_(layer) {}
  std::shared_ptr<flow::ContainerLayer> layer_;

  FML_FRIEND_MAKE_REF_COUNTED(EngineLayer);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_ENGINE_LAYER_H_
