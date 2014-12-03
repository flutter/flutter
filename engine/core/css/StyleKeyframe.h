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

#ifndef SKY_ENGINE_CORE_CSS_STYLEKEYFRAME_H_
#define SKY_ENGINE_CORE_CSS_STYLEKEYFRAME_H_

#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class CSSKeyframesRule;
class CSSParserValueList;
class MutableStylePropertySet;
class StylePropertySet;

class StyleKeyframe final : public RefCounted<StyleKeyframe> {
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassRefPtr<StyleKeyframe> create()
    {
        return adoptRef(new StyleKeyframe());
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
    void setProperties(PassRefPtr<StylePropertySet>);

    String cssText() const;

    static PassOwnPtr<Vector<double> > createKeyList(CSSParserValueList*);

private:
    StyleKeyframe();

    RefPtr<StylePropertySet> m_properties;
    // These are both calculated lazily. Either one can be set, which invalidates the other.
    mutable String m_keyText;
    mutable OwnPtr<Vector<double> > m_keys;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_STYLEKEYFRAME_H_
