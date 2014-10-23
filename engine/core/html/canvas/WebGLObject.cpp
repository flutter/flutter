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

#include "core/html/canvas/WebGLObject.h"

namespace blink {

WebGLObject::WebGLObject(WebGLRenderingContextBase*)
    : m_object(0)
    , m_attachmentCount(0)
    , m_deleted(false)
{
}

WebGLObject::~WebGLObject()
{
    // Verify that platform objects have been explicitly deleted.
    ASSERT(m_deleted);
}

void WebGLObject::setObject(Platform3DObject object)
{
    // object==0 && m_deleted==false indicating an uninitialized state;
    ASSERT(!m_object && !m_deleted);
    m_object = object;
}

void WebGLObject::deleteObject(blink::WebGraphicsContext3D* context3d)
{
    m_deleted = true;
    if (!m_object)
        return;

    if (!hasGroupOrContext())
        return;

    if (!m_attachmentCount) {
        if (!context3d)
            context3d = getAWebGraphicsContext3D();

        if (context3d)
            deleteObjectImpl(context3d, m_object);

        m_object = 0;
    }
}

void WebGLObject::detach()
{
    m_attachmentCount = 0; // Make sure OpenGL resource is deleted.
}

void WebGLObject::detachAndDeleteObject()
{
    // Helper method that pairs detachment with platform object
    // deletion.
    //
    // With Oilpan enabled, objects may end up being finalized without
    // having been detached first. Consequently, the objects force
    // detachment first before deleting the platform object. Without
    // Oilpan, the objects will have been detached from the 'parent'
    // objects first and do not separately require it when finalizing.
    //
    // However, as detach() is trivial, the individual WebGL
    // destructors will always call detachAndDeleteObject() rather
    // than do it based on Oilpan being enabled.
    detach();
    deleteObject(0);
}

void WebGLObject::onDetached(blink::WebGraphicsContext3D* context3d)
{
    if (m_attachmentCount)
        --m_attachmentCount;
    if (m_deleted)
        deleteObject(context3d);
}

}
