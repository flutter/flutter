/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2008 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_CSSFONTVALUE_H_
#define SKY_ENGINE_CORE_CSS_CSSFONTVALUE_H_

#include "sky/engine/core/css/CSSValue.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class CSSPrimitiveValue;
class CSSValueList;

class CSSFontValue : public CSSValue {
public:
    static PassRefPtr<CSSFontValue> create()
    {
        return adoptRef(new CSSFontValue);
    }

    String customCSSText() const;

    bool equals(const CSSFontValue&) const;

    RefPtr<CSSPrimitiveValue> style;
    RefPtr<CSSPrimitiveValue> variant;
    RefPtr<CSSPrimitiveValue> weight;
    RefPtr<CSSPrimitiveValue> stretch;
    RefPtr<CSSPrimitiveValue> size;
    RefPtr<CSSPrimitiveValue> lineHeight;
    RefPtr<CSSValueList> family;

private:
    CSSFontValue()
        : CSSValue(FontClass)
    {
    }
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSFontValue, isFontValue());

} // namespace

#endif  // SKY_ENGINE_CORE_CSS_CSSFONTVALUE_H_
