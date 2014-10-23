/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2011 Research In Motion Limited. All rights reserved.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
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

#ifndef StylePropertySerializer_h
#define StylePropertySerializer_h

#include "core/css/CSSValueList.h"
#include "core/css/StylePropertySet.h"

namespace blink {

class StylePropertySet;

class StylePropertySerializer {
public:
    StylePropertySerializer(const StylePropertySet&);
    String asText() const;
    String getPropertyValue(CSSPropertyID) const;
private:
    String getCommonValue(const StylePropertyShorthand&) const;
    enum CommonValueMode { OmitUncommonValues, ReturnNullOnUncommonValues };
    String borderPropertyValue(CommonValueMode) const;
    String getLayeredShorthandValue(const StylePropertyShorthand&) const;
    String get4Values(const StylePropertyShorthand&) const;
    String borderSpacingValue(const StylePropertyShorthand&) const;
    String getShorthandValue(const StylePropertyShorthand&) const;
    String fontValue() const;
    void appendFontLonghandValueIfExplicit(CSSPropertyID, StringBuilder& result, String& value) const;
    String backgroundRepeatPropertyValue() const;
    String getPropertyText(CSSPropertyID, const String& value, bool isImportant, bool isNotFirstDecl) const;
    bool isPropertyShorthandAvailable(const StylePropertyShorthand&) const;
    bool shorthandHasOnlyInitialOrInheritedValue(const StylePropertyShorthand&) const;
    void appendBackgroundPropertyAsText(StringBuilder& result, unsigned& numDecls) const;

    const StylePropertySet& m_propertySet;
};

} // namespace blink

#endif
