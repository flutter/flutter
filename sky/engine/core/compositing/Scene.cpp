// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/compositing/Scene.h"

namespace blink {

PassRefPtr<Scene> Scene::create(PassRefPtr<SkPicture> picture)
{
    ASSERT(picture);
    return adoptRef(new Scene(picture));
}

Scene::Scene(PassRefPtr<SkPicture> picture)
    : m_picture(picture)
{
}

Scene::~Scene()
{
}

} // namespace blink
