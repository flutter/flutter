// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Picture.h"

#include "sky/engine/core/painting/Canvas.h"

namespace blink {

PassRefPtr<Picture> Picture::create(PassRefPtr<SkPicture> skPicture)
{
    ASSERT(skPicture);
    return adoptRef(new Picture(skPicture));
}

Picture::Picture(PassRefPtr<SkPicture> skPicture)
    : m_picture(skPicture)
{
}

Picture::~Picture()
{
}

void Picture::playback(Canvas* canvas)
{
    m_picture->playback(canvas->skCanvas());
}

} // namespace blink
