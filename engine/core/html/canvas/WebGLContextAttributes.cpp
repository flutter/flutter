/*
 * Copyright (c) 2010, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "core/html/canvas/WebGLContextAttributes.h"

#include "core/frame/Settings.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(WebGLContextAttributes);

PassRefPtrWillBeRawPtr<WebGLContextAttributes> WebGLContextAttributes::create()
{
    return adoptRefWillBeNoop(new WebGLContextAttributes());
}

WebGLContextAttributes::WebGLContextAttributes()
    : CanvasContextAttributes()
    , m_alpha(true)
    , m_depth(true)
    , m_stencil(false)
    , m_antialias(true)
    , m_premultipliedAlpha(true)
    , m_preserveDrawingBuffer(false)
    , m_failIfMajorPerformanceCaveat(false)
{
    ScriptWrappable::init(this);
}

WebGLContextAttributes::WebGLContextAttributes(const WebGLContextAttributes& attrs)
    : CanvasContextAttributes()
    , m_alpha(attrs.m_alpha)
    , m_depth(attrs.m_depth)
    , m_stencil(attrs.m_stencil)
    , m_antialias(attrs.m_antialias)
    , m_premultipliedAlpha(attrs.m_premultipliedAlpha)
    , m_preserveDrawingBuffer(attrs.m_preserveDrawingBuffer)
    , m_failIfMajorPerformanceCaveat(attrs.m_failIfMajorPerformanceCaveat)
{
    ScriptWrappable::init(this);
}

PassRefPtrWillBeRawPtr<WebGLContextAttributes> WebGLContextAttributes::clone() const
{
    return adoptRefWillBeNoop(new WebGLContextAttributes(*this));
}

bool WebGLContextAttributes::alpha() const
{
    return m_alpha;
}

void WebGLContextAttributes::setAlpha(bool alpha)
{
    m_alpha = alpha;
}

bool WebGLContextAttributes::depth() const
{
    return m_depth;
}

void WebGLContextAttributes::setDepth(bool depth)
{
    m_depth = depth;
}

bool WebGLContextAttributes::stencil() const
{
    return m_stencil;
}

void WebGLContextAttributes::setStencil(bool stencil)
{
    m_stencil = stencil;
}

bool WebGLContextAttributes::antialias() const
{
    return m_antialias;
}

void WebGLContextAttributes::setAntialias(bool antialias)
{
    m_antialias = antialias;
}

bool WebGLContextAttributes::premultipliedAlpha() const
{
    return m_premultipliedAlpha;
}

void WebGLContextAttributes::setPremultipliedAlpha(bool premultipliedAlpha)
{
    m_premultipliedAlpha = premultipliedAlpha;
}

bool WebGLContextAttributes::preserveDrawingBuffer() const
{
    return m_preserveDrawingBuffer;
}

void WebGLContextAttributes::setPreserveDrawingBuffer(bool preserveDrawingBuffer)
{
    m_preserveDrawingBuffer = preserveDrawingBuffer;
}

bool WebGLContextAttributes::failIfMajorPerformanceCaveat() const
{
    return m_failIfMajorPerformanceCaveat;
}

void WebGLContextAttributes::setFailIfMajorPerformanceCaveat(bool failIfMajorPerformanceCaveat)
{
    m_failIfMajorPerformanceCaveat = failIfMajorPerformanceCaveat;
}

blink::WebGraphicsContext3D::Attributes WebGLContextAttributes::attributes(
    const blink::WebString& topDocumentURL, Settings* settings, unsigned webGLVersion) const
{
    blink::WebGraphicsContext3D::Attributes attrs;

    attrs.alpha = m_alpha;
    attrs.depth = m_depth;
    attrs.stencil = m_stencil;
    attrs.antialias = m_antialias;
    if (m_antialias) {
        if (settings && !settings->openGLMultisamplingEnabled())
            attrs.antialias = false;
    }
    attrs.premultipliedAlpha = m_premultipliedAlpha;
    attrs.failIfMajorPerformanceCaveat = m_failIfMajorPerformanceCaveat;

    attrs.noExtensions = true;
    attrs.shareResources = false;
    attrs.preferDiscreteGPU = true;

    attrs.topDocumentURL = topDocumentURL;

    attrs.webGL = true;
    attrs.webGLVersion = webGLVersion;

    return attrs;
}

} // namespace blink
