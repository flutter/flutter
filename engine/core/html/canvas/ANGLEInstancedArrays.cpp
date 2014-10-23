/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
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

#include "core/html/canvas/ANGLEInstancedArrays.h"

#include "core/html/canvas/WebGLRenderingContextBase.h"

namespace blink {

ANGLEInstancedArrays::ANGLEInstancedArrays(WebGLRenderingContextBase* context)
    : WebGLExtension(context)
{
    ScriptWrappable::init(this);
    context->extensionsUtil()->ensureExtensionEnabled("GL_ANGLE_instanced_arrays");
}

ANGLEInstancedArrays::~ANGLEInstancedArrays()
{
}

WebGLExtensionName ANGLEInstancedArrays::name() const
{
    return ANGLEInstancedArraysName;
}

PassRefPtrWillBeRawPtr<ANGLEInstancedArrays> ANGLEInstancedArrays::create(WebGLRenderingContextBase* context)
{
    return adoptRefWillBeNoop(new ANGLEInstancedArrays(context));
}

bool ANGLEInstancedArrays::supported(WebGLRenderingContextBase* context)
{
    return context->extensionsUtil()->supportsExtension("GL_ANGLE_instanced_arrays");
}

const char* ANGLEInstancedArrays::extensionName()
{
    return "ANGLE_instanced_arrays";
}

void ANGLEInstancedArrays::drawArraysInstancedANGLE(GLenum mode, GLint first, GLsizei count, GLsizei primcount)
{
    if (isLost())
        return;

    m_context->drawArraysInstancedANGLE(mode, first, count, primcount);
}

void ANGLEInstancedArrays::drawElementsInstancedANGLE(GLenum mode, GLsizei count, GLenum type, long long offset, GLsizei primcount)
{
    if (isLost())
        return;

    m_context->drawElementsInstancedANGLE(mode, count, type, offset, primcount);
}

void ANGLEInstancedArrays::vertexAttribDivisorANGLE(GLuint index, GLuint divisor)
{
    if (isLost())
        return;

    m_context->vertexAttribDivisorANGLE(index, divisor);
}

} // namespace blink
