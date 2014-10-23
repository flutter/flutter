/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef WebGLExtension_h
#define WebGLExtension_h

#include "core/html/canvas/WebGLExtensionName.h"
#include "core/html/canvas/WebGLRenderingContextBase.h"
#include "platform/heap/Handle.h"
#include "wtf/RefCounted.h"

namespace blink {

class WebGLExtension : public RefCountedWillBeGarbageCollectedFinalized<WebGLExtension> {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    WebGLRenderingContextBase* context() { return m_context; }

    virtual ~WebGLExtension();
    virtual WebGLExtensionName name() const = 0;

    // Lose this extension. Passing true = force loss. Some extensions
    // like WEBGL_lose_context are not normally lost when the context
    // is lost but must be lost when destroying their WebGLRenderingContextBase.
    virtual void lose(bool)
    {
        m_context = nullptr;
    }

    bool isLost()
    {
        return !m_context;
    }

    virtual void trace(Visitor*);

protected:
    explicit WebGLExtension(WebGLRenderingContextBase*);

    RawPtrWillBeWeakMember<WebGLRenderingContextBase> m_context;
};

} // namespace blink

#endif // WebGLExtension_h
