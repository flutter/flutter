/*
 * Copyright (C) 2011, 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef CSSValuePool_h
#define CSSValuePool_h

#include "core/CSSPropertyNames.h"
#include "core/CSSValueKeywords.h"
#include "core/css/CSSInheritedValue.h"
#include "core/css/CSSInitialValue.h"
#include "core/css/CSSPrimitiveValue.h"
#include "wtf/HashMap.h"
#include "wtf/RefPtr.h"
#include "wtf/text/AtomicStringHash.h"

namespace blink {

class CSSValueList;

class CSSValuePool :  public NoBaseWillBeGarbageCollected<CSSValuePool> {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    PassRefPtrWillBeRawPtr<CSSValueList> createFontFaceValue(const AtomicString&);
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createFontFamilyValue(const String&);
    PassRefPtrWillBeRawPtr<CSSInheritedValue> createInheritedValue() { return m_inheritedValue; }
    PassRefPtrWillBeRawPtr<CSSInitialValue> createImplicitInitialValue() { return m_implicitInitialValue; }
    PassRefPtrWillBeRawPtr<CSSInitialValue> createExplicitInitialValue() { return m_explicitInitialValue; }
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createIdentifierValue(CSSValueID identifier);
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createIdentifierValue(CSSPropertyID identifier);
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createColorValue(unsigned rgbValue);
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createValue(double value, CSSPrimitiveValue::UnitType);
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createValue(const String& value, CSSPrimitiveValue::UnitType type) { return CSSPrimitiveValue::create(value, type); }
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createValue(const Length& value, const RenderStyle&);
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createValue(const Length& value, float zoom) { return CSSPrimitiveValue::create(value, zoom); }
    template<typename T> static PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createValue(T value) { return CSSPrimitiveValue::create(value); }

    void trace(Visitor*);

private:
    CSSValuePool();

    RefPtrWillBeMember<CSSInheritedValue> m_inheritedValue;
    RefPtrWillBeMember<CSSInitialValue> m_implicitInitialValue;
    RefPtrWillBeMember<CSSInitialValue> m_explicitInitialValue;

    WillBeHeapVector<RefPtrWillBeMember<CSSPrimitiveValue>, numCSSValueKeywords> m_identifierValueCache;

    typedef WillBeHeapHashMap<unsigned, RefPtrWillBeMember<CSSPrimitiveValue> > ColorValueCache;
    ColorValueCache m_colorValueCache;
    RefPtrWillBeMember<CSSPrimitiveValue> m_colorTransparent;
    RefPtrWillBeMember<CSSPrimitiveValue> m_colorWhite;
    RefPtrWillBeMember<CSSPrimitiveValue> m_colorBlack;

    static const int maximumCacheableIntegerValue = 255;

    WillBeHeapVector<RefPtrWillBeMember<CSSPrimitiveValue>, maximumCacheableIntegerValue + 1> m_pixelValueCache;
    WillBeHeapVector<RefPtrWillBeMember<CSSPrimitiveValue>, maximumCacheableIntegerValue + 1> m_percentValueCache;
    WillBeHeapVector<RefPtrWillBeMember<CSSPrimitiveValue>, maximumCacheableIntegerValue + 1> m_numberValueCache;

    typedef WillBeHeapHashMap<AtomicString, RefPtrWillBeMember<CSSValueList> > FontFaceValueCache;
    FontFaceValueCache m_fontFaceValueCache;

    typedef WillBeHeapHashMap<String, RefPtrWillBeMember<CSSPrimitiveValue> > FontFamilyValueCache;
    FontFamilyValueCache m_fontFamilyValueCache;

    friend CSSValuePool& cssValuePool();
};

CSSValuePool& cssValuePool();

}

#endif
