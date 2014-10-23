/*
 * Copyright (C) 2012 Intel Corporation. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef ViewportStyleResolver_h
#define ViewportStyleResolver_h

#include "core/CSSPropertyNames.h"
#include "core/css/RuleSet.h"
#include "platform/Length.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"

namespace blink {

class Document;
class MutableStylePropertySet;
class StyleRuleViewport;

class ViewportStyleResolver : public NoBaseWillBeGarbageCollected<ViewportStyleResolver> {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ViewportStyleResolver);
public:
    static PassOwnPtrWillBeRawPtr<ViewportStyleResolver> create(Document* document)
    {
        return adoptPtrWillBeNoop(new ViewportStyleResolver(document));
    }

    enum Origin { UserAgentOrigin, AuthorOrigin };

    void collectViewportRules(RuleSet*, Origin);

    void resolve();

    void trace(Visitor*);

private:
    explicit ViewportStyleResolver(Document*);

    void addViewportRule(StyleRuleViewport*, Origin);

    float viewportArgumentValue(CSSPropertyID) const;
    Length viewportLengthValue(CSSPropertyID) const;

    RawPtrWillBeMember<Document> m_document;
    RefPtrWillBeMember<MutableStylePropertySet> m_propertySet;
    bool m_hasAuthorStyle;
};

} // namespace blink

#endif // ViewportStyleResolver_h
