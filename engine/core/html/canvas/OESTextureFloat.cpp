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

#include "core/html/canvas/OESTextureFloat.h"

namespace blink {

OESTextureFloat::OESTextureFloat(WebGLRenderingContextBase* context)
    : WebGLExtension(context)
{
    ScriptWrappable::init(this);
    if (context->extensionsUtil()->ensureExtensionEnabled("GL_OES_texture_float")) {
        // Implicitly enable rendering to float textures
        context->extensionsUtil()->ensureExtensionEnabled("GL_CHROMIUM_color_buffer_float_rgba");
        context->extensionsUtil()->ensureExtensionEnabled("GL_CHROMIUM_color_buffer_float_rgb");
    }
}

OESTextureFloat::~OESTextureFloat()
{
}

WebGLExtensionName OESTextureFloat::name() const
{
    return OESTextureFloatName;
}

PassRefPtr<OESTextureFloat> OESTextureFloat::create(WebGLRenderingContextBase* context)
{
    return adoptRef(new OESTextureFloat(context));
}

bool OESTextureFloat::supported(WebGLRenderingContextBase* context)
{
    return context->extensionsUtil()->supportsExtension("GL_OES_texture_float");
}

const char* OESTextureFloat::extensionName()
{
    return "OES_texture_float";
}

} // namespace blink
