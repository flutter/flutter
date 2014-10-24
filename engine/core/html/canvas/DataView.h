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

#ifndef DataView_h
#define DataView_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "wtf/ArrayBufferView.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class ExceptionState;

class DataView final : public ArrayBufferView, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<DataView> create(unsigned length);
    static PassRefPtr<DataView> create(PassRefPtr<ArrayBuffer>, unsigned byteOffset, unsigned byteLength);

    virtual unsigned byteLength() const override { return m_byteLength; }

    int8_t getInt8(unsigned byteOffset, ExceptionState&);
    uint8_t getUint8(unsigned byteOffset, ExceptionState&);
    int16_t getInt16(unsigned byteOffset, ExceptionState& ec) { return getInt16(byteOffset, false, ec); }
    int16_t getInt16(unsigned byteOffset, bool littleEndian, ExceptionState&);
    uint16_t getUint16(unsigned byteOffset, ExceptionState& ec) { return getUint16(byteOffset, false, ec); }
    uint16_t getUint16(unsigned byteOffset, bool littleEndian, ExceptionState&);
    int32_t getInt32(unsigned byteOffset, ExceptionState& ec) { return getInt32(byteOffset, false, ec); }
    int32_t getInt32(unsigned byteOffset, bool littleEndian, ExceptionState&);
    uint32_t getUint32(unsigned byteOffset, ExceptionState& ec) { return getUint32(byteOffset, false, ec); }
    uint32_t getUint32(unsigned byteOffset, bool littleEndian, ExceptionState&);
    float getFloat32(unsigned byteOffset, ExceptionState& ec) { return getFloat32(byteOffset, false, ec); }
    float getFloat32(unsigned byteOffset, bool littleEndian, ExceptionState&);
    double getFloat64(unsigned byteOffset, ExceptionState& ec) { return getFloat64(byteOffset, false, ec); }
    double getFloat64(unsigned byteOffset, bool littleEndian, ExceptionState&);

    void setInt8(unsigned byteOffset, int8_t value, ExceptionState&);
    void setUint8(unsigned byteOffset, uint8_t value, ExceptionState&);
    void setInt16(unsigned byteOffset, int16_t value, ExceptionState& ec) { setInt16(byteOffset, value, false, ec); }
    void setInt16(unsigned byteOffset, int16_t value, bool littleEndian, ExceptionState&);
    void setUint16(unsigned byteOffset, uint16_t value, ExceptionState& ec) { setUint16(byteOffset, value, false, ec); }
    void setUint16(unsigned byteOffset, uint16_t value, bool littleEndian, ExceptionState&);
    void setInt32(unsigned byteOffset, int32_t value, ExceptionState& ec) { setInt32(byteOffset, value, false, ec); }
    void setInt32(unsigned byteOffset, int32_t value, bool littleEndian, ExceptionState&);
    void setUint32(unsigned byteOffset, uint32_t value, ExceptionState& ec) { setUint32(byteOffset, value, false, ec); }
    void setUint32(unsigned byteOffset, uint32_t value, bool littleEndian, ExceptionState&);
    void setFloat32(unsigned byteOffset, float value, ExceptionState& ec) { setFloat32(byteOffset, value, false, ec); }
    void setFloat32(unsigned byteOffset, float value, bool littleEndian, ExceptionState&);
    void setFloat64(unsigned byteOffset, double value, ExceptionState& ec) { setFloat64(byteOffset, value, false, ec); }
    void setFloat64(unsigned byteOffset, double value, bool littleEndian, ExceptionState&);

    virtual ViewType type() const override
    {
        return TypeDataView;
    }

    virtual v8::Handle<v8::Object> wrap(v8::Handle<v8::Object> creationContext, v8::Isolate*) override;

protected:
    virtual void neuter() override;

private:
    DataView(PassRefPtr<ArrayBuffer>, unsigned byteOffset, unsigned byteLength);

    template<typename T>
    inline bool beyondRange(unsigned byteOffset) const { return byteOffset >= m_byteLength || byteOffset + sizeof(T) > m_byteLength; }

    template<typename T>
    T getData(unsigned byteOffset, bool littleEndian, ExceptionState&) const;

    template<typename T>
    void setData(unsigned byteOffset, T value, bool littleEndian, ExceptionState&);

    unsigned m_byteLength;
};

} // namespace blink

#endif // DataView_h
