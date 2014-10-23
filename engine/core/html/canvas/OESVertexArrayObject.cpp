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

#include "core/html/canvas/OESVertexArrayObject.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/html/canvas/WebGLRenderingContextBase.h"
#include "core/html/canvas/WebGLVertexArrayObjectOES.h"

namespace blink {

OESVertexArrayObject::OESVertexArrayObject(WebGLRenderingContextBase* context)
    : WebGLExtension(context)
{
    ScriptWrappable::init(this);
    context->extensionsUtil()->ensureExtensionEnabled("GL_OES_vertex_array_object");
}

OESVertexArrayObject::~OESVertexArrayObject()
{
}

WebGLExtensionName OESVertexArrayObject::name() const
{
    return OESVertexArrayObjectName;
}

PassRefPtrWillBeRawPtr<OESVertexArrayObject> OESVertexArrayObject::create(WebGLRenderingContextBase* context)
{
    return adoptRefWillBeNoop(new OESVertexArrayObject(context));
}

PassRefPtrWillBeRawPtr<WebGLVertexArrayObjectOES> OESVertexArrayObject::createVertexArrayOES()
{
    if (isLost())
        return nullptr;

    RefPtrWillBeRawPtr<WebGLVertexArrayObjectOES> o = WebGLVertexArrayObjectOES::create(m_context, WebGLVertexArrayObjectOES::VaoTypeUser);
    m_context->addContextObject(o.get());
    return o.release();
}

void OESVertexArrayObject::deleteVertexArrayOES(WebGLVertexArrayObjectOES* arrayObject)
{
    if (!arrayObject || isLost())
        return;

    if (!arrayObject->isDefaultObject() && arrayObject == m_context->m_boundVertexArrayObject)
        m_context->setBoundVertexArrayObject(nullptr);

    arrayObject->deleteObject(m_context->webContext());
}

GLboolean OESVertexArrayObject::isVertexArrayOES(WebGLVertexArrayObjectOES* arrayObject)
{
    if (!arrayObject || isLost())
        return 0;

    if (!arrayObject->hasEverBeenBound())
        return 0;

    return m_context->webContext()->isVertexArrayOES(arrayObject->object());
}

void OESVertexArrayObject::bindVertexArrayOES(WebGLVertexArrayObjectOES* arrayObject)
{
    if (isLost())
        return;

    if (arrayObject && (arrayObject->isDeleted() || !arrayObject->validate(0, context()))) {
        m_context->webContext()->synthesizeGLError(GL_INVALID_OPERATION);
        return;
    }

    if (arrayObject && !arrayObject->isDefaultObject() && arrayObject->object()) {
        m_context->webContext()->bindVertexArrayOES(arrayObject->object());

        arrayObject->setHasEverBeenBound();
        m_context->setBoundVertexArrayObject(arrayObject);
    } else {
        m_context->webContext()->bindVertexArrayOES(0);
        m_context->setBoundVertexArrayObject(nullptr);
    }
}

bool OESVertexArrayObject::supported(WebGLRenderingContextBase* context)
{
    return context->extensionsUtil()->supportsExtension("GL_OES_vertex_array_object");
}

const char* OESVertexArrayObject::extensionName()
{
    return "OES_vertex_array_object";
}

} // namespace blink
