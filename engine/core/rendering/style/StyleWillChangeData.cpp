// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/rendering/style/StyleWillChangeData.h"

namespace blink {

StyleWillChangeData::StyleWillChangeData()
    : m_contents(false)
{
}

StyleWillChangeData::StyleWillChangeData(const StyleWillChangeData& o)
    : RefCounted<StyleWillChangeData>()
    , m_properties(o.m_properties)
    , m_contents(o.m_contents)
{
}

} // namespace blink
