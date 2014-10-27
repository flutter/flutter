/*
 * Copyright (C) 2009 Apple Inc. All Rights Reserved.
 * Copyright (C) 2009 Google Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/html/canvas/WebGLGetInfo.h"


namespace blink {

WebGLGetInfo::WebGLGetInfo(bool value)
    : m_type(kTypeBool)
    , m_bool(value)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
{
}

WebGLGetInfo::WebGLGetInfo(const bool* value, int size)
    : m_type(kTypeBoolArray)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
{
    if (!value || size <=0)
        return;
    m_boolArray.resize(size);
    for (int ii = 0; ii < size; ++ii)
        m_boolArray[ii] = value[ii];
}

WebGLGetInfo::WebGLGetInfo(float value)
    : m_type(kTypeFloat)
    , m_bool(false)
    , m_float(value)
    , m_int(0)
    , m_unsignedInt(0)
{
}

WebGLGetInfo::WebGLGetInfo(int value)
    : m_type(kTypeInt)
    , m_bool(false)
    , m_float(0)
    , m_int(value)
    , m_unsignedInt(0)
{
}

WebGLGetInfo::WebGLGetInfo()
    : m_type(kTypeNull)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
{
}

WebGLGetInfo::WebGLGetInfo(const String& value)
    : m_type(kTypeString)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_string(value)
    , m_unsignedInt(0)
{
}

WebGLGetInfo::WebGLGetInfo(unsigned value)
    : m_type(kTypeUnsignedInt)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<WebGLBuffer> value)
    : m_type(kTypeWebGLBuffer)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglBuffer(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<Float32Array> value)
    : m_type(kTypeWebGLFloatArray)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglFloatArray(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<WebGLFramebuffer> value)
    : m_type(kTypeWebGLFramebuffer)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglFramebuffer(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<Int32Array> value)
    : m_type(kTypeWebGLIntArray)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglIntArray(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<WebGLProgram> value)
    : m_type(kTypeWebGLProgram)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglProgram(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<WebGLRenderbuffer> value)
    : m_type(kTypeWebGLRenderbuffer)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglRenderbuffer(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<WebGLTexture> value)
    : m_type(kTypeWebGLTexture)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglTexture(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<Uint8Array> value)
    : m_type(kTypeWebGLUnsignedByteArray)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglUnsignedByteArray(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<Uint32Array> value)
    : m_type(kTypeWebGLUnsignedIntArray)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglUnsignedIntArray(value)
{
}

WebGLGetInfo::WebGLGetInfo(PassRefPtr<WebGLVertexArrayObjectOES> value)
    : m_type(kTypeWebGLVertexArrayObjectOES)
    , m_bool(false)
    , m_float(0)
    , m_int(0)
    , m_unsignedInt(0)
    , m_webglVertexArrayObject(value)
{
}

WebGLGetInfo::Type WebGLGetInfo::getType() const
{
    return m_type;
}

bool WebGLGetInfo::getBool() const
{
    ASSERT(getType() == kTypeBool);
    return m_bool;
}

const Vector<bool>& WebGLGetInfo::getBoolArray() const
{
    ASSERT(getType() == kTypeBoolArray);
    return m_boolArray;
}

float WebGLGetInfo::getFloat() const
{
    ASSERT(getType() == kTypeFloat);
    return m_float;
}

int WebGLGetInfo::getInt() const
{
    ASSERT(getType() == kTypeInt);
    return m_int;
}

const String& WebGLGetInfo::getString() const
{
    ASSERT(getType() == kTypeString);
    return m_string;
}

unsigned WebGLGetInfo::getUnsignedInt() const
{
    ASSERT(getType() == kTypeUnsignedInt);
    return m_unsignedInt;
}

PassRefPtr<WebGLBuffer> WebGLGetInfo::getWebGLBuffer() const
{
    ASSERT(getType() == kTypeWebGLBuffer);
    return m_webglBuffer;
}

PassRefPtr<Float32Array> WebGLGetInfo::getWebGLFloatArray() const
{
    ASSERT(getType() == kTypeWebGLFloatArray);
    return m_webglFloatArray;
}

PassRefPtr<WebGLFramebuffer> WebGLGetInfo::getWebGLFramebuffer() const
{
    ASSERT(getType() == kTypeWebGLFramebuffer);
    return m_webglFramebuffer;
}

PassRefPtr<Int32Array> WebGLGetInfo::getWebGLIntArray() const
{
    ASSERT(getType() == kTypeWebGLIntArray);
    return m_webglIntArray;
}

PassRefPtr<WebGLProgram> WebGLGetInfo::getWebGLProgram() const
{
    ASSERT(getType() == kTypeWebGLProgram);
    return m_webglProgram;
}

PassRefPtr<WebGLRenderbuffer> WebGLGetInfo::getWebGLRenderbuffer() const
{
    ASSERT(getType() == kTypeWebGLRenderbuffer);
    return m_webglRenderbuffer;
}

PassRefPtr<WebGLTexture> WebGLGetInfo::getWebGLTexture() const
{
    ASSERT(getType() == kTypeWebGLTexture);
    return m_webglTexture;
}

PassRefPtr<Uint8Array> WebGLGetInfo::getWebGLUnsignedByteArray() const
{
    ASSERT(getType() == kTypeWebGLUnsignedByteArray);
    return m_webglUnsignedByteArray;
}

PassRefPtr<Uint32Array> WebGLGetInfo::getWebGLUnsignedIntArray() const
{
    ASSERT(getType() == kTypeWebGLUnsignedIntArray);
    return m_webglUnsignedIntArray;
}

PassRefPtr<WebGLVertexArrayObjectOES> WebGLGetInfo::getWebGLVertexArrayObjectOES() const
{
    ASSERT(getType() == kTypeWebGLVertexArrayObjectOES);
    return m_webglVertexArrayObject;
}

} // namespace blink
