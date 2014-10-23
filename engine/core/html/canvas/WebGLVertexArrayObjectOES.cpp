/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#include "config.h"

#include "core/html/canvas/WebGLVertexArrayObjectOES.h"

#include "core/html/canvas/WebGLRenderingContextBase.h"

namespace blink {

PassRefPtrWillBeRawPtr<WebGLVertexArrayObjectOES> WebGLVertexArrayObjectOES::create(WebGLRenderingContextBase* ctx, VaoType type)
{
    return adoptRefWillBeNoop(new WebGLVertexArrayObjectOES(ctx, type));
}

WebGLVertexArrayObjectOES::WebGLVertexArrayObjectOES(WebGLRenderingContextBase* ctx, VaoType type)
    : WebGLContextObject(ctx)
    , m_type(type)
    , m_hasEverBeenBound(false)
#if ENABLE(OILPAN)
    , m_destructionInProgress(false)
#endif
    , m_boundElementArrayBuffer(nullptr)
{
    ScriptWrappable::init(this);
    m_vertexAttribState.resize(ctx->maxVertexAttribs());

    switch (m_type) {
    case VaoTypeDefault:
        break;
    default:
        setObject(context()->webContext()->createVertexArrayOES());
        break;
    }
}

WebGLVertexArrayObjectOES::~WebGLVertexArrayObjectOES()
{
#if ENABLE(OILPAN)
    m_destructionInProgress = true;
#endif

    // Delete the platform framebuffer resource. Explicit detachment
    // is for the benefit of Oilpan, where this vertex array object
    // isn't detached when it and the WebGLRenderingContextBase object
    // it is registered with are both finalized. Without Oilpan, the
    // object will have been detached.
    //
    // To keep the code regular, the trivial detach()ment is always
    // performed.
    detachAndDeleteObject();
}

void WebGLVertexArrayObjectOES::dispatchDetached(blink::WebGraphicsContext3D* context3d)
{
    if (m_boundElementArrayBuffer)
        m_boundElementArrayBuffer->onDetached(context3d);

    for (size_t i = 0; i < m_vertexAttribState.size(); ++i) {
        VertexAttribState& state = m_vertexAttribState[i];
        if (state.bufferBinding)
            state.bufferBinding->onDetached(context3d);
    }
}

void WebGLVertexArrayObjectOES::deleteObjectImpl(blink::WebGraphicsContext3D* context3d, Platform3DObject object)
{
    switch (m_type) {
    case VaoTypeDefault:
        break;
    default:
        context3d->deleteVertexArrayOES(object);
        break;
    }

#if ENABLE(OILPAN)
    // These m_boundElementArrayBuffer and m_vertexAttribState heap
    // objects must not be accessed during destruction in the oilpan
    // build. They could have been already finalized. The finalizers
    // of these objects (and their elements) will themselves handle
    // detachment.
    if (!m_destructionInProgress)
        dispatchDetached(context3d);
#else
    dispatchDetached(context3d);
#endif
}

void WebGLVertexArrayObjectOES::setElementArrayBuffer(PassRefPtrWillBeRawPtr<WebGLBuffer> buffer)
{
    if (buffer)
        buffer->onAttached();
    if (m_boundElementArrayBuffer)
        m_boundElementArrayBuffer->onDetached(context()->webContext());
    m_boundElementArrayBuffer = buffer;
}

void WebGLVertexArrayObjectOES::setVertexAttribState(
    GLuint index, GLsizei bytesPerElement, GLint size, GLenum type, GLboolean normalized, GLsizei stride, GLintptr offset, PassRefPtrWillBeRawPtr<WebGLBuffer> buffer)
{
    GLsizei validatedStride = stride ? stride : bytesPerElement;

    VertexAttribState& state = m_vertexAttribState[index];

    if (buffer)
        buffer->onAttached();
    if (state.bufferBinding)
        state.bufferBinding->onDetached(context()->webContext());

    state.bufferBinding = buffer;
    state.bytesPerElement = bytesPerElement;
    state.size = size;
    state.type = type;
    state.normalized = normalized;
    state.stride = validatedStride;
    state.originalStride = stride;
    state.offset = offset;
}

void WebGLVertexArrayObjectOES::unbindBuffer(PassRefPtrWillBeRawPtr<WebGLBuffer> buffer)
{
    if (m_boundElementArrayBuffer == buffer) {
        m_boundElementArrayBuffer->onDetached(context()->webContext());
        m_boundElementArrayBuffer = nullptr;
    }

    for (size_t i = 0; i < m_vertexAttribState.size(); ++i) {
        VertexAttribState& state = m_vertexAttribState[i];
        if (state.bufferBinding == buffer) {
            buffer->onDetached(context()->webContext());
            state.bufferBinding = nullptr;
        }
    }
}

void WebGLVertexArrayObjectOES::setVertexAttribDivisor(GLuint index, GLuint divisor)
{
    VertexAttribState& state = m_vertexAttribState[index];
    state.divisor = divisor;
}

void WebGLVertexArrayObjectOES::VertexAttribState::trace(Visitor* visitor)
{
    visitor->trace(bufferBinding);
}

void WebGLVertexArrayObjectOES::trace(Visitor* visitor)
{
    visitor->trace(m_boundElementArrayBuffer);
    visitor->trace(m_vertexAttribState);
    WebGLContextObject::trace(visitor);
}

}
