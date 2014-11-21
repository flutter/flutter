// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WebGLCompressedTextureETC1_h
#define WebGLCompressedTextureETC1_h

#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/core/html/canvas/WebGLExtension.h"
#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {

class WebGLTexture;

class WebGLCompressedTextureETC1 final : public WebGLExtension, public ScriptWrappable {
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

#endif // WebGLCompressedTextureETC1_h
