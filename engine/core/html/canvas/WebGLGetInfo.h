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

#ifndef WebGLGetInfo_h
#define WebGLGetInfo_h

#include "core/html/canvas/WebGLBuffer.h"
#include "core/html/canvas/WebGLFramebuffer.h"
#include "core/html/canvas/WebGLProgram.h"
#include "core/html/canvas/WebGLRenderbuffer.h"
#include "core/html/canvas/WebGLTexture.h"
#include "core/html/canvas/WebGLVertexArrayObjectOES.h"
#include "wtf/Float32Array.h"
#include "wtf/Int32Array.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/Uint32Array.h"
#include "wtf/Uint8Array.h"
#include "wtf/text/WTFString.h"

namespace blink {

// A tagged union representing the result of get queries like
// getParameter (encompassing getBooleanv, getIntegerv, getFloatv) and
// similar variants. For reference counted types, increments and
// decrements the reference count of the target object.

class WebGLGetInfo FINAL {
    STACK_ALLOCATED();
public:
    enum Type {
        kTypeBool,
        kTypeBoolArray,
        kTypeFloat,
        kTypeInt,
        kTypeNull,
        kTypeString,
        kTypeUnsignedInt,
        kTypeWebGLBuffer,
        kTypeWebGLFloatArray,
        kTypeWebGLFramebuffer,
        kTypeWebGLIntArray,
        kTypeWebGLObjectArray,
        kTypeWebGLProgram,
        kTypeWebGLRenderbuffer,
        kTypeWebGLTexture,
        kTypeWebGLUnsignedByteArray,
        kTypeWebGLUnsignedIntArray,
        kTypeWebGLVertexArrayObjectOES,
    };

    explicit WebGLGetInfo(bool value);
    WebGLGetInfo(const bool* value, int size);
    explicit WebGLGetInfo(float value);
    explicit WebGLGetInfo(int value);
    // Represents the null value and type.
    WebGLGetInfo();
    explicit WebGLGetInfo(const String& value);
    explicit WebGLGetInfo(unsigned value);
    explicit WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLBuffer> value);
    explicit WebGLGetInfo(PassRefPtr<Float32Array> value);
    explicit WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLFramebuffer> value);
    explicit WebGLGetInfo(PassRefPtr<Int32Array> value);
    // FIXME: implement WebGLObjectArray
    // WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLObjectArray> value);
    explicit WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLProgram> value);
    explicit WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLRenderbuffer> value);
    explicit WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLTexture> value);
    explicit WebGLGetInfo(PassRefPtr<Uint8Array> value);
    explicit WebGLGetInfo(PassRefPtr<Uint32Array> value);
    explicit WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLVertexArrayObjectOES> value);

    Type getType() const;

    bool getBool() const;
    const Vector<bool>& getBoolArray() const;
    float getFloat() const;
    int getInt() const;
    const String& getString() const;
    unsigned getUnsignedInt() const;
    PassRefPtrWillBeRawPtr<WebGLBuffer> getWebGLBuffer() const;
    PassRefPtr<Float32Array> getWebGLFloatArray() const;
    PassRefPtrWillBeRawPtr<WebGLFramebuffer> getWebGLFramebuffer() const;
    PassRefPtr<Int32Array> getWebGLIntArray() const;
    // FIXME: implement WebGLObjectArray
    // PassRefPtr<WebGLObjectArray> getWebGLObjectArray() const;
    PassRefPtrWillBeRawPtr<WebGLProgram> getWebGLProgram() const;
    PassRefPtrWillBeRawPtr<WebGLRenderbuffer> getWebGLRenderbuffer() const;
    PassRefPtrWillBeRawPtr<WebGLTexture> getWebGLTexture() const;
    PassRefPtr<Uint8Array> getWebGLUnsignedByteArray() const;
    PassRefPtr<Uint32Array> getWebGLUnsignedIntArray() const;
    PassRefPtrWillBeRawPtr<WebGLVertexArrayObjectOES> getWebGLVertexArrayObjectOES() const;

private:
    Type m_type;
    bool m_bool;
    Vector<bool> m_boolArray;
    float m_float;
    int m_int;
    String m_string;
    unsigned m_unsignedInt;
    RefPtrWillBeMember<WebGLBuffer> m_webglBuffer;
    RefPtr<Float32Array> m_webglFloatArray;
    RefPtrWillBeMember<WebGLFramebuffer> m_webglFramebuffer;
    RefPtr<Int32Array> m_webglIntArray;
    // FIXME: implement WebGLObjectArray
    // RefPtr<WebGLObjectArray> m_webglObjectArray;
    RefPtrWillBeMember<WebGLProgram> m_webglProgram;
    RefPtrWillBeMember<WebGLRenderbuffer> m_webglRenderbuffer;
    RefPtrWillBeMember<WebGLTexture> m_webglTexture;
    RefPtr<Uint8Array> m_webglUnsignedByteArray;
    RefPtr<Uint32Array> m_webglUnsignedIntArray;
    RefPtrWillBeMember<WebGLVertexArrayObjectOES> m_webglVertexArrayObject;
};

} // namespace blink

#endif // WebGLGetInfo_h
