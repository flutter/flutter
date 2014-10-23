/*
   Copyright (C) 2000-2001 Dawit Alemayehu <adawit@kde.org>
   Copyright (C) 2006 Alexey Proskuryakov <ap@webkit.org>
   Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
   Copyright (C) 2010 Patrick Gansterer <paroga@paroga.com>

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License (LGPL)
   version 2 as published by the Free Software Foundation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

   This code is based on the java implementation in HTTPClient
   package by Ronald Tschalär Copyright (C) 1996-1999.
*/

#include "config.h"
#include "Base64.h"

#include <limits.h>
#include "wtf/StringExtras.h"

namespace WTF {

static const char base64EncMap[64] = {
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
    0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50,
    0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
    0x59, 0x5A, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66,
    0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E,
    0x6F, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76,
    0x77, 0x78, 0x79, 0x7A, 0x30, 0x31, 0x32, 0x33,
    0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x2B, 0x2F
};

static const char base64DecMap[128] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x3E, 0x00, 0x00, 0x00, 0x3F,
    0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B,
    0x3C, 0x3D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06,
    0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E,
    0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16,
    0x17, 0x18, 0x19, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20,
    0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28,
    0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30,
    0x31, 0x32, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00
};

String base64Encode(const char* data, unsigned length, Base64EncodePolicy policy)
{
    Vector<char> result;
    base64Encode(data, length, result, policy);
    return String(result.data(), result.size());
}

void base64Encode(const char* data, unsigned len, Vector<char>& out, Base64EncodePolicy policy)
{
    out.clear();
    if (!len)
        return;

    // If the input string is pathologically large, just return nothing.
    // Note: Keep this in sync with the "outLength" computation below.
    // Rather than being perfectly precise, this is a bit conservative.
    const unsigned maxInputBufferSize = UINT_MAX / 77 * 76 / 4 * 3 - 2;
    if (len > maxInputBufferSize)
        return;

    unsigned sidx = 0;
    unsigned didx = 0;

    unsigned outLength = ((len + 2) / 3) * 4;

    // Deal with the 76 character per line limit specified in RFC 2045.
    bool insertLFs = (policy == Base64InsertLFs && outLength > 76);
    if (insertLFs)
        outLength += ((outLength - 1) / 76);

    int count = 0;
    out.grow(outLength);

    // 3-byte to 4-byte conversion + 0-63 to ascii printable conversion
    if (len > 1) {
        while (sidx < len - 2) {
            if (insertLFs) {
                if (count && !(count % 76))
                    out[didx++] = '\n';
                count += 4;
            }
            out[didx++] = base64EncMap[(data[sidx] >> 2) & 077];
            out[didx++] = base64EncMap[((data[sidx + 1] >> 4) & 017) | ((data[sidx] << 4) & 077)];
            out[didx++] = base64EncMap[((data[sidx + 2] >> 6) & 003) | ((data[sidx + 1] << 2) & 077)];
            out[didx++] = base64EncMap[data[sidx + 2] & 077];
            sidx += 3;
        }
    }

    if (sidx < len) {
        if (insertLFs && (count > 0) && !(count % 76))
           out[didx++] = '\n';

        out[didx++] = base64EncMap[(data[sidx] >> 2) & 077];
        if (sidx < len - 1) {
            out[didx++] = base64EncMap[((data[sidx + 1] >> 4) & 017) | ((data[sidx] << 4) & 077)];
            out[didx++] = base64EncMap[(data[sidx + 1] << 2) & 077];
        } else
            out[didx++] = base64EncMap[(data[sidx] << 4) & 077];
    }

    // Add padding
    while (didx < out.size()) {
        out[didx] = '=';
        ++didx;
    }
}

bool base64Decode(const Vector<char>& in, Vector<char>& out, CharacterMatchFunctionPtr shouldIgnoreCharacter, Base64DecodePolicy policy)
{
    out.clear();

    // If the input string is pathologically large, just return nothing.
    if (in.size() > UINT_MAX)
        return false;

    return base64Decode(in.data(), in.size(), out, shouldIgnoreCharacter, policy);
}

template<typename T>
static inline bool base64DecodeInternal(const T* data, unsigned length, Vector<char>& out, CharacterMatchFunctionPtr shouldIgnoreCharacter, Base64DecodePolicy policy)
{
    out.clear();
    if (!length)
        return true;

    out.grow(length);

    unsigned equalsSignCount = 0;
    unsigned outLength = 0;
    bool hadError = false;
    for (unsigned idx = 0; idx < length; ++idx) {
        unsigned ch = data[idx];
        if (ch == '=') {
            ++equalsSignCount;
            // There should never be more than 2 padding characters.
            if (policy == Base64ValidatePadding && equalsSignCount > 2) {
                hadError = true;
                break;
            }
        } else if (('0' <= ch && ch <= '9') || ('A' <= ch && ch <= 'Z') || ('a' <= ch && ch <= 'z') || ch == '+' || ch == '/') {
            if (equalsSignCount) {
                hadError = true;
                break;
            }
            out[outLength++] = base64DecMap[ch];
        } else if (!shouldIgnoreCharacter || !shouldIgnoreCharacter(ch)) {
            hadError = true;
            break;
        }
    }

    if (outLength < out.size())
        out.shrink(outLength);

    if (hadError)
        return false;

    if (!outLength)
        return !equalsSignCount;

    // There should be no padding if length is a multiple of 4.
    // We use (outLength + equalsSignCount) instead of length because we don't want to account for ignored characters.
    if (policy == Base64ValidatePadding && equalsSignCount && (outLength + equalsSignCount) % 4)
        return false;

    // Valid data is (n * 4 + [0,2,3]) characters long.
    if ((outLength % 4) == 1)
        return false;

    // 4-byte to 3-byte conversion
    outLength -= (outLength + 3) / 4;
    if (!outLength)
        return false;

    unsigned sidx = 0;
    unsigned didx = 0;
    if (outLength > 1) {
        while (didx < outLength - 2) {
            out[didx] = (((out[sidx] << 2) & 255) | ((out[sidx + 1] >> 4) & 003));
            out[didx + 1] = (((out[sidx + 1] << 4) & 255) | ((out[sidx + 2] >> 2) & 017));
            out[didx + 2] = (((out[sidx + 2] << 6) & 255) | (out[sidx + 3] & 077));
            sidx += 4;
            didx += 3;
        }
    }

    if (didx < outLength)
        out[didx] = (((out[sidx] << 2) & 255) | ((out[sidx + 1] >> 4) & 003));

    if (++didx < outLength)
        out[didx] = (((out[sidx + 1] << 4) & 255) | ((out[sidx + 2] >> 2) & 017));

    if (outLength < out.size())
        out.shrink(outLength);

    return true;
}

bool base64Decode(const char* data, unsigned length, Vector<char>& out, CharacterMatchFunctionPtr shouldIgnoreCharacter, Base64DecodePolicy policy)
{
    return base64DecodeInternal<LChar>(reinterpret_cast<const LChar*>(data), length, out, shouldIgnoreCharacter, policy);
}

bool base64Decode(const UChar* data, unsigned length, Vector<char>& out, CharacterMatchFunctionPtr shouldIgnoreCharacter, Base64DecodePolicy policy)
{
    return base64DecodeInternal<UChar>(data, length, out, shouldIgnoreCharacter, policy);
}

bool base64Decode(const String& in, Vector<char>& out, CharacterMatchFunctionPtr shouldIgnoreCharacter, Base64DecodePolicy policy)
{
    if (in.isEmpty())
        return base64DecodeInternal<LChar>(0, 0, out, shouldIgnoreCharacter, policy);
    if (in.is8Bit())
        return base64DecodeInternal<LChar>(in.characters8(), in.length(), out, shouldIgnoreCharacter, policy);
    return base64DecodeInternal<UChar>(in.characters16(), in.length(), out, shouldIgnoreCharacter, policy);
}

} // namespace WTF
