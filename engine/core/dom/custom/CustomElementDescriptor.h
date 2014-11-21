/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef CustomElementDescriptor_h
#define CustomElementDescriptor_h

#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/HashTableDeletedValueType.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

struct CustomElementDescriptorHash;

// A Custom Element descriptor is everything necessary to match a
// Custom Element instance to a definition.
class CustomElementDescriptor {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    CustomElementDescriptor(const AtomicString& type, const AtomicString& localName)
        : m_type(type)
        , m_localName(localName)
    {
    }

    ~CustomElementDescriptor() { }

    // The tag name.
    const AtomicString& localName() const { return m_localName; }

    // The name of the definition. For custom tags, this is the tag
    // name and the same as "localName". For type extensions, this is
    // the value of the "is" attribute.
    const AtomicString& type() const { return m_type; }

    bool isTypeExtension() const { return m_type != m_localName; }

    // Stuff for hashing.

    CustomElementDescriptor() { }
    explicit CustomElementDescriptor(WTF::HashTableDeletedValueType value)
        : m_type(value) { }
    bool isHashTableDeletedValue() const { return m_type.isHashTableDeletedValue(); }

    bool operator==(const CustomElementDescriptor& other) const
    {
        return m_type == other.m_type
            && m_localName == other.m_localName;
    }

private:
    AtomicString m_type;
    AtomicString m_localName;
};

} // namespace blink

namespace WTF {

template<typename T> struct DefaultHash;
template<> struct DefaultHash<blink::CustomElementDescriptor> {
    typedef blink::CustomElementDescriptorHash Hash;
};

} // namespace WTF

#endif // CustomElementDescriptor_h
