/*
 * Copyright (C) 2007, 2008, 2009, 2011 Apple Inc. All rights reserved.
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
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
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

#ifndef WTF_ASCIICType_h
#define WTF_ASCIICType_h

#include "wtf/Assertions.h"

// The behavior of many of the functions in the <ctype.h> header is dependent
// on the current locale. But in the WebKit project, all uses of those functions
// are in code processing something that's not locale-specific. These equivalents
// for some of the <ctype.h> functions are named more explicitly, not dependent
// on the C library locale, and we should also optimize them as needed.

// All functions return false or leave the character unchanged if passed a character
// that is outside the range 0-7F. So they can be used on Unicode strings or
// characters if the intent is to do processing only if the character is ASCII.

namespace WTF {

template<typename CharType> inline bool isASCII(CharType c)
{
    return !(c & ~0x7F);
}

template<typename CharType> inline bool isASCIIAlpha(CharType c)
{
    return (c | 0x20) >= 'a' && (c | 0x20) <= 'z';
}

template<typename CharType> inline bool isASCIIDigit(CharType c)
{
    return c >= '0' && c <= '9';
}

template<typename CharType> inline bool isASCIIAlphanumeric(CharType c)
{
    return isASCIIDigit(c) || isASCIIAlpha(c);
}

template<typename CharType> inline bool isASCIIHexDigit(CharType c)
{
    return isASCIIDigit(c) || ((c | 0x20) >= 'a' && (c | 0x20) <= 'f');
}

template<typename CharType> inline bool isASCIILower(CharType c)
{
    return c >= 'a' && c <= 'z';
}

template<typename CharType> inline bool isASCIIOctalDigit(CharType c)
{
    return (c >= '0') & (c <= '7');
}

template<typename CharType> inline bool isASCIIPrintable(CharType c)
{
    return c >= ' ' && c <= '~';
}

/*
 Statistics from a run of Apple's page load test for callers of isASCIISpace:

 character          count
 ---------          -----
 non-spaces         689383
 20  space          294720
 0A  \n             89059
 09  \t             28320
 0D  \r             0
 0C  \f             0
 0B  \v             0
 */
template<typename CharType> inline bool isASCIISpace(CharType c)
{
    return c <= ' ' && (c == ' ' || (c <= 0xD && c >= 0x9));
}

template<typename CharType> inline bool isASCIIUpper(CharType c)
{
    return c >= 'A' && c <= 'Z';
}

template<typename CharType> inline CharType toASCIILower(CharType c)
{
#if defined(_MSC_FULL_VER) && _MSC_FULL_VER == 170060610
    // Make a workaround for VS2012 update 3 optimizer bug, remove once VS2012 fix it.
    return (c >= 'A' && c <= 'Z') ? c + 0x20 : c;
#else
    return c | ((c >= 'A' && c <= 'Z') << 5);
#endif
}

template<typename CharType> inline CharType toASCIILowerUnchecked(CharType character)
{
    // This function can be used for comparing any input character
    // to a lowercase English character. The isASCIIAlphaCaselessEqual
    // below should be used for regular comparison of ASCII alpha
    // characters, but switch statements in CSS tokenizer require
    // direct use of this function.
    return character | 0x20;
}

template<typename CharType> inline CharType toASCIIUpper(CharType c)
{
    return c & ~((c >= 'a' && c <= 'z') << 5);
}

template<typename CharType> inline int toASCIIHexValue(CharType c)
{
    ASSERT(isASCIIHexDigit(c));
    return c < 'A' ? c - '0' : (c - 'A' + 10) & 0xF;
}

template<typename CharType> inline int toASCIIHexValue(CharType upperValue, CharType lowerValue)
{
    ASSERT(isASCIIHexDigit(upperValue) && isASCIIHexDigit(lowerValue));
    return ((toASCIIHexValue(upperValue) << 4) & 0xF0) | toASCIIHexValue(lowerValue);
}

inline char lowerNibbleToASCIIHexDigit(char c)
{
    char nibble = c & 0xF;
    return nibble < 10 ? '0' + nibble : 'A' + nibble - 10;
}

inline char upperNibbleToASCIIHexDigit(char c)
{
    char nibble = (c >> 4) & 0xF;
    return nibble < 10 ? '0' + nibble : 'A' + nibble - 10;
}

template<typename CharType> inline bool isASCIIAlphaCaselessEqual(CharType cssCharacter, char character)
{
    // This function compares a (preferrably) constant ASCII
    // lowercase letter to any input character.
    ASSERT(character >= 'a' && character <= 'z');
    return LIKELY(toASCIILowerUnchecked(cssCharacter) == character);
}

}

using WTF::isASCII;
using WTF::isASCIIAlpha;
using WTF::isASCIIAlphanumeric;
using WTF::isASCIIDigit;
using WTF::isASCIIHexDigit;
using WTF::isASCIILower;
using WTF::isASCIIOctalDigit;
using WTF::isASCIIPrintable;
using WTF::isASCIISpace;
using WTF::isASCIIUpper;
using WTF::toASCIIHexValue;
using WTF::toASCIILower;
using WTF::toASCIILowerUnchecked;
using WTF::toASCIIUpper;
using WTF::lowerNibbleToASCIIHexDigit;
using WTF::upperNibbleToASCIIHexDigit;
using WTF::isASCIIAlphaCaselessEqual;

#endif
