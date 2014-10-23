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

class WebGLRenderingContext FINAL : public WebGLRenderingContextBase, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassOwnPtrWillBeRawPtr<WebGLRenderingContext> create(HTMLCanvasElement*, WebGLContextAttributes*);
    virtual ~WebGLRenderingContext();

    virtual unsigned version() const OVERRIDE { return 1; }
    virtual String contextName() const OVERRIDE { return "WebGLRenderingContext"; }
    virtual void registerContextExtensions() OVERRIDE;

    virtual void trace(Visitor*) OVERRIDE;

private:
    WebGLRenderingContext(HTMLCanvasElement*, PassOwnPtr<blink::WebGraphicsContext3D>, WebGLContextAttributes*);

    // Enabled extension objects.
    RefPtrWillBeMember<ANGLEInstancedArrays> m_angleInstancedArrays;
    RefPtrWillBeMember<EXTBlendMinMax> m_extBlendMinMax;
    RefPtrWillBeMember<EXTFragDepth> m_extFragDepth;
    RefPtrWillBeMember<EXTShaderTextureLOD> m_extShaderTextureLOD;
    RefPtrWillBeMember<EXTTextureFilterAnisotropic> m_extTextureFilterAnisotropic;
    RefPtrWillBeMember<OESTextureFloat> m_oesTextureFloat;
    RefPtrWillBeMember<OESTextureFloatLinear> m_oesTextureFloatLinear;
    RefPtrWillBeMember<OESTextureHalfFloat> m_oesTextureHalfFloat;
    RefPtrWillBeMember<OESTextureHalfFloatLinear> m_oesTextureHalfFloatLinear;
    RefPtrWillBeMember<OESStandardDerivatives> m_oesStandardDerivatives;
    RefPtrWillBeMember<OESVertexArrayObject> m_oesVertexArrayObject;
    RefPtrWillBeMember<OESElementIndexUint> m_oesElementIndexUint;
    RefPtrWillBeMember<WebGLLoseContext> m_webglLoseContext;
    RefPtrWillBeMember<WebGLDebugRendererInfo> m_webglDebugRendererInfo;
    RefPtrWillBeMember<WebGLDebugShaders> m_webglDebugShaders;
    RefPtrWillBeMember<WebGLDrawBuffers> m_webglDrawBuffers;
    RefPtrWillBeMember<WebGLCompressedTextureATC> m_webglCompressedTextureATC;
    RefPtrWillBeMember<WebGLCompressedTextureETC1> m_webglCompressedTextureETC1;
    RefPtrWillBeMember<WebGLCompressedTexturePVRTC> m_webglCompressedTexturePVRTC;
    RefPtrWillBeMember<WebGLCompressedTextureS3TC> m_webglCompressedTextureS3TC;
    RefPtrWillBeMember<WebGLDepthTexture> m_webglDepthTexture;
};

DEFINE_TYPE_CASTS(WebGLRenderingContext, CanvasRenderingContext, context,
    context->is3d() && WebGLRenderingContextBase::getWebGLVersion(context) == 1,
    context.is3d() && WebGLRenderingContextBase::getWebGLVersion(&context) == 1);

} // namespace blink

#endif // WebGLRenderingContext_h
