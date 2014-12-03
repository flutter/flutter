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

#ifndef SKY_ENGINE_CORE_CSS_STYLERULEKEYFRAMES_H_
#define SKY_ENGINE_CORE_CSS_STYLERULEKEYFRAMES_H_

#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

class StyleKeyframe;

class StyleRuleKeyframes final : public StyleRuleBase {
public:
    static PassRefPtr<StyleRuleKeyframes> create() { return adoptRef(new StyleRuleKeyframes()); }

    ~StyleRuleKeyframes();

    const Vector<RefPtr<StyleKeyframe> >& keyframes() const { return m_keyframes; }

    void parserAppendKeyframe(PassRefPtr<StyleKeyframe>);
    void wrapperAppendKeyframe(PassRefPtr<StyleKeyframe>);
    void wrapperRemoveKeyframe(unsigned);

    String name() const { return m_name; }
    void setName(const String& name) { m_name = AtomicString(name); }

    bool isVendorPrefixed() const { return m_isPrefixed; }
    void setVendorPrefixed(bool isPrefixed) { m_isPrefixed = isPrefixed; }

    int findKeyframeIndex(const String& key) const;

    PassRefPtr<StyleRuleKeyframes> copy() const { return adoptRef(new StyleRuleKeyframes(*this)); }

private:
    StyleRuleKeyframes();
    explicit StyleRuleKeyframes(const StyleRuleKeyframes&);

    Vector<RefPtr<StyleKeyframe> > m_keyframes;
    AtomicString m_name;
    bool m_isPrefixed;
};

DEFINE_STYLE_RULE_TYPE_CASTS(Keyframes);

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_STYLERULEKEYFRAMES_H_
