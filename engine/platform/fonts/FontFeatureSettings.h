/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef FontFeatureSettings_h
#define FontFeatureSettings_h

#include "platform/PlatformExport.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class PLATFORM_EXPORT FontFeature {
public:
    FontFeature(const AtomicString& tag, int value);
    bool operator==(const FontFeature&);

    const AtomicString& tag() const { return m_tag; }
    int value() const { return m_value; }

private:
    AtomicString m_tag;
    const int m_value;
};

class PLATFORM_EXPORT FontFeatureSettings : public RefCounted<FontFeatureSettings> {
public:
    static PassRefPtr<FontFeatureSettings> create()
    {
        return adoptRef(new FontFeatureSettings());
    }
    void append(const FontFeature& feature) { m_list.append(feature); }
    size_t size() const { return m_list.size(); }
    const FontFeature& operator[](int index) const { return m_list[index]; }
    const FontFeature& at(size_t index) const { return m_list.at(index); }

private:
    FontFeatureSettings();
    Vector<FontFeature> m_list;
};

} // namespace blink

#endif // FontFeatureSettings_h
