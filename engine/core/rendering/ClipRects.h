/*
 * Copyright (C) 2003, 2009, 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef ClipRects_h
#define ClipRects_h

#include "core/rendering/ClipRect.h"

namespace blink {

class ClipRects {
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassRefPtr<ClipRects> create()
    {
        return adoptRef(new ClipRects);
    }

    static PassRefPtr<ClipRects> create(const ClipRects& other)
    {
        return adoptRef(new ClipRects(other));
    }

    ClipRects()
        : m_refCnt(1)
        , m_fixed(0)
    {
    }

    void reset(const LayoutRect& r)
    {
        m_overflowClipRect = r;
        m_fixedClipRect = r;
        m_posClipRect = r;
        m_fixed = 0;
    }

    const ClipRect& overflowClipRect() const { return m_overflowClipRect; }
    void setOverflowClipRect(const ClipRect& r) { m_overflowClipRect = r; }

    const ClipRect& fixedClipRect() const { return m_fixedClipRect; }
    void setFixedClipRect(const ClipRect&r) { m_fixedClipRect = r; }

    const ClipRect& posClipRect() const { return m_posClipRect; }
    void setPosClipRect(const ClipRect& r) { m_posClipRect = r; }

    bool fixed() const { return static_cast<bool>(m_fixed); }
    void setFixed(bool fixed) { m_fixed = fixed ? 1 : 0; }

    void ref() { m_refCnt++; }
    void deref()
    {
        if (!--m_refCnt)
            delete this;
    }

    bool operator==(const ClipRects& other) const
    {
        return m_overflowClipRect == other.overflowClipRect()
            && m_fixedClipRect == other.fixedClipRect()
            && m_posClipRect == other.posClipRect()
            && fixed() == other.fixed();
    }

    ClipRects& operator=(const ClipRects& other)
    {
        m_overflowClipRect = other.overflowClipRect();
        m_fixedClipRect = other.fixedClipRect();
        m_posClipRect = other.posClipRect();
        m_fixed = other.fixed();
        return *this;
    }

private:
    ClipRects(const LayoutRect& r)
        : m_overflowClipRect(r)
        , m_fixedClipRect(r)
        , m_posClipRect(r)
        , m_refCnt(1)
        , m_fixed(0)
    {
    }

    ClipRects(const ClipRects& other)
        : m_overflowClipRect(other.overflowClipRect())
        , m_fixedClipRect(other.fixedClipRect())
        , m_posClipRect(other.posClipRect())
        , m_refCnt(1)
        , m_fixed(other.fixed())
    {
    }

    ClipRect m_overflowClipRect;
    ClipRect m_fixedClipRect;
    ClipRect m_posClipRect;
    unsigned m_refCnt : 31;
    unsigned m_fixed : 1;
};

} // namespace blink

#endif // ClipRects_h
