// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Drawable.h"
#include "sky/engine/core/painting/Picture.h"

namespace blink {

PassRefPtr<Drawable> Drawable::create(PassRefPtr<SkDrawable> skDrawable)
{
    ASSERT(skDrawable);
    return adoptRef(new Drawable(skDrawable));
}

Drawable::Drawable(PassRefPtr<SkDrawable> skDrawable)
    : m_drawable(skDrawable)
{
}

PassRefPtr<Picture> Drawable::newPictureSnapshot()
{
    if (!m_drawable)
        return nullptr;
    return Picture::create(
        adoptRef(m_drawable->newPictureSnapshot()));
}

Drawable::~Drawable()
{
}

} // namespace blink
