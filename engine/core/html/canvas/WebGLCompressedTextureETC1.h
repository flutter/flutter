// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_CANVAS_WEBGLCOMPRESSEDTEXTUREETC1_H_
#define SKY_ENGINE_CORE_HTML_CANVAS_WEBGLCOMPRESSEDTEXTUREETC1_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/core/html/canvas/WebGLExtension.h"
#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {

class WebGLTexture;

class WebGLCompressedTextureETC1 final : public WebGLExtension, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<WebGLCompressedTextureETC1> create(WebGLRenderingContextBase*);
    static bool supported(WebGLRenderingContextBase*);
    static const char* extensionName();

    virtual ~WebGLCompressedTextureETC1();
    virtual WebGLExtensionName name() const override;

private:
    explicit WebGLCompressedTextureETC1(WebGLRenderingContextBase*);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_CANVAS_WEBGLCOMPRESSEDTEXTUREETC1_H_
