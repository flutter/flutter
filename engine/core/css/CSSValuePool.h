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

#include "core/css/CSSInheritedValue.h"
#include "core/css/CSSInitialValue.h"
#include "core/css/CSSPrimitiveValue.h"
#include "gen/sky/core/CSSPropertyNames.h"
#include "gen/sky/core/CSSValueKeywords.h"
#include "wtf/HashMap.h"
#include "wtf/RefPtr.h"
#include "wtf/text/AtomicStringHash.h"

namespace blink {

class CSSValueList;

class CSSValuePool {
    WTF_MAKE_FAST_ALLOCATED;
public:
    PassRefPtr<CSSValueList> createFontFaceValue(const AtomicString&);
    PassRefPtr<CSSPrimitiveValue> createFontFamilyValue(const String&);
    PassRefPtr<CSSInheritedValue> createInheritedValue() { return m_inheritedValue; }
    PassRefPtr<CSSInitialValue> createImplicitInitialValue() { return m_implicitInitialValue; }
    PassRefPtr<CSSInitialValue> createExplicitInitialValue() { return m_explicitInitialValue; }
    PassRefPtr<CSSPrimitiveValue> createIdentifierValue(CSSValueID identifier);
    PassRefPtr<CSSPrimitiveValue> createIdentifierValue(CSSPropertyID identifier);
    PassRefPtr<CSSPrimitiveValue> createColorValue(unsigned rgbValue);
    PassRefPtr<CSSPrimitiveValue> createValue(double value, CSSPrimitiveValue::UnitType);
    PassRefPtr<CSSPrimitiveValue> createValue(const String& value, CSSPrimitiveValue::UnitType type) { return CSSPrimitiveValue::create(value, type); }
    PassRefPtr<CSSPrimitiveValue> createValue(const Length& value, const RenderStyle&);
    PassRefPtr<CSSPrimitiveValue> createValue(const Length& value) { return CSSPrimitiveValue::create(value); }
    template<typename T> static PassRefPtr<CSSPrimitiveValue> createValue(T value) { return CSSPrimitiveValue::create(value); }

private:
    CSSValuePool();

    RefPtr<CSSInheritedValue> m_inheritedValue;
    RefPtr<CSSInitialValue> m_implicitInitialValue;
    RefPtr<CSSInitialValue> m_explicitInitialValue;

    Vector<RefPtr<CSSPrimitiveValue>, numCSSValueKeywords> m_identifierValueCache;

    typedef HashMap<unsigned, RefPtr<CSSPrimitiveValue> > ColorValueCache;
    ColorValueCache m_colorValueCache;
    RefPtr<CSSPrimitiveValue> m_colorTransparent;
    RefPtr<CSSPrimitiveValue> m_colorWhite;
    RefPtr<CSSPrimitiveValue> m_colorBlack;

    static const int maximumCacheableIntegerValue = 255;

    Vector<RefPtr<CSSPrimitiveValue>, maximumCacheableIntegerValue + 1> m_pixelValueCache;
    Vector<RefPtr<CSSPrimitiveValue>, maximumCacheableIntegerValue + 1> m_percentValueCache;
    Vector<RefPtr<CSSPrimitiveValue>, maximumCacheableIntegerValue + 1> m_numberValueCache;

    typedef HashMap<AtomicString, RefPtr<CSSValueList> > FontFaceValueCache;
    FontFaceValueCache m_fontFaceValueCache;

    typedef HashMap<String, RefPtr<CSSPrimitiveValue> > FontFamilyValueCache;
    FontFamilyValueCache m_fontFamilyValueCache;

    friend CSSValuePool& cssValuePool();
};

CSSValuePool& cssValuePool();

}

#endif
