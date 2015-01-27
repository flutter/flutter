// Copyright 2011, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"

#include "bindings/core/dart/DartWebGLRenderingContext.h"

#include "bindings/core/dart/DartANGLEInstancedArrays.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartEXTFragDepth.h"
#include "bindings/core/dart/DartEXTTextureFilterAnisotropic.h"
#include "bindings/core/dart/DartHTMLCanvasElement.h"
#include "bindings/core/dart/DartHTMLImageElement.h"
#include "bindings/core/dart/DartHTMLVideoElement.h"
#include "bindings/core/dart/DartImageData.h"
#include "bindings/core/dart/DartOESElementIndexUint.h"
#include "bindings/core/dart/DartOESStandardDerivatives.h"
#include "bindings/core/dart/DartOESTextureFloat.h"
#include "bindings/core/dart/DartOESTextureFloatLinear.h"
#include "bindings/core/dart/DartOESTextureHalfFloat.h"
#include "bindings/core/dart/DartOESTextureHalfFloatLinear.h"
#include "bindings/core/dart/DartOESVertexArrayObject.h"
#include "bindings/core/dart/DartWebGLBuffer.h"
#include "bindings/core/dart/DartWebGLCompressedTextureATC.h"
#include "bindings/core/dart/DartWebGLCompressedTexturePVRTC.h"
#include "bindings/core/dart/DartWebGLCompressedTextureS3TC.h"
#include "bindings/core/dart/DartWebGLDebugRendererInfo.h"
#include "bindings/core/dart/DartWebGLDebugShaders.h"
#include "bindings/core/dart/DartWebGLDepthTexture.h"
#include "bindings/core/dart/DartWebGLDrawBuffers.h"
#include "bindings/core/dart/DartWebGLFramebuffer.h"
#include "bindings/core/dart/DartWebGLLoseContext.h"
#include "bindings/core/dart/DartWebGLProgram.h"
#include "bindings/core/dart/DartWebGLRenderbuffer.h"
#include "bindings/core/dart/DartWebGLShader.h"
#include "bindings/core/dart/DartWebGLTexture.h"
#include "bindings/core/dart/DartWebGLUniformLocation.h"
#include "bindings/core/dart/DartWebGLVertexArrayObjectOES.h"
#include "core/dom/ExceptionCode.h"
#include "core/html/canvas/WebGLExtensionName.h"
#include "core/html/canvas/WebGLRenderingContext.h"
#include "platform/NotImplemented.h"

#include <limits>
#include <wtf/FastMalloc.h>

namespace blink {

namespace DartWebGLRenderingContextInternal {

template <class Element>
inline Element toWebGLArrayElement(Dart_Handle, Dart_Handle& exception);

template <>
inline double toWebGLArrayElement<double>(Dart_Handle object, Dart_Handle& exception)
{
    return DartUtilities::dartToDouble(object, exception);
}

template <>
inline float toWebGLArrayElement<float>(Dart_Handle object, Dart_Handle& exception)
{
    return DartUtilities::dartToDouble(object, exception);
}

template <>
inline int8_t toWebGLArrayElement<int8_t>(Dart_Handle object, Dart_Handle& exception)
{
    return DartUtilities::toInteger(object, exception);
}

template <>
inline int16_t toWebGLArrayElement<int16_t>(Dart_Handle object, Dart_Handle& exception)
{
    return DartUtilities::toInteger(object, exception);
}

template <>
inline int32_t toWebGLArrayElement<int32_t>(Dart_Handle object, Dart_Handle& exception)
{
    return DartUtilities::toInteger(object, exception);
}

template <>
inline int64_t toWebGLArrayElement<int64_t>(Dart_Handle object, Dart_Handle& exception)
{
    return DartUtilities::toInteger(object, exception);
}

template <>
inline uint8_t toWebGLArrayElement<uint8_t>(Dart_Handle object, Dart_Handle& exception)
{
    return DartUtilities::toInteger(object, exception);
}

template <>
inline uint16_t toWebGLArrayElement<uint16_t>(Dart_Handle object, Dart_Handle& exception)
{
    return DartUtilities::toInteger(object, exception);
}

template <>
inline uint32_t toWebGLArrayElement<uint32_t>(Dart_Handle object, Dart_Handle& exception)
{
    return DartUtilities::toInteger(object, exception);
}

template <class Element>
inline void dartListToVector(Dart_Handle list, Vector<Element>& array, Dart_Handle& exception)
{
    // FIXME: create vector from list for primitive types
    // without element-by-element copying and conversion.
    // Need VM support.
    DartUtilities::toVector(&toWebGLArrayElement<Element>, list, array, exception);
}

template <class Array>
struct TypedArrayTraits;

template <>
struct TypedArrayTraits<Int8Array> {
    typedef int8_t ElementType;
    typedef int ReturnedElementType;
};

template <>
struct TypedArrayTraits<Int16Array> {
    typedef int16_t ElementType;
    typedef int ReturnedElementType;
};

template <>
struct TypedArrayTraits<Int32Array> {
    typedef int32_t ElementType;
    typedef int ReturnedElementType;
};

template <>
struct TypedArrayTraits<Uint8Array> {
    typedef uint8_t ElementType;
    typedef unsigned ReturnedElementType;
};

template <>
struct TypedArrayTraits<Uint8ClampedArray> {
    typedef uint8_t ElementType;
    typedef unsigned ReturnedElementType;
};

template <>
struct TypedArrayTraits<Uint16Array> {
    typedef uint16_t ElementType;
    typedef unsigned ReturnedElementType;
};

template <>
struct TypedArrayTraits<Uint32Array> {
    typedef uint32_t ElementType;
    typedef unsigned ReturnedElementType;
};

template <>
struct TypedArrayTraits<Float32Array> {
    typedef float ElementType;
    typedef float ReturnedElementType;
};

template <>
struct TypedArrayTraits<Float64Array> {
    typedef double ElementType;
    typedef double ReturnedElementType;
};

template<typename ElementType>
struct ToDartTraits {
};

template<>
struct ToDartTraits<String> {
    static Dart_Handle toDart(const String& value) { return DartUtilities::stringToDart(value); }
};

template<>
struct ToDartTraits<bool> {
    static Dart_Handle toDart(bool value) { return DartUtilities::boolToDart(value); }
};

template<>
struct ToDartTraits<int> {
    static Dart_Handle toDart(int value) { return DartUtilities::intToDart(value); }
};

template<>
struct ToDartTraits<unsigned> {
    static Dart_Handle toDart(unsigned value) { return DartUtilities::unsignedToDart(value); }
};

template<>
struct ToDartTraits<float> {
    static Dart_Handle toDart(float value) { return DartUtilities::doubleToDart(value); }
};

template<>
struct ToDartTraits<double> {
    static Dart_Handle toDart(double value) { return DartUtilities::doubleToDart(value); }
};

template<typename T>
static Dart_Handle vectorToDart(const Vector<T>& vector)
{
    Dart_Handle list = Dart_NewList(vector.size());
    if (Dart_IsError(list))
        return list;
    for (size_t i = 0; i < vector.size(); i++) {
        Dart_Handle element = ToDartTraits<T>::toDart(vector[i]);
        Dart_Handle result = Dart_ListSetAt(list, i, element);
        if (Dart_IsError(result))
            return result;
    }
    return list;
}

static Dart_Handle webGLExtensionToDart(WebGLExtension* extension)
{
    if (!extension)
        return Dart_Null();
    switch (extension->name()) {
    case WebGLLoseContextName:
        return DartWebGLLoseContext::toDart(static_cast<WebGLLoseContext*>(extension));
    case WebGLDrawBuffersName:
        return DartWebGLDrawBuffers::toDart(static_cast<WebGLDrawBuffers*>(extension));
    case ANGLEInstancedArraysName:
        return DartANGLEInstancedArrays::toDart(static_cast<ANGLEInstancedArrays*>(extension));
    case EXTFragDepthName:
        return DartEXTFragDepth::toDart(static_cast<EXTFragDepth*>(extension));
    case EXTTextureFilterAnisotropicName:
        return DartEXTTextureFilterAnisotropic::toDart(static_cast<EXTTextureFilterAnisotropic*>(extension));
    case OESStandardDerivativesName:
        return DartOESStandardDerivatives::toDart(static_cast<OESStandardDerivatives*>(extension));
    case OESTextureFloatName:
        return DartOESTextureFloat::toDart(static_cast<OESTextureFloat*>(extension));
    case OESTextureFloatLinearName:
        return DartOESTextureFloatLinear::toDart(static_cast<OESTextureFloatLinear*>(extension));
    case OESTextureHalfFloatName:
        return DartOESTextureHalfFloat::toDart(static_cast<OESTextureHalfFloat*>(extension));
    case OESTextureHalfFloatLinearName:
        return DartOESTextureHalfFloatLinear::toDart(static_cast<OESTextureHalfFloatLinear*>(extension));
    case OESVertexArrayObjectName:
        return DartOESVertexArrayObject::toDart(static_cast<OESVertexArrayObject*>(extension));
    case OESElementIndexUintName:
        return DartOESElementIndexUint::toDart(static_cast<OESElementIndexUint*>(extension));
    case WebGLDebugRendererInfoName:
        return DartWebGLDebugRendererInfo::toDart(static_cast<WebGLDebugRendererInfo*>(extension));
    case WebGLDebugShadersName:
        return DartWebGLDebugShaders::toDart(static_cast<WebGLDebugShaders*>(extension));
    case WebGLCompressedTextureATCName:
        return DartWebGLCompressedTextureATC::toDart(static_cast<WebGLCompressedTextureATC*>(extension));
    case WebGLCompressedTexturePVRTCName:
        return DartWebGLCompressedTexturePVRTC::toDart(static_cast<WebGLCompressedTexturePVRTC*>(extension));
    case WebGLCompressedTextureS3TCName:
        return DartWebGLCompressedTextureS3TC::toDart(static_cast<WebGLCompressedTextureS3TC*>(extension));
    case WebGLDepthTextureName:
        return DartWebGLDepthTexture::toDart(static_cast<WebGLDepthTexture*>(extension));
    default:
        ASSERT_NOT_REACHED();
    }

    ASSERT_NOT_REACHED();
    return Dart_Null();
}

static Dart_Handle webGLGetInfoToDart(const WebGLGetInfo& info)
{
    switch (info.getType()) {
    case WebGLGetInfo::kTypeBool:
        return DartUtilities::boolToDart(info.getBool());
    case WebGLGetInfo::kTypeBoolArray:
        return vectorToDart(info.getBoolArray());
    case WebGLGetInfo::kTypeFloat:
        return DartUtilities::doubleToDart(info.getFloat());
    case WebGLGetInfo::kTypeInt:
        return DartUtilities::intToDart(info.getInt());
    case WebGLGetInfo::kTypeNull:
        return Dart_Null();
    case WebGLGetInfo::kTypeString:
        return DartUtilities::stringToDart(info.getString());
    case WebGLGetInfo::kTypeUnsignedInt:
        return DartUtilities::unsignedToDart(info.getUnsignedInt());
    case WebGLGetInfo::kTypeWebGLBuffer:
        return DartWebGLBuffer::toDart(info.getWebGLBuffer());
    case WebGLGetInfo::kTypeWebGLFloatArray:
        return DartUtilities::arrayBufferViewToDart(info.getWebGLFloatArray());
    case WebGLGetInfo::kTypeWebGLFramebuffer:
        return DartWebGLFramebuffer::toDart(info.getWebGLFramebuffer());
    case WebGLGetInfo::kTypeWebGLIntArray:
        return DartUtilities::arrayBufferViewToDart(info.getWebGLIntArray());
    case WebGLGetInfo::kTypeWebGLObjectArray:
        // FIXME: implement WebGLObjectArray.
        return DART_UNIMPLEMENTED_EXCEPTION();
    case WebGLGetInfo::kTypeWebGLProgram:
        return DartWebGLProgram::toDart(info.getWebGLProgram());
    case WebGLGetInfo::kTypeWebGLRenderbuffer:
        return DartWebGLRenderbuffer::toDart(info.getWebGLRenderbuffer());
    case WebGLGetInfo::kTypeWebGLTexture:
        return DartWebGLTexture::toDart(info.getWebGLTexture());
    case WebGLGetInfo::kTypeWebGLUnsignedByteArray:
        return DartUtilities::arrayBufferViewToDart(info.getWebGLUnsignedByteArray());
    case WebGLGetInfo::kTypeWebGLUnsignedIntArray:
        return DartUtilities::arrayBufferViewToDart(info.getWebGLUnsignedIntArray());
    case WebGLGetInfo::kTypeWebGLVertexArrayObjectOES:
        return DartWebGLVertexArrayObjectOES::toDart(info.getWebGLVertexArrayObjectOES());
    }

    ASSERT_NOT_REACHED();
    return Dart_Null();
}

enum ObjectType {
    kBuffer, kRenderbuffer, kTexture, kVertexAttrib
};

static void getObjectParameter(Dart_NativeArguments args, ObjectType objectType)
{
    Dart_Handle exception = 0;
    {
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        int target = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;
        int pname = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;

        WebGLGetInfo info;
        switch (objectType) {
        case kBuffer:
            info = context->getBufferParameter(target, pname);
            break;
        case kRenderbuffer:
            info = context->getRenderbufferParameter(target, pname);
            break;
        case kTexture:
            info = context->getTexParameter(target, pname);
            break;
        case kVertexAttrib:
            // target => index
            info = context->getVertexAttrib(target, pname);
            break;
        default:
            notImplemented();
            break;
        }
        Dart_Handle result = webGLGetInfoToDart(info);
        if (!DartUtilities::checkResult(result, exception))
            goto fail;

        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void getBufferParameterCallback(Dart_NativeArguments args)
{
    getObjectParameter(args, kBuffer);
}

void getExtensionCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        DartStringAdapter name = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        WebGLExtension* extension = context->getExtension(name).get();
        Dart_Handle result = webGLExtensionToDart(extension);
        if (!DartUtilities::checkResult(result, exception))
            goto fail;
        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void getFramebufferAttachmentParameterCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        int target = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;
        int attachment = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;
        int pname = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 3), exception);
        if (exception)
            goto fail;

        WebGLGetInfo info = context->getFramebufferAttachmentParameter(target, attachment, pname);
        Dart_Handle result = webGLGetInfoToDart(info);
        if (!DartUtilities::checkResult(result, exception))
            goto fail;
        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void getParameterCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        int pname = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;

        WebGLGetInfo info = context->getParameter(pname);
        Dart_Handle result = webGLGetInfoToDart(info);
        if (!DartUtilities::checkResult(result, exception))
            goto fail;

        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void getProgramParameterCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        WebGLProgram* program = DartWebGLProgram::toNativeWithNullCheck(Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;
        int pname = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;

        WebGLGetInfo info = context->getProgramParameter(program, pname);
        Dart_Handle result = webGLGetInfoToDart(info);
        if (!DartUtilities::checkResult(result, exception))
            goto fail;

        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void getRenderbufferParameterCallback(Dart_NativeArguments args)
{
    getObjectParameter(args, kRenderbuffer);
}

void getShaderParameterCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        WebGLShader* shader = DartWebGLShader::toNativeWithNullCheck(Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;
        int pname = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;

        WebGLGetInfo info = context->getShaderParameter(shader, pname);
        Dart_Handle result = webGLGetInfoToDart(info);
        if (!DartUtilities::checkResult(result, exception))
            goto fail;

        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void getSupportedExtensionsCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        Nullable<Vector<String>> value = context->getSupportedExtensions();
        if (value.isNull()) {
            // Return null.
            return;
        }

        Dart_Handle result = vectorToDart(value.get());
        if (!DartUtilities::checkResult(result, exception))
            goto fail;

        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void getTexParameterCallback(Dart_NativeArguments args)
{
    getObjectParameter(args, kTexture);
}

void getUniformCallback(Dart_NativeArguments args)
{
    getObjectParameter(args, kVertexAttrib);
}

void getVertexAttribCallback(Dart_NativeArguments args)
{
    getObjectParameter(args, kVertexAttrib);
}

enum FunctionToCall {
    kUniform1v, kUniform2v, kUniform3v, kUniform4v,
    kVertexAttrib1v, kVertexAttrib2v, kVertexAttrib3v, kVertexAttrib4v
};

static inline bool isFunctionToCallForAttribute(FunctionToCall functionToCall)
{
    switch (functionToCall) {
    case kVertexAttrib1v:
    case kVertexAttrib2v:
    case kVertexAttrib3v:
    case kVertexAttrib4v:
        return true;
    default:
        break;
    }
    return false;
}

static void vertexAttribAndUniformHelperf(Dart_NativeArguments args, FunctionToCall functionToCall)
{
    Dart_Handle exception = 0;
    {
        // Forms:
        // * glUniform1fv(WebGLUniformLocation location, Array data);
        // * glUniform1fv(WebGLUniformLocation location, Float32Array data);
        // * glUniform2fv(WebGLUniformLocation location, Array data);
        // * glUniform2fv(WebGLUniformLocation location, Float32Array data);
        // * glUniform3fv(WebGLUniformLocation location, Array data);
        // * glUniform3fv(WebGLUniformLocation location, Float32Array data);
        // * glUniform4fv(WebGLUniformLocation location, Array data);
        // * glUniform4fv(WebGLUniformLocation location, Float32Array data);
        // * glVertexAttrib1fv(GLint index, Array data);
        // * glVertexAttrib1fv(GLint index, Float32Array data);
        // * glVertexAttrib2fv(GLint index, Array data);
        // * glVertexAttrib2fv(GLint index, Float32Array data);
        // * glVertexAttrib3fv(GLint index, Array data);
        // * glVertexAttrib3fv(GLint index, Float32Array data);
        // * glVertexAttrib4fv(GLint index, Array data);
        // * glVertexAttrib4fv(GLint index, Float32Array data);
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        int index = -1;
        WebGLUniformLocation* location = 0;

        if (isFunctionToCallForAttribute(functionToCall)) {
            int indexParam = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 1), exception);
            if (exception)
                goto fail;
            index = indexParam;
        } else {
            WebGLUniformLocation* locationParam = DartWebGLUniformLocation::toNativeWithNullCheck(Dart_GetNativeArgument(args, 1), exception);
            if (exception)
                goto fail;
            location = locationParam;
        }

        RefPtr<Float32Array> array = DartUtilities::dartToFloat32Array(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;

        switch (functionToCall) {
        case kUniform1v:
            context->uniform1fv(location, array.get());
            break;
        case kUniform2v:
            context->uniform2fv(location, array.get());
            break;
        case kUniform3v:
            context->uniform3fv(location, array.get());
            break;
        case kUniform4v:
            context->uniform4fv(location, array.get());
            break;
        case kVertexAttrib1v:
            context->vertexAttrib1fv(index, array.get());
            break;
        case kVertexAttrib2v:
            context->vertexAttrib2fv(index, array.get());
            break;
        case kVertexAttrib3v:
            context->vertexAttrib3fv(index, array.get());
            break;
        case kVertexAttrib4v:
            context->vertexAttrib4fv(index, array.get());
            break;
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void uniformHelperi(Dart_NativeArguments args, FunctionToCall functionToCall)
{
    Dart_Handle exception = 0;
    {
        // Forms:
        // * glUniform1iv(GLUniformLocation location, Array data);
        // * glUniform1iv(GLUniformLocation location, Int32Array data);
        // * glUniform2iv(GLUniformLocation location, Array data);
        // * glUniform2iv(GLUniformLocation location, Int32Array data);
        // * glUniform3iv(GLUniformLocation location, Array data);
        // * glUniform3iv(GLUniformLocation location, Int32Array data);
        // * glUniform4iv(GLUniformLocation location, Array data);
        // * glUniform4iv(GLUniformLocation location, Int32Array data);
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        WebGLUniformLocation* location = DartWebGLUniformLocation::toNativeWithNullCheck(Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;

        RefPtr<Int32Array> array = DartUtilities::dartToInt32Array(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;

        switch (functionToCall) {
        case kUniform1v:
            context->uniform1iv(location, array.get());
            break;
        case kUniform2v:
            context->uniform2iv(location, array.get());
            break;
        case kUniform3v:
            context->uniform3iv(location, array.get());
            break;
        case kUniform4v:
            context->uniform4iv(location, array.get());
            break;
        default:
            ASSERT_NOT_REACHED();
            break;
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void uniformMatrixHelper(Dart_NativeArguments args, int matrixSize)
{
    Dart_Handle exception = 0;
    {
        // Forms:
        // * glUniformMatrix2fv(GLint location, GLboolean transpose, Array data);
        // * glUniformMatrix2fv(GLint location, GLboolean transpose, Float32Array data);
        // * glUniformMatrix3fv(GLint location, GLboolean transpose, Array data);
        // * glUniformMatrix3fv(GLint location, GLboolean transpose, Float32Array data);
        // * glUniformMatrix4fv(GLint location, GLboolean transpose, Array data);
        // * glUniformMatrix4fv(GLint location, GLboolean transpose, Float32Array data);
        //
        WebGLRenderingContext* context = DartDOMWrapper::receiver<WebGLRenderingContext>(args);
        WebGLUniformLocation* location = DartWebGLUniformLocation::toNativeWithNullCheck(Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;
        bool transpose = DartUtilities::dartToBool(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;

        RefPtr<Float32Array> array = DartUtilities::dartToFloat32Array(Dart_GetNativeArgument(args, 3), exception);
        if (exception)
            goto fail;

        switch (matrixSize) {
        case 2:
            context->uniformMatrix2fv(location, transpose, array.get());
            break;
        case 3:
            context->uniformMatrix3fv(location, transpose, array.get());
            break;
        case 4:
            context->uniformMatrix4fv(location, transpose, array.get());
            break;
        default:
            ASSERT_NOT_REACHED();
            break;
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void uniform1fvCallback(Dart_NativeArguments args)
{
    vertexAttribAndUniformHelperf(args, kUniform1v);
}

void uniform1ivCallback(Dart_NativeArguments args)
{
    uniformHelperi(args, kUniform1v);
}

void uniform2fvCallback(Dart_NativeArguments args)
{
    vertexAttribAndUniformHelperf(args, kUniform2v);
}

void uniform2ivCallback(Dart_NativeArguments args)
{
    uniformHelperi(args, kUniform2v);
}

void uniform3fvCallback(Dart_NativeArguments args)
{
    vertexAttribAndUniformHelperf(args, kUniform3v);
}

void uniform3ivCallback(Dart_NativeArguments args)
{
    uniformHelperi(args, kUniform3v);
}

void uniform4fvCallback(Dart_NativeArguments args)
{
    vertexAttribAndUniformHelperf(args, kUniform4v);
}

void uniform4ivCallback(Dart_NativeArguments args)
{
    uniformHelperi(args, kUniform4v);
}

void uniformMatrix2fvCallback(Dart_NativeArguments args)
{
    uniformMatrixHelper(args, 2);
}

void uniformMatrix3fvCallback(Dart_NativeArguments args)
{
    uniformMatrixHelper(args, 3);
}

void uniformMatrix4fvCallback(Dart_NativeArguments args)
{
    uniformMatrixHelper(args, 4);
}

void vertexAttrib1fvCallback(Dart_NativeArguments args)
{
    vertexAttribAndUniformHelperf(args, kVertexAttrib1v);
}

void vertexAttrib2fvCallback(Dart_NativeArguments args)
{
    vertexAttribAndUniformHelperf(args, kVertexAttrib2v);
}

void vertexAttrib3fvCallback(Dart_NativeArguments args)
{
    vertexAttribAndUniformHelperf(args, kVertexAttrib3v);
}

void vertexAttrib4fvCallback(Dart_NativeArguments args)
{
    vertexAttribAndUniformHelperf(args, kVertexAttrib4v);
}

}

}
