/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef HTMLContentElement_h
#define HTMLContentElement_h

#include "core/css/CSSSelectorList.h"
#include "core/dom/shadow/InsertionPoint.h"

namespace blink {

class HTMLContentElement FINAL : public InsertionPoint {
    DEFINE_WRAPPERTYPEINFO();
public:
    DECLARE_NODE_FACTORY(HTMLContentElement);
    virtual ~HTMLContentElement();

    virtual bool canAffectSelector() const OVERRIDE { return true; }

    bool canSelectNode(const WillBeHeapVector<RawPtrWillBeMember<Node>, 32>& siblings, int nth) const;

    const CSSSelectorList& selectorList() const;
    bool isSelectValid() const;

private:
    explicit HTMLContentElement(Document&);

    virtual void parseAttribute(const QualifiedName&, const AtomicString&) OVERRIDE;

    bool validateSelect() const;
    void parseSelect();

    bool matchSelector(const WillBeHeapVector<RawPtrWillBeMember<Node>, 32>& siblings, int nth) const;

    bool m_shouldParseSelect;
    bool m_isValidSelector;
    AtomicString m_select;
    CSSSelectorList m_selectorList;
};

inline const CSSSelectorList& HTMLContentElement::selectorList() const
{
    if (m_shouldParseSelect)
        const_cast<HTMLContentElement*>(this)->parseSelect();
    return m_selectorList;
}

inline bool HTMLContentElement::isSelectValid() const
{
    if (m_shouldParseSelect)
        const_cast<HTMLContentElement*>(this)->parseSelect();
    return m_isValidSelector;
}

inline bool HTMLContentElement::canSelectNode(const WillBeHeapVector<RawPtrWillBeMember<Node>, 32>& siblings, int nth) const
{
    if (m_select.isNull() || m_select.isEmpty())
        return true;
    if (!isSelectValid())
        return false;
    if (!siblings[nth]->isElementNode())
        return false;
    return matchSelector(siblings, nth);
}

} // namespace blink

#endif // HTMLContentElement_h
