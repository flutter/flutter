/*
 * Copyright (c) 2008, 2009, Google Inc. All rights reserved.
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
#include "VDMXParser.h"

#include <stdlib.h>
#include <string.h>

#include "wtf/ByteOrder.h"

// Buffer helper class
//
// This class perform some trival buffer operations while checking for
// out-of-bounds errors. As a family they return false if anything is amiss,
// updating the current offset otherwise.
class Buffer {
public:
    Buffer(const uint8_t* buffer, size_t length)
        : m_buffer(buffer)
        , m_length(length)
        , m_offset(0) { }

    bool skip(size_t numBytes)
    {
        if (m_offset + numBytes > m_length)
            return false;
        m_offset += numBytes;
        return true;
    }

    bool readU8(uint8_t* value)
    {
        if (m_offset + sizeof(uint8_t) > m_length)
            return false;
        *value = m_buffer[m_offset];
        m_offset += sizeof(uint8_t);
        return true;
    }

    bool readU16(uint16_t* value)
    {
        if (m_offset + sizeof(uint16_t) > m_length)
            return false;
        memcpy(value, m_buffer + m_offset, sizeof(uint16_t));
        *value = ntohs(*value);
        m_offset += sizeof(uint16_t);
        return true;
    }

    bool readS16(int16_t* value)
    {
        return readU16(reinterpret_cast<uint16_t*>(value));
    }

    size_t offset() const
    {
        return m_offset;
    }

    void setOffset(size_t newoffset)
    {
        m_offset = newoffset;
    }

private:
    const uint8_t *const m_buffer;
    const size_t m_length;
    size_t m_offset;
};

// VDMX parsing code.
//
// VDMX tables are found in some TrueType/OpenType fonts and contain
// ascender/descender overrides for certain (usually small) sizes. This is
// needed in order to match font metrics on Windows.
//
// Freetype does not parse these tables so we do so here.

namespace blink {

// Parse a TrueType VDMX table.
//   yMax: (output) the ascender value from the table
//   yMin: (output) the descender value from the table (negative!)
//   vdmx: the table bytes
//   vdmxLength: length of @vdmx, in bytes
//   targetPixelSize: the pixel size of the font (e.g. 16)
//
// Returns true iff a suitable match are found. Otherwise, *yMax and *yMin are
// untouched. size_t must be 32-bits to avoid overflow.
//
// See http://www.microsoft.com/opentype/otspec/vdmx.htm
bool parseVDMX(int* yMax, int* yMin,
               const uint8_t* vdmx, size_t vdmxLength,
               unsigned targetPixelSize)
{
    Buffer buf(vdmx, vdmxLength);

    // We ignore the version. Future tables should be backwards compatible with
    // this layout.
    uint16_t numRatios;
    if (!buf.skip(4) || !buf.readU16(&numRatios))
        return false;

    // Now we have two tables. Firstly we have @numRatios Ratio records, then a
    // matching array of @numRatios offsets. We save the offset of the beginning
    // of this second table.
    //
    // Range 6 <= x <= 262146
    unsigned long offsetTableOffset =
        buf.offset() + 4 /* sizeof struct ratio */ * numRatios;

    unsigned desiredRatio = 0xffffffff;
    // We read 4 bytes per record, so the offset range is
    //   6 <= x <= 524286
    for (unsigned i = 0; i < numRatios; ++i) {
        uint8_t xRatio, yRatio1, yRatio2;

        if (!buf.skip(1)
            || !buf.readU8(&xRatio)
            || !buf.readU8(&yRatio1)
            || !buf.readU8(&yRatio2))
            return false;

        // This either covers 1:1, or this is the default entry (0, 0, 0)
        if ((xRatio == 1 && yRatio1 <= 1 && yRatio2 >= 1)
            || (xRatio == 0 && yRatio1 == 0 && yRatio2 == 0)) {
            desiredRatio = i;
            break;
        }
    }

    if (desiredRatio == 0xffffffff) // no ratio found
        return false;

    // Range 10 <= x <= 393216
    buf.setOffset(offsetTableOffset + sizeof(uint16_t) * desiredRatio);

    // Now we read from the offset table to get the offset of another array
    uint16_t groupOffset;
    if (!buf.readU16(&groupOffset))
        return false;
    // Range 0 <= x <= 65535
    buf.setOffset(groupOffset);

    uint16_t numRecords;
    if (!buf.readU16(&numRecords) || !buf.skip(sizeof(uint16_t)))
        return false;

    // We read 6 bytes per record, so the offset range is
    //   4 <= x <= 458749
    for (unsigned i = 0; i < numRecords; ++i) {
        uint16_t pixelSize;
        if (!buf.readU16(&pixelSize))
            return false;
        // the entries are sorted, so we can abort early if need be
        if (pixelSize > targetPixelSize)
            return false;

        if (pixelSize == targetPixelSize) {
            int16_t tempYMax, tempYMin;
            if (!buf.readS16(&tempYMax)
                || !buf.readS16(&tempYMin))
                return false;
            *yMin = tempYMin;
            *yMax = tempYMax;
            return true;
        }
        if (!buf.skip(2 * sizeof(int16_t)))
            return false;
    }

    return false;
}

} // namespace blink
