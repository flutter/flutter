/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_HTML_CLASSLIST_H_
#define SKY_ENGINE_CORE_HTML_CLASSLIST_H_

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/dom/DOMTokenList.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/SpaceSplitString.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

class Element;

typedef int ExceptionCode;

class ClassList final : public DOMTokenList {
public:
    static PassOwnPtr<ClassList> create(Element* element)
    {
        return adoptPtr(new ClassList(element));
    }

#if !ENABLE(OILPAN)
    virtual void ref() override;
    virtual void deref() override;
#endif

    virtual unsigned length() const override;
    virtual const AtomicString item(unsigned index) const override;

    virtual Element* element() override { return m_element; }

private:
    explicit ClassList(Element*);

    virtual bool containsInternal(const AtomicString&) const override;

    const SpaceSplitString& classNames() const;

    virtual const AtomicString& value() const override { return m_element->getAttribute(HTMLNames::classAttr); }
    virtual void setValue(const AtomicString& value) override { m_element->setAttribute(HTMLNames::classAttr, value); }

    RawPtr<Element> m_element;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_CLASSLIST_H_
