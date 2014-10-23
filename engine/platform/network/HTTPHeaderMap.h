/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef HTTPHeaderMap_h
#define HTTPHeaderMap_h

#include "platform/PlatformExport.h"
#include "wtf/HashMap.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/AtomicStringHash.h"
#include "wtf/text/StringHash.h"
#include <utility>

namespace blink {

typedef Vector<std::pair<String, String> > CrossThreadHTTPHeaderMapData;

// FIXME: Not every header fits into a map. Notably, multiple Set-Cookie header fields are needed to set multiple cookies.
class PLATFORM_EXPORT HTTPHeaderMap {
public:
    HTTPHeaderMap();
    ~HTTPHeaderMap();

    // Gets a copy of the data suitable for passing to another thread.
    PassOwnPtr<CrossThreadHTTPHeaderMapData> copyData() const;

    void adopt(PassOwnPtr<CrossThreadHTTPHeaderMapData>);

    typedef HashMap<AtomicString, AtomicString, CaseFoldingHash> MapType;
    typedef MapType::AddResult AddResult;
    typedef MapType::const_iterator const_iterator;

    size_t size() const { return m_headers.size(); }
    const_iterator begin() const { return m_headers.begin(); }
    const_iterator end() const { return m_headers.end(); }
    const_iterator find(const AtomicString &k) const { return m_headers.find(k); }
    void clear() { m_headers.clear(); }
    const AtomicString& get(const AtomicString& k) const { return m_headers.get(k); }
    AddResult set(const AtomicString& k, const AtomicString& v) { return m_headers.set(k, v); }
    AddResult add(const AtomicString& k, const AtomicString& v) { return m_headers.add(k, v); }
    void remove(const AtomicString& k) { m_headers.remove(k); }
    bool operator!=(const HTTPHeaderMap& rhs) const { return m_headers != rhs.m_headers; }
    bool operator==(const HTTPHeaderMap& rhs) const { return m_headers == rhs.m_headers; }

    // Alternate accessors that are faster than converting the char* to AtomicString first.
    bool contains(const char*) const;
    const AtomicString& get(const char*) const;
    AddResult add(const char* name, const AtomicString& value);

private:
    HashMap<AtomicString, AtomicString, CaseFoldingHash> m_headers;
};

} // namespace blink

#endif // HTTPHeaderMap_h
