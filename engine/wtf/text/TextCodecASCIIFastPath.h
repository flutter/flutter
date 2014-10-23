/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef TextCodecASCIIFastPath_h
#define TextCodecASCIIFastPath_h

#include "wtf/text/ASCIIFastPath.h"

namespace WTF {

template<size_t size> struct UCharByteFiller;
template<> struct UCharByteFiller<4> {
    static void copy(LChar* destination, const uint8_t* source)
    {
        memcpy(destination, source, 4);
    }

    static void copy(UChar* destination, const uint8_t* source)
    {
        destination[0] = source[0];
        destination[1] = source[1];
        destination[2] = source[2];
        destination[3] = source[3];
    }
};
template<> struct UCharByteFiller<8> {
    static void copy(LChar* destination, const uint8_t* source)
    {
        memcpy(destination, source, 8);
    }

    static void copy(UChar* destination, const uint8_t* source)
    {
        destination[0] = source[0];
        destination[1] = source[1];
        destination[2] = source[2];
        destination[3] = source[3];
        destination[4] = source[4];
        destination[5] = source[5];
        destination[6] = source[6];
        destination[7] = source[7];
    }
};

inline void copyASCIIMachineWord(LChar* destination, const uint8_t* source)
{
    UCharByteFiller<sizeof(WTF::MachineWord)>::copy(destination, source);
}

inline void copyASCIIMachineWord(UChar* destination, const uint8_t* source)
{
    UCharByteFiller<sizeof(WTF::MachineWord)>::copy(destination, source);
}

} // namespace WTF

#endif // TextCodecASCIIFastPath_h
