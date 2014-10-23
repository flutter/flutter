/*
 * Copyright (C) 2009 Apple Inc.  All rights reserved.
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

#ifndef RenderObjectChildList_h
#define RenderObjectChildList_h

#include "platform/heap/Handle.h"
#include "wtf/Forward.h"

namespace blink {

class RenderObject;

class RenderObjectChildList {
    DISALLOW_ALLOCATION();
public:
    RenderObjectChildList()
        : m_firstChild(nullptr)
        , m_lastChild(nullptr)
    {
    }
    void trace(Visitor*);

    RenderObject* firstChild() const { return m_firstChild.get(); }
    RenderObject* lastChild() const { return m_lastChild.get(); }

    // FIXME: Temporary while RenderBox still exists. Eventually this will just happen during insert/append/remove methods on the child list, and nobody
    // will need to manipulate firstChild or lastChild directly.
    void setFirstChild(RenderObject* child) { m_firstChild = child; }
    void setLastChild(RenderObject* child) { m_lastChild = child; }

    void destroyLeftoverChildren();

    RenderObject* removeChildNode(RenderObject* owner, RenderObject*, bool notifyRenderer = true);
    void insertChildNode(RenderObject* owner, RenderObject* newChild, RenderObject* beforeChild, bool notifyRenderer = true);
    void appendChildNode(RenderObject* owner, RenderObject* newChild, bool notifyRenderer = true)
    {
        insertChildNode(owner, newChild, 0, notifyRenderer);
    }

private:
    RawPtrWillBeMember<RenderObject> m_firstChild;
    RawPtrWillBeMember<RenderObject> m_lastChild;
};

} // namespace blink

#endif // RenderObjectChildList_h
