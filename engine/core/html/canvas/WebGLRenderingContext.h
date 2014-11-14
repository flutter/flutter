/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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

#ifndef WebGLRenderingContext_h
#define WebGLRenderingContext_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/html/canvas/WebGLRenderingContextBase.h"

namespace blink {

class WebGLRenderingContext final : public WebGLRenderingContextBase, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassOwnPtr<WebGLRenderingContext> create(HTMLCanvasElement*, WebGLContextAttributes*);
    virtual ~WebGLRenderingContext();

    virtual unsigned version() const override { return 1; }
    virtual String contextName() const override { return "WebGLRenderingContext"; }
    virtual void registerContextExtensions() override;

private:
    WebGLRenderingContext(HTMLCanvasElement*, PassOwnPtr<blink::WebGraphicsContext3D>, WebGLContextAttributes*);

    // Enabled extension objects.
    RefPtr<ANGLEInstancedArrays> m_angleInstancedArrays;
    RefPtr<EXTBlendMinMax> m_extBlendMinMax;
    RefPtr<EXTFragDepth> m_extFragDepth;
    RefPtr<EXTShaderTextureLOD> m_extShaderTextureLOD;
    RefPtr<EXTTextureFilterAnisotropic> m_extTextureFilterAnisotropic;
    RefPtr<OESTextureFloat> m_oesTextureFloat;
    RefPtr<OESTextureFloatLinear> m_oesTextureFloatLinear;
    RefPtr<OESTextureHalfFloat> m_oesTextureHalfFloat;
    RefPtr<OESTextureHalfFloatLinear> m_oesTextureHalfFloatLinear;
    RefPtr<OESStandardDerivatives> m_oesStandardDerivatives;
    RefPtr<OESVertexArrayObject> m_oesVertexArrayObject;
    RefPtr<OESElementIndexUint> m_oesElementIndexUint;
    RefPtr<WebGLLoseContext> m_webglLoseContext;
    RefPtr<WebGLDebugRendererInfo> m_webglDebugRendererInfo;
    RefPtr<WebGLDebugShaders> m_webglDebugShaders;
    RefPtr<WebGLDrawBuffers> m_webglDrawBuffers;
    RefPtr<WebGLCompressedTextureATC> m_webglCompressedTextureATC;
    RefPtr<WebGLCompressedTextureETC1> m_webglCompressedTextureETC1;
    RefPtr<WebGLCompressedTexturePVRTC> m_webglCompressedTexturePVRTC;
    RefPtr<WebGLCompressedTextureS3TC> m_webglCompressedTextureS3TC;
    RefPtr<WebGLDepthTexture> m_webglDepthTexture;
};

DEFINE_TYPE_CASTS(WebGLRenderingContext, CanvasRenderingContext, context,
    context->is3d() && WebGLRenderingContextBase::getWebGLVersion(context) == 1,
    context.is3d() && WebGLRenderingContextBase::getWebGLVersion(&context) == 1);

} // namespace blink

#endif // WebGLRenderingContext_h
