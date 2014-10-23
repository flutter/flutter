/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
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

#include "core/html/canvas/WebGLShaderPrecisionFormat.h"

namespace blink {

// static
PassRefPtrWillBeRawPtr<WebGLShaderPrecisionFormat> WebGLShaderPrecisionFormat::create(GLint rangeMin, GLint rangeMax, GLint precision)
{
    return adoptRefWillBeNoop(new WebGLShaderPrecisionFormat(rangeMin, rangeMax, precision));
}

GLint WebGLShaderPrecisionFormat::rangeMin() const
{
    return m_rangeMin;
}

GLint WebGLShaderPrecisionFormat::rangeMax() const
{
    return m_rangeMax;
}

GLint WebGLShaderPrecisionFormat::precision() const
{
    return m_precision;
}

WebGLShaderPrecisionFormat::WebGLShaderPrecisionFormat(GLint rangeMin, GLint rangeMax, GLint precision)
    : m_rangeMin(rangeMin)
    , m_rangeMax(rangeMax)
    , m_precision(precision)
{
    ScriptWrappable::init(this);
}

}
