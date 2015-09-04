// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/compositing/Scene.h"

#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace blink {

PassRefPtr<Scene> Scene::create(std::unique_ptr<sky::Layer> rootLayer)
{
    ASSERT(rootLayer);
    return adoptRef(new Scene(std::move(rootLayer)));
}

Scene::Scene(std::unique_ptr<sky::Layer> rootLayer)
    : m_layerTree(new sky::LayerTree())
{
    m_layerTree->set_root_layer(std::move(rootLayer));
}

Scene::~Scene()
{
}

std::unique_ptr<sky::LayerTree> Scene::takeLayerTree() {
  return std::move(m_layerTree);
}

} // namespace blink
