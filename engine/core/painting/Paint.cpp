// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/Paint.h"

#include "sky/engine/core/painting/ColorFilter.h"
#include "sky/engine/core/painting/DrawLooper.h"
#include "sky/engine/core/painting/MaskFilter.h"

namespace blink {

Paint::Paint()
{
}

Paint::~Paint()
{
}

void Paint::setDrawLooper(DrawLooper* looper)
{
    ASSERT(looper);
    m_paint.setLooper(looper->looper());
}

void Paint::setColorFilter(ColorFilter* filter)
{
    ASSERT(filter);
    m_paint.setColorFilter(filter->filter());
}

void Paint::setMaskFilter(MaskFilter* filter)
{
    ASSERT(filter);
    m_paint.setMaskFilter(filter->filter());
}

void Paint::setStyle(SkPaint::Style style)
{
    m_paint.setStyle(style);
}

void Paint::setTransferMode(SkXfermode::Mode transfer_mode)
{
    m_paint.setXfermodeMode(transfer_mode);
}

} // namespace blink
