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

#ifndef CSSKeyframeRule_h
#define CSSKeyframeRule_h

#include "core/css/CSSRule.h"

namespace blink {

class CSSKeyframesRule;
class CSSParserValueList;
class CSSStyleDeclaration;
class MutableStylePropertySet;
class StylePropertySet;
class StyleRuleCSSStyleDeclaration;

class StyleKeyframe FINAL : public RefCountedWillBeGarbageCollectedFinalized<StyleKeyframe> {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    static PassRefPtrWillBeRawPtr<StyleKeyframe> create()
    {
        return adoptRefWillBeNoop(new StyleKeyframe());
    }
    ~StyleKeyframe();

    // Exposed to JavaScript.
    String keyText() const;
    void setKeyText(const String&);

    // Used by StyleResolver.
    const Vector<double>& keys() const;
    // Used by BisonCSSParser when constructing a new StyleKeyframe.
    void setKeys(PassOwnPtr<Vector<double> >);

    const StylePropertySet& properties() const { return *m_properties; }
    MutableStylePropertySet& mutableProperties();
    void setProperties(PassRefPtrWillBeRawPtr<StylePropertySet>);

    String cssText() const;

    void trace(Visitor*);

    static PassOwnPtr<Vector<double> > createKeyList(CSSParserValueList*);

private:
    StyleKeyframe();

    RefPtrWillBeMember<StylePropertySet> m_properties;
    // These are both calculated lazily. Either one can be set, which invalidates the other.
    mutable String m_keyText;
    mutable OwnPtr<Vector<double> > m_keys;
};

class CSSKeyframeRule FINAL : public CSSRule {
public:
    virtual ~CSSKeyframeRule();

    virtual CSSRule::Type type() const OVERRIDE { return KEYFRAME_RULE; }
    virtual String cssText() const OVERRIDE { return m_keyframe->cssText(); }
    virtual void reattach(StyleRuleBase*) OVERRIDE;

    String keyText() const { return m_keyframe->keyText(); }
    void setKeyText(const String& s) { m_keyframe->setKeyText(s); }

    CSSStyleDeclaration* style() const;

    virtual void trace(Visitor*) OVERRIDE;

private:
    CSSKeyframeRule(StyleKeyframe*, CSSKeyframesRule* parent);

    RefPtrWillBeMember<StyleKeyframe> m_keyframe;
    mutable RefPtrWillBeMember<StyleRuleCSSStyleDeclaration> m_propertiesCSSOMWrapper;

    friend class CSSKeyframesRule;
};

DEFINE_CSS_RULE_TYPE_CASTS(CSSKeyframeRule, KEYFRAME_RULE);

} // namespace blink

#endif // CSSKeyframeRule_h
