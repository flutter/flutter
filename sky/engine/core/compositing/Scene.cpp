// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/compositing/Scene.h"

#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace blink {

PassRefPtr<Scene> Scene::create(
    std::unique_ptr<sky::compositor::Layer> rootLayer,
    uint32_t rasterizerTracingThreshold) {
  ASSERT(rootLayer);
  return adoptRef(new Scene(std::move(rootLayer), rasterizerTracingThreshold));
}

Scene::Scene(std::unique_ptr<sky::compositor::Layer> rootLayer,
             uint32_t rasterizerTracingThreshold)
    : m_layerTree(new sky::compositor::LayerTree()) {
  m_layerTree->set_root_layer(std::move(rootLayer));
  m_layerTree->set_rasterizer_tracing_threshold(rasterizerTracingThreshold);
}

Scene::~Scene() {}

std::unique_ptr<sky::compositor::LayerTree> Scene::takeLayerTree() {
  return std::move(m_layerTree);
}

}  // namespace blink
