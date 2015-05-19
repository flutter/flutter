// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/view/View.h"

namespace blink {

PassRefPtr<View> View::create(const base::Closure& schedulePaintCallback)
{
    return adoptRef(new View(schedulePaintCallback));
}

View::View(const base::Closure& schedulePaintCallback)
    : m_schedulePaintCallback(schedulePaintCallback)
{
}

View::~View()
{
}

void View::schedulePaint()
{
    m_schedulePaintCallback.Run();
}

} // namespace blink
