// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Picture.h"

#include "sky/engine/core/painting/Canvas.h"
#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(Picture);

#define FOR_EACH_BINDING(V) \
  V(Picture, playback) \
  V(Picture, dispose)

DART_BIND_ALL(Picture, FOR_EACH_BINDING)

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

void Picture::dispose()
{
    ClearDartWrapper();
}

} // namespace blink
