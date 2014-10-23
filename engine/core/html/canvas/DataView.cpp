/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/html/canvas/DataView.h"

#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/custom/V8DataViewCustom.h"
#include "bindings/core/v8/custom/V8TypedArrayCustom.h"
#include "core/dom/ExceptionCode.h"
#include "platform/CheckedInt.h"
#include "wtf/CPU.h"

namespace {

template<typename T>
union Value {
    T data;
    char bytes[sizeof(T)];
};

}

namespace blink {

PassRefPtr<DataView> DataView::create(unsigned length)
{
    RefPtr<ArrayBuffer> buffer = ArrayBuffer::create(length, sizeof(uint8_t));
    if (!buffer.get())
        return nullptr;
    return create(buffer, 0, length);
}

PassRefPtr<DataView> DataView::create(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned byteLength)
{
    if (byteOffset > buffer->byteLength())
        return nullptr;
    CheckedInt<uint32_t> checkedOffset(byteOffset);
    CheckedInt<uint32_t> checkedLength(byteLength);
    CheckedInt<uint32_t> checkedMax = checkedOffset + checkedLength;
    if (!checkedMax.isValid() || checkedMax.value() > buffer->byteLength())
        return nullptr;
    return adoptRef(new DataView(buffer, byteOffset, byteLength));
}

DataView::DataView(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned byteLength)
    : ArrayBufferView(buffer, byteOffset)
    , m_byteLength(byteLength)
{
    ScriptWrappable::init(this);
}

static bool needToFlipBytes(bool littleEndian)
{
#if CPU(BIG_ENDIAN)
    return littleEndian;
#else
    return !littleEndian;
#endif
}

inline void swapBytes(char* p, char* q)
{
    char temp = *p;
    *p = *q;
    *q = temp;
}

static void flipBytesFor16Bits(char* p)
{
    swapBytes(p, p + 1);
}

static void flipBytesFor32Bits(char* p)
{
    swapBytes(p, p + 3);
    swapBytes(p + 1, p + 2);
}

static void flipBytesFor64Bits(char* p)
{
    swapBytes(p, p + 7);
    swapBytes(p + 1, p + 6);
    swapBytes(p + 2, p + 5);
    swapBytes(p + 3, p + 4);
}

static void flipBytesIfNeeded(char* value, size_t size, bool littleEndian)
{
    if (!needToFlipBytes(littleEndian))
        return;

    switch (size) {
    case 1:
        // Nothing to do.
        break;
    case 2:
        flipBytesFor16Bits(value);
        break;
    case 4:
        flipBytesFor32Bits(value);
        break;
    case 8:
        flipBytesFor64Bits(value);
        break;
    default:
        ASSERT_NOT_REACHED();
        break;
    }
}

template<typename T>
T DataView::getData(unsigned byteOffset, bool littleEndian, ExceptionState& exceptionState) const
{
    if (beyondRange<T>(byteOffset)) {
        exceptionState.throwDOMException(IndexSizeError, "The provided offset (" + String::number(byteOffset) + ") is outside the allowed range.");
        return 0;
    }

    // We do not want to load the data directly since it would cause a bus error on architectures that don't support unaligned loads.
    Value<T> value;
    memcpy(value.bytes, static_cast<const char*>(m_baseAddress) + byteOffset, sizeof(T));
    flipBytesIfNeeded(value.bytes, sizeof(T), littleEndian);
    return value.data;
}

template<typename T>
void DataView::setData(unsigned byteOffset, T value, bool littleEndian, ExceptionState& exceptionState)
{
    if (beyondRange<T>(byteOffset)) {
        exceptionState.throwDOMException(IndexSizeError, "The provided offset (" + String::number(byteOffset) + ") is outside the allowed range.");
        return;
    }

    // We do not want to store the data directly since it would cause a bus error on architectures that don't support unaligned stores.
    Value<T> tempValue;
    tempValue.data = value;
    flipBytesIfNeeded(tempValue.bytes, sizeof(T), littleEndian);
    memcpy(static_cast<char*>(m_baseAddress) + byteOffset, tempValue.bytes, sizeof(T));
}

int8_t DataView::getInt8(unsigned byteOffset, ExceptionState& exceptionState)
{
    return getData<int8_t>(byteOffset, false, exceptionState);
}

uint8_t DataView::getUint8(unsigned byteOffset, ExceptionState& exceptionState)
{
    return getData<uint8_t>(byteOffset, false, exceptionState);
}

int16_t DataView::getInt16(unsigned byteOffset, bool littleEndian, ExceptionState& exceptionState)
{
    return getData<int16_t>(byteOffset, littleEndian, exceptionState);
}

uint16_t DataView::getUint16(unsigned byteOffset, bool littleEndian, ExceptionState& exceptionState)
{
    return getData<uint16_t>(byteOffset, littleEndian, exceptionState);
}

int32_t DataView::getInt32(unsigned byteOffset, bool littleEndian, ExceptionState& exceptionState)
{
    return getData<int32_t>(byteOffset, littleEndian, exceptionState);
}

uint32_t DataView::getUint32(unsigned byteOffset, bool littleEndian, ExceptionState& exceptionState)
{
    return getData<uint32_t>(byteOffset, littleEndian, exceptionState);
}

float DataView::getFloat32(unsigned byteOffset, bool littleEndian, ExceptionState& exceptionState)
{
    return getData<float>(byteOffset, littleEndian, exceptionState);
}

double DataView::getFloat64(unsigned byteOffset, bool littleEndian, ExceptionState& exceptionState)
{
    return getData<double>(byteOffset, littleEndian, exceptionState);
}

void DataView::setInt8(unsigned byteOffset, int8_t value, ExceptionState& exceptionState)
{
    setData<int8_t>(byteOffset, value, false, exceptionState);
}

void DataView::setUint8(unsigned byteOffset, uint8_t value, ExceptionState& exceptionState)
{
    setData<uint8_t>(byteOffset, value, false, exceptionState);
}

void DataView::setInt16(unsigned byteOffset, short value, bool littleEndian, ExceptionState& exceptionState)
{
    setData<int16_t>(byteOffset, value, littleEndian, exceptionState);
}

void DataView::setUint16(unsigned byteOffset, uint16_t value, bool littleEndian, ExceptionState& exceptionState)
{
    setData<uint16_t>(byteOffset, value, littleEndian, exceptionState);
}

void DataView::setInt32(unsigned byteOffset, int32_t value, bool littleEndian, ExceptionState& exceptionState)
{
    setData<int32_t>(byteOffset, value, littleEndian, exceptionState);
}

void DataView::setUint32(unsigned byteOffset, uint32_t value, bool littleEndian, ExceptionState& exceptionState)
{
    setData<uint32_t>(byteOffset, value, littleEndian, exceptionState);
}

void DataView::setFloat32(unsigned byteOffset, float value, bool littleEndian, ExceptionState& exceptionState)
{
    setData<float>(byteOffset, value, littleEndian, exceptionState);
}

void DataView::setFloat64(unsigned byteOffset, double value, bool littleEndian, ExceptionState& exceptionState)
{
    setData<double>(byteOffset, value, littleEndian, exceptionState);
}

v8::Handle<v8::Object> DataView::wrap(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    return V8TypedArray<DataView>::wrap(this, creationContext, isolate);
}

void DataView::neuter()
{
    ArrayBufferView::neuter();
    m_byteLength = 0;
}

} // namespace blink
