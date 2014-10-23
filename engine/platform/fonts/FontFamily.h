/*
 * Copyright (C) 2003, 2006, 2008 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
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

#ifndef FontFamily_h
#define FontFamily_h

#include "platform/PlatformExport.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class SharedFontFamily;

class PLATFORM_EXPORT FontFamily {
public:
    FontFamily() { }
    ~FontFamily();

    void setFamily(const AtomicString& family) { m_family = family; }
    const AtomicString& family() const { return m_family; }
    bool familyIsEmpty() const { return m_family.isEmpty(); }

    const FontFamily* next() const;

    void appendFamily(PassRefPtr<SharedFontFamily>);
    PassRefPtr<SharedFontFamily> releaseNext();

private:
    AtomicString m_family;
    RefPtr<SharedFontFamily> m_next;
};

class PLATFORM_EXPORT SharedFontFamily : public FontFamily, public RefCounted<SharedFontFamily> {
public:
    static PassRefPtr<SharedFontFamily> create()
    {
        return adoptRef(new SharedFontFamily);
    }

private:
    SharedFontFamily() { }
};

PLATFORM_EXPORT bool operator==(const FontFamily&, const FontFamily&);
inline bool operator!=(const FontFamily& a, const FontFamily& b) { return !(a == b); }

inline FontFamily::~FontFamily()
{
    RefPtr<SharedFontFamily> reaper = m_next.release();
    while (reaper && reaper->hasOneRef())
        reaper = reaper->releaseNext(); // implicitly protects reaper->next, then derefs reaper
}

inline const FontFamily* FontFamily::next() const
{
    return m_next.get();
}

inline void FontFamily::appendFamily(PassRefPtr<SharedFontFamily> family)
{
    m_next = family;
}

inline PassRefPtr<SharedFontFamily> FontFamily::releaseNext()
{
    return m_next.release();
}

} // namespace blink

#endif
