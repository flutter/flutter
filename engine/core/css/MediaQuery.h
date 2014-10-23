/*
 * CSS Media Query
 *
 * Copyright (C) 2006 Kimmo Kinnunen <kimmo.t.kinnunen@nokia.com>.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
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

#ifndef MediaQuery_h
#define MediaQuery_h

#include "platform/heap/Handle.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/StringHash.h"
#include "wtf/text/WTFString.h"

namespace blink {
class MediaQueryExp;

typedef WillBeHeapVector<OwnPtrWillBeMember<MediaQueryExp> > ExpressionHeapVector;

class MediaQuery : public NoBaseWillBeGarbageCollectedFinalized<MediaQuery> {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    enum Restrictor {
        Only, Not, None
    };

    static PassOwnPtrWillBeRawPtr<MediaQuery> createNotAll();

    MediaQuery(Restrictor, const String& mediaType, PassOwnPtrWillBeRawPtr<ExpressionHeapVector> exprs);
    ~MediaQuery();

    Restrictor restrictor() const { return m_restrictor; }
    const ExpressionHeapVector& expressions() const { return *m_expressions; }
    const String& mediaType() const { return m_mediaType; }
    bool operator==(const MediaQuery& other) const;
    String cssText() const;

    PassOwnPtrWillBeRawPtr<MediaQuery> copy() const { return adoptPtrWillBeNoop(new MediaQuery(*this)); }

    void trace(Visitor*);

private:
    MediaQuery(const MediaQuery&);

    Restrictor m_restrictor;
    String m_mediaType;
    OwnPtrWillBeMember<ExpressionHeapVector> m_expressions;
    String m_serializationCache;

    String serialize() const;
};

} // namespace

#endif
