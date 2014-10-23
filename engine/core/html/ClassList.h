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

#ifndef ClassList_h
#define ClassList_h

#include "core/HTMLNames.h"
#include "core/dom/DOMTokenList.h"
#include "core/dom/Element.h"
#include "core/dom/SpaceSplitString.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class Element;

typedef int ExceptionCode;

class ClassList FINAL : public DOMTokenList {
public:
    static PassOwnPtrWillBeRawPtr<ClassList> create(Element* element)
    {
        return adoptPtrWillBeNoop(new ClassList(element));
    }

#if !ENABLE(OILPAN)
    virtual void ref() OVERRIDE;
    virtual void deref() OVERRIDE;
#endif

    virtual unsigned length() const OVERRIDE;
    virtual const AtomicString item(unsigned index) const OVERRIDE;

    virtual Element* element() OVERRIDE { return m_element; }

    virtual void trace(Visitor*) OVERRIDE;

private:
    explicit ClassList(Element*);

    virtual bool containsInternal(const AtomicString&) const OVERRIDE;

    const SpaceSplitString& classNames() const;

    virtual const AtomicString& value() const OVERRIDE { return m_element->getAttribute(HTMLNames::classAttr); }
    virtual void setValue(const AtomicString& value) OVERRIDE { m_element->setAttribute(HTMLNames::classAttr, value); }

    RawPtrWillBeMember<Element> m_element;
};

} // namespace blink

#endif // ClassList_h
