// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/rendering/style/StyleWillChangeData.h"

namespace blink {

StyleWillChangeData::StyleWillChangeData()
    : m_contents(false)
    , m_scrollPosition(false)
{
}

StyleWillChangeData::StyleWillChangeData(const StyleWillChangeData& o)
    : RefCounted<StyleWillChangeData>()
    , m_properties(o.m_properties)
    , m_contents(o.m_contents)
    , m_scrollPosition(o.m_scrollPosition)
{
}

} // namespace blink
