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

#ifndef WebGLShader_h
#define WebGLShader_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/html/canvas/WebGLSharedObject.h"
#include "wtf/PassRefPtr.h"
#include "wtf/text/WTFString.h"

namespace blink {

class WebGLShader FINAL : public WebGLSharedObject, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    virtual ~WebGLShader();

    static PassRefPtrWillBeRawPtr<WebGLShader> create(WebGLRenderingContextBase*, GLenum);

    GLenum type() const { return m_type; }
    const String& source() const { return m_source; }

    void setSource(const String& source) { m_source = source; }

private:
    WebGLShader(WebGLRenderingContextBase*, GLenum);

    virtual void deleteObjectImpl(blink::WebGraphicsContext3D*, Platform3DObject) OVERRIDE;

    virtual bool isShader() const OVERRIDE { return true; }

    GLenum m_type;
    String m_source;
};

} // namespace blink

#endif // WebGLShader_h
