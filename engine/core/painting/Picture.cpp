// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Picture.h"

#include "base/logging.h"

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

} // namespace blink
