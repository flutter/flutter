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

#ifndef WebGLProgram_h
#define WebGLProgram_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/html/canvas/WebGLSharedObject.h"
#include "core/html/canvas/WebGLShader.h"
#include "wtf/PassRefPtr.h"
#include "wtf/Vector.h"

namespace blink {

class WebGLProgram FINAL : public WebGLSharedObject, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    virtual ~WebGLProgram();

    static PassRefPtrWillBeRawPtr<WebGLProgram> create(WebGLRenderingContextBase*);

    unsigned numActiveAttribLocations();
    GLint getActiveAttribLocation(GLuint index);

    bool isUsingVertexAttrib0();

    bool linkStatus();

    unsigned linkCount() const { return m_linkCount; }

    // This is to be called everytime after the program is successfully linked.
    // We don't deal with integer overflow here, assuming in reality a program
    // will never be linked so many times.
    // Also, we invalidate the cached program info.
    void increaseLinkCount();

    WebGLShader* getAttachedShader(GLenum);
    bool attachShader(WebGLShader*);
    bool detachShader(WebGLShader*);

    virtual void trace(Visitor*) OVERRIDE;

protected:
    explicit WebGLProgram(WebGLRenderingContextBase*);

    virtual void deleteObjectImpl(blink::WebGraphicsContext3D*, Platform3DObject) OVERRIDE;

private:
    virtual bool isProgram() const OVERRIDE { return true; }

    void cacheActiveAttribLocations(blink::WebGraphicsContext3D*);
    void cacheInfoIfNeeded();

    Vector<GLint> m_activeAttribLocations;

    GLint m_linkStatus;

    // This is used to track whether a WebGLUniformLocation belongs to this
    // program or not.
    unsigned m_linkCount;

    RefPtrWillBeMember<WebGLShader> m_vertexShader;
    RefPtrWillBeMember<WebGLShader> m_fragmentShader;

    bool m_infoValid;
};

} // namespace blink

#endif // WebGLProgram_h
