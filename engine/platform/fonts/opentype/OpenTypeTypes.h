/*
 * Copyright (C) 2012 Koji Ishii <kojiishi@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef OpenTypeTypes_h
#define OpenTypeTypes_h

#include "platform/SharedBuffer.h"
#include "wtf/ByteOrder.h"

namespace blink {
namespace OpenType {

struct Int16 {
    Int16(int16_t u) : v(htons(static_cast<uint16_t>(u))) { }
    operator int16_t() const { return static_cast<int16_t>(ntohs(v)); }
    uint16_t v; // in BigEndian
};

struct UInt16 {
    UInt16(uint16_t u) : v(htons(u)) { }
    operator uint16_t() const { return ntohs(v); }
    uint16_t v; // in BigEndian
};

struct Int32 {
    Int32(int32_t u) : v(htonl(static_cast<uint32_t>(u))) { }
    operator int32_t() const { return static_cast<int32_t>(ntohl(v)); }
    uint32_t v; // in BigEndian
};

struct UInt32 {
    UInt32(uint32_t u) : v(htonl(u)) { }
    operator uint32_t() const { return ntohl(v); }
    uint32_t v; // in BigEndian
};

typedef UInt32 Fixed;
typedef UInt16 Offset;
typedef UInt16 GlyphID;

// OTTag is native because it's only compared against constants, so we don't
// do endian conversion here but make sure constants are in big-endian order.
// Note that multi-character literal is implementation-defined in C++0x.
typedef uint32_t Tag;
#define OT_MAKE_TAG(ch1, ch2, ch3, ch4) ((((uint32_t)(ch4)) << 24) | (((uint32_t)(ch3)) << 16) | (((uint32_t)(ch2)) << 8) | ((uint32_t)(ch1)))

template <typename T> static const T* validateTable(const RefPtr<SharedBuffer>& buffer, size_t count = 1)
{
    if (!buffer || buffer->size() < sizeof(T) * count)
        return 0;
    return reinterpret_cast<const T*>(buffer->data());
}

struct TableBase {
protected:
    static bool isValidEnd(const SharedBuffer& buffer, const void* position)
    {
        if (position < buffer.data())
            return false;
        size_t offset = reinterpret_cast<const char*>(position) - buffer.data();
        return offset <= buffer.size(); // "<=" because end is included as valid
    }

    template <typename T> static const T* validatePtr(const SharedBuffer& buffer, const void* position)
    {
        const T* casted = reinterpret_cast<const T*>(position);
        if (!isValidEnd(buffer, &casted[1]))
            return 0;
        return casted;
    }

    template <typename T> const T* validateOffset(const SharedBuffer& buffer, uint16_t offset) const
    {
        return validatePtr<T>(buffer, reinterpret_cast<const int8_t*>(this) + offset);
    }
};

} // namespace OpenType
} // namespace blink
#endif // OpenTypeTypes_h
