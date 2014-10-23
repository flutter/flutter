/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "core/html/canvas/WebGLDepthTexture.h"

namespace blink {

WebGLDepthTexture::WebGLDepthTexture(WebGLRenderingContextBase* context)
    : WebGLExtension(context)
{
    ScriptWrappable::init(this);
    context->extensionsUtil()->ensureExtensionEnabled("GL_CHROMIUM_depth_texture");
}

WebGLDepthTexture::~WebGLDepthTexture()
{
}

WebGLExtensionName WebGLDepthTexture::name() const
{
    return WebGLDepthTextureName;
}

PassRefPtrWillBeRawPtr<WebGLDepthTexture> WebGLDepthTexture::create(WebGLRenderingContextBase* context)
{
    return adoptRefWillBeNoop(new WebGLDepthTexture(context));
}

bool WebGLDepthTexture::supported(WebGLRenderingContextBase* context)
{
    Extensions3DUtil* extensionsUtil = context->extensionsUtil();
    // Emulating the UNSIGNED_INT_24_8_WEBGL texture internal format in terms
    // of two separate texture objects is too difficult, so disable depth
    // textures unless a packed depth/stencil format is available.
    if (!extensionsUtil->supportsExtension("GL_OES_packed_depth_stencil"))
        return false;
    return extensionsUtil->supportsExtension("GL_CHROMIUM_depth_texture")
        || extensionsUtil->supportsExtension("GL_OES_depth_texture")
        || extensionsUtil->supportsExtension("GL_ARB_depth_texture");
}

const char* WebGLDepthTexture::extensionName()
{
    return "WEBGL_depth_texture";
}

} // namespace blink
