/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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
#include "bindings/core/dart/V8Converter.h"

#include "bindings/core/dart/DartBlob.h"
#include "bindings/core/dart/DartDOMStringList.h"
#include "bindings/core/dart/DartEvent.h"
#include "bindings/core/dart/DartImageData.h"
#include "bindings/core/dart/DartNode.h"
#include "bindings/core/dart/DartWindow.h"
#include "bindings/core/v8/V8Blob.h"
#include "bindings/core/v8/V8DOMStringList.h"
#include "bindings/core/v8/V8Event.h"
#include "bindings/core/v8/V8ImageData.h"
#include "bindings/core/v8/V8Node.h"
#include "bindings/core/v8/V8Window.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/modules/dart/DartIDBCursor.h"
#include "bindings/modules/dart/DartIDBCursorWithValue.h"
#include "bindings/modules/dart/DartIDBDatabase.h"
#include "bindings/modules/dart/DartIDBFactory.h"
#include "bindings/modules/dart/DartIDBKeyRange.h"
#include "bindings/modules/v8/V8IDBCursor.h"
#include "bindings/modules/v8/V8IDBCursorWithValue.h"
#include "bindings/modules/v8/V8IDBDatabase.h"
#include "bindings/modules/v8/V8IDBFactory.h"
#include "bindings/modules/v8/V8IDBKeyRange.h"
#include "bindings/core/v8/custom/V8ArrayBufferViewCustom.h"
#include "bindings/core/v8/custom/V8DataViewCustom.h"
#include "bindings/core/v8/custom/V8Float32ArrayCustom.h"
#include "bindings/core/v8/custom/V8Float64ArrayCustom.h"
#include "bindings/core/v8/custom/V8Int16ArrayCustom.h"
#include "bindings/core/v8/custom/V8Int32ArrayCustom.h"
#include "bindings/core/v8/custom/V8Int8ArrayCustom.h"
#include "bindings/core/v8/custom/V8TypedArrayCustom.h"
#include "bindings/core/v8/custom/V8Uint16ArrayCustom.h"
#include "bindings/core/v8/custom/V8Uint32ArrayCustom.h"
#include "bindings/core/v8/custom/V8Uint8ArrayCustom.h"
#include "bindings/core/v8/custom/V8Uint8ClampedArrayCustom.h"

#include "wtf/Vector.h"

#include <utility>

namespace blink {

class DartToV8Map {
public:
    DartToV8Map()
        : m_list()
    {
    }

    v8::Handle<v8::Value> get(Dart_Handle key)
    {
        for (size_t i = 0; i < m_list.size(); ++i) {
            if (Dart_IdentityEquals(key, m_list[i].first))
                return m_list[i].second;
        }
        return v8::Handle<v8::Value>();
    }

    v8::Handle<v8::Value> put(Dart_Handle key, v8::Handle<v8::Value> value)
    {
        ASSERT(!value.IsEmpty());
        ASSERT(get(key).IsEmpty());
        m_list.append(std::make_pair(key, value));
        return value;
    }

private:
    Vector< std::pair< Dart_Handle, v8::Handle<v8::Value> > > m_list;
};

class V8ToDartMap {
public:
    V8ToDartMap()
        : m_list()
    {
    }

    Dart_Handle get(v8::Handle<v8::Value> key)
    {
        for (size_t i = 0; i < m_list.size(); ++i) {
            if (m_list[i].first == key)
                return m_list[i].second;
        }
        return 0;
    }

    Dart_Handle put(v8::Handle<v8::Value> key, Dart_Handle value)
    {
        ASSERT(!get(key));
        m_list.append(std::make_pair(key, value));
        return value;
    }

private:
    Vector< std::pair<v8::Handle<v8::Value> , Dart_Handle> > m_list;
};

v8::Handle<v8::Value> V8Converter::toV8IfPrimitive(DartDOMData* domData, Dart_Handle value, Dart_Handle& exception)
{
    if (Dart_IsNull(value))
        return v8::Null(v8::Isolate::GetCurrent());
    if (Dart_IsString(value))
        return stringToV8(value);
    if (Dart_IsBoolean(value))
        return booleanToV8(value);
    if (Dart_IsNumber(value))
        return numberToV8(value, exception);
    if (DartUtilities::isDateTime(domData, value))
        return dateToV8(value, exception);

    return v8::Handle<v8::Value>();
}

v8::Handle<v8::Value> V8Converter::toV8IfBrowserNative(DartDOMData* domData, Dart_Handle value, Dart_Handle& exception)
{
    if (Dart_IsByteBuffer(value)) {
        Dart_Handle data = Dart_GetDataFromByteBuffer(value);
        return arrayBufferToV8(data, exception);
    }
    if (Dart_IsTypedData(value))
        return arrayBufferToV8(value, exception);
    if (DartDOMWrapper::subtypeOf(value, DartBlob::dartClassId))
        return blobToV8(value, exception);
    if (DartDOMWrapper::subtypeOf(value, DartImageData::dartClassId))
        return imageDataToV8(value, exception);
    if (DartDOMWrapper::subtypeOf(value, DartIDBKeyRange::dartClassId))
        return idbKeyRangeToV8(value, exception);
    if (DartDOMWrapper::subtypeOf(value, DartDOMStringList::dartClassId))
        return domStringListToV8(value, exception);
    if (DartDOMWrapper::subtypeOf(value, DartNode::dartClassId))
        return nodeToV8(value, exception);
    if (DartDOMWrapper::subtypeOf(value, DartEvent::dartClassId))
        return eventToV8(value, exception);
    if (DartDOMWrapper::subtypeOf(value, DartWindow::dartClassId))
        return windowToV8(value, exception);

    return v8::Handle<v8::Value>();
}

v8::Handle<v8::Value> V8Converter::toV8(Dart_Handle value, DartToV8Map& map, Dart_Handle& exception)
{
    v8::Handle<v8::Value> result = map.get(value);
    if (!result.IsEmpty())
        return result;

    DartDOMData* domData = DartDOMData::current();

    result = toV8IfPrimitive(domData, value, exception);
    if (!result.IsEmpty())
        return result;

    // ArrayBuffer{,View} checks in toV8IfBrowserNative must go before IsList
    // check as they implement list.
    result = toV8IfBrowserNative(domData, value, exception);
    if (!result.IsEmpty()) {
        map.put(value, result);
        return result;
    }

    if (Dart_IsList(value))
        return listToV8(value, map, exception);

    bool isMap = DartUtilities::dartToBool(DartUtilities::invokeUtilsMethod("isMap", 1, &value), exception);
    ASSERT(!exception);
    if (isMap)
        return mapToV8(value, map, exception);

    exception = Dart_NewStringFromCString("unsupported object type for conversion");
    return v8::Handle<v8::Value>();
}

v8::Handle<v8::Value> V8Converter::toV8(Dart_Handle value, Dart_Handle& exception)
{
    DartToV8Map map;
    return toV8(value, map, exception);
}

Dart_Handle V8Converter::toDartIfPrimitive(v8::Handle<v8::Value> value)
{
    if (value->IsUndefined())
        return Dart_Null();
    if (value->IsNull())
        return Dart_Null();
    if (value->IsString())
        return stringToDart(value);
    if (value->IsNumber())
        return DartUtilities::numberToDart(value->NumberValue());
    if (value->IsBoolean())
        return Dart_NewBoolean(value->BooleanValue());
    if (value->IsDate())
        return dateToDart(value);
    return 0;
}

/**
 * Convert a subset of types that are backed by browser native objects.
 * These are types that can be passed transparently between Dart and JS
 * with the dart:js interop library.
 */
Dart_Handle V8Converter::toDartIfBrowserNative(v8::Handle<v8::Object> object, v8::Isolate* isolate, Dart_Handle& exception)
{
    if (V8ArrayBuffer::hasInstance(object, isolate))
        return arrayBufferToDart(object, exception);
    if (V8ArrayBufferView::hasInstance(object, isolate))
        return arrayBufferViewToDart(object, exception);
    if (V8Blob::hasInstance(object, isolate))
        return blobToDart(object, exception);
    if (V8DOMStringList::hasInstance(object, isolate))
        return domStringListToDart(object, exception);
    if (V8ImageData::hasInstance(object, isolate))
        return imageDataToDart(object, exception);
    if (V8IDBKeyRange::hasInstance(object, isolate))
        return idbKeyRangeToDart(object, exception);
    if (V8IDBDatabase::hasInstance(object, isolate))
        return idbDatabaseToDart(object, exception);
    if (V8IDBFactory::hasInstance(object, isolate))
        return idbFactoryToDart(object, exception);
    if (V8IDBCursorWithValue::hasInstance(object, isolate))
        return idbCursorWithValueToDart(object, exception);
    if (V8IDBCursor::hasInstance(object, isolate))
        return idbCursorToDart(object, exception);
    if (V8Node::hasInstance(object, isolate)) {
        // FIXME(jacobr): there has to be a faster way to perform this check.
        if (!object->CreationContext()->Global()->StrictEquals(DartUtilities::currentV8Context()->Global())) {
            // The window is from a different context so do not convert.
            return 0;
        }
        return nodeToDart(object);
    }
    if (V8Event::hasInstance(object, isolate)) {
        // FIXME(jacobr): there has to be a faster way to perform this check.
        if (!object->CreationContext()->Global()->StrictEquals(DartUtilities::currentV8Context()->Global())) {
            // The window is from a different context so do not convert.
            return 0;
        }
        return eventToDart(object);
    }

    v8::Handle<v8::Object> window = object->FindInstanceInPrototypeChain(V8Window::domTemplate(isolate));
    if (!window.IsEmpty()) {
        // FIXME(jacobr): there has to be a faster way to perform this check.
        if (!object->CreationContext()->Global()->StrictEquals(DartUtilities::currentV8Context()->Global())) {
            // The window is from a different context so do not convert.
            return 0;
        }
        return windowToDart(window);
    }
    return 0;
}

Dart_Handle V8Converter::toDart(v8::Handle<v8::Value> value, V8ToDartMap& map, Dart_Handle& exception)
{
    Dart_Handle result = map.get(value);
    if (result)
        return result;

    result = toDartIfPrimitive(value);
    if (result)
        return result;

    if (value->IsArray())
        return listToDart(value.As<v8::Array>(), map, exception);
    if (value->IsObject()) {
        v8::Handle<v8::Object> object = value.As<v8::Object>();
        v8::Isolate* isolate = object->CreationContext()->GetIsolate();

        result = toDartIfBrowserNative(object, isolate, exception);
        if (result) {
            map.put(object, result);
            return result;
        }
        return mapToDart(object, map, exception);
    }

    // FIXME: support other types.
    exception = Dart_NewStringFromCString("unsupported object type for conversion");
    return 0;
}

Dart_Handle V8Converter::toDart(v8::Handle<v8::Value> value, Dart_Handle& exception)
{
    V8ToDartMap map;
    return toDart(value, map, exception);
}

v8::Handle<v8::String> V8Converter::stringToV8(Dart_Handle value)
{
    ASSERT(Dart_IsString(value));
    uint8_t* data = 0;
    intptr_t length = -1;
    Dart_Handle ALLOW_UNUSED result = Dart_StringToUTF8(value, &data, &length);
    ASSERT(!Dart_IsError(result));
    return v8::String::NewFromUtf8(
        v8::Isolate::GetCurrent(), reinterpret_cast<const char*>(data),
        v8::String::kNormalString, length);
}

Dart_Handle V8Converter::stringToDart(v8::Handle<v8::Value> value)
{
    ASSERT(value->IsString());
    v8::String::Utf8Value stringValue(value);
    const char* data = *stringValue;
    return Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(data), stringValue.length());
}

v8::Handle<v8::Value> V8Converter::nodeToV8(Dart_Handle value, Dart_Handle& exception)
{
    Node* node = DartNode::toNative(value, exception);
    ASSERT(!exception);
    if (exception)
        return v8::Handle<v8::Value>();
    ASSERT(node);

    V8ScriptState* state = DartUtilities::v8ScriptStateForCurrentIsolate();
    return blink::toV8(node, state->context()->Global(), state->isolate());
}

Dart_Handle V8Converter::nodeToDart(v8::Handle<v8::Value> value)
{
    ASSERT(value->IsObject());

    v8::Handle<v8::Object> object = value.As<v8::Object>();
    Node* node = V8Node::toNative(object);
    ASSERT(node);
    return DartNode::toDart(node);
}

v8::Handle<v8::Value> V8Converter::eventToV8(Dart_Handle value, Dart_Handle& exception)
{
    Event* event = DartEvent::toNative(value, exception);
    ASSERT(!exception);
    if (exception)
        return v8::Handle<v8::Value>();
    ASSERT(event);
    V8ScriptState* state = DartUtilities::v8ScriptStateForCurrentIsolate();
    return blink::toV8(event, state->context()->Global(), state->isolate());
}

Dart_Handle V8Converter::eventToDart(v8::Handle<v8::Value> value)
{
    ASSERT(value->IsObject());

    v8::Handle<v8::Object> object = value.As<v8::Object>();
    Event* event = V8Event::toNative(object);
    ASSERT(event);
    return DartEvent::toDart(event);
}

v8::Handle<v8::Value> V8Converter::windowToV8(Dart_Handle value, Dart_Handle& exception)
{
    LocalDOMWindow* window = DartWindow::toNative(value, exception);
    ASSERT(!exception);
    if (exception)
        return v8::Handle<v8::Value>();
    ASSERT(window);
    V8ScriptState* state = DartUtilities::v8ScriptStateForCurrentIsolate();
    return blink::toV8(window, state->context()->Global(), state->isolate());
}

Dart_Handle V8Converter::windowToDart(v8::Handle<v8::Value> value)
{
    ASSERT(value->IsObject());

    v8::Handle<v8::Object> object = value.As<v8::Object>();
    LocalDOMWindow* window = V8Window::toNative(object);
    ASSERT(window);
    return DartWindow::toDart(window);
}

v8::Handle<v8::Value> V8Converter::booleanToV8(Dart_Handle value)
{
    ASSERT(Dart_IsBoolean(value));
    bool booleanValue;
    Dart_Handle ALLOW_UNUSED result = Dart_BooleanValue(value, &booleanValue);
    ASSERT(!Dart_IsError(result));
    return v8::Boolean::New(v8::Isolate::GetCurrent(), booleanValue);
}

v8::Handle<v8::Value> V8Converter::numberToV8(Dart_Handle value)
{
    Dart_Handle exception = 0;
    v8::Handle<v8::Value> result = numberToV8(value, exception);
    ASSERT(!exception);
    return result;
}

v8::Handle<v8::Value> V8Converter::numberToV8(Dart_Handle value, Dart_Handle& exception)
{
    ASSERT(Dart_IsNumber(value));

    double asDouble = DartUtilities::dartToDouble(value, exception);
    if (exception)
        return v8::Undefined(v8::Isolate::GetCurrent());
    return v8::Number::New(v8::Isolate::GetCurrent(), asDouble);
}

v8::Handle<v8::Value> V8Converter::listToV8(Dart_Handle value)
{
    DartToV8Map map;
    Dart_Handle exception = 0;
    v8::Handle<v8::Value> result = listToV8(value, map, exception);
    ASSERT(!exception);
    return result;
}

v8::Handle<v8::Value> V8Converter::listToV8(Dart_Handle value, DartToV8Map& map, Dart_Handle& exception)
{
    ASSERT(Dart_IsList(value));

    intptr_t length = 0;
    Dart_Handle result = Dart_ListLength(value, &length);
    if (!DartUtilities::checkResult(result, exception))
        return v8::Handle<v8::Value>();

    v8::Local<v8::Array> array = v8::Array::New(v8::Isolate::GetCurrent(), length);
    map.put(value, array);

    for (intptr_t i = 0; i < length; ++i) {
        result = Dart_ListGetAt(value, i);
        if (!DartUtilities::checkResult(result, exception))
            return v8::Handle<v8::Value>();
        v8::Handle<v8::Value> v8value = toV8(result, map, exception);
        if (exception)
            return v8::Handle<v8::Value>();
        array->Set(i, v8value);
    }

    return array;
}

v8::Handle<v8::Value> V8Converter::dateToV8(Dart_Handle value)
{
    Dart_Handle exception = 0;
    v8::Handle<v8::Value> result = dateToV8(value, exception);
    ASSERT(!exception);
    return result;
}

v8::Handle<v8::Value> V8Converter::dateToV8(Dart_Handle value, Dart_Handle& exception)
{
    ASSERT(DartUtilities::isDateTime(DartDOMData::current(), value));

    Dart_Handle asDouble = DartUtilities::invokeUtilsMethod("dateTimeToDouble", 1, &value);

    if (!DartUtilities::checkResult(asDouble, exception))
        return v8::Handle<v8::Value>();

    double doubleValue = DartUtilities::dartToDouble(asDouble, exception);

    return v8::Date::New(v8::Isolate::GetCurrent(), doubleValue);
}

Dart_Handle V8Converter::dateToDart(v8::Handle<v8::Value> value)
{
    ASSERT(value->IsDate());
    return DartUtilities::dateToDart(value->NumberValue());
}

Dart_Handle V8Converter::blobToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    return DartBlob::toDart(V8Blob::toNative(object));
}

v8::Handle<v8::Value> V8Converter::blobToV8(Dart_Handle handle, Dart_Handle& exception)
{
    Blob* blob = DartBlob::toNative(handle, exception);
    if (exception)
        return v8::Handle<v8::Value>();

    V8ScriptState* state = DartUtilities::v8ScriptStateForCurrentIsolate();
    return blink::toV8(blob, state->context()->Global(), state->isolate());
}

Dart_Handle V8Converter::imageDataToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    return DartImageData::toDart(V8ImageData::toNative(object));
}

v8::Handle<v8::Value> V8Converter::imageDataToV8(Dart_Handle handle, Dart_Handle& exception)
{
    ImageData* imageData = DartImageData::toNative(handle, exception);
    if (exception)
        return v8::Handle<v8::Value>();

    V8ScriptState* state = DartUtilities::v8ScriptStateForCurrentIsolate();
    return blink::toV8(imageData, state->context()->Global(), state->isolate());
}

Dart_Handle V8Converter::idbKeyRangeToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    return DartIDBKeyRange::toDart(V8IDBKeyRange::toNative(object));
}

Dart_Handle V8Converter::domStringListToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    return DartDOMStringList::toDart(V8DOMStringList::toNative(object));
}

Dart_Handle V8Converter::idbDatabaseToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    return DartIDBDatabase::toDart(V8IDBDatabase::toNative(object));
}

Dart_Handle V8Converter::idbFactoryToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    return DartIDBFactory::toDart(V8IDBFactory::toNative(object));
}

Dart_Handle V8Converter::idbCursorToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    return DartIDBCursor::toDart(V8IDBCursor::toNative(object));
}

Dart_Handle V8Converter::idbCursorWithValueToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    return DartIDBCursorWithValue::toDart(V8IDBCursorWithValue::toNative(object));
}

v8::Handle<v8::Value> V8Converter::idbKeyRangeToV8(Dart_Handle handle, Dart_Handle& exception)
{
    IDBKeyRange* keyRange = DartIDBKeyRange::toNative(handle, exception);
    if (exception)
        return v8::Handle<v8::Value>();

    V8ScriptState* state = DartUtilities::v8ScriptStateForCurrentIsolate();
    return blink::toV8(keyRange, state->context()->Global(), state->isolate());
}

v8::Handle<v8::Value> V8Converter::domStringListToV8(Dart_Handle handle, Dart_Handle& exception)
{
    DOMStringList* list = DartDOMStringList::toNative(handle, exception);
    if (exception)
        return v8::Handle<v8::Value>();

    V8ScriptState* state = DartUtilities::v8ScriptStateForCurrentIsolate();
    return blink::toV8(list, state->context()->Global(), state->isolate());
}

Dart_Handle V8Converter::listToDart(v8::Handle<v8::Array> value, V8ToDartMap& map, Dart_Handle& exception)
{
    ASSERT(value->IsArray());

    uint32_t length = value->Length();

    Dart_Handle list = Dart_NewList(length);
    ASSERT(!Dart_IsError(list));
    map.put(value, list);

    for (uint32_t i = 0; i < length; ++i) {
        Dart_Handle result = toDart(value->Get(i), map, exception);
        if (exception)
            return 0;
        if (!DartUtilities::checkResult(result, exception))
            return 0;
        result = Dart_ListSetAt(list, i, result);
        if (!DartUtilities::checkResult(result, exception))
            return 0;
    }

    return list;
}

v8::Handle<v8::Value> V8Converter::mapToV8(Dart_Handle value, DartToV8Map& map, Dart_Handle& exception)
{
    Dart_Handle asList = DartUtilities::invokeUtilsMethod("convertMapToList", 1, &value);
    if (!DartUtilities::checkResult(asList, exception))
        return v8::Handle<v8::Value>();
    ASSERT(Dart_IsList(asList));

    // Now we have a list [key, value, key, value, ....], create a v8 object and set necesary
    // properties on it.
    v8::Handle<v8::Object> object = v8::Object::New(v8::Isolate::GetCurrent());
    map.put(value, object);

    // We converted to internal Dart list, methods shouldn't throw exceptions now.
    intptr_t length = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_ListLength(asList, &length);
    ASSERT(!Dart_IsError(result));
    ASSERT(!(length % 2));
    for (intptr_t i = 0; i < length; i += 2) {
        v8::Handle<v8::Value> key = toV8(Dart_ListGetAt(asList, i), map, exception);
        if (exception)
            return v8::Handle<v8::Value>();
        v8::Handle<v8::Value> value = toV8(Dart_ListGetAt(asList, i + 1), map, exception);
        if (exception)
            return v8::Handle<v8::Value>();

        object->Set(key, value);
    }

    return object;
}

Dart_Handle V8Converter::mapToDart(v8::Handle<v8::Object> object, V8ToDartMap& map, Dart_Handle& exception)
{
    v8::Handle<v8::Array> ownPropertyNames = object->GetOwnPropertyNames();
    uint32_t ownPropertiesCount = ownPropertyNames->Length();

    Dart_Handle result = DartUtilities::invokeUtilsMethod("createMap", 0, 0);
    ASSERT(!Dart_IsError(result));
    map.put(object, result);

    Dart_Handle asList = Dart_NewList(ownPropertiesCount * 2);
    ASSERT(!Dart_IsError(asList));

    for (uint32_t i = 0; i < ownPropertiesCount; i++) {
        v8::Handle<v8::Value> v8key = ownPropertyNames->Get(i);

        Dart_Handle key = toDart(v8key, map, exception);
        if (exception)
            return 0;
        Dart_ListSetAt(asList, 2 * i, key);

        Dart_Handle value = toDart(object->Get(v8key), map, exception);
        if (exception)
            return 0;
        Dart_ListSetAt(asList, 2 * i + 1, value);
    }

    Dart_Handle args[2] = { result, asList };
    DartUtilities::invokeUtilsMethod("populateMap", 2, args);
    return result;
}

v8::Handle<v8::Value> V8Converter::arrayBufferToV8(Dart_Handle value, Dart_Handle& exception)
{
    V8ScriptState* state = DartUtilities::v8ScriptStateForCurrentIsolate();
    return blink::toV8(DartUtilities::dartToExternalizedArrayBuffer(value, exception).get(), state->context()->Global(), state->isolate());
}

Dart_Handle V8Converter::arrayBufferToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    return DartUtilities::arrayBufferToDart(V8ArrayBuffer::toNative(object));
}

v8::Handle<v8::Value> V8Converter::arrayBufferViewToV8(Dart_Handle value, Dart_Handle& exception)
{
    RefPtr<ArrayBufferView> view = DartUtilities::dartToExternalizedArrayBufferView(value, exception);
    V8ScriptState* state = DartUtilities::v8ScriptStateForCurrentIsolate();

    switch (view->type()) {
    case ArrayBufferView::TypeInt8:
        return blink::toV8(static_cast<Int8Array*>(view.get()), state->context()->Global(), state->isolate());
    case ArrayBufferView::TypeUint8:
        return blink::toV8(static_cast<Uint8Array*>(view.get()), state->context()->Global(), state->isolate());
    case ArrayBufferView::TypeUint8Clamped:
        return blink::toV8(static_cast<Uint8ClampedArray*>(view.get()), state->context()->Global(), state->isolate());
    case ArrayBufferView::TypeInt16:
        return blink::toV8(static_cast<Int16Array*>(view.get()), state->context()->Global(), state->isolate());
    case ArrayBufferView::TypeUint16:
        return blink::toV8(static_cast<Uint16Array*>(view.get()), state->context()->Global(), state->isolate());
    case ArrayBufferView::TypeInt32:
        return blink::toV8(static_cast<Int32Array*>(view.get()), state->context()->Global(), state->isolate());
    case ArrayBufferView::TypeUint32:
        return blink::toV8(static_cast<Uint32Array*>(view.get()), state->context()->Global(), state->isolate());
    case ArrayBufferView::TypeFloat32:
        return blink::toV8(static_cast<Float32Array*>(view.get()), state->context()->Global(), state->isolate());
    case ArrayBufferView::TypeFloat64:
        return blink::toV8(static_cast<Float64Array*>(view.get()), state->context()->Global(), state->isolate());
    case ArrayBufferView::TypeDataView:
        return blink::toV8(static_cast<DataView*>(view.get()), state->context()->Global(), state->isolate());
    default:
        ASSERT_NOT_REACHED();
        return v8::Handle<v8::Value>();
    }
}

Dart_Handle V8Converter::arrayBufferViewToDart(v8::Handle<v8::Object> object, Dart_Handle& exception)
{
    RefPtr<ArrayBufferView> view = V8ArrayBufferView::toNative(object);
    return DartUtilities::arrayBufferViewToDart(view.get());
}

} // namespace blink
