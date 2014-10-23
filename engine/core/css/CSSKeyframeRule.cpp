/*
 * Copyright (C) 2007, 2008, 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
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

#include "config.h"
#include "core/css/CSSKeyframeRule.h"

#include "core/css/CSSKeyframesRule.h"
#include "core/css/parser/BisonCSSParser.h"
#include "core/css/PropertySetCSSStyleDeclaration.h"
#include "core/css/StylePropertySet.h"
#include "core/frame/UseCounter.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

StyleKeyframe::StyleKeyframe()
{
}

StyleKeyframe::~StyleKeyframe()
{
}

String StyleKeyframe::keyText() const
{
    if (m_keyText.isNull()) {
        // Keys are always set when these objects are created.
        ASSERT(m_keys && !m_keys->isEmpty());
        StringBuilder keyText;
        for (unsigned i = 0; i < m_keys->size(); ++i) {
            if (i)
                keyText.append(',');
            keyText.append(String::number(m_keys->at(i) * 100));
            keyText.append('%');
        }
        m_keyText = keyText.toString();
    }
    ASSERT(!m_keyText.isNull());
    return m_keyText;
}

void StyleKeyframe::setKeyText(const String& keyText)
{
    // FIXME: Should we trim whitespace?
    // FIXME: Should we leave keyText unchanged when attempting to set to an
    // invalid string?
    ASSERT(!keyText.isNull());
    m_keyText = keyText;
    m_keys.clear();
}

const Vector<double>& StyleKeyframe::keys() const
{
    if (!m_keys) {
        // Keys can only be cleared by setting the key text from JavaScript
        // and this can never be null.
        ASSERT(!m_keyText.isNull());
        m_keys = BisonCSSParser(strictCSSParserContext()).parseKeyframeKeyList(m_keyText);
    }
    // If an invalid key string was set, m_keys may be empty.
    ASSERT(m_keys);
    return *m_keys;
}

void StyleKeyframe::setKeys(PassOwnPtr<Vector<double> > keys)
{
    ASSERT(keys && !keys->isEmpty());
    m_keys = keys;
    m_keyText = String();
    ASSERT(m_keyText.isNull());
}

MutableStylePropertySet& StyleKeyframe::mutableProperties()
{
    if (!m_properties->isMutable())
        m_properties = m_properties->mutableCopy();
    return *toMutableStylePropertySet(m_properties.get());
}

void StyleKeyframe::setProperties(PassRefPtrWillBeRawPtr<StylePropertySet> properties)
{
    ASSERT(properties);
    m_properties = properties;
}

String StyleKeyframe::cssText() const
{
    StringBuilder result;
    result.append(keyText());
    result.appendLiteral(" { ");
    String decls = m_properties->asText();
    result.append(decls);
    if (!decls.isEmpty())
        result.append(' ');
    result.append('}');
    return result.toString();
}

PassOwnPtr<Vector<double> > StyleKeyframe::createKeyList(CSSParserValueList* keys)
{
    OwnPtr<Vector<double> > keyVector = adoptPtr(new Vector<double>(keys->size()));
    for (unsigned i = 0; i < keys->size(); ++i) {
        ASSERT(keys->valueAt(i)->unit == blink::CSSPrimitiveValue::CSS_NUMBER);
        double key = keys->valueAt(i)->fValue;
        if (key < 0 || key > 100) {
            // As per http://www.w3.org/TR/css3-animations/#keyframes,
            // "If a keyframe selector specifies negative percentage values
            // or values higher than 100%, then the keyframe will be ignored."
            keyVector->clear();
            break;
        }
        keyVector->at(i) = key / 100;
    }
    return keyVector.release();
}

void StyleKeyframe::trace(Visitor* visitor)
{
    visitor->trace(m_properties);
}

CSSKeyframeRule::CSSKeyframeRule(StyleKeyframe* keyframe, CSSKeyframesRule* parent)
    : CSSRule(0)
    , m_keyframe(keyframe)
{
    setParentRule(parent);
}

CSSKeyframeRule::~CSSKeyframeRule()
{
#if !ENABLE(OILPAN)
    if (m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper->clearParentRule();
#endif
}

CSSStyleDeclaration* CSSKeyframeRule::style() const
{
    if (!m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper = StyleRuleCSSStyleDeclaration::create(m_keyframe->mutableProperties(), const_cast<CSSKeyframeRule*>(this));
    return m_propertiesCSSOMWrapper.get();
}

void CSSKeyframeRule::reattach(StyleRuleBase*)
{
    // No need to reattach, the underlying data is shareable on mutation.
    ASSERT_NOT_REACHED();
}

void CSSKeyframeRule::trace(Visitor* visitor)
{
    visitor->trace(m_keyframe);
    visitor->trace(m_propertiesCSSOMWrapper);
    CSSRule::trace(visitor);
}

} // namespace blink
