/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#include "core/html/canvas/WebGLCompressedTextureS3TC.h"

#include "core/html/canvas/WebGLRenderingContextBase.h"

namespace blink {

WebGLCompressedTextureS3TC::WebGLCompressedTextureS3TC(WebGLRenderingContextBase* context)
    : WebGLExtension(context)
{
    ScriptWrappable::init(this);
    context->addCompressedTextureFormat(GL_COMPRESSED_RGB_S3TC_DXT1_EXT);
    context->addCompressedTextureFormat(GL_COMPRESSED_RGBA_S3TC_DXT1_EXT);
    context->addCompressedTextureFormat(GL_COMPRESSED_RGBA_S3TC_DXT3_EXT);
    context->addCompressedTextureFormat(GL_COMPRESSED_RGBA_S3TC_DXT5_EXT);
}

WebGLCompressedTextureS3TC::~WebGLCompressedTextureS3TC()
{
}

WebGLExtensionName WebGLCompressedTextureS3TC::name() const
{
    return WebGLCompressedTextureS3TCName;
}

PassRefPtr<WebGLCompressedTextureS3TC> WebGLCompressedTextureS3TC::create(WebGLRenderingContextBase* context)
{
    return adoptRef(new WebGLCompressedTextureS3TC(context));
}

bool WebGLCompressedTextureS3TC::supported(WebGLRenderingContextBase* context)
{
    Extensions3DUtil* extensionsUtil = context->extensionsUtil();
    return extensionsUtil->supportsExtension("GL_EXT_texture_compression_s3tc")
        || (extensionsUtil->supportsExtension("GL_EXT_texture_compression_dxt1")
            && extensionsUtil->supportsExtension("GL_CHROMIUM_texture_compression_dxt3")
            && extensionsUtil->supportsExtension("GL_CHROMIUM_texture_compression_dxt5"));
}

const char* WebGLCompressedTextureS3TC::extensionName()
{
    return "WEBGL_compressed_texture_s3tc";
}

} // namespace blink
