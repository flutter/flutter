// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"

#include "core/html/canvas/EXTShaderTextureLOD.h"

namespace blink {

EXTShaderTextureLOD::EXTShaderTextureLOD(WebGLRenderingContextBase* context)
    : WebGLExtension(context)
{
    ScriptWrappable::init(this);
    context->extensionsUtil()->ensureExtensionEnabled("GL_EXT_shader_texture_lod");
}

EXTShaderTextureLOD::~EXTShaderTextureLOD()
{
}

WebGLExtensionName EXTShaderTextureLOD::name() const
{
    return EXTShaderTextureLODName;
}

PassRefPtrWillBeRawPtr<EXTShaderTextureLOD> EXTShaderTextureLOD::create(WebGLRenderingContextBase* context)
{
    return adoptRefWillBeNoop(new EXTShaderTextureLOD(context));
}

bool EXTShaderTextureLOD::supported(WebGLRenderingContextBase* context)
{
    return context->extensionsUtil()->supportsExtension("GL_EXT_shader_texture_lod");
}

const char* EXTShaderTextureLOD::extensionName()
{
    return "EXT_shader_texture_lod";
}

} // namespace blink
