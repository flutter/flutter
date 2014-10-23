/*
 * Copyright (C) 2011, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Samsung Electronics. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SelectorQuery_h
#define SelectorQuery_h

#include "core/css/CSSSelectorList.h"
#include "platform/heap/Handle.h"
#include "wtf/HashMap.h"
#include "wtf/Vector.h"
#include "wtf/text/AtomicStringHash.h"

namespace blink {

class CSSSelector;
class ContainerNode;
class Document;
class Element;
class ExceptionState;
template <typename NodeType> class StaticNodeTypeList;
typedef StaticNodeTypeList<Element> StaticElementList;

class SelectorQuery {
    WTF_MAKE_NONCOPYABLE(SelectorQuery);
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<SelectorQuery> adopt(CSSSelectorList&);

    bool matches(Element&) const;
    PassRefPtrWillBeRawPtr<StaticElementList> queryAll(ContainerNode& rootNode) const;
    PassRefPtrWillBeRawPtr<Element> queryFirst(ContainerNode& rootNode) const;
private:
    explicit SelectorQuery(CSSSelectorList&);
    bool selectorMatches(ContainerNode& rootNode, Element& subject) const;

    CSSSelectorList m_selectors;
};

class SelectorQueryCache {
    WTF_MAKE_FAST_ALLOCATED;
public:
    SelectorQuery* add(const AtomicString&, const Document&, ExceptionState&);

private:
    HashMap<AtomicString, OwnPtr<SelectorQuery> > m_entries;
};

}

#endif
