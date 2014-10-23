/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
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

#ifndef HTMLParserIdioms_h
#define HTMLParserIdioms_h

#include "core/dom/QualifiedName.h"
#include "platform/Decimal.h"
#include "wtf/Forward.h"
#include "wtf/text/WTFString.h"

namespace WTF {
class TextEncoding;
}

namespace blink {

// Strip leading and trailing whitespace as defined by the HTML specification.
String stripLeadingAndTrailingHTMLSpaces(const String&);
template<size_t inlineCapacity>
String stripLeadingAndTrailingHTMLSpaces(const Vector<UChar, inlineCapacity>& vector)
{
    return stripLeadingAndTrailingHTMLSpaces(StringImpl::create8BitIfPossible(vector));
}

// An implementation of the HTML specification's algorithm to convert a number to a string for number and range types.
String serializeForNumberType(const Decimal&);
String serializeForNumberType(double);

// Convert the specified string to a decimal/double. If the conversion fails, the return value is fallback value or NaN if not specified.
// Leading or trailing illegal characters cause failure, as does passing an empty string.
// The double* parameter may be 0 to check if the string can be parsed without getting the result.
Decimal parseToDecimalForNumberType(const String&, const Decimal& fallbackValue = Decimal::nan());
double parseToDoubleForNumberType(const String&, double fallbackValue = std::numeric_limits<double>::quiet_NaN());

// http://www.whatwg.org/specs/web-apps/current-work/#rules-for-parsing-integers
bool parseHTMLInteger(const String&, int&);

// http://www.whatwg.org/specs/web-apps/current-work/#rules-for-parsing-non-negative-integers
bool parseHTMLNonNegativeInteger(const String&, unsigned&);

typedef Vector<pair<String, String> > HTMLAttributeList;
// The returned encoding might not be valid.
WTF::TextEncoding encodingFromMetaAttributes(const HTMLAttributeList&);

// Space characters as defined by the HTML specification.
template<typename CharType>
inline bool isHTMLSpace(CharType character)
{
    // Histogram from Apple's page load test combined with some ad hoc browsing some other test suites.
    //
    //     82%: 216330 non-space characters, all > U+0020
    //     11%:  30017 plain space characters, U+0020
    //      5%:  12099 newline characters, U+000A
    //      2%:   5346 tab characters, U+0009
    //
    // No other characters seen. No U+000C or U+000D, and no other control characters.
    // Accordingly, we check for non-spaces first, then space, then newline, then tab, then the other characters.

    return character <= ' ' && (character == ' ' || character == '\n' || character == '\t' || character == '\r' || character == '\f');
}

template<typename CharType>
inline bool isComma(CharType character)
{
    return character == ',';
}

template<typename CharType>
inline bool isHTMLSpaceOrComma(CharType character)
{
    return isComma(character) || isHTMLSpace(character);
}

inline bool isHTMLLineBreak(UChar character)
{
    return character <= '\r' && (character == '\n' || character == '\r');
}

template<typename CharType>
inline bool isNotHTMLSpace(CharType character)
{
    return !isHTMLSpace<CharType>(character);
}

bool threadSafeMatch(const QualifiedName&, const QualifiedName&);
bool threadSafeMatch(const String&, const QualifiedName&);

enum CharacterWidth {
    Likely8Bit,
    Force8Bit,
    Force16Bit
};

String attemptStaticStringCreation(const LChar*, size_t);

String attemptStaticStringCreation(const UChar*, size_t, CharacterWidth);

template<size_t inlineCapacity>
inline static String attemptStaticStringCreation(const Vector<UChar, inlineCapacity>& vector, CharacterWidth width)
{
    return attemptStaticStringCreation(vector.data(), vector.size(), width);
}

inline static String attemptStaticStringCreation(const String str)
{
    if (!str.is8Bit())
        return attemptStaticStringCreation(str.characters16(), str.length(), Force16Bit);
    return attemptStaticStringCreation(str.characters8(), str.length());
}


}
#endif
