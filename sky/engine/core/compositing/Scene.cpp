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
    : m_rootLayer(std::move(rootLayer))
{
}

Scene::~Scene()
{
}

PassRefPtr<SkPicture> Scene::createPicture() const
{
    SkRTreeFactory rtreeFactory;
    SkPictureRecorder pictureRecorder;
    SkCanvas* canvas = pictureRecorder.beginRecording(m_rootLayer->paint_bounds(),
        &rtreeFactory, SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag);
    m_rootLayer->Paint(canvas);
    return adoptRef(pictureRecorder.endRecording());
}

} // namespace blink
