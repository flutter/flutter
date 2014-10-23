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

#ifndef WebGLRenderbuffer_h
#define WebGLRenderbuffer_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/html/canvas/WebGLSharedObject.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class WebGLRenderbuffer FINAL : public WebGLSharedObject, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    virtual ~WebGLRenderbuffer();

    static PassRefPtrWillBeRawPtr<WebGLRenderbuffer> create(WebGLRenderingContextBase*);

    void setInternalFormat(GLenum internalformat)
    {
        m_internalFormat = internalformat;
    }
    GLenum internalFormat() const { return m_internalFormat; }

    void setSize(GLsizei width, GLsizei height)
    {
        m_width = width;
        m_height = height;
    }
    GLsizei width() const { return m_width; }
    GLsizei height() const { return m_height; }

    bool hasEverBeenBound() const { return object() && m_hasEverBeenBound; }

    void setHasEverBeenBound() { m_hasEverBeenBound = true; }

    void setEmulatedStencilBuffer(PassRefPtrWillBeRawPtr<WebGLRenderbuffer> buffer) { m_emulatedStencilBuffer = buffer; }
    WebGLRenderbuffer* emulatedStencilBuffer() const { return m_emulatedStencilBuffer.get(); }
    void deleteEmulatedStencilBuffer(blink::WebGraphicsContext3D* context3d);

    virtual void trace(Visitor*) OVERRIDE;

protected:
    explicit WebGLRenderbuffer(WebGLRenderingContextBase*);

    virtual void deleteObjectImpl(blink::WebGraphicsContext3D*, Platform3DObject) OVERRIDE;

private:
    virtual bool isRenderbuffer() const OVERRIDE { return true; }

    GLenum m_internalFormat;
    GLsizei m_width, m_height;

    bool m_hasEverBeenBound;

    RefPtrWillBeMember<WebGLRenderbuffer> m_emulatedStencilBuffer;
};

} // namespace blink

#endif // WebGLRenderbuffer_h
