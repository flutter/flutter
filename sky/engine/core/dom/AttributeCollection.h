/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 * Copyright (C) 2014 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Samsung Electronics. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_DOM_ATTRIBUTECOLLECTION_H_
#define SKY_ENGINE_CORE_DOM_ATTRIBUTECOLLECTION_H_

#include "sky/engine/core/dom/Attr.h"
#include "sky/engine/core/dom/Attribute.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

template <typename Container, typename ContainerMemberType = Container>
class AttributeCollectionGeneric {
public:
    typedef typename Container::ValueType ValueType;
    typedef ValueType* iterator;

    AttributeCollectionGeneric(Container& attributes)
        : m_attributes(attributes)
    { }

    ValueType& operator[](unsigned index) const { return at(index); }
    ValueType& at(unsigned index) const
    {
        RELEASE_ASSERT(index < size());
        return begin()[index];
    }

    iterator begin() const { return m_attributes.data(); }
    iterator end() const { return begin() + size(); }

    unsigned size() const { return m_attributes.size(); }
    bool isEmpty() const { return !size(); }

    iterator find(const AtomicString& name) const;
    size_t findIndex(const AtomicString& name) const;
    size_t findIndex(Attr*) const;

    iterator find(const QualifiedName& name) { return find(name.localName()); }
    size_t findIndex(const QualifiedName& name) const { return findIndex(name.localName()); }

protected:
    ContainerMemberType m_attributes;
};

class AttributeArray {
public:
    typedef const Attribute ValueType;

    AttributeArray(const Attribute* array, unsigned size)
        : m_array(array)
        , m_size(size)
    { }

    const Attribute* data() const { return m_array; }
    unsigned size() const { return m_size; }

private:
    const Attribute* m_array;
    unsigned m_size;
};

class AttributeCollection : public AttributeCollectionGeneric<const AttributeArray> {
public:
    AttributeCollection()
        : AttributeCollectionGeneric<const AttributeArray>(AttributeArray(nullptr, 0))
    { }

    AttributeCollection(const Attribute* array, unsigned size)
        : AttributeCollectionGeneric<const AttributeArray>(AttributeArray(array, size))
    { }
};

typedef Vector<Attribute, 4> AttributeVector;
class MutableAttributeCollection : public AttributeCollectionGeneric<AttributeVector, AttributeVector&> {
public:
    explicit MutableAttributeCollection(AttributeVector& attributes)
        : AttributeCollectionGeneric<AttributeVector, AttributeVector&>(attributes)
    { }

    // These functions do no error/duplicate checking.
    void append(const QualifiedName&, const AtomicString& value);
    void remove(unsigned index);
};

inline void MutableAttributeCollection::append(const QualifiedName& name, const AtomicString& value)
{
    m_attributes.append(Attribute(name, value));
}

inline void MutableAttributeCollection::remove(unsigned index)
{
    m_attributes.remove(index);
}

template <typename Container, typename ContainerMemberType>
inline typename AttributeCollectionGeneric<Container, ContainerMemberType>::iterator AttributeCollectionGeneric<Container, ContainerMemberType>::find(const AtomicString& name) const
{
    size_t index = findIndex(name);
    return index != kNotFound ? &at(index) : 0;
}

template <typename Container, typename ContainerMemberType>
inline size_t AttributeCollectionGeneric<Container, ContainerMemberType>::findIndex(const AtomicString& name) const
{
    // Optimize for the case where the attribute exists and its name exactly matches.
    iterator end = this->end();
    unsigned index = 0;
    for (iterator it = begin(); it != end; ++it, ++index) {
        if (name == it->localName())
            return index;
    }

    return kNotFound;
}

template <typename Container, typename ContainerMemberType>
size_t AttributeCollectionGeneric<Container, ContainerMemberType>::findIndex(Attr* attr) const
{
    // This relies on the fact that Attr's QualifiedName == the Attribute's name.
    iterator end = this->end();
    unsigned index = 0;
    for (iterator it = begin(); it != end; ++it, ++index) {
        if (it->localName() == attr->name())
            return index;
    }
    return kNotFound;
}

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_ATTRIBUTECOLLECTION_H_
