/*
 * Copyright (C) 2011 Google Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 *  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 *  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include "config.h"
#include "core/rendering/style/StyleFlexibleBoxData.h"

#include "core/rendering/style/RenderStyle.h"

namespace blink {

StyleFlexibleBoxData::StyleFlexibleBoxData()
    : m_flexGrow(RenderStyle::initialFlexGrow())
    , m_flexShrink(RenderStyle::initialFlexShrink())
    , m_flexBasis(RenderStyle::initialFlexBasis())
    , m_flexDirection(RenderStyle::initialFlexDirection())
    , m_flexWrap(RenderStyle::initialFlexWrap())
{
}

StyleFlexibleBoxData::StyleFlexibleBoxData(const StyleFlexibleBoxData& o)
    : RefCounted<StyleFlexibleBoxData>()
    , m_flexGrow(o.m_flexGrow)
    , m_flexShrink(o.m_flexShrink)
    , m_flexBasis(o.m_flexBasis)
    , m_flexDirection(o.m_flexDirection)
    , m_flexWrap(o.m_flexWrap)
{
}

bool StyleFlexibleBoxData::operator==(const StyleFlexibleBoxData& o) const
{
    return m_flexGrow == o.m_flexGrow && m_flexShrink == o.m_flexShrink && m_flexBasis == o.m_flexBasis
        && m_flexDirection == o.m_flexDirection && m_flexWrap == o.m_flexWrap;
}

}
