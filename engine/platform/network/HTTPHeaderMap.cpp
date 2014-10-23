/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/network/HTTPHeaderMap.h"

namespace blink {

HTTPHeaderMap::HTTPHeaderMap()
{
}

HTTPHeaderMap::~HTTPHeaderMap()
{
}

PassOwnPtr<CrossThreadHTTPHeaderMapData> HTTPHeaderMap::copyData() const
{
    OwnPtr<CrossThreadHTTPHeaderMapData> data = adoptPtr(new CrossThreadHTTPHeaderMapData());
    data->reserveInitialCapacity(size());

    HTTPHeaderMap::const_iterator endIt = end();
    for (HTTPHeaderMap::const_iterator it = begin(); it != endIt; ++it)
        data->uncheckedAppend(std::make_pair(it->key.string().isolatedCopy(), it->value.string().isolatedCopy()));

    return data.release();
}

void HTTPHeaderMap::adopt(PassOwnPtr<CrossThreadHTTPHeaderMapData> data)
{
    clear();
    size_t dataSize = data->size();
    for (size_t index = 0; index < dataSize; ++index) {
        pair<String, String>& header = (*data)[index];
        set(AtomicString(header.first), AtomicString(header.second));
    }
}

// Adapter that allows the HashMap to take C strings as keys.
struct CaseFoldingCStringTranslator {
    static unsigned hash(const char* cString)
    {
        return CaseFoldingHash::hash(cString, strlen(cString));
    }

    static bool equal(const AtomicString& key, const char* cString)
    {
        return equalIgnoringCase(key, cString);
    }

    static void translate(AtomicString& location, const char* cString, unsigned /*hash*/)
    {
        location = AtomicString(cString);
    }
};

const AtomicString& HTTPHeaderMap::get(const char* name) const
{
    const_iterator i = m_headers.find<CaseFoldingCStringTranslator>(name);
    if (i == end())
        return nullAtom;
    return i->value;
}

bool HTTPHeaderMap::contains(const char* name) const
{
    return m_headers.find<CaseFoldingCStringTranslator>(name) != end();
}

HTTPHeaderMap::AddResult HTTPHeaderMap::add(const char* name, const AtomicString& value)
{
    return m_headers.add<CaseFoldingCStringTranslator>(name, value);
}

} // namespace blink
