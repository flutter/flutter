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

#include "config.h"

#include "core/html/canvas/WebGLProgram.h"

#include "core/html/canvas/WebGLContextGroup.h"
#include "core/html/canvas/WebGLRenderingContextBase.h"

namespace blink {

PassRefPtrWillBeRawPtr<WebGLProgram> WebGLProgram::create(WebGLRenderingContextBase* ctx)
{
    return adoptRefWillBeNoop(new WebGLProgram(ctx));
}

WebGLProgram::WebGLProgram(WebGLRenderingContextBase* ctx)
    : WebGLSharedObject(ctx)
    , m_linkStatus(false)
    , m_linkCount(0)
    , m_infoValid(true)
{
    ScriptWrappable::init(this);
    setObject(ctx->webContext()->createProgram());
}

WebGLProgram::~WebGLProgram()
{
#if ENABLE(OILPAN)
    // These heap objects handle detachment on their own. Clear out
    // the references to prevent deleteObjectImpl() from trying to do
    // same, as we cannot safely access other heap objects from this
    // destructor.
    m_vertexShader = nullptr;
    m_fragmentShader = nullptr;
#endif
    // Always call detach here to ensure that platform object deletion
    // happens with Oilpan enabled. It keeps the code regular to do it
    // with or without Oilpan enabled.
    //
    // See comment in WebGLBuffer's destructor for additional
    // information on why this is done for WebGLSharedObject-derived
    // objects.
    detachAndDeleteObject();
}

void WebGLProgram::deleteObjectImpl(blink::WebGraphicsContext3D* context3d, Platform3DObject obj)
{
    context3d->deleteProgram(obj);
    if (m_vertexShader) {
        m_vertexShader->onDetached(context3d);
        m_vertexShader = nullptr;
    }
    if (m_fragmentShader) {
        m_fragmentShader->onDetached(context3d);
        m_fragmentShader = nullptr;
    }
}

unsigned WebGLProgram::numActiveAttribLocations()
{
    cacheInfoIfNeeded();
    return m_activeAttribLocations.size();
}

GLint WebGLProgram::getActiveAttribLocation(GLuint index)
{
    cacheInfoIfNeeded();
    if (index >= numActiveAttribLocations())
        return -1;
    return m_activeAttribLocations[index];
}

bool WebGLProgram::isUsingVertexAttrib0()
{
    cacheInfoIfNeeded();
    for (unsigned ii = 0; ii < numActiveAttribLocations(); ++ii) {
        if (!getActiveAttribLocation(ii))
            return true;
    }
    return false;
}

bool WebGLProgram::linkStatus()
{
    cacheInfoIfNeeded();
    return m_linkStatus;
}

void WebGLProgram::increaseLinkCount()
{
    ++m_linkCount;
    m_infoValid = false;
}

WebGLShader* WebGLProgram::getAttachedShader(GLenum type)
{
    switch (type) {
    case GL_VERTEX_SHADER:
        return m_vertexShader.get();
    case GL_FRAGMENT_SHADER:
        return m_fragmentShader.get();
    default:
        return 0;
    }
}

bool WebGLProgram::attachShader(WebGLShader* shader)
{
    if (!shader || !shader->object())
        return false;
    switch (shader->type()) {
    case GL_VERTEX_SHADER:
        if (m_vertexShader)
            return false;
        m_vertexShader = shader;
        return true;
    case GL_FRAGMENT_SHADER:
        if (m_fragmentShader)
            return false;
        m_fragmentShader = shader;
        return true;
    default:
        return false;
    }
}

bool WebGLProgram::detachShader(WebGLShader* shader)
{
    if (!shader || !shader->object())
        return false;
    switch (shader->type()) {
    case GL_VERTEX_SHADER:
        if (m_vertexShader != shader)
            return false;
        m_vertexShader = nullptr;
        return true;
    case GL_FRAGMENT_SHADER:
        if (m_fragmentShader != shader)
            return false;
        m_fragmentShader = nullptr;
        return true;
    default:
        return false;
    }
}

void WebGLProgram::cacheActiveAttribLocations(blink::WebGraphicsContext3D* context3d)
{
    m_activeAttribLocations.clear();

    GLint numAttribs = 0;
    context3d->getProgramiv(object(), GL_ACTIVE_ATTRIBUTES, &numAttribs);
    m_activeAttribLocations.resize(static_cast<size_t>(numAttribs));
    for (int i = 0; i < numAttribs; ++i) {
        blink::WebGraphicsContext3D::ActiveInfo info;
        context3d->getActiveAttrib(object(), i, info);
        m_activeAttribLocations[i] = context3d->getAttribLocation(object(), info.name.utf8().data());
    }
}

void WebGLProgram::cacheInfoIfNeeded()
{
    if (m_infoValid)
        return;

    if (!object())
        return;

    if (!contextGroup())
        return;
    blink::WebGraphicsContext3D* context = contextGroup()->getAWebGraphicsContext3D();
    if (!context)
        return;
    GLint linkStatus = 0;
    context->getProgramiv(object(), GL_LINK_STATUS, &linkStatus);
    m_linkStatus = linkStatus;
    if (m_linkStatus)
        cacheActiveAttribLocations(context);
    m_infoValid = true;
}

void WebGLProgram::trace(Visitor* visitor)
{
    visitor->trace(m_vertexShader);
    visitor->trace(m_fragmentShader);
    WebGLSharedObject::trace(visitor);
}

}
