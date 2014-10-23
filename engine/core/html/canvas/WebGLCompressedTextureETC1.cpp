// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"

#include "core/html/canvas/WebGLCompressedTextureETC1.h"

#include "core/html/canvas/WebGLRenderingContextBase.h"

namespace blink {

WebGLCompressedTextureETC1::WebGLCompressedTextureETC1(WebGLRenderingContextBase* context)
    : WebGLExtension(context)
{
    ScriptWrappable::init(this);
    context->addCompressedTextureFormat(GL_ETC1_RGB8_OES);
}

WebGLCompressedTextureETC1::~WebGLCompressedTextureETC1()
{
}

WebGLExtensionName WebGLCompressedTextureETC1::name() const
{
    return WebGLCompressedTextureETC1Name;
}

PassRefPtrWillBeRawPtr<WebGLCompressedTextureETC1> WebGLCompressedTextureETC1::create(WebGLRenderingContextBase* context)
{
    return adoptRefWillBeNoop(new WebGLCompressedTextureETC1(context));
}

bool WebGLCompressedTextureETC1::supported(WebGLRenderingContextBase* context)
{
    Extensions3DUtil* extensionsUtil = context->extensionsUtil();
    return extensionsUtil->supportsExtension("GL_OES_compressed_ETC1_RGB8_texture");
}

const char* WebGLCompressedTextureETC1::extensionName()
{
    return "WEBGL_compressed_texture_etc1";
}

} // namespace blink
