/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
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

#ifndef KeyframeValueList_h
#define KeyframeValueList_h

#include "platform/animation/AnimationValue.h"

#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/Vector.h"

namespace blink {

enum AnimatedPropertyID {
    AnimatedPropertyInvalid,
    AnimatedPropertyTransform,
    AnimatedPropertyOpacity,
    AnimatedPropertyBackgroundColor,
    AnimatedPropertyWebkitFilter
};

// Used to store a series of values in a keyframe list.
// Values will all be of the same type, which can be inferred from the property.
class PLATFORM_EXPORT KeyframeValueList {
public:
    explicit KeyframeValueList(AnimatedPropertyID property)
        : m_property(property)
    {
    }

    KeyframeValueList(const KeyframeValueList& other)
        : m_property(other.property())
    {
        for (size_t i = 0; i < other.m_values.size(); ++i)
            m_values.append(other.m_values[i]->clone());
    }

    KeyframeValueList& operator=(const KeyframeValueList& other)
    {
        KeyframeValueList copy(other);
        swap(copy);
        return *this;
    }

    void swap(KeyframeValueList& other)
    {
        std::swap(m_property, other.m_property);
        m_values.swap(other.m_values);
    }

    AnimatedPropertyID property() const { return m_property; }

    size_t size() const { return m_values.size(); }
    const AnimationValue* at(size_t i) const { return m_values.at(i).get(); }

    // Insert, sorted by keyTime.
    void insert(PassOwnPtr<const AnimationValue>);

protected:
    Vector<OwnPtr<const AnimationValue> > m_values;
    AnimatedPropertyID m_property;
};

} // namespace blink

#endif // KeyframeValueList_h
