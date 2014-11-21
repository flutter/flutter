// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_CANVAS_WEBGLSHAREDWEBGRAPHICSCONTEXT3D_H_
#define SKY_ENGINE_CORE_HTML_CANVAS_WEBGLSHAREDWEBGRAPHICSCONTEXT3D_H_

#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class WebGraphicsContext3D;
class DrawingBuffer;

#if ENABLE(OILPAN)
// The attached WebGLContextObjects are finalized using the
// blink::WebGraphicsContext3D object of this object's DrawingBuffer.
// Naturally the DrawingBuffer must then be kept alive until those
// finalizers have run. With Oilpan, accomplish that by having the
// WebGLContextObjects keep a RefPtr<> to an off-heap object that
// safely handles the eventual release of the underlying
// DrawingBuffer.
class WebGLSharedWebGraphicsContext3D final : public RefCounted<WebGLSharedWebGraphicsContext3D> {
public:
    static PassRefPtr<WebGLSharedWebGraphicsContext3D> create(PassRefPtr<DrawingBuffer>);

    ~WebGLSharedWebGraphicsContext3D();

    // Disposing and updating the underlying DrawingBuffer;
    // needed when handling loss and restoration of graphics contexts.
    void dispose();
    void update(PassRefPtr<DrawingBuffer>);

    DrawingBuffer* drawingBuffer() const;

    blink::WebGraphicsContext3D* webContext() const;
private:
    explicit WebGLSharedWebGraphicsContext3D(PassRefPtr<DrawingBuffer>);

    RefPtr<DrawingBuffer> m_buffer;
};
#endif

}

#endif  // SKY_ENGINE_CORE_HTML_CANVAS_WEBGLSHAREDWEBGRAPHICSCONTEXT3D_H_
