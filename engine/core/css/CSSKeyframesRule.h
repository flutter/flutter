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

#ifndef CSSKeyframesRule_h
#define CSSKeyframesRule_h

#include "core/css/CSSRule.h"
#include "core/css/StyleRule.h"
#include "wtf/Forward.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class CSSRuleList;
class StyleKeyframe;
class CSSKeyframeRule;

class StyleRuleKeyframes final : public StyleRuleBase {
public:
    static PassRefPtrWillBeRawPtr<StyleRuleKeyframes> create() { return adoptRefWillBeNoop(new StyleRuleKeyframes()); }

    ~StyleRuleKeyframes();

    const WillBeHeapVector<RefPtrWillBeMember<StyleKeyframe> >& keyframes() const { return m_keyframes; }

    void parserAppendKeyframe(PassRefPtrWillBeRawPtr<StyleKeyframe>);
    void wrapperAppendKeyframe(PassRefPtrWillBeRawPtr<StyleKeyframe>);
    void wrapperRemoveKeyframe(unsigned);

    String name() const { return m_name; }
    void setName(const String& name) { m_name = AtomicString(name); }

    bool isVendorPrefixed() const { return m_isPrefixed; }
    void setVendorPrefixed(bool isPrefixed) { m_isPrefixed = isPrefixed; }

    int findKeyframeIndex(const String& key) const;

    PassRefPtrWillBeRawPtr<StyleRuleKeyframes> copy() const { return adoptRefWillBeNoop(new StyleRuleKeyframes(*this)); }

    void traceAfterDispatch(Visitor*);

private:
    StyleRuleKeyframes();
    explicit StyleRuleKeyframes(const StyleRuleKeyframes&);

    WillBeHeapVector<RefPtrWillBeMember<StyleKeyframe> > m_keyframes;
    AtomicString m_name;
    bool m_isPrefixed;
};

DEFINE_STYLE_RULE_TYPE_CASTS(Keyframes);

class CSSKeyframesRule final : public CSSRule {
public:
    static PassRefPtrWillBeRawPtr<CSSKeyframesRule> create(StyleRuleKeyframes* rule, CSSStyleSheet* sheet)
    {
        return adoptRefWillBeNoop(new CSSKeyframesRule(rule, sheet));
    }

    virtual ~CSSKeyframesRule();

    virtual CSSRule::Type type() const override { return KEYFRAMES_RULE; }
    virtual String cssText() const override;
    virtual void reattach(StyleRuleBase*) override;

    String name() const { return m_keyframesRule->name(); }
    void setName(const String&);

    CSSRuleList* cssRules();

    void insertRule(const String& rule);
    void deleteRule(const String& key);
    CSSKeyframeRule* findRule(const String& key);

    // For IndexedGetter and CSSRuleList.
    unsigned length() const;
    CSSKeyframeRule* item(unsigned index) const;

    bool isVendorPrefixed() const { return m_isPrefixed; }
    void setVendorPrefixed(bool isPrefixed) { m_isPrefixed = isPrefixed; }

    virtual void trace(Visitor*) override;

private:
    CSSKeyframesRule(StyleRuleKeyframes*, CSSStyleSheet* parent);

    RefPtrWillBeMember<StyleRuleKeyframes> m_keyframesRule;
    mutable WillBeHeapVector<RefPtrWillBeMember<CSSKeyframeRule> > m_childRuleCSSOMWrappers;
    mutable OwnPtrWillBeMember<CSSRuleList> m_ruleListCSSOMWrapper;
    bool m_isPrefixed;
};

DEFINE_CSS_RULE_TYPE_CASTS(CSSKeyframesRule, KEYFRAMES_RULE);

} // namespace blink

#endif // CSSKeyframesRule_h
