/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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
#include "bindings/core/v8/V8WebGLRenderingContext.h"

#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/V8ANGLEInstancedArrays.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8EXTBlendMinMax.h"
#include "bindings/core/v8/V8EXTFragDepth.h"
#include "bindings/core/v8/V8EXTShaderTextureLOD.h"
#include "bindings/core/v8/V8EXTTextureFilterAnisotropic.h"
#include "bindings/core/v8/V8HTMLCanvasElement.h"
#include "bindings/core/v8/V8HTMLImageElement.h"
#include "bindings/core/v8/V8HTMLVideoElement.h"
#include "bindings/core/v8/V8HiddenValue.h"
#include "bindings/core/v8/V8ImageData.h"
#include "bindings/core/v8/V8OESElementIndexUint.h"
#include "bindings/core/v8/V8OESStandardDerivatives.h"
#include "bindings/core/v8/V8OESTextureFloat.h"
#include "bindings/core/v8/V8OESTextureFloatLinear.h"
#include "bindings/core/v8/V8OESTextureHalfFloat.h"
#include "bindings/core/v8/V8OESTextureHalfFloatLinear.h"
#include "bindings/core/v8/V8OESVertexArrayObject.h"
#include "bindings/core/v8/V8WebGLBuffer.h"
#include "bindings/core/v8/V8WebGLCompressedTextureATC.h"
#include "bindings/core/v8/V8WebGLCompressedTextureETC1.h"
#include "bindings/core/v8/V8WebGLCompressedTexturePVRTC.h"
#include "bindings/core/v8/V8WebGLCompressedTextureS3TC.h"
#include "bindings/core/v8/V8WebGLDebugRendererInfo.h"
#include "bindings/core/v8/V8WebGLDebugShaders.h"
#include "bindings/core/v8/V8WebGLDepthTexture.h"
#include "bindings/core/v8/V8WebGLDrawBuffers.h"
#include "bindings/core/v8/V8WebGLFramebuffer.h"
#include "bindings/core/v8/V8WebGLLoseContext.h"
#include "bindings/core/v8/V8WebGLProgram.h"
#include "bindings/core/v8/V8WebGLRenderbuffer.h"
#include "bindings/core/v8/V8WebGLShader.h"
#include "bindings/core/v8/V8WebGLTexture.h"
#include "bindings/core/v8/V8WebGLUniformLocation.h"
#include "bindings/core/v8/V8WebGLVertexArrayObjectOES.h"
#include "bindings/core/v8/custom/V8ArrayBufferViewCustom.h"
#include "bindings/core/v8/custom/V8Float32ArrayCustom.h"
#include "bindings/core/v8/custom/V8Int16ArrayCustom.h"
#include "bindings/core/v8/custom/V8Int32ArrayCustom.h"
#include "bindings/core/v8/custom/V8Int8ArrayCustom.h"
#include "bindings/core/v8/custom/V8Uint16ArrayCustom.h"
#include "bindings/core/v8/custom/V8Uint32ArrayCustom.h"
#include "bindings/core/v8/custom/V8Uint8ArrayCustom.h"
#include "core/dom/ExceptionCode.h"
#include "core/html/canvas/WebGLRenderingContext.h"
#include "platform/NotImplemented.h"
#include "wtf/FastMalloc.h"
#include <limits>

namespace blink {

// Allocates new storage via fastMalloc.
// Returns 0 if array failed to convert for any reason.
static float* jsArrayToFloatArray(v8::Handle<v8::Array> array, uint32_t len, ExceptionState& exceptionState)
{
    // Convert the data element-by-element.
    if (len > std::numeric_limits<uint32_t>::max() / sizeof(float)) {
        exceptionState.throwTypeError("Array length exceeds supported limit.");
        return 0;
    }
    float* data = static_cast<float*>(fastMalloc(len * sizeof(float)));

    for (uint32_t i = 0; i < len; i++) {
        v8::Local<v8::Value> val = array->Get(i);
        float value = toFloat(val, exceptionState);
        if (exceptionState.hadException()) {
            fastFree(data);
            return 0;
        }
        data[i] = value;
    }
    return data;
}

// Allocates new storage via fastMalloc.
// Returns 0 if array failed to convert for any reason.
static int* jsArrayToIntArray(v8::Handle<v8::Array> array, uint32_t len, ExceptionState& exceptionState)
{
    // Convert the data element-by-element.
    if (len > std::numeric_limits<uint32_t>::max() / sizeof(int)) {
        exceptionState.throwTypeError("Array length exceeds supported limit.");
        return 0;
    }
    int* data = static_cast<int*>(fastMalloc(len * sizeof(int)));

    for (uint32_t i = 0; i < len; i++) {
        v8::Local<v8::Value> val = array->Get(i);
        int ival = toInt32(val, exceptionState);
        if (exceptionState.hadException()) {
            fastFree(data);
            return 0;
        }
        data[i] = ival;
    }
    return data;
}

static v8::Handle<v8::Value> toV8Object(const WebGLGetInfo& args, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    switch (args.getType()) {
    case WebGLGetInfo::kTypeBool:
        return v8Boolean(args.getBool(), isolate);
    case WebGLGetInfo::kTypeBoolArray: {
        const Vector<bool>& value = args.getBoolArray();
        v8::Local<v8::Array> array = v8::Array::New(isolate, value.size());
        for (size_t ii = 0; ii < value.size(); ++ii)
            array->Set(v8::Integer::New(isolate, ii), v8Boolean(value[ii], isolate));
        return array;
    }
    case WebGLGetInfo::kTypeFloat:
        return v8::Number::New(isolate, args.getFloat());
    case WebGLGetInfo::kTypeInt:
        return v8::Integer::New(isolate, args.getInt());
    case WebGLGetInfo::kTypeNull:
        return v8::Null(isolate);
    case WebGLGetInfo::kTypeString:
        return v8String(isolate, args.getString());
    case WebGLGetInfo::kTypeUnsignedInt:
        return v8::Integer::NewFromUnsigned(isolate, args.getUnsignedInt());
    case WebGLGetInfo::kTypeWebGLBuffer:
        return toV8(args.getWebGLBuffer(), creationContext, isolate);
    case WebGLGetInfo::kTypeWebGLFloatArray:
        return toV8(args.getWebGLFloatArray(), creationContext, isolate);
    case WebGLGetInfo::kTypeWebGLFramebuffer:
        return toV8(args.getWebGLFramebuffer(), creationContext, isolate);
    case WebGLGetInfo::kTypeWebGLIntArray:
        return toV8(args.getWebGLIntArray(), creationContext, isolate);
    // FIXME: implement WebGLObjectArray
    // case WebGLGetInfo::kTypeWebGLObjectArray:
    case WebGLGetInfo::kTypeWebGLProgram:
        return toV8(args.getWebGLProgram(), creationContext, isolate);
    case WebGLGetInfo::kTypeWebGLRenderbuffer:
        return toV8(args.getWebGLRenderbuffer(), creationContext, isolate);
    case WebGLGetInfo::kTypeWebGLTexture:
        return toV8(args.getWebGLTexture(), creationContext, isolate);
    case WebGLGetInfo::kTypeWebGLUnsignedByteArray:
        return toV8(args.getWebGLUnsignedByteArray(), creationContext, isolate);
    case WebGLGetInfo::kTypeWebGLUnsignedIntArray:
        return toV8(args.getWebGLUnsignedIntArray(), creationContext, isolate);
    case WebGLGetInfo::kTypeWebGLVertexArrayObjectOES:
        return toV8(args.getWebGLVertexArrayObjectOES(), creationContext, isolate);
    default:
        notImplemented();
        return v8::Undefined(isolate);
    }
}

static v8::Handle<v8::Value> toV8Object(WebGLExtension* extension, v8::Handle<v8::Object> contextObject, v8::Isolate* isolate)
{
    if (!extension)
        return v8::Null(isolate);
    v8::Handle<v8::Value> extensionObject;
    const char* referenceName = 0;
    switch (extension->name()) {
    case ANGLEInstancedArraysName:
        extensionObject = toV8(static_cast<ANGLEInstancedArrays*>(extension), contextObject, isolate);
        referenceName = "angleInstancedArraysName";
        break;
    case EXTBlendMinMaxName:
        extensionObject = toV8(static_cast<EXTBlendMinMax*>(extension), contextObject, isolate);
        referenceName = "extBlendMinMaxName";
        break;
    case EXTFragDepthName:
        extensionObject = toV8(static_cast<EXTFragDepth*>(extension), contextObject, isolate);
        referenceName = "extFragDepthName";
        break;
    case EXTShaderTextureLODName:
        extensionObject = toV8(static_cast<EXTShaderTextureLOD*>(extension), contextObject, isolate);
        referenceName = "extShaderTextureLODName";
        break;
    case EXTTextureFilterAnisotropicName:
        extensionObject = toV8(static_cast<EXTTextureFilterAnisotropic*>(extension), contextObject, isolate);
        referenceName = "extTextureFilterAnisotropicName";
        break;
    case OESElementIndexUintName:
        extensionObject = toV8(static_cast<OESElementIndexUint*>(extension), contextObject, isolate);
        referenceName = "oesElementIndexUintName";
        break;
    case OESStandardDerivativesName:
        extensionObject = toV8(static_cast<OESStandardDerivatives*>(extension), contextObject, isolate);
        referenceName = "oesStandardDerivativesName";
        break;
    case OESTextureFloatName:
        extensionObject = toV8(static_cast<OESTextureFloat*>(extension), contextObject, isolate);
        referenceName = "oesTextureFloatName";
        break;
    case OESTextureFloatLinearName:
        extensionObject = toV8(static_cast<OESTextureFloatLinear*>(extension), contextObject, isolate);
        referenceName = "oesTextureFloatLinearName";
        break;
    case OESTextureHalfFloatName:
        extensionObject = toV8(static_cast<OESTextureHalfFloat*>(extension), contextObject, isolate);
        referenceName = "oesTextureHalfFloatName";
        break;
    case OESTextureHalfFloatLinearName:
        extensionObject = toV8(static_cast<OESTextureHalfFloatLinear*>(extension), contextObject, isolate);
        referenceName = "oesTextureHalfFloatLinearName";
        break;
    case OESVertexArrayObjectName:
        extensionObject = toV8(static_cast<OESVertexArrayObject*>(extension), contextObject, isolate);
        referenceName = "oesVertexArrayObjectName";
        break;
    case WebGLCompressedTextureATCName:
        extensionObject = toV8(static_cast<WebGLCompressedTextureATC*>(extension), contextObject, isolate);
        referenceName = "webGLCompressedTextureATCName";
        break;
    case WebGLCompressedTextureETC1Name:
        extensionObject = toV8(static_cast<WebGLCompressedTextureETC1*>(extension), contextObject, isolate);
        referenceName = "webGLCompressedTextureETC1Name";
        break;
    case WebGLCompressedTexturePVRTCName:
        extensionObject = toV8(static_cast<WebGLCompressedTexturePVRTC*>(extension), contextObject, isolate);
        referenceName = "webGLCompressedTexturePVRTCName";
        break;
    case WebGLCompressedTextureS3TCName:
        extensionObject = toV8(static_cast<WebGLCompressedTextureS3TC*>(extension), contextObject, isolate);
        referenceName = "webGLCompressedTextureS3TCName";
        break;
    case WebGLDebugRendererInfoName:
        extensionObject = toV8(static_cast<WebGLDebugRendererInfo*>(extension), contextObject, isolate);
        referenceName = "webGLDebugRendererInfoName";
        break;
    case WebGLDebugShadersName:
        extensionObject = toV8(static_cast<WebGLDebugShaders*>(extension), contextObject, isolate);
        referenceName = "webGLDebugShadersName";
        break;
    case WebGLDepthTextureName:
        extensionObject = toV8(static_cast<WebGLDepthTexture*>(extension), contextObject, isolate);
        referenceName = "webGLDepthTextureName";
        break;
    case WebGLDrawBuffersName:
        extensionObject = toV8(static_cast<WebGLDrawBuffers*>(extension), contextObject, isolate);
        referenceName = "webGLDrawBuffersName";
        break;
    case WebGLLoseContextName:
        extensionObject = toV8(static_cast<WebGLLoseContext*>(extension), contextObject, isolate);
        referenceName = "webGLLoseContextName";
        break;
    case WebGLExtensionNameCount:
        notImplemented();
        return v8::Undefined(isolate);
    }
    ASSERT(!extensionObject.IsEmpty());
    V8HiddenValue::setHiddenValue(isolate, contextObject, v8AtomicString(isolate, referenceName), extensionObject);
    return extensionObject;
}

enum ObjectType {
    kBuffer, kRenderbuffer, kTexture, kVertexAttrib
};

static void getObjectParameter(const v8::FunctionCallbackInfo<v8::Value>& info, ObjectType objectType, ExceptionState& exceptionState)
{
    if (info.Length() != 2) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(2, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    WebGLRenderingContext* context = V8WebGLRenderingContext::toNative(info.Holder());
    unsigned target;
    unsigned pname;
    {
        v8::TryCatch block;
        V8RethrowTryCatchScope rethrow(block);
        TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(target, toUInt32(info[0], exceptionState), exceptionState);
        TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(pname, toUInt32(info[1], exceptionState), exceptionState);
    }
    WebGLGetInfo args;
    switch (objectType) {
    case kBuffer:
        args = context->getBufferParameter(target, pname);
        break;
    case kRenderbuffer:
        args = context->getRenderbufferParameter(target, pname);
        break;
    case kTexture:
        args = context->getTexParameter(target, pname);
        break;
    case kVertexAttrib:
        // target => index
        args = context->getVertexAttrib(target, pname);
        break;
    default:
        notImplemented();
        break;
    }
    v8SetReturnValue(info, toV8Object(args, info.Holder(), info.GetIsolate()));
}

static WebGLUniformLocation* toWebGLUniformLocation(v8::Handle<v8::Value> value, v8::Isolate* isolate)
{
    return V8WebGLUniformLocation::toNativeWithTypeCheck(isolate, value);
}

void V8WebGLRenderingContext::getBufferParameterMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getBufferParameter", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    getObjectParameter(info, kBuffer, exceptionState);
}

void V8WebGLRenderingContext::getExtensionMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getExtension", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    WebGLRenderingContext* impl = V8WebGLRenderingContext::toNative(info.Holder());
    if (info.Length() < 1) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(1, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }
    TOSTRING_VOID(V8StringResource<>, name, info[0]);
    RefPtrWillBeRawPtr<WebGLExtension> extension(impl->getExtension(name));
    v8SetReturnValue(info, toV8Object(extension.get(), info.Holder(), info.GetIsolate()));
}

void V8WebGLRenderingContext::getFramebufferAttachmentParameterMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getFramebufferAttachmentParameter", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    if (info.Length() != 3) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(3, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    WebGLRenderingContext* context = V8WebGLRenderingContext::toNative(info.Holder());
    unsigned target;
    unsigned attachment;
    unsigned pname;
    {
        v8::TryCatch block;
        V8RethrowTryCatchScope rethrow(block);
        TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(target, toUInt32(info[0], exceptionState), exceptionState);
        TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(attachment, toUInt32(info[1], exceptionState), exceptionState);
        TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(pname, toUInt32(info[2], exceptionState), exceptionState);
    }
    WebGLGetInfo args = context->getFramebufferAttachmentParameter(target, attachment, pname);
    v8SetReturnValue(info, toV8Object(args, info.Holder(), info.GetIsolate()));
}

void V8WebGLRenderingContext::getParameterMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getParameter", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    if (info.Length() != 1) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(1, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    WebGLRenderingContext* context = V8WebGLRenderingContext::toNative(info.Holder());
    unsigned pname;
    {
        v8::TryCatch block;
        V8RethrowTryCatchScope rethrow(block);
        TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(pname, toUInt32(info[0], exceptionState), exceptionState);
    }
    WebGLGetInfo args = context->getParameter(pname);
    v8SetReturnValue(info, toV8Object(args, info.Holder(), info.GetIsolate()));
}

void V8WebGLRenderingContext::getProgramParameterMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getProgramParameter", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    if (info.Length() != 2) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(2, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    WebGLRenderingContext* context = V8WebGLRenderingContext::toNative(info.Holder());
    WebGLProgram* program;
    unsigned pname;
    {
        v8::TryCatch block;
        V8RethrowTryCatchScope rethrow(block);
        if (info.Length() > 0 && !isUndefinedOrNull(info[0]) && !V8WebGLProgram::hasInstance(info[0], info.GetIsolate())) {
            exceptionState.throwTypeError("parameter 1 is not of type 'WebGLProgram'.");
            exceptionState.throwIfNeeded();
            return;
        }
        TONATIVE_VOID_INTERNAL(program, V8WebGLProgram::toNativeWithTypeCheck(info.GetIsolate(), info[0]));
        TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(pname, toUInt32(info[1], exceptionState), exceptionState);
    }
    WebGLGetInfo args = context->getProgramParameter(program, pname);
    v8SetReturnValue(info, toV8Object(args, info.Holder(), info.GetIsolate()));
}

void V8WebGLRenderingContext::getRenderbufferParameterMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getRenderbufferParameter", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    getObjectParameter(info, kRenderbuffer, exceptionState);
}

void V8WebGLRenderingContext::getShaderParameterMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getShaderParameter", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    if (info.Length() != 2) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(2, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    WebGLRenderingContext* context = V8WebGLRenderingContext::toNative(info.Holder());
    WebGLShader* shader;
    unsigned pname;
    {
        v8::TryCatch block;
        V8RethrowTryCatchScope rethrow(block);
        if (info.Length() > 0 && !isUndefinedOrNull(info[0]) && !V8WebGLShader::hasInstance(info[0], info.GetIsolate())) {
            exceptionState.throwTypeError("parameter 1 is not of type 'WebGLShader'.");
            exceptionState.throwIfNeeded();
            return;
        }
        TONATIVE_VOID_INTERNAL(shader, V8WebGLShader::toNativeWithTypeCheck(info.GetIsolate(), info[0]));
        TONATIVE_VOID_EXCEPTIONSTATE_INTERNAL(pname, toUInt32(info[1], exceptionState), exceptionState);
    }
    WebGLGetInfo args = context->getShaderParameter(shader, pname);
    v8SetReturnValue(info, toV8Object(args, info.Holder(), info.GetIsolate()));
}

void V8WebGLRenderingContext::getTexParameterMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getTexParameter", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    getObjectParameter(info, kTexture, exceptionState);
}

void V8WebGLRenderingContext::getUniformMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getUniform", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    if (info.Length() != 2) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(2, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    WebGLRenderingContext* context = V8WebGLRenderingContext::toNative(info.Holder());
    WebGLProgram* program;
    WebGLUniformLocation* location;
    {
        v8::TryCatch block;
        V8RethrowTryCatchScope rethrow(block);
        if (info.Length() > 0 && !isUndefinedOrNull(info[0]) && !V8WebGLProgram::hasInstance(info[0], info.GetIsolate())) {
            V8ThrowException::throwTypeError(ExceptionMessages::failedToExecute("getUniform", "WebGLRenderingContext", "parameter 1 is not of type 'WebGLProgram'."), info.GetIsolate());
            return;
        }
        TONATIVE_VOID_INTERNAL(program, V8WebGLProgram::toNativeWithTypeCheck(info.GetIsolate(), info[0]));
        if (info.Length() > 1 && !isUndefinedOrNull(info[1]) && !V8WebGLUniformLocation::hasInstance(info[1], info.GetIsolate())) {
            V8ThrowException::throwTypeError(ExceptionMessages::failedToExecute("getUniform", "WebGLRenderingContext", "parameter 2 is not of type 'WebGLUniformLocation'."), info.GetIsolate());
            return;
        }
        TONATIVE_VOID_INTERNAL(location, V8WebGLUniformLocation::toNativeWithTypeCheck(info.GetIsolate(), info[1]));
    }
    WebGLGetInfo args = context->getUniform(program, location);
    v8SetReturnValue(info, toV8Object(args, info.Holder(), info.GetIsolate()));
}

void V8WebGLRenderingContext::getVertexAttribMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "getVertexAttrib", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    getObjectParameter(info, kVertexAttrib, exceptionState);
}

enum FunctionToCall {
    kUniform1v, kUniform2v, kUniform3v, kUniform4v,
    kVertexAttrib1v, kVertexAttrib2v, kVertexAttrib3v, kVertexAttrib4v
};

bool isFunctionToCallForAttribute(FunctionToCall functionToCall)
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

static void vertexAttribAndUniformHelperf(const v8::FunctionCallbackInfo<v8::Value>& info, FunctionToCall functionToCall, ExceptionState& exceptionState)
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

    if (info.Length() != 2) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(2, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    int index = -1;
    WebGLUniformLocation* location = 0;

    if (isFunctionToCallForAttribute(functionToCall)) {
        index = toInt32(info[0], exceptionState);
        if (exceptionState.throwIfNeeded())
            return;
    } else {
        const int uniformLocationArgumentIndex = 0;
        if (info.Length() > 0 && !isUndefinedOrNull(info[uniformLocationArgumentIndex]) && !V8WebGLUniformLocation::hasInstance(info[uniformLocationArgumentIndex], info.GetIsolate())) {
            exceptionState.throwTypeError(ExceptionMessages::argumentNullOrIncorrectType(uniformLocationArgumentIndex + 1, "WebGLUniformLocation"));
            exceptionState.throwIfNeeded();
            return;
        }
        location = toWebGLUniformLocation(info[uniformLocationArgumentIndex], info.GetIsolate());
    }

    WebGLRenderingContext* context = V8WebGLRenderingContext::toNative(info.Holder());

    const int indexArrayArgument = 1;
    if (V8Float32Array::hasInstance(info[indexArrayArgument], info.GetIsolate())) {
        Float32Array* array = V8Float32Array::toNative(info[indexArrayArgument]->ToObject());
        ASSERT(array);
        switch (functionToCall) {
        case kUniform1v: context->uniform1fv(location, array); break;
        case kUniform2v: context->uniform2fv(location, array); break;
        case kUniform3v: context->uniform3fv(location, array); break;
        case kUniform4v: context->uniform4fv(location, array); break;
        case kVertexAttrib1v: context->vertexAttrib1fv(index, array); break;
        case kVertexAttrib2v: context->vertexAttrib2fv(index, array); break;
        case kVertexAttrib3v: context->vertexAttrib3fv(index, array); break;
        case kVertexAttrib4v: context->vertexAttrib4fv(index, array); break;
        default: ASSERT_NOT_REACHED(); break;
        }
        return;
    }

    if (info[indexArrayArgument].IsEmpty() || !info[indexArrayArgument]->IsArray()) {
        exceptionState.throwTypeError(ExceptionMessages::argumentNullOrIncorrectType(indexArrayArgument + 1, "Array"));
        exceptionState.throwIfNeeded();
        return;
    }
    v8::Handle<v8::Array> array = v8::Local<v8::Array>::Cast(info[1]);
    uint32_t len = array->Length();
    float* data = jsArrayToFloatArray(array, len, exceptionState);
    if (exceptionState.throwIfNeeded())
        return;
    if (!data) {
        // FIXME: consider different / better exception type.
        exceptionState.throwDOMException(SyntaxError, "Failed to convert array argument");
        exceptionState.throwIfNeeded();
        return;
    }
    switch (functionToCall) {
    case kUniform1v: context->uniform1fv(location, data, len); break;
    case kUniform2v: context->uniform2fv(location, data, len); break;
    case kUniform3v: context->uniform3fv(location, data, len); break;
    case kUniform4v: context->uniform4fv(location, data, len); break;
    case kVertexAttrib1v: context->vertexAttrib1fv(index, data, len); break;
    case kVertexAttrib2v: context->vertexAttrib2fv(index, data, len); break;
    case kVertexAttrib3v: context->vertexAttrib3fv(index, data, len); break;
    case kVertexAttrib4v: context->vertexAttrib4fv(index, data, len); break;
    default: ASSERT_NOT_REACHED(); break;
    }
    fastFree(data);
}

static void uniformHelperi(const v8::FunctionCallbackInfo<v8::Value>& info, FunctionToCall functionToCall, ExceptionState& exceptionState)
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

    if (info.Length() != 2) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(2, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    const int uniformLocationArgumentIndex = 0;
    WebGLRenderingContext* context = V8WebGLRenderingContext::toNative(info.Holder());
    if (info.Length() > 0 && !isUndefinedOrNull(info[uniformLocationArgumentIndex]) && !V8WebGLUniformLocation::hasInstance(info[uniformLocationArgumentIndex], info.GetIsolate())) {
        exceptionState.throwTypeError(ExceptionMessages::argumentNullOrIncorrectType(uniformLocationArgumentIndex + 1, "WebGLUniformLocation"));
        exceptionState.throwIfNeeded();
        return;
    }
    WebGLUniformLocation* location = toWebGLUniformLocation(info[uniformLocationArgumentIndex], info.GetIsolate());

    const int indexArrayArgumentIndex = 1;
    if (V8Int32Array::hasInstance(info[indexArrayArgumentIndex], info.GetIsolate())) {
        Int32Array* array = V8Int32Array::toNative(info[indexArrayArgumentIndex]->ToObject());
        ASSERT(array);
        switch (functionToCall) {
        case kUniform1v: context->uniform1iv(location, array); break;
        case kUniform2v: context->uniform2iv(location, array); break;
        case kUniform3v: context->uniform3iv(location, array); break;
        case kUniform4v: context->uniform4iv(location, array); break;
        default: ASSERT_NOT_REACHED(); break;
        }
        return;
    }

    if (info[indexArrayArgumentIndex].IsEmpty() || !info[indexArrayArgumentIndex]->IsArray()) {
        exceptionState.throwTypeError(ExceptionMessages::argumentNullOrIncorrectType(indexArrayArgumentIndex + 1, "Array"));
        exceptionState.throwIfNeeded();
        return;
    }
    v8::Handle<v8::Array> array = v8::Local<v8::Array>::Cast(info[indexArrayArgumentIndex]);
    uint32_t len = array->Length();
    int* data = jsArrayToIntArray(array, len, exceptionState);
    if (exceptionState.throwIfNeeded())
        return;
    if (!data) {
        // FIXME: consider different / better exception type.
        exceptionState.throwDOMException(SyntaxError, "Failed to convert array argument");
        exceptionState.throwIfNeeded();
        return;
    }
    switch (functionToCall) {
    case kUniform1v: context->uniform1iv(location, data, len); break;
    case kUniform2v: context->uniform2iv(location, data, len); break;
    case kUniform3v: context->uniform3iv(location, data, len); break;
    case kUniform4v: context->uniform4iv(location, data, len); break;
    default: ASSERT_NOT_REACHED(); break;
    }
    fastFree(data);
}

void V8WebGLRenderingContext::uniform1fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniform1fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    vertexAttribAndUniformHelperf(info, kUniform1v, exceptionState);
}

void V8WebGLRenderingContext::uniform1ivMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniform1iv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    uniformHelperi(info, kUniform1v, exceptionState);
}

void V8WebGLRenderingContext::uniform2fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniform2fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    vertexAttribAndUniformHelperf(info, kUniform2v, exceptionState);
}

void V8WebGLRenderingContext::uniform2ivMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniform2iv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    uniformHelperi(info, kUniform2v, exceptionState);
}

void V8WebGLRenderingContext::uniform3fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniform3fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    vertexAttribAndUniformHelperf(info, kUniform3v, exceptionState);
}

void V8WebGLRenderingContext::uniform3ivMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniform3iv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    uniformHelperi(info, kUniform3v, exceptionState);
}

void V8WebGLRenderingContext::uniform4fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniform4fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    vertexAttribAndUniformHelperf(info, kUniform4v, exceptionState);
}

void V8WebGLRenderingContext::uniform4ivMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniform4iv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    uniformHelperi(info, kUniform4v, exceptionState);
}

static void uniformMatrixHelper(const v8::FunctionCallbackInfo<v8::Value>& info, int matrixSize, ExceptionState& exceptionState)
{
    // Forms:
    // * glUniformMatrix2fv(GLint location, GLboolean transpose, Array data);
    // * glUniformMatrix2fv(GLint location, GLboolean transpose, Float32Array data);
    // * glUniformMatrix3fv(GLint location, GLboolean transpose, Array data);
    // * glUniformMatrix3fv(GLint location, GLboolean transpose, Float32Array data);
    // * glUniformMatrix4fv(GLint location, GLboolean transpose, Array data);
    // * glUniformMatrix4fv(GLint location, GLboolean transpose, Float32Array data);
    //
    // FIXME: need to change to accept Float32Array as well.
    if (info.Length() != 3) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(3, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    WebGLRenderingContext* context = V8WebGLRenderingContext::toNative(info.Holder());

    const int uniformLocationArgumentIndex = 0;
    if (info.Length() > 0 && !isUndefinedOrNull(info[uniformLocationArgumentIndex]) && !V8WebGLUniformLocation::hasInstance(info[uniformLocationArgumentIndex], info.GetIsolate())) {
        exceptionState.throwTypeError(ExceptionMessages::argumentNullOrIncorrectType(uniformLocationArgumentIndex + 1, "WebGLUniformLocation"));
        exceptionState.throwIfNeeded();
        return;
    }
    WebGLUniformLocation* location = toWebGLUniformLocation(info[uniformLocationArgumentIndex], info.GetIsolate());

    bool transpose = info[1]->BooleanValue();
    const int arrayArgumentIndex = 2;
    if (V8Float32Array::hasInstance(info[arrayArgumentIndex], info.GetIsolate())) {
        Float32Array* array = V8Float32Array::toNative(info[arrayArgumentIndex]->ToObject());
        ASSERT(array);
        switch (matrixSize) {
        case 2: context->uniformMatrix2fv(location, transpose, array); break;
        case 3: context->uniformMatrix3fv(location, transpose, array); break;
        case 4: context->uniformMatrix4fv(location, transpose, array); break;
        default: ASSERT_NOT_REACHED(); break;
        }
        return;
    }

    if (info[arrayArgumentIndex].IsEmpty() || !info[arrayArgumentIndex]->IsArray()) {
        exceptionState.throwTypeError(ExceptionMessages::argumentNullOrIncorrectType(arrayArgumentIndex + 1, "Array"));
        exceptionState.throwIfNeeded();
        return;
    }
    v8::Handle<v8::Array> array = v8::Local<v8::Array>::Cast(info[2]);
    uint32_t len = array->Length();
    float* data = jsArrayToFloatArray(array, len, exceptionState);
    if (exceptionState.throwIfNeeded())
        return;
    if (!data) {
        // FIXME: consider different / better exception type.
        exceptionState.throwDOMException(SyntaxError, "failed to convert Array value");
        exceptionState.throwIfNeeded();
        return;
    }
    switch (matrixSize) {
    case 2: context->uniformMatrix2fv(location, transpose, data, len); break;
    case 3: context->uniformMatrix3fv(location, transpose, data, len); break;
    case 4: context->uniformMatrix4fv(location, transpose, data, len); break;
    default: ASSERT_NOT_REACHED(); break;
    }
    fastFree(data);
}

void V8WebGLRenderingContext::uniformMatrix2fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniformMatrix2fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    uniformMatrixHelper(info, 2, exceptionState);
}

void V8WebGLRenderingContext::uniformMatrix3fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniformMatrix3fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    uniformMatrixHelper(info, 3, exceptionState);
}

void V8WebGLRenderingContext::uniformMatrix4fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "uniformMatrix4fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    uniformMatrixHelper(info, 4, exceptionState);
}

void V8WebGLRenderingContext::vertexAttrib1fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "vertexAttrib1fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    vertexAttribAndUniformHelperf(info, kVertexAttrib1v, exceptionState);
}

void V8WebGLRenderingContext::vertexAttrib2fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "vertexAttrib2fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    vertexAttribAndUniformHelperf(info, kVertexAttrib2v, exceptionState);
}

void V8WebGLRenderingContext::vertexAttrib3fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "vertexAttrib3fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    vertexAttribAndUniformHelperf(info, kVertexAttrib3v, exceptionState);
}

void V8WebGLRenderingContext::vertexAttrib4fvMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "vertexAttrib4fv", "WebGLRenderingContext", info.Holder(), info.GetIsolate());
    vertexAttribAndUniformHelperf(info, kVertexAttrib4v, exceptionState);
}

} // namespace blink
