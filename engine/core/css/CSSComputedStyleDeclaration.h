/*
 * Copyright (C) 2004 Zack Rusin <zack@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2008, 2012 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#ifndef SKY_ENGINE_CORE_CSS_CSSCOMPUTEDSTYLEDECLARATION_H_
#define SKY_ENGINE_CORE_CSS_CSSCOMPUTEDSTYLEDECLARATION_H_

#include "sky/engine/core/css/CSSStyleDeclaration.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "sky/engine/platform/fonts/FixedPitchFontType.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "sky/engine/wtf/text/AtomicStringHash.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class CSSPrimitiveValue;
class CSSValueList;
class ExceptionState;
class MutableStylePropertySet;
class Node;
class RenderObject;
class RenderStyle;
class ShadowData;
class ShadowList;
class StyleColor;
class StylePropertySet;
class StylePropertyShorthand;

enum EUpdateLayout { DoNotUpdateLayout = false, UpdateLayout = true };

class CSSComputedStyleDeclaration final : public CSSStyleDeclaration {
public:
    static PassRefPtr<CSSComputedStyleDeclaration> create(PassRefPtr<Node> node, bool allowVisitedStyle = false)
    {
        return adoptRef(new CSSComputedStyleDeclaration(node, allowVisitedStyle));
    }
    virtual ~CSSComputedStyleDeclaration();

#if !ENABLE(OILPAN)
    virtual void ref() override;
    virtual void deref() override;
#endif

    String getPropertyValue(CSSPropertyID) const;

    virtual PassRefPtr<MutableStylePropertySet> copyProperties() const override;

    PassRefPtr<CSSValue> getPropertyCSSValue(CSSPropertyID, EUpdateLayout = UpdateLayout) const;
    PassRefPtr<CSSValue> getFontSizeCSSValuePreferringKeyword() const;
    FixedPitchFontType fixedPitchFontType() const;

    PassRefPtr<MutableStylePropertySet> copyPropertiesInSet(const Vector<CSSPropertyID>&) const;

private:
    CSSComputedStyleDeclaration(PassRefPtr<Node>, bool allowVisitedStyle);

    // CSSOM functions. Don't make these public.
    virtual unsigned length() const override;
    virtual String item(unsigned index) const override;
    PassRefPtr<RenderStyle> computeRenderStyle(CSSPropertyID) const;
    virtual PassRefPtr<CSSValue> getPropertyCSSValue(const String& propertyName) override;
    virtual String getPropertyValue(const String& propertyName) override;
    virtual String getPropertyShorthand(const String& propertyName) override;
    virtual bool isPropertyImplicit(const String& propertyName) override;
    virtual void setProperty(const String& propertyName, const String& value, const String& priority, ExceptionState&) override;
    virtual String removeProperty(const String& propertyName, ExceptionState&) override;
    virtual String cssText() const override;
    virtual void setCSSText(const String&, ExceptionState&) override;
    virtual PassRefPtr<CSSValue> getPropertyCSSValueInternal(CSSPropertyID) override;
    virtual String getPropertyValueInternal(CSSPropertyID) override;
    virtual void setPropertyInternal(CSSPropertyID, const String& value, ExceptionState&) override;

    virtual bool cssPropertyMatches(CSSPropertyID, const CSSValue*) const override;

    PassRefPtr<CSSValue> valueForShadowData(const ShadowData&, const RenderStyle&, bool useSpread) const;
    PassRefPtr<CSSValue> valueForShadowList(const ShadowList*, const RenderStyle&, bool useSpread) const;
    PassRefPtr<CSSPrimitiveValue> currentColorOrValidColor(const RenderStyle&, const StyleColor&) const;

    PassRefPtr<CSSValue> valueForFilter(const RenderObject*, const RenderStyle&) const;

    PassRefPtr<CSSValueList> valuesForShorthandProperty(const StylePropertyShorthand&) const;
    PassRefPtr<CSSValueList> valuesForSidesShorthand(const StylePropertyShorthand&) const;
    PassRefPtr<CSSValueList> valuesForBackgroundShorthand() const;

    RefPtr<Node> m_node;
    bool m_allowVisitedStyle;
#if !ENABLE(OILPAN)
    unsigned m_refCount;
#endif
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_CSSCOMPUTEDSTYLEDECLARATION_H_
