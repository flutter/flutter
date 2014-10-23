// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/html/canvas/WebGLSharedWebGraphicsContext3D.h"

#if ENABLE(OILPAN)
#include "platform/graphics/gpu/DrawingBuffer.h"
#include "public/platform/WebGraphicsContext3D.h"

namespace blink {

PassRefPtr<WebGLSharedWebGraphicsContext3D> WebGLSharedWebGraphicsContext3D::create(PassRefPtr<DrawingBuffer> buffer)
{
    return adoptRef(new WebGLSharedWebGraphicsContext3D(buffer));
}

WebGLSharedWebGraphicsContext3D::WebGLSharedWebGraphicsContext3D(PassRefPtr<DrawingBuffer> buffer)
    : m_buffer(buffer)
{
}

WebGLSharedWebGraphicsContext3D::~WebGLSharedWebGraphicsContext3D()
{
    dispose();
}

void WebGLSharedWebGraphicsContext3D::dispose()
{
    if (m_buffer) {
        m_buffer->beginDestruction();
        m_buffer.clear();
    }
}

void WebGLSharedWebGraphicsContext3D::update(PassRefPtr<DrawingBuffer> buffer)
{
    m_buffer = buffer;
}

DrawingBuffer* WebGLSharedWebGraphicsContext3D::drawingBuffer() const
{
    return m_buffer.get();
}

blink::WebGraphicsContext3D* WebGLSharedWebGraphicsContext3D::webContext() const
{
    return m_buffer ? m_buffer->context() : 0;
}

} // namespace blink

#endif // ENABLE(OILPAN)
