// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_CANVAS_EXTBLENDMINMAX_H_
#define SKY_ENGINE_CORE_HTML_CANVAS_EXTBLENDMINMAX_H_

#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/core/html/canvas/WebGLExtension.h"
#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {

class EXTBlendMinMax final : public WebGLExtension, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<EXTBlendMinMax> create(WebGLRenderingContextBase*);
    static bool supported(WebGLRenderingContextBase*);
    static const char* extensionName();

    virtual ~EXTBlendMinMax();
    virtual WebGLExtensionName name() const override;

private:
    explicit EXTBlendMinMax(WebGLRenderingContextBase*);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_CANVAS_EXTBLENDMINMAX_H_
