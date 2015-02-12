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

#ifndef SKY_ENGINE_CORE_DOM_DOMTOKENLIST_H_
#define SKY_ENGINE_CORE_DOM_DOMTOKENLIST_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

class Element;
class ExceptionState;
class SpaceSplitString;

class DOMTokenList final : public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
    WTF_MAKE_FAST_ALLOCATED;
    WTF_MAKE_NONCOPYABLE(DOMTokenList);
public:
    static PassOwnPtr<DOMTokenList> create(Element& element)
    {
        return adoptPtr(new DOMTokenList(element));
    }

    ~DOMTokenList() { }

    void ref();
    void deref();

    unsigned length() const;
    const AtomicString item(unsigned index) const;

    bool contains(const AtomicString&, ExceptionState&) const;
    void add(const Vector<String>&, ExceptionState&);
    void add(const AtomicString&, ExceptionState&);
    void remove(const Vector<String>&, ExceptionState&);
    void remove(const AtomicString&, ExceptionState&);
    bool toggle(const AtomicString&, ExceptionState&);
    bool toggle(const AtomicString&, bool force, ExceptionState&);
    void clear();

    const AtomicString& toString() const { return value(); }

    Element* element() { return m_element.get(); }

    const AtomicString& value() const;
    void setValue(const AtomicString& value);

private:
    DOMTokenList(Element&);

    const SpaceSplitString& classNames() const;

    void addInternal(const AtomicString&);
    bool containsInternal(const AtomicString&) const;
    void removeInternal(const AtomicString&);

    static bool validateToken(const String&, ExceptionState&);
    static bool validateTokens(const Vector<String>&, ExceptionState&);
    static AtomicString addToken(const AtomicString&, const AtomicString&);
    static AtomicString addTokens(const AtomicString&, const Vector<String>&);
    static AtomicString removeToken(const AtomicString&, const AtomicString&);
    static AtomicString removeTokens(const AtomicString&, const Vector<String>&);

    RawPtr<Element> m_element;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_DOMTOKENLIST_H_
