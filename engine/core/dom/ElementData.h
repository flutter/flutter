/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 * Copyright (C) 2014 Apple Inc. All rights reserved.
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

#ifndef ElementData_h
#define ElementData_h

#include "core/dom/Attribute.h"
#include "core/dom/AttributeCollection.h"
#include "core/dom/SpaceSplitString.h"
#include "platform/heap/Handle.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class ShareableElementData;
class StylePropertySet;
class UniqueElementData;

// ElementData represents very common, but not necessarily unique to an element,
// data such as attributes, inline style, and parsed class names and ids.
class ElementData : public RefCounted<ElementData> {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    // Override RefCounted's deref() to ensure operator delete is called on
    // the appropriate subclass type.
    void deref();

    void clearClass() const { m_classNames.clear(); }
    void setClass(const AtomicString& className, bool shouldFoldCase) const { m_classNames.set(className, shouldFoldCase); }
    const SpaceSplitString& classNames() const { return m_classNames; }

    const AtomicString& idForStyleResolution() const { return m_idForStyleResolution; }
    void setIdForStyleResolution(const AtomicString& newId) const { m_idForStyleResolution = newId; }

    const StylePropertySet* inlineStyle() const { return m_inlineStyle.get(); }

    AttributeCollection attributes() const;

    bool hasID() const { return !m_idForStyleResolution.isNull(); }
    bool hasClass() const { return !m_classNames.isNull(); }

    bool isEquivalent(const ElementData* other) const;

    bool isUnique() const { return m_isUnique; }

    void traceAfterDispatch(Visitor*);
    void trace(Visitor*);

protected:
    ElementData();
    explicit ElementData(unsigned arraySize);
    ElementData(const ElementData&, bool isUnique);

    // Keep the type in a bitfield instead of using virtual destructors to avoid adding a vtable.
    unsigned m_isUnique : 1;
    unsigned m_arraySize : 28;
    mutable unsigned m_styleAttributeIsDirty : 1;

    mutable RefPtr<StylePropertySet> m_inlineStyle;
    mutable SpaceSplitString m_classNames;
    mutable AtomicString m_idForStyleResolution;

private:
    friend class Element;
    friend class ShareableElementData;
    friend class UniqueElementData;

#if !ENABLE(OILPAN)
    void destroy();
#endif

    PassRefPtr<UniqueElementData> makeUniqueCopy() const;
};

#define DEFINE_ELEMENT_DATA_TYPE_CASTS(thisType,  pointerPredicate, referencePredicate) \
    template<typename T> inline thisType* to##thisType(const RefPtr<T>& data) { return to##thisType(data.get()); } \
    DEFINE_TYPE_CASTS(thisType, ElementData, data, pointerPredicate, referencePredicate)

#if COMPILER(MSVC)
#pragma warning(push)
#pragma warning(disable: 4200) // Disable "zero-sized array in struct/union" warning
#endif

// SharableElementData is managed by ElementDataCache and is produced by
// the parser during page load for elements that have identical attributes. This
// is a memory optimization since it's very common for many elements to have
// duplicate sets of attributes (ex. the same classes).
class ShareableElementData final : public ElementData {
public:
    static PassRefPtr<ShareableElementData> createWithAttributes(const Vector<Attribute>&);

    explicit ShareableElementData(const Vector<Attribute>&);
    explicit ShareableElementData(const UniqueElementData&);
    ~ShareableElementData();

    void traceAfterDispatch(Visitor* visitor) { ElementData::traceAfterDispatch(visitor); }

    // Add support for placement new as ShareableElementData is not allocated
    // with a fixed size. Instead the allocated memory size is computed based on
    // the number of attributes. This requires us to use Heap::allocate directly
    // with the computed size and subsequently call placement new with the
    // allocated memory address.
    void* operator new(std::size_t, void* location)
    {
        return location;
    }

    AttributeCollection attributes() const;

    Attribute m_attributeArray[0];
};

DEFINE_ELEMENT_DATA_TYPE_CASTS(ShareableElementData, !data->isUnique(), !data.isUnique());

#if COMPILER(MSVC)
#pragma warning(pop)
#endif

// UniqueElementData is created when an element needs to mutate its attributes
// or gains presentation attribute style (ex. width="10"). It does not need to
// be created to fill in values in the ElementData that are derived from
// attributes. For example populating the m_inlineStyle from the style attribute
// doesn't require a UniqueElementData as all elements with the same style
// attribute will have the same inline style.
class UniqueElementData final : public ElementData {
public:
    static PassRefPtr<UniqueElementData> create();
    PassRefPtr<ShareableElementData> makeShareableCopy() const;

    MutableAttributeCollection attributes();
    AttributeCollection attributes() const;

    UniqueElementData();
    explicit UniqueElementData(const ShareableElementData&);
    explicit UniqueElementData(const UniqueElementData&);

    void traceAfterDispatch(Visitor*);

    AttributeVector m_attributeVector;
};

DEFINE_ELEMENT_DATA_TYPE_CASTS(UniqueElementData, data->isUnique(), data.isUnique());

#if !ENABLE(OILPAN)
inline void ElementData::deref()
{
    if (!derefBase())
        return;
    destroy();
}
#endif

inline AttributeCollection ElementData::attributes() const
{
    if (isUnique())
        return toUniqueElementData(this)->attributes();
    return toShareableElementData(this)->attributes();
}

inline AttributeCollection ShareableElementData::attributes() const
{
    return AttributeCollection(m_attributeArray, m_arraySize);
}

inline AttributeCollection UniqueElementData::attributes() const
{
    return AttributeCollection(m_attributeVector.data(), m_attributeVector.size());
}

inline MutableAttributeCollection UniqueElementData::attributes()
{
    return MutableAttributeCollection(m_attributeVector);
}

} // namespace blink

#endif // ElementData_h
