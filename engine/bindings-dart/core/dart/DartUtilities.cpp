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
#include "bindings/core/dart/DartUtilities.h"

#if OS(ANDROID)
#include <sys/system_properties.h>
#endif

#include "core/FetchInitiatorTypeNames.h"
#include "bindings/core/dart/DartBlob.h"
#include "bindings/core/dart/DartController.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartHTMLElement.h"
#include "bindings/core/dart/DartImageData.h"
#include "bindings/core/dart/DartMessagePort.h"
#include "bindings/core/dart/DartScriptDebugServer.h"
#include "bindings/core/dart/DartScriptPromise.h"
#include "bindings/core/dart/DartScriptState.h"
#include "bindings/core/dart/V8Converter.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/SerializedScriptValue.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8ExceptionState.h"
#include "bindings/core/v8/V8PerIsolateData.h"
#include "bindings/modules/dart/DartIDBKeyRange.h"
#include "core/dom/Document.h"
#include "core/events/ErrorEvent.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/html/canvas/DataView.h"
#include "core/inspector/ScriptArguments.h"
#include "core/inspector/ScriptCallStack.h"
#include "core/loader/FrameLoader.h"
#include "modules/webdatabase/sqlite/SQLValue.h"
#include "platform/SharedBuffer.h"
#include "platform/network/ResourceRequest.h"

#include "wtf/ArrayBufferView.h"
#include "wtf/Float32Array.h"
#include "wtf/Float64Array.h"
#include "wtf/Int16Array.h"
#include "wtf/Int32Array.h"
#include "wtf/Int8Array.h"
#include "wtf/RefCounted.h"
#include "wtf/Uint16Array.h"
#include "wtf/Uint32Array.h"
#include "wtf/Uint8Array.h"
#include "wtf/Uint8ClampedArray.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"

namespace blink {

// FIXMEDART: Why aren't these being linked into webkit_unit_tests?
class GarbageCollectedScriptWrappable;
class RefCountedScriptWrappable;
template<>
Dart_Handle toDartNoInline(blink::GarbageCollectedScriptWrappable* impl, DartDOMData* domData) { return 0; }
template<>
Dart_Handle toDartNoInline(blink::RefCountedScriptWrappable* impl, DartDOMData* domData) { return 0; }

V8Scope::V8Scope(DartDOMData* dartDOMData, v8::Handle<v8::Context> context)
    : m_v8Isolate(v8::Isolate::GetCurrent())
    , m_dartDOMData(dartDOMData)
    , m_handleScope(m_v8Isolate)
    , m_contextScope(context)
    , m_recursionScope(m_v8Isolate, DartUtilities::scriptExecutionContext())
{
    if (m_dartDOMData)
        (*m_dartDOMData->recursion())++;
}

V8Scope::V8Scope(DartDOMData* dartDOMData)
    : m_v8Isolate(v8::Isolate::GetCurrent())
    , m_dartDOMData(dartDOMData)
    , m_handleScope(m_v8Isolate)
    , m_contextScope(DartUtilities::currentV8Context())
    , m_recursionScope(m_v8Isolate, DartUtilities::scriptExecutionContext())
{
    if (m_dartDOMData)
        (*m_dartDOMData->recursion())++;
}

V8Scope::~V8Scope()
{
    if (m_dartDOMData)
        (*m_dartDOMData->recursion())--;
}

DartStringPeer* DartStringPeer::nullString()
{
    DEFINE_STATIC_LOCAL(DartStringPeer, empty, ());
    return &empty;
}

DartStringPeer* DartStringPeer::emptyString()
{
    DEFINE_STATIC_LOCAL(DartStringPeer, empty, (StringImpl::empty()));
    return &empty;
}


static void stringFinalizer(void* peer)
{
    ASSERT(reinterpret_cast<DartStringPeer*>(peer) != DartStringPeer::nullString());
    delete reinterpret_cast<DartStringPeer*>(peer);
}

template <typename T> DartStringPeer* convertAndExternalize(Dart_Handle string, intptr_t length)
{
    if (!length)
        return new DartStringPeer(StringImpl::empty());
#ifndef NDEBUG
    {
        intptr_t storageSize = 0;
        Dart_StringStorageSize(string, &storageSize);
        ASSERT(length * intptr_t(sizeof(T)) == storageSize);
    }
#endif
    T* buffer = 0;
    DartStringPeer* peer = new DartStringPeer(StringImpl::createUninitialized(length, buffer));
    Dart_Handle ALLOW_UNUSED r = Dart_MakeExternalString(string, buffer, length * sizeof(T), peer, stringFinalizer);
    ASSERT(!Dart_IsError(r));
    return peer;
}

DartStringPeer* DartUtilities::toStringImpl(Dart_Handle object, intptr_t charsize, intptr_t strlength)
{
    ASSERT(Dart_IsString(object) && !Dart_IsExternalString(object));
    return (charsize == 1) ? convertAndExternalize<LChar>(object, strlength) : convertAndExternalize<UChar>(object, strlength);
}


Dart_Handle DartUtilities::stringImplToDartString(StringImpl* stringImpl)
{
    if (!stringImpl) {
        DartDOMData* domData = DartDOMData::current();
        return domData->emptyString();
    }

    DartStringPeer* peer = new DartStringPeer(stringImpl);
    if (stringImpl->is8Bit()) {
        // FIXME: maybe it makes sense only externalize strings longer than certain threshold, such as 5 symbols.
        return Dart_NewExternalLatin1String(reinterpret_cast<const uint8_t*>(stringImpl->characters8()),
            stringImpl->length(), peer, stringFinalizer);
    } else {
        // FIXME: maybe it makes sense only externalize strings longer than certain threshold, such as 5 symbols.
        return Dart_NewExternalUTF16String(reinterpret_cast<const uint16_t*>(stringImpl->characters16()),
            stringImpl->length(), peer, stringFinalizer);
    }
}

Dart_Handle DartUtilities::stringToDartString(const String& str)
{
    return stringImplToDartString(str.impl());
}

Dart_Handle DartUtilities::stringToDartString(const AtomicString& str)
{
    return stringImplToDartString(str.impl());
}


Dart_Handle DartUtilities::safeStringImplToDartString(StringImpl* stringImpl)
{
    if (!stringImpl) {
        DartDOMData* domData = DartDOMData::current();
        return domData->emptyString();
    }

    if (stringImpl->is8Bit()) {
        return Dart_NewStringFromUTF8(
            reinterpret_cast<const uint8_t*>(stringImpl->characters8()),
            stringImpl->length());
    } else {
        return Dart_NewStringFromUTF16(
            reinterpret_cast<const uint16_t*>(stringImpl->characters16()),
            stringImpl->length());
    }
}

Dart_Handle DartUtilities::safeStringToDartString(const String& str)
{
    return safeStringImplToDartString(str.impl());
}

Dart_Handle DartUtilities::safeStringToDartString(const AtomicString& str)
{
    return safeStringImplToDartString(str.impl());
}

template <typename Trait>
typename Trait::nativeType convert(Dart_Handle object, Dart_Handle& exception)
{
    typename Trait::nativeType value;
    Dart_Handle result = Trait::convert(object, &value);
    if (Dart_IsError(result)) {
        exception = Dart_NewStringFromCString(Dart_GetError(result));
        return typename Trait::nativeType();
    }
    return value;
}

struct IntegerTrait {
    typedef int64_t nativeType;
    static Dart_Handle convert(Dart_Handle object, int64_t* value)
    {
        return Dart_IntegerToInt64(object, value);
        // FIXME: support bigints.
    }
};

int64_t DartUtilities::toInteger(Dart_Handle object, Dart_Handle& exception)
{
    return convert<IntegerTrait>(object, exception);
}

String DartUtilities::toString(Dart_Handle object)
{
    Dart_Handle exception = 0;
    String string = dartToString(object, exception);
    ASSERT(!exception);
    return string;
}

struct DoubleTrait {
    typedef double nativeType;
    static Dart_Handle convert(Dart_Handle object, double* value)
    {
        if (Dart_IsDouble(object))
            return Dart_DoubleValue(object, value);

        if (Dart_IsInteger(object)) {
            int64_t v = 0;
            Dart_Handle result = Dart_IntegerToInt64(object, &v);
            if (!Dart_IsError(result)) {
                *value = static_cast<double>(v);
                return result;
            }
        }

        if (Dart_IsNumber(object)) {
            object = Dart_Invoke(object, Dart_NewStringFromCString("toDouble"), 0, 0);
            if (Dart_IsError(object))
                return object;
        }

        // For non-Number objects, use the error message returned by Dart_DoubleValue.
        return Dart_DoubleValue(object, value);
    }
};

double DartUtilities::dartToDouble(Dart_Handle object, Dart_Handle& exception)
{
    return convert<DoubleTrait>(object, exception);
}

struct BoolTrait {
    typedef bool nativeType;
    static Dart_Handle convert(Dart_Handle object, bool* value)
    {
        if (Dart_IsNull(object)) {
            *value = false;
            return Dart_Null();
        }
        return Dart_BooleanValue(object, value);
    }
};

bool DartUtilities::dartToBool(Dart_Handle object, Dart_Handle& exception)
{
    return convert<BoolTrait>(object, exception);
}

DartStringAdapter DartUtilities::dartToStringImpl(Dart_Handle object, Dart_Handle& exception, bool autoDartScope)
{
    if (!Dart_IsError(object) && !Dart_IsNull(object)) {
        ASSERT(Dart_IsString(object) && !Dart_IsExternalString(object));
        intptr_t charsize = Dart_IsStringLatin1(object) ? 1 : 2;
        intptr_t strlength;
        Dart_StringLength(object, &strlength);
        if (autoDartScope)
            return DartStringAdapter(toStringImpl(object, charsize, strlength));
        DartApiScope apiScope;
        return DartStringAdapter(toStringImpl(object, charsize, strlength));
    }
    if (!autoDartScope) {
        DartApiScope apiScope;
        DartDOMData* domData = DartDOMData::current();
        Dart_Handle excp = Dart_NewStringFromCString("String expected");
        Dart_SetPersistentHandle(domData->currentException(), excp);
        exception = domData->currentException();
    } else {
        exception = Dart_NewStringFromCString("String expected");
    }
    return DartStringAdapter(DartStringPeer::nullString());
}

void DartUtilities::extractMapElements(Dart_Handle map, Dart_Handle& exception, HashMap<String, Dart_Handle>& elements)
{
    ASSERT(elements.isEmpty());
    Dart_Handle list = DartUtilities::invokeUtilsMethod("convertMapToList", 1, &map);
    if (!DartUtilities::checkResult(list, exception))
        return;
    ASSERT(Dart_IsList(list));

    intptr_t length = 0;
    Dart_ListLength(list, &length);
    ASSERT(length % 2 == 0);

    for (intptr_t i = 0; i < length; i += 2) {
        Dart_Handle key = Dart_ListGetAt(list, i);
        ASSERT(!Dart_IsError(key) && Dart_IsString(key));
        Dart_Handle value = Dart_ListGetAt(list, i+1);
        ASSERT(!Dart_IsError(value));
        String keyString = DartUtilities::dartToString(key, exception);
        if (exception)
            return;
        elements.add(keyString, value);
    }
}

Dart_Handle DartUtilities::toList(const Vector<Dart_Handle>& elements, Dart_Handle& exception)
{
    Dart_Handle ret = Dart_NewList(elements.size());
    if (Dart_IsError(ret)) {
        exception = ret;
        return Dart_Null();
    }
    for (size_t i = 0; i < elements.size(); i++) {
        Dart_ListSetAt(ret, i, elements[i]);
    }
    return ret;
}

void DartUtilities::extractListElements(Dart_Handle list, Dart_Handle& exception, Vector<Dart_Handle>& elements)
{
    ASSERT(elements.isEmpty());
    list = DartUtilities::invokeUtilsMethod("convertToList", 1, &list);
    if (!DartUtilities::checkResult(list, exception))
        return;
    ASSERT(Dart_IsList(list));

    intptr_t length = 0;
    Dart_ListLength(list, &length);
    elements.reserveCapacity(length);
    for (intptr_t i = 0; i < length; i++) {
        Dart_Handle element = Dart_ListGetAt(list, i);
        ASSERT(!Dart_IsError(element));
        elements.append(element);
    }
}

v8::Local<v8::Context> DartUtilities::currentV8Context()
{
    LocalFrame* frame = DartUtilities::domWindowForCurrentIsolate()->frame();
    v8::Local<v8::Context> context = toV8Context(frame, DOMWrapperWorld::mainWorld());
    ASSERT(!context.IsEmpty());
    return context;
}

int DartUtilities::dartToInt(Dart_Handle object, Dart_Handle& exception)
{
    int64_t value = toInteger(object, exception);
    if (exception)
        return 0;
    if (value < INT_MIN || value > INT_MAX) {
        exception = Dart_NewStringFromCString("value out of range");
        return 0;
    }
    return value;
}

unsigned DartUtilities::dartToUnsigned(Dart_Handle object, Dart_Handle& exception)
{
    int64_t value = toInteger(object, exception);
    if (exception)
        return 0;
    if (value < 0 || value > UINT_MAX) {
        exception = Dart_NewStringFromCString("value out of range");
        return 0;
    }
    return value;
}

long long DartUtilities::dartToLongLong(Dart_Handle object, Dart_Handle& exception)
{
    // FIXME: proper processing of longer integer values.
    return toInteger(object, exception);
}

unsigned long long DartUtilities::dartToUnsignedLongLong(Dart_Handle object, Dart_Handle& exception)
{
    // FIXME: proper processing of longer integer values.
    int64_t value = toInteger(object, exception);
    if (exception)
        return 0;
    if (value < 0) {
        exception = Dart_NewStringFromCString("value out of range");
        return 0;
    }
    return value;
}

Dart_Handle DartUtilities::numberToDart(double value)
{
    // JS can store integer values that are no greater than 2^53 - 1.
    if (-kJSMaxInteger <= value && value <= kJSMaxInteger) {
        int64_t intValue = static_cast<int64_t>(value);
        if (value == intValue)
            return intToDart(intValue);
    }
    return doubleToDart(value);
}

ScriptValue DartUtilities::dartToScriptValue(Dart_Handle object)
{
    return ScriptValue(DartScriptValue::create(currentScriptState(), object));
}

Dart_Handle DartUtilities::scriptValueToDart(const ScriptValue& value)
{
    if (value.isEmpty()) {
        return Dart_Null();
    }
    AbstractScriptValue* scriptValue = value.scriptValue();
    if (scriptValue->isDart()) {
        DartScriptValue* dartScriptValue = static_cast<DartScriptValue*>(scriptValue);
        return dartScriptValue->dartValue();
    }
    // FIXMEMULTIVM: Should not be converting from V8 values. Major culprit is IDB.
    // FIXME: better error handling.
    Dart_Handle exception = 0;
    return V8Converter::toDart(value.v8Value(), exception);
}

Dart_Handle DartUtilities::scriptPromiseToDart(const ScriptPromise& promise)
{
    AbstractScriptPromise* scriptPromise = promise.scriptPromise().get();
    if (scriptPromise->isDartScriptPromise()) {
        DartScriptPromise* dartScriptPromise = static_cast<DartScriptPromise*>(scriptPromise);
        return dartScriptPromise->dartValue();
    }
    ASSERT_NOT_REACHED();
    return Dart_NewStringFromCString("Internal error: Expected Dart promise");
}

PassRefPtr<SerializedScriptValue> DartUtilities::toSerializedScriptValue(Dart_Handle value, MessagePortArray* ports, ArrayBufferArray* arrayBuffers, Dart_Handle& exception)
{
    v8::Handle<v8::Value> v8Value = V8Converter::toV8(value, exception);
    if (exception)
        return nullptr;

    V8TrackExceptionState exceptionState;
    RefPtr<SerializedScriptValue> message = SerializedScriptValue::create(v8Value, ports, arrayBuffers, exceptionState, v8::Isolate::GetCurrent());
    if (exceptionState.hadException()) {
        // FIXME: better exception here. We should match the exception v8 would throw.
        exception = Dart_NewStringFromCString("Failed to create SerializedScriptValue");
        return nullptr;
    }

    return message.release();
}

Dart_Handle DartUtilities::dateToDart(double date)
{
    Dart_Handle asDouble = DartUtilities::doubleToDart(date);
    ASSERT(!Dart_IsError(asDouble));
    return DartUtilities::invokeUtilsMethod("doubleToDateTime", 1, &asDouble);
}

double DartUtilities::dartToDate(Dart_Handle date, Dart_Handle& exception)
{
    Dart_Handle asDouble = DartUtilities::invokeUtilsMethod("dateTimeToDouble", 1, &date);
    if (!DartUtilities::checkResult(asDouble, exception))
        return 0.0;

    return DartUtilities::dartToDouble(asDouble, exception);
}

double DartUtilities::dartToDate(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToDate(object, exception);
}

bool DartUtilities::isDateTime(DartDOMData* domData, Dart_Handle handle)
{
    ASSERT(domData);
    Dart_Handle type = DartDOMWrapper::dartClass(domData, _DateTimeClassId);
    ASSERT(!Dart_IsError(type));
    return objectIsType(handle, type);
}

bool DartUtilities::objectIsType(Dart_Handle handle, Dart_Handle type)
{
    bool isType = false;
    Dart_Handle result = Dart_ObjectIsType(handle, type, &isType);
    if (Dart_IsError(result))
        return false;
    return isType;
}

bool DartUtilities::isTypeSubclassOf(Dart_Handle type, Dart_Handle library, const char* typeName)
{
    Dart_Handle other = Dart_GetType(library, Dart_NewStringFromCString(typeName), 0, 0);
    ASSERT(!Dart_IsError(other));

    Dart_Handle args[2] = { type, other };
    Dart_Handle result = DartUtilities::invokeUtilsMethod("isTypeSubclassOf", 2, args);
    if (Dart_IsError(result)) {
        ASSERT_NOT_REACHED();
        return false;
    }

    Dart_Handle exception = 0;
    bool boolResult = dartToBool(result, exception);
    if (exception)
        return false;
    return boolResult;
}

Dart_Handle DartUtilities::getAndValidateNativeType(Dart_Handle type, const String& tagName)
{
    Dart_Handle args[2] = { type, stringToDartString(tagName) };
    Dart_Handle result = DartUtilities::invokeUtilsMethod("getAndValidateNativeType", 2, args);
    ASSERT(!Dart_IsError(result));
    if (Dart_IsError(result)) {
        ASSERT_NOT_REACHED();
        return Dart_Null();
    }
    return result;
}

bool DartUtilities::isFunction(DartDOMData* domData, Dart_Handle handle)
{
    return DartUtilities::objectIsType(handle, domData->functionType());
}

static Dart_TypedData_Type typedDataTypeFromViewType(ArrayBufferView::ViewType type)
{
    switch (type) {
    case ArrayBufferView::TypeInt8:
        return Dart_TypedData_kInt8;
    case ArrayBufferView::TypeUint8:
        return Dart_TypedData_kUint8;
    case ArrayBufferView::TypeUint8Clamped:
        return Dart_TypedData_kUint8Clamped;
    case ArrayBufferView::TypeInt16:
        return Dart_TypedData_kInt16;
    case ArrayBufferView::TypeUint16:
        return Dart_TypedData_kUint16;
    case ArrayBufferView::TypeInt32:
        return Dart_TypedData_kInt32;
    case ArrayBufferView::TypeUint32:
        return Dart_TypedData_kUint32;
    case ArrayBufferView::TypeFloat32:
        return Dart_TypedData_kFloat32;
    case ArrayBufferView::TypeFloat64:
        return Dart_TypedData_kFloat64;
    case ArrayBufferView::TypeDataView:
        return Dart_TypedData_kByteData;
    }
    ASSERT_NOT_REACHED();
    return Dart_TypedData_kInvalid;
}

static unsigned elementSizeFromViewType(Dart_TypedData_Type type)
{
    switch (type) {
    case Dart_TypedData_kByteData:
        return sizeof(uint8_t);
    case Dart_TypedData_kInt8:
        return sizeof(int8_t);
    case Dart_TypedData_kUint8:
        return sizeof(uint8_t);
    case Dart_TypedData_kUint8Clamped:
        return sizeof(uint8_t);
    case Dart_TypedData_kInt16:
        return sizeof(int16_t);
    case Dart_TypedData_kUint16:
        return sizeof(uint16_t);
    case Dart_TypedData_kInt32:
        return sizeof(int32_t);
    case Dart_TypedData_kUint32:
        return sizeof(uint32_t);
    case Dart_TypedData_kFloat32:
        return sizeof(float);
    case Dart_TypedData_kFloat64:
        return sizeof(double);
    case Dart_TypedData_kFloat32x4:
        return 4 * sizeof(float);
    default:
        break;
    }
    ASSERT_NOT_REACHED();
    return 0;
}

static unsigned elementSizeFromViewType(ArrayBufferView::ViewType type)
{
    return elementSizeFromViewType(typedDataTypeFromViewType(type));
}

class TypedDataPeer {
public:
    virtual ~TypedDataPeer() { };
    virtual bool isViewPeer() = 0;
};

class TypedBufferPeer : public TypedDataPeer {
public:
    TypedBufferPeer(PassRefPtr<ArrayBuffer> buffer) : m_buffer(buffer) { }
    virtual ~TypedBufferPeer() { }

    PassRefPtr<ArrayBuffer> buffer()
    {
        return m_buffer;
    }

    virtual bool isViewPeer()
    {
        return false;
    }

private:
    RefPtr<ArrayBuffer> m_buffer;
};

class TypedViewPeer : public TypedDataPeer {
public:
    TypedViewPeer(PassRefPtr<ArrayBufferView> view) : m_view(view) { }
    virtual ~TypedViewPeer() { }

    PassRefPtr<ArrayBufferView> view()
    {
        return m_view;
    }

    virtual bool isViewPeer()
    {
        return true;
    }

private:
    RefPtr<ArrayBufferView> m_view;
};

static void externalArrayBufferCallback(void* isolateCallbackData, Dart_WeakPersistentHandle handle, void* peer)
{
    delete reinterpret_cast<TypedDataPeer*>(peer);
}

static Dart_Handle createExternalTypedData(Dart_TypedData_Type type, void* data, intptr_t numberOfElements, TypedDataPeer* peer, intptr_t peerSize, Dart_WeakPersistentHandleFinalizer callback)
{
    Dart_Handle newInstance = Dart_NewExternalTypedData(type, data, numberOfElements);
    Dart_Handle result = Dart_SetPeer(newInstance, peer);
    if (Dart_IsError(result))
        return result;
    Dart_NewWeakPersistentHandle(newInstance, peer, peerSize, callback);
    return newInstance;
}

Dart_Handle DartUtilities::arrayBufferToDart(WTF::ArrayBuffer* buffer)
{
    void* data = buffer->data();
    unsigned byteLength = buffer->byteLength();
    TypedBufferPeer* peer = new TypedBufferPeer(buffer);
    Dart_Handle typedData =  createExternalTypedData(Dart_TypedData_kUint8, data, byteLength, peer, byteLength, externalArrayBufferCallback);
    ASSERT(!Dart_IsError(typedData));
    return Dart_NewByteBuffer(typedData);
}

static bool externalTypedDataGetPeer(Dart_Handle handle, void** peer)
{
    *peer = 0;
    Dart_Handle getPeerResult = Dart_GetPeer(handle, peer);
    if (!Dart_IsError(getPeerResult) && *peer) {
        return true;
    }
    return false;
}

static PassRefPtr<WTF::ArrayBuffer> dartToArrayBufferHelper(Dart_Handle array, Dart_Handle& exception, bool externalize)
{
    void* data = 0;

    // If a ByteBuffer is passed in extract the typed data first.
    if (Dart_IsByteBuffer(array)) {
        array = Dart_GetDataFromByteBuffer(array);
    }

    // Check if the Dart array buffer object is external and has an
    // ArrayBuffer peer.
    if (externalTypedDataGetPeer(array, &data) && !reinterpret_cast<TypedDataPeer*>(data)->isViewPeer()) {
        return reinterpret_cast<TypedBufferPeer*>(data)->buffer();
    }

    Dart_TypedData_Type type;
    intptr_t elementLength = 0;
    intptr_t byteLength = 0;

    // Check if the Dart object is a typed data object by acquiring its data.
    // If it is, create a thin ArrayBuffer wrapper around the data in the dart
    // heap.
    Dart_Handle result = Dart_TypedDataAcquireData(array, &type, &data, &elementLength);
    if (Dart_IsError(result)) {
        exception = Dart_NewStringFromCString("Typed data object expected");
        return nullptr;
    }
    // FIXME: we really shouldn't release the data until we are done with it.
    Dart_TypedDataReleaseData(array);
    byteLength = elementLength * elementSizeFromViewType(type);
    return externalize ? ArrayBuffer::create(data, byteLength) : ArrayBuffer::createNoCopy(data, byteLength);
}

PassRefPtr<WTF::ArrayBuffer> DartUtilities::dartToArrayBuffer(Dart_Handle array, Dart_Handle& exception)
{
    return dartToArrayBufferHelper(array, exception, false);
}

PassRefPtr<WTF::ArrayBuffer> DartUtilities::dartToExternalizedArrayBuffer(Dart_Handle array, Dart_Handle& exception)
{
    return dartToArrayBufferHelper(array, exception, true);
}

// FIXME: This mapping to dart objects loses object identity for
// the buffer part of views. If we have two views on the same buffer
// in C++ and we create dart wrappers we will get two different dart
// buffer objects. Additionally, this means that neutering will not work.
Dart_Handle DartUtilities::arrayBufferViewToDart(WTF::ArrayBufferView* view)
{
    ArrayBufferView::ViewType type = view->type();
    void* address = view->baseAddress();
    unsigned byteLength = view->byteLength();
    unsigned length = byteLength / elementSizeFromViewType(type);
    TypedViewPeer* peer = new TypedViewPeer(view);
    return createExternalTypedData(typedDataTypeFromViewType(type), address, length, peer, byteLength, externalArrayBufferCallback);
}


// FIXME: Again, this breaks the view-buffer relationship.
static PassRefPtr<WTF::ArrayBufferView> dartToArrayBufferViewHelper(Dart_Handle array, Dart_Handle& exception, bool externalize)
{
    void* data = 0;

    // Check if the array is external and has an ArrayBufferView peer.
    if (externalTypedDataGetPeer(array, &data)) {
        if (!reinterpret_cast<TypedDataPeer*>(data)->isViewPeer()) {
            exception = Dart_NewStringFromCString("Typed data view expected");
            return nullptr;
        }
        return reinterpret_cast<TypedViewPeer*>(data)->view();
    }

    // Check if the dart object is an internal typed data object and get
    // the data from it.
    Dart_TypedData_Type type;
    intptr_t elementLength = 0;
    Dart_Handle result = Dart_TypedDataAcquireData(array, &type, &data, &elementLength);
    if (Dart_IsError(result)) {
        exception = Dart_NewStringFromCString("Typed data object expected");
        return nullptr;
    }
    intptr_t byteLength = elementLength * elementSizeFromViewType(type);
    // FIXME: we really shouldn't release the data until we are done with it.
    Dart_TypedDataReleaseData(array);
    RefPtr<ArrayBuffer> buffer = externalize ? ArrayBuffer::create(data, byteLength) : ArrayBuffer::createNoCopy(data, byteLength);

    switch (type) {
    case Dart_TypedData_kByteData:
        return DataView::create(buffer, 0, elementLength);
    case Dart_TypedData_kInt8:
        return Int8Array::create(buffer, 0, elementLength);
    case Dart_TypedData_kUint8:
        return Uint8Array::create(buffer, 0, elementLength);
    case Dart_TypedData_kUint8Clamped:
        return Uint8ClampedArray::create(buffer, 0, elementLength);
    case Dart_TypedData_kInt16:
        return Uint16Array::create(buffer, 0, elementLength);
    case Dart_TypedData_kUint16:
        return Uint16Array::create(buffer, 0, elementLength);
    case Dart_TypedData_kInt32:
        return Int32Array::create(buffer, 0, elementLength);
    case Dart_TypedData_kUint32:
        return Uint32Array::create(buffer, 0, elementLength);
    case Dart_TypedData_kFloat32:
        return Float32Array::create(buffer, 0, elementLength);
    case Dart_TypedData_kFloat64:
        return Float64Array::create(buffer, 0, elementLength);
    case Dart_TypedData_kFloat32x4:
        return Float32Array::create(buffer, 0, elementLength * sizeof(float));
    default:
        break;
    }
    ASSERT_NOT_REACHED();
    return nullptr;
}

PassRefPtr<WTF::ArrayBufferView> DartUtilities::dartToArrayBufferView(Dart_Handle array, Dart_Handle& exception)
{
    return dartToArrayBufferViewHelper(array, exception, false);
}

PassRefPtr<WTF::ArrayBufferView> DartUtilities::dartToExternalizedArrayBufferView(Dart_Handle array, Dart_Handle& exception)
{
    return dartToArrayBufferViewHelper(array, exception, true);
}

PassRefPtr<WTF::Int8Array> DartUtilities::dartToInt8ArrayWithNullCheck(Dart_Handle handle, Dart_Handle& exception)
{
    return Dart_IsNull(handle) ? nullptr : dartToInt8Array(handle, exception);
}

PassRefPtr<WTF::Int8Array> DartUtilities::dartToInt8Array(Dart_Handle handle, Dart_Handle& exception)
{
    RefPtr<ArrayBufferView> view = DartUtilities::dartToArrayBufferView(handle, exception);
    if (exception)
        return nullptr;
    if (view->type() == ArrayBufferView::TypeInt8)
        return reinterpret_cast<Int8Array*>(view.get());
    exception = Dart_NewStringFromCString("Int8List expected");
    return nullptr;
}

PassRefPtr<WTF::Int8Array> DartUtilities::dartToInt8ArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToInt8ArrayWithNullCheck(object, exception);
}

PassRefPtr<WTF::Int8Array> DartUtilities::dartToInt8Array(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToInt8Array(object, exception);
}

PassRefPtr<WTF::Int32Array> DartUtilities::dartToInt32ArrayWithNullCheck(Dart_Handle handle, Dart_Handle& exception)
{
    return Dart_IsNull(handle) ? nullptr : dartToInt32Array(handle, exception);
}

PassRefPtr<WTF::Int32Array> DartUtilities::dartToInt32Array(Dart_Handle handle, Dart_Handle& exception)
{
    RefPtr<ArrayBufferView> view = DartUtilities::dartToArrayBufferView(handle, exception);
    if (exception)
        return nullptr;
    if (view->type() == ArrayBufferView::TypeInt32)
        return reinterpret_cast<Int32Array*>(view.get());
    exception = Dart_NewStringFromCString("Int32List expected");
    return nullptr;
}

PassRefPtr<WTF::Int32Array> DartUtilities::dartToInt32ArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToInt32ArrayWithNullCheck(object, exception);
}

PassRefPtr<WTF::Int32Array> DartUtilities::dartToInt32Array(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToInt32Array(object, exception);
}

PassRefPtr<WTF::Uint8ClampedArray> DartUtilities::dartToUint8ClampedArrayWithNullCheck(Dart_Handle handle, Dart_Handle& exception)
{
    return Dart_IsNull(handle) ? nullptr : dartToUint8ClampedArray(handle, exception);
}

PassRefPtr<WTF::Uint8ClampedArray> DartUtilities::dartToUint8ClampedArray(Dart_Handle handle, Dart_Handle& exception)
{
    RefPtr<ArrayBufferView> view = DartUtilities::dartToArrayBufferView(handle, exception);
    if (exception)
        return nullptr;
    if (view->type() == ArrayBufferView::TypeUint8Clamped)
        return reinterpret_cast<Uint8ClampedArray*>(view.get());
    exception = Dart_NewStringFromCString("Uint8ClampedList expected");
    return nullptr;
}

PassRefPtr<WTF::Uint8ClampedArray> DartUtilities::dartToUint8ClampedArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToUint8ClampedArrayWithNullCheck(object, exception);
}

PassRefPtr<WTF::Uint8ClampedArray> DartUtilities::dartToUint8ClampedArray(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToUint8ClampedArray(object, exception);
}

PassRefPtr<WTF::Uint8Array> DartUtilities::dartToUint8ArrayWithNullCheck(Dart_Handle handle, Dart_Handle& exception)
{
    return Dart_IsNull(handle) ? nullptr : dartToUint8Array(handle, exception);
}

PassRefPtr<WTF::Uint8Array> DartUtilities::dartToUint8Array(Dart_Handle handle, Dart_Handle& exception)
{
    RefPtr<ArrayBufferView> view = DartUtilities::dartToArrayBufferView(handle, exception);
    if (exception)
        return nullptr;
    if (view->type() == ArrayBufferView::TypeUint8)
        return reinterpret_cast<Uint8Array*>(view.get());
    exception = Dart_NewStringFromCString("Uint8List expected");
    return nullptr;
}

PassRefPtr<WTF::Uint8Array> DartUtilities::dartToUint8ArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToUint8ArrayWithNullCheck(object, exception);
}

PassRefPtr<WTF::Uint8Array> DartUtilities::dartToUint8Array(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToUint8Array(object, exception);
}

PassRefPtr<WTF::Float32Array> DartUtilities::dartToFloat32ArrayWithNullCheck(Dart_Handle handle, Dart_Handle& exception)
{
    return Dart_IsNull(handle) ? nullptr : dartToFloat32Array(handle, exception);
}

PassRefPtr<WTF::Float32Array> DartUtilities::dartToFloat32Array(Dart_Handle handle, Dart_Handle& exception)
{
    RefPtr<ArrayBufferView> view = DartUtilities::dartToArrayBufferView(handle, exception);
    if (exception)
        return nullptr;
    if (view->type() == ArrayBufferView::TypeFloat32)
        return reinterpret_cast<Float32Array*>(view.get());
    exception = Dart_NewStringFromCString("Float32List expected");
    return nullptr;
}

PassRefPtr<WTF::Float32Array> DartUtilities::dartToFloat32ArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToFloat32ArrayWithNullCheck(object, exception);
}

PassRefPtr<WTF::Float32Array> DartUtilities::dartToFloat32Array(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToFloat32Array(object, exception);
}

bool DartUtilities::isUint8Array(Dart_Handle object)
{
    return Dart_GetTypeOfTypedData(object) == Dart_TypedData_kUint8;
}

bool DartUtilities::isUint8ClampedArray(Dart_Handle object)
{
    return Dart_GetTypeOfTypedData(object) == Dart_TypedData_kUint8Clamped;
}

SQLValue DartUtilities::toSQLValue(Dart_Handle object, Dart_Handle& exception)
{
    if (Dart_IsNull(object))
        return SQLValue();

    if (Dart_IsNumber(object))
        return SQLValue(DartUtilities::dartToDouble(object, exception));

    return SQLValue(DartUtilities::dartToString(object, exception));
}

PassRefPtr<SerializedScriptValue> DartUtilities::dartToSerializedScriptValue(Dart_Handle object, Dart_Handle& exception)
{
    return toSerializedScriptValue(object, 0, 0, exception);
}

Dart_Handle DartUtilities::serializedScriptValueToDart(PassRefPtr<SerializedScriptValue> value)
{
    // FIXME: better error handling.
    Dart_Handle exception = 0;
    return V8Converter::toDart(value->deserialize(), exception);
}

// FIXME: this function requires better testing. Currently blocking as new MessageChannel hasn't been implemented yet.
void DartUtilities::toMessagePortArray(Dart_Handle value, MessagePortArray& ports, ArrayBufferArray& arrayBuffers, Dart_Handle& exception)
{
    Vector<Dart_Handle> elements;
    DartUtilities::extractListElements(value, exception, elements);
    if (exception)
        return;

    DartDOMData* domData = DartDOMData::current();
    for (size_t i = 0; i < elements.size(); i++) {
        Dart_Handle element = elements[i];
        if (DartDOMWrapper::instanceOf<DartMessagePort>(domData, element)) {
            MessagePort* messagePort = DartMessagePort::toNative(element, exception);
            ASSERT(!exception);
            ASSERT(messagePort);
            ports.append(messagePort);
            continue;
        }

        if (Dart_IsByteBuffer(element)) {
            element = Dart_GetDataFromByteBuffer(element);
            RefPtr<ArrayBuffer> arrayBuffer = DartUtilities::dartToExternalizedArrayBuffer(element, exception);
            ASSERT(!exception);
            ASSERT(arrayBuffer);
            arrayBuffers.append(arrayBuffer);
            continue;
        }

        exception = Dart_NewStringFromCString("TransferArray argument must contain only Transferables");
        return;
    }
}

Dictionary DartUtilities::dartToDictionary(Dart_Handle object, Dart_Handle& exception)
{
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Value> value = v8::Local<v8::Value>::New(v8Isolate, V8Converter::toV8(object, exception));
    if (exception)
        return Dictionary();
    return Dictionary(value, v8Isolate);
}

Dictionary DartUtilities::dartToDictionaryWithNullCheck(Dart_Handle object, Dart_Handle& exception)
{
    if (Dart_IsNull(object))
        return Dictionary();
    return dartToDictionary(object, exception);
}

Dictionary DartUtilities::dartToDictionary(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToDictionary(object, exception);
}

Dictionary DartUtilities::dartToDictionaryWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception)
{
    Dart_Handle object = Dart_GetNativeArgument(args, idx);
    return dartToDictionaryWithNullCheck(object, exception);
}

LocalDOMWindow* DartUtilities::domWindowForCurrentIsolate()
{
    DartDOMData* domData = DartDOMData::current();
    ASSERT(domData->scriptExecutionContext()->isDocument());
    Document* document = static_cast<Document*>(domData->scriptExecutionContext());
    return document->domWindow();
}

V8ScriptState* DartUtilities::v8ScriptStateForCurrentIsolate()
{
    return V8ScriptState::forMainWorld(domWindowForCurrentIsolate()->frame());
}

ExecutionContext* DartUtilities::scriptExecutionContext()
{
    if (Dart_CurrentIsolate())
        return DartDOMData::current()->scriptExecutionContext();
    return 0;
}

bool DartUtilities::processingUserGesture()
{
    // FIXME: implement this.
    return false;
}

intptr_t DartUtilities::libraryHandleToLibraryId(Dart_Handle library)
{
    intptr_t libraryId = -1;
    Dart_Handle ALLOW_UNUSED result = Dart_LibraryId(library, &libraryId);
    ASSERT(!Dart_IsError(result));
    return libraryId;
}

DartScriptState* DartUtilities::currentScriptState()
{
    DartDOMData* dartDOMData = DartDOMData::current();
    if (!dartDOMData->rootScriptState()) {
        DartController* controller = DartController::retrieve(dartDOMData->scriptExecutionContext());
        intptr_t libraryId = DartUtilities::libraryHandleToLibraryId(Dart_RootLibrary());
        DartScriptState* scriptState = controller->lookupScriptState(Dart_CurrentIsolate(), currentV8Context(), libraryId);
        dartDOMData->setRootScriptState(scriptState);
        return scriptState;
    }
    return dartDOMData->rootScriptState();
}

PassRefPtr<ScriptArguments> DartUtilities::createScriptArguments(Dart_Handle argument, Dart_Handle& exception)
{
    Vector<ScriptValue> arguments;
    arguments.append(DartUtilities::dartToScriptValue(argument));
    return ScriptArguments::create(DartUtilities::currentScriptState(), arguments);
}

static PassRefPtr<ScriptCallStack> createScriptCallStackFromStackTrace(Dart_StackTrace stackTrace)
{
    uintptr_t frameCount = 0;
    Dart_Handle result = Dart_StackTraceLength(stackTrace, reinterpret_cast<intptr_t*>(&frameCount));
    if (Dart_IsError(result))
        return nullptr;

    if (frameCount > ScriptCallStack::maxCallStackSizeToCapture)
        frameCount = ScriptCallStack::maxCallStackSizeToCapture;

    Dart_Isolate isolate = Dart_CurrentIsolate();
    Vector<ScriptCallFrame> scriptCallStackFrames;
    for (uintptr_t frameIndex = 0; frameIndex < frameCount; frameIndex++) {
        Dart_ActivationFrame frame = 0;
        result = Dart_GetActivationFrame(stackTrace, frameIndex, &frame);
        if (Dart_IsError(result)) {
            return nullptr;
        }
        ASSERT(frame);

        Dart_Handle dartFunctionName;
        Dart_Handle dartScriptUrl;
        intptr_t lineNumber = 0;
        intptr_t columnNumber = 0;
        result = Dart_ActivationFrameInfo(frame, &dartFunctionName, &dartScriptUrl, &lineNumber, &columnNumber);
        if (Dart_IsError(result)) {
            return nullptr;
        }

        // This skips frames where source is unavailable. WebKit code for the
        // console assumes that console.log et al. are implemented directly
        // as natives, i.e. that the top-of-stack will be the caller of
        // console.log. The Dart implementation involves intermediate Dart
        // calls, which are skipped by this clause.
        if (columnNumber == -1)
            continue;

        String functionName = DartUtilities::toString(dartFunctionName);
        String scriptUrl = DartUtilities::toString(dartScriptUrl);

        scriptCallStackFrames.append(ScriptCallFrame(functionName, DartScriptDebugServer::shared().getScriptId(scriptUrl, isolate), scriptUrl, lineNumber, columnNumber));
    }
    if (scriptCallStackFrames.isEmpty())
        scriptCallStackFrames.append(ScriptCallFrame("undefined", "undefined", "undefined", 0, 0));

    return ScriptCallStack::create(scriptCallStackFrames);
}

ScriptCallFrame DartUtilities::getTopFrame(Dart_StackTrace stackTrace, Dart_Handle& exception)
{
    {
        uintptr_t frameCount = 0;
        Dart_Handle result = Dart_StackTraceLength(stackTrace, reinterpret_cast<intptr_t*>(&frameCount));
        if (Dart_IsError(result)) {
            exception = result;
            goto fail;
        }
        if (!frameCount) {
            exception = Dart_NewStringFromCString("Empty stack trace");
            goto fail;
        }
        Dart_ActivationFrame frame = 0;
        result = Dart_GetActivationFrame(stackTrace, 0, &frame);
        if (Dart_IsError(result)) {
            exception = result;
            goto fail;
        }
        ASSERT(frame);
        return toScriptCallFrame(frame, exception);
    }
fail:
    return ScriptCallFrame("undefined", "undefined", "undefined", 0, 0);
}

ScriptCallFrame DartUtilities::toScriptCallFrame(Dart_ActivationFrame frame, Dart_Handle& exception)
{
    ASSERT(frame);
    Dart_Handle functionName;
    Dart_Handle scriptUrl;
    intptr_t lineNumber = 0;
    intptr_t columnNumber = 0;
    Dart_Handle result = Dart_ActivationFrameInfo(frame, &functionName, &scriptUrl, &lineNumber, &columnNumber);
    if (Dart_IsError(result)) {
        exception = result;
        return ScriptCallFrame("undefined", "undefined", "undefined", 0, 0);
    }
    return ScriptCallFrame(DartUtilities::toString(functionName), "undefined", DartUtilities::toString(scriptUrl), lineNumber, columnNumber);
}

PassRefPtr<ScriptCallStack> DartUtilities::createScriptCallStack()
{
    Dart_StackTrace trace = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_GetStackTrace(&trace);
    ASSERT(!Dart_IsError(result));
    ASSERT(!Dart_IsNull(result));
    ASSERT(trace);
    return createScriptCallStackFromStackTrace(trace);
}

const uint8_t* DartUtilities::fullSnapshot(LocalFrame* frame)
{
    static const uint8_t snapshotBuffer[] = {
// DartSnapshot.bytes is generated by build system.
#include "bindings/dart/DartSnapshot.bytes"
    };
    return snapshotBuffer;
}

Dart_Handle DartUtilities::canonicalizeUrl(Dart_Handle library, Dart_Handle urlHandle, String url)
{
    DEFINE_STATIC_LOCAL(String, dartPrefix, ("dart:"));
    DEFINE_STATIC_LOCAL(String, packagePrefix, ("package:"));

    if (url.startsWith(dartPrefix) || url.startsWith(packagePrefix))
        // Not a relative URL.
        return urlHandle;

    Dart_Handle libraryURLHandle = Dart_LibraryUrl(library);
    ASSERT(!Dart_IsError(libraryURLHandle));
    String libraryURL = DartUtilities::toString(libraryURLHandle);

    String result;
    if (libraryURL.startsWith(packagePrefix) && !libraryURL.startsWith("package://")) {
        // KURL expects a URL with an authority. If the library URL is
        // "package:<path>", we convert to "package://_/<path>" for resolution
        // and convert back.
        DEFINE_STATIC_LOCAL(String, resolvePrefix, ("package://_/"));

        libraryURL = resolvePrefix + libraryURL.substring(packagePrefix.length());
        result = KURL(KURL(KURL(), libraryURL), url).string();
        if (result.startsWith(resolvePrefix))
            result = packagePrefix + result.substring(resolvePrefix.length());
    } else {
        result = KURL(KURL(KURL(), libraryURL), url).string();
    }

    return DartUtilities::stringToDartString(result);
}

void DartUtilities::reportProblem(ExecutionContext* context, const String& error, int line, int col)
{
    String sourceURL = context->url().string();

    // FIXME: Pass in stack trace.
    if (context && context->isDocument()) {
        static_cast<Document*>(context)->reportException(ErrorEvent::create(error, sourceURL, line, col, 0), nullptr, NotSharableCrossOrigin);
    }
}

void DartUtilities::reportProblem(ExecutionContext* context, Dart_Handle result)
{
    // FIXME: provide sourceURL.
    String sourceURL = "FIXME";
    reportProblem(context, result, sourceURL);
}

void DartUtilities::reportProblem(ExecutionContext* context, Dart_Handle result, const String& sourceURL)
{
    ASSERT(Dart_IsError(result));
    ASSERT(!sourceURL.isEmpty());

    const String internalErrorPrefix("Internal error: ");

    String errorMessage;
    // FIXME: line number info.
    int lineNumber = 0;
    // FIXME: call stack info.
    RefPtr<ScriptCallStack> callStack;

    if (!Dart_ErrorHasException(result)) {
        errorMessage = internalErrorPrefix + Dart_GetError(result);
    } else {
        // Print the exception.
        Dart_Handle exception = Dart_ErrorGetException(result);
        ASSERT(!Dart_IsError(exception));

        exception = Dart_ToString(exception);
        if (Dart_IsError(exception))
            errorMessage = String("Error: ") + Dart_GetError(exception);
        else
            errorMessage = String("Exception: ") + DartUtilities::toString(exception);

        // Print the stack trace.
        Dart_StackTrace stacktrace;
        Dart_Handle ALLOW_UNUSED traceResult = Dart_GetStackTraceFromError(result, &stacktrace);
        ASSERT(!Dart_IsError(traceResult));
        callStack = createScriptCallStackFromStackTrace(stacktrace);
    }

    if (context && context->isDocument()) {
        static_cast<Document*>(context)->reportException(ErrorEvent::create(errorMessage, sourceURL, lineNumber, 0, 0), callStack, NotSharableCrossOrigin);
    }
}

Dart_Handle DartUtilities::toDartCoreException(const String& className, const String& message)
{
    DartApiScope apiScope;
    DartDOMData* domData = DartDOMData::current();
    Dart_Handle coreLib = Dart_LookupLibrary(Dart_NewStringFromCString("dart:core"));
    Dart_Handle errorClass = Dart_GetType(coreLib, stringToDart(className), 0, 0);
    Dart_Handle dartMessage = stringToDart(message);
    Dart_Handle error = Dart_New(errorClass, Dart_NewStringFromCString(""), 1, &dartMessage);
    Dart_SetPersistentHandle(domData->currentException(), error);
    return domData->currentException();
}

Dart_Handle DartUtilities::coreArgumentErrorException(const String& message)
{
    return DartUtilities::toDartCoreException("ArgumentError", message);
}

Dart_Handle DartUtilities::notImplementedException(const char* fileName, int lineNumber)
{
    Dart_Handle args[2] = { Dart_NewStringFromCString(fileName), Dart_NewInteger(lineNumber) };
    Dart_Handle result = DartUtilities::invokeUtilsMethod("makeUnimplementedError", 2, args);
    ASSERT(!Dart_IsError(result));
    return result;
}

Dart_Handle DartUtilities::newResolvedPromise(Dart_Handle value)
{
    Dart_Handle asyncLib = Dart_LookupLibrary(Dart_NewStringFromCString("dart:async"));
    Dart_Handle futureClass = Dart_GetType(asyncLib, Dart_NewStringFromCString("Future"), 0, 0);
    return Dart_New(futureClass, Dart_NewStringFromCString("value"), 1, &value);
}

Dart_Handle DartUtilities::newSmashedPromise(Dart_Handle error)
{
    Dart_Handle asyncLib = Dart_LookupLibrary(Dart_NewStringFromCString("dart:async"));
    Dart_Handle futureClass = Dart_GetType(asyncLib, Dart_NewStringFromCString("Future"), 0, 0);
    return Dart_New(futureClass, Dart_NewStringFromCString("error"), 1, &error);
}

Dart_Handle DartUtilities::newResolver()
{
    Dart_Handle asyncLib = Dart_LookupLibrary(Dart_NewStringFromCString("dart:async"));
    Dart_Handle futureClass = Dart_GetType(asyncLib, Dart_NewStringFromCString("Completer"), 0, 0);
    return Dart_New(futureClass, Dart_EmptyString(), 0, 0);
}

Dart_Handle DartUtilities::newArgumentError(const String& message)
{
    Dart_Handle asyncLib = Dart_LookupLibrary(Dart_NewStringFromCString("dart:core"));
    Dart_Handle futureClass = Dart_GetType(asyncLib, Dart_NewStringFromCString("ArgumentError"), 0, 0);
    Dart_Handle dartMessage = stringToDart(message);
    return Dart_New(futureClass, Dart_EmptyString(), 1, &dartMessage);
}

Dart_Handle DartUtilities::invokeUtilsMethod(const char* methodName, int argCount, Dart_Handle* args)
{
    DartDOMData* domData = DartDOMData::current();
    ASSERT(domData);
    Dart_PersistentHandle library = domData->htmlLibrary();
    ASSERT(!Dart_IsError(library));

    Dart_Handle utilsClass = Dart_GetType(library, Dart_NewStringFromCString("_Utils"), 0, 0);
    ASSERT(!Dart_IsError(utilsClass));

    return Dart_Invoke(utilsClass, Dart_NewStringFromCString(methodName), argCount, args);
}


int DartUtilities::getProp(const char* name, char* value, int valueLen)
{
#if OS(ANDROID)
    return __system_property_get(name, value);
#else
    char* v = getenv(name);
    if (!v) {
        return 0;
    }
    ASSERT(valueLen > 0 && static_cast<size_t>(valueLen) > strlen(v));
    strncpy(value, v, valueLen);
    value[valueLen - 1] = '\0';
    return strlen(value);
#endif
}
}
