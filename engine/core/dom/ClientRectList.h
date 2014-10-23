/*
 * Copyright (C) 2009 Apple Inc. All Rights Reserved.
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
 *
 */

#ifndef ClientRectList_h
#define ClientRectList_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "platform/geometry/FloatQuad.h"
#include "platform/heap/Handle.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/Vector.h"

namespace blink {

class ClientRect;

class ClientRectList FINAL : public RefCountedWillBeGarbageCollected<ClientRectList>, public ScriptWrappable {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ClientRectList);
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<ClientRectList> create()
    {
        return adoptRefWillBeNoop(new ClientRectList);
    }
    static PassRefPtrWillBeRawPtr<ClientRectList> create(const Vector<FloatQuad>& quads)
    {
        return adoptRefWillBeNoop(new ClientRectList(quads));
    }
    unsigned length() const;
    ClientRect* item(unsigned index);

    void trace(Visitor*);

private:
    ClientRectList();
    explicit ClientRectList(const Vector<FloatQuad>&);

    WillBeHeapVector<RefPtrWillBeMember<ClientRect> > m_list;
};

} // namespace blink

#endif // ClientRectList_h
