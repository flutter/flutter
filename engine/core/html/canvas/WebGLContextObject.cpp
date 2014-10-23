/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

#include "config.h"

#include "core/html/canvas/WebGLContextObject.h"

#include "core/html/canvas/WebGLRenderingContextBase.h"
#include "core/html/canvas/WebGLSharedWebGraphicsContext3D.h"

namespace blink {

WebGLContextObject::WebGLContextObject(WebGLRenderingContextBase* context)
    : WebGLObject(context)
    , m_context(context)
#if ENABLE(OILPAN)
    , m_sharedWebGraphicsContext3D(context->sharedWebGraphicsContext3D())
#endif
{
}

WebGLContextObject::~WebGLContextObject()
{
#if !ENABLE(OILPAN)
    if (m_context)
        m_context->removeContextObject(this);
#endif
}

void WebGLContextObject::detachContext()
{
    detach();
    if (m_context) {
        deleteObject(m_context->webContext());
        m_context->removeContextObject(this);
        m_context = nullptr;
#if ENABLE(OILPAN)
        m_sharedWebGraphicsContext3D.clear();
#endif
    }
}

blink::WebGraphicsContext3D* WebGLContextObject::getAWebGraphicsContext3D() const
{
#if ENABLE(OILPAN)
    return m_sharedWebGraphicsContext3D ? m_sharedWebGraphicsContext3D->webContext() : 0;
#else
    return m_context ? m_context->webContext() : 0;
#endif
}

void WebGLContextObject::trace(Visitor* visitor)
{
    visitor->trace(m_context);
    WebGLObject::trace(visitor);
}

}
