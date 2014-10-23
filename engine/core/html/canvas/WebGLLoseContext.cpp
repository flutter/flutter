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

#include "config.h"

#include "core/html/canvas/WebGLLoseContext.h"

#include "core/html/canvas/WebGLRenderingContextBase.h"

namespace blink {

WebGLLoseContext::WebGLLoseContext(WebGLRenderingContextBase* context)
    : WebGLExtension(context)
{
    ScriptWrappable::init(this);
}

WebGLLoseContext::~WebGLLoseContext()
{
}

void WebGLLoseContext::lose(bool force)
{
    if (force)
        WebGLExtension::lose(true);
}

WebGLExtensionName WebGLLoseContext::name() const
{
    return WebGLLoseContextName;
}

PassRefPtrWillBeRawPtr<WebGLLoseContext> WebGLLoseContext::create(WebGLRenderingContextBase* context)
{
    return adoptRefWillBeNoop(new WebGLLoseContext(context));
}

void WebGLLoseContext::loseContext()
{
    if (!isLost())
        m_context->forceLostContext(WebGLRenderingContextBase::WebGLLoseContextLostContext, WebGLRenderingContextBase::Manual);
}

void WebGLLoseContext::restoreContext()
{
    if (!isLost())
        m_context->forceRestoreContext();
}

bool WebGLLoseContext::supported(WebGLRenderingContextBase*)
{
    return true;
}

const char* WebGLLoseContext::extensionName()
{
    return "WEBGL_lose_context";
}

} // namespace blink
