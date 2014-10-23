/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2008, 2009 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef CSSShadowValue_h
#define CSSShadowValue_h

#include "core/css/CSSValue.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

class CSSPrimitiveValue;

// Used for text-shadow and box-shadow
class CSSShadowValue : public CSSValue {
public:
    static PassRefPtrWillBeRawPtr<CSSShadowValue> create(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> x,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> y,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> blur,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> spread,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> style,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> color)
    {
        return adoptRefWillBeNoop(new CSSShadowValue(x, y, blur, spread, style, color));
    }

    String customCSSText() const;

    bool equals(const CSSShadowValue&) const;

    RefPtrWillBeMember<CSSPrimitiveValue> x;
    RefPtrWillBeMember<CSSPrimitiveValue> y;
    RefPtrWillBeMember<CSSPrimitiveValue> blur;
    RefPtrWillBeMember<CSSPrimitiveValue> spread;
    RefPtrWillBeMember<CSSPrimitiveValue> style;
    RefPtrWillBeMember<CSSPrimitiveValue> color;

    void traceAfterDispatch(Visitor*);

private:
    CSSShadowValue(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> x,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> y,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> blur,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> spread,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> style,
        PassRefPtrWillBeRawPtr<CSSPrimitiveValue> color);
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSShadowValue, isShadowValue());

} // namespace

#endif
