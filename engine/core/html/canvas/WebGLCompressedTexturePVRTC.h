/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_HTML_CANVAS_WEBGLCOMPRESSEDTEXTUREPVRTC_H_
#define SKY_ENGINE_CORE_HTML_CANVAS_WEBGLCOMPRESSEDTEXTUREPVRTC_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/core/html/canvas/WebGLExtension.h"
#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {

class WebGLCompressedTexturePVRTC final : public WebGLExtension, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<WebGLCompressedTexturePVRTC> create(WebGLRenderingContextBase*);
    static bool supported(WebGLRenderingContextBase*);
    static const char* extensionName();

    virtual ~WebGLCompressedTexturePVRTC();
    virtual WebGLExtensionName name() const override;

private:
    explicit WebGLCompressedTexturePVRTC(WebGLRenderingContextBase*);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_CANVAS_WEBGLCOMPRESSEDTEXTUREPVRTC_H_
