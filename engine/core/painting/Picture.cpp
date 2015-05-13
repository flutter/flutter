// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/Picture.h"

#include "base/logging.h"

namespace blink {

PassRefPtr<Picture> Picture::create(PassRefPtr<DisplayList> list)
{
    ASSERT(list);
    return adoptRef(new Picture(list));
}

Picture::Picture(PassRefPtr<DisplayList> list)
    : m_displayList(list)
{
}

Picture::~Picture()
{
}

} // namespace blink
