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

#ifndef WebGLContextAttributes_h
#define WebGLContextAttributes_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/html/canvas/CanvasContextAttributes.h"
#include "public/platform/WebGraphicsContext3D.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class Settings;

class WebGLContextAttributes final : public CanvasContextAttributes, public ScriptWrappable {
    DECLARE_EMPTY_VIRTUAL_DESTRUCTOR_WILL_BE_REMOVED(WebGLContextAttributes);
    DEFINE_WRAPPERTYPEINFO();
public:
    // Create a new attributes object
    static PassRefPtrWillBeRawPtr<WebGLContextAttributes> create();

    // Create a copy of this object.
    PassRefPtrWillBeRawPtr<WebGLContextAttributes> clone() const;

    // Whether or not the drawing buffer has an alpha channel; default=true
    bool alpha() const;
    void setAlpha(bool);

    // Whether or not the drawing buffer has a depth buffer; default=true
    bool depth() const;
    void setDepth(bool);

    // Whether or not the drawing buffer has a stencil buffer; default=false
    bool stencil() const;
    void setStencil(bool);

    // Whether or not the drawing buffer is antialiased; default=true
    bool antialias() const;
    void setAntialias(bool);

    // Whether or not to treat the values in the drawing buffer as
    // though their alpha channel has already been multiplied into the
    // color channels; default=true
    bool premultipliedAlpha() const;
    void setPremultipliedAlpha(bool);

    // Whether or not to preserve the drawing buffer after presentation to the
    // screen; default=false
    bool preserveDrawingBuffer() const;
    void setPreserveDrawingBuffer(bool);

    // Whether or not to fail context creation if performance will be
    // significantly degraded compared to a native GL context; default=false
    bool failIfMajorPerformanceCaveat() const;
    void setFailIfMajorPerformanceCaveat(bool);

    // Set up the attributes that can be used to initialize a WebGraphicsContext3D.
    // It's mostly based on WebGLContextAttributes, but would be adjusted based
    // on settings.
    blink::WebGraphicsContext3D::Attributes attributes(const blink::WebString&, Settings*, unsigned webGLVersion) const;

protected:
    WebGLContextAttributes();
    WebGLContextAttributes(const WebGLContextAttributes&);

private:
    bool m_alpha;
    bool m_depth;
    bool m_stencil;
    bool m_antialias;
    bool m_premultipliedAlpha;
    bool m_preserveDrawingBuffer;
    bool m_failIfMajorPerformanceCaveat;
};

} // namespace blink

#endif // WebGLContextAttributes_h
