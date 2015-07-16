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

#ifndef SKY_ENGINE_CORE_CSS_CSSINITIALVALUE_H_
#define SKY_ENGINE_CORE_CSS_CSSINITIALVALUE_H_

#include "sky/engine/core/css/CSSValue.h"
#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {

class CSSInitialValue : public CSSValue {
public:
    static PassRefPtr<CSSInitialValue> createExplicit()
    {
        return adoptRef(new CSSInitialValue(/* implicit */ false));
    }
    static PassRefPtr<CSSInitialValue> createImplicit()
    {
        return adoptRef(new CSSInitialValue(/* implicit */ true));
    }

    String customCSSText() const;

    bool isImplicit() const { return m_isImplicit; }

    bool equals(const CSSInitialValue&) const { return true; }

private:
    explicit CSSInitialValue(bool implicit)
        : CSSValue(InitialClass)
        , m_isImplicit(implicit)
    {
    }

    bool m_isImplicit;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSInitialValue, isInitialValue());

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_CSSINITIALVALUE_H_
