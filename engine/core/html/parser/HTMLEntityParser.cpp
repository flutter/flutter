/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 * Copyright (C) 2009 Torch Mobile, Inc. http://www.torchmobile.com/
 * Copyright (C) 2010 Google, Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/html/parser/HTMLEntityParser.h"

#include "core/html/parser/HTMLEntitySearch.h"
#include "core/html/parser/HTMLEntityTable.h"
#include "wtf/text/StringBuilder.h"

using namespace WTF;

namespace blink {

static const UChar windowsLatin1ExtensionArray[32] = {
    0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, // 80-87
    0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F, // 88-8F
    0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, // 90-97
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178, // 98-9F
};

static bool isAlphaNumeric(UChar cc)
{
    return (cc >= '0' && cc <= '9') || (cc >= 'a' && cc <= 'z') || (cc >= 'A' && cc <= 'Z');
}

static UChar adjustEntity(UChar32 value)
{
    if ((value & ~0x1F) != 0x0080)
        return value;
    return windowsLatin1ExtensionArray[value - 0x80];
}

static void appendLegalEntityFor(UChar32 c, DecodedHTMLEntity& decodedEntity)
{
    // FIXME: A number of specific entity values generate parse errors.
    if (c <= 0 || c > 0x10FFFF || (c >= 0xD800 && c <= 0xDFFF)) {
        decodedEntity.append(0xFFFD);
        return;
    }
    if (U_IS_BMP(c)) {
        decodedEntity.append(adjustEntity(c));
        return;
    }
    decodedEntity.append(c);
}

static const UChar32 kInvalidUnicode = -1;

static bool isHexDigit(UChar cc)
{
    return (cc >= '0' && cc <= '9') || (cc >= 'a' && cc <= 'f') || (cc >= 'A' && cc <= 'F');
}

static UChar asHexDigit(UChar cc)
{
    if (cc >= '0' && cc <= '9')
      return cc - '0';
    if (cc >= 'a' && cc <= 'z')
      return 10 + cc - 'a';
    if (cc >= 'A' && cc <= 'Z')
      return 10 + cc - 'A';
    ASSERT_NOT_REACHED();
    return 0;
}

typedef Vector<UChar, 64> ConsumedCharacterBuffer;

static void unconsumeCharacters(SegmentedString& source, ConsumedCharacterBuffer& consumedCharacters)
{
    if (consumedCharacters.size() == 1)
        source.push(consumedCharacters[0]);
    else if (consumedCharacters.size() == 2) {
        source.push(consumedCharacters[0]);
        source.push(consumedCharacters[1]);
    } else
        source.prepend(SegmentedString(String(consumedCharacters)));
}

static bool consumeNamedEntity(SegmentedString& source, DecodedHTMLEntity& decodedEntity, bool& notEnoughCharacters, UChar additionalAllowedCharacter, UChar& cc)
{
    ConsumedCharacterBuffer consumedCharacters;
    HTMLEntitySearch entitySearch;
    while (!source.isEmpty()) {
        cc = source.currentChar();
        entitySearch.advance(cc);
        if (!entitySearch.isEntityPrefix())
            break;
        consumedCharacters.append(cc);
        source.advanceAndASSERT(cc);
    }
    notEnoughCharacters = source.isEmpty();
    if (notEnoughCharacters) {
        // We can't decide on an entity because there might be a longer entity
        // that we could match if we had more data.
        unconsumeCharacters(source, consumedCharacters);
        return false;
    }
    if (!entitySearch.mostRecentMatch()) {
        unconsumeCharacters(source, consumedCharacters);
        return false;
    }
    if (entitySearch.mostRecentMatch()->length != entitySearch.currentLength()) {
        // We've consumed too many characters. We need to walk the
        // source back to the point at which we had consumed an
        // actual entity.
        unconsumeCharacters(source, consumedCharacters);
        consumedCharacters.clear();
        const HTMLEntityTableEntry* mostRecent = entitySearch.mostRecentMatch();
        const int length = mostRecent->length;
        const LChar* reference = HTMLEntityTable::entityString(*mostRecent);
        for (int i = 0; i < length; ++i) {
            cc = source.currentChar();
            ASSERT_UNUSED(reference, cc == static_cast<UChar>(*reference++));
            consumedCharacters.append(cc);
            source.advanceAndASSERT(cc);
            ASSERT(!source.isEmpty());
        }
        cc = source.currentChar();
    }
    if (entitySearch.mostRecentMatch()->lastCharacter() == ';'
        || !additionalAllowedCharacter
        || !(isAlphaNumeric(cc) || cc == '=')) {
        decodedEntity.append(entitySearch.mostRecentMatch()->firstValue);
        if (UChar32 second = entitySearch.mostRecentMatch()->secondValue)
            decodedEntity.append(second);
        return true;
    }
    unconsumeCharacters(source, consumedCharacters);
    return false;
}

bool consumeHTMLEntity(SegmentedString& source, DecodedHTMLEntity& decodedEntity, bool& notEnoughCharacters, UChar additionalAllowedCharacter)
{
    ASSERT(!additionalAllowedCharacter || additionalAllowedCharacter == '"' || additionalAllowedCharacter == '\'' || additionalAllowedCharacter == '>');
    ASSERT(!notEnoughCharacters);
    ASSERT(decodedEntity.isEmpty());

    enum EntityState {
        Initial,
        Number,
        MaybeHexLowerCaseX,
        MaybeHexUpperCaseX,
        Hex,
        Decimal,
        Named
    };
    EntityState entityState = Initial;
    UChar32 result = 0;
    ConsumedCharacterBuffer consumedCharacters;

    while (!source.isEmpty()) {
        UChar cc = source.currentChar();
        switch (entityState) {
        case Initial: {
            if (cc == '\x09' || cc == '\x0A' || cc == '\x0C' || cc == ' ' || cc == '<' || cc == '&')
                return false;
            if (additionalAllowedCharacter && cc == additionalAllowedCharacter)
                return false;
            if (cc == '#') {
                entityState = Number;
                break;
            }
            if ((cc >= 'a' && cc <= 'z') || (cc >= 'A' && cc <= 'Z')) {
                entityState = Named;
                continue;
            }
            return false;
        }
        case Number: {
            if (cc == 'x') {
                entityState = MaybeHexLowerCaseX;
                break;
            }
            if (cc == 'X') {
                entityState = MaybeHexUpperCaseX;
                break;
            }
            if (cc >= '0' && cc <= '9') {
                entityState = Decimal;
                continue;
            }
            source.push('#');
            return false;
        }
        case MaybeHexLowerCaseX: {
            if (isHexDigit(cc)) {
                entityState = Hex;
                continue;
            }
            source.push('#');
            source.push('x');
            return false;
        }
        case MaybeHexUpperCaseX: {
            if (isHexDigit(cc)) {
                entityState = Hex;
                continue;
            }
            source.push('#');
            source.push('X');
            return false;
        }
        case Hex: {
            if (isHexDigit(cc)) {
                if (result != kInvalidUnicode)
                    result = result * 16 + asHexDigit(cc);
            } else if (cc == ';') {
                source.advanceAndASSERT(cc);
                appendLegalEntityFor(result, decodedEntity);
                return true;
            } else {
                appendLegalEntityFor(result, decodedEntity);
                return true;
            }
            break;
        }
        case Decimal: {
            if (cc >= '0' && cc <= '9') {
                if (result != kInvalidUnicode)
                    result = result * 10 + cc - '0';
            } else if (cc == ';') {
                source.advanceAndASSERT(cc);
                appendLegalEntityFor(result, decodedEntity);
                return true;
            } else {
                appendLegalEntityFor(result, decodedEntity);
                return true;
            }
            break;
        }
        case Named: {
            return consumeNamedEntity(source, decodedEntity, notEnoughCharacters, additionalAllowedCharacter, cc);
        }
        }

        if (result > UCHAR_MAX_VALUE)
            result = kInvalidUnicode;

        consumedCharacters.append(cc);
        source.advanceAndASSERT(cc);
    }
    ASSERT(source.isEmpty());
    notEnoughCharacters = true;
    unconsumeCharacters(source, consumedCharacters);
    return false;
}

static size_t appendUChar32ToUCharArray(UChar32 value, UChar* result)
{
    if (U_IS_BMP(value)) {
        UChar character = static_cast<UChar>(value);
        ASSERT(character == value);
        result[0] = character;
        return 1;
    }

    result[0] = U16_LEAD(value);
    result[1] = U16_TRAIL(value);
    return 2;
}

size_t decodeNamedEntityToUCharArray(const char* name, UChar result[4])
{
    HTMLEntitySearch search;
    while (*name) {
        search.advance(*name++);
        if (!search.isEntityPrefix())
            return 0;
    }
    search.advance(';');
    if (!search.isEntityPrefix())
        return 0;

    size_t numberOfCodePoints = appendUChar32ToUCharArray(search.mostRecentMatch()->firstValue, result);
    if (!search.mostRecentMatch()->secondValue)
        return numberOfCodePoints;
    return numberOfCodePoints + appendUChar32ToUCharArray(search.mostRecentMatch()->secondValue, result + numberOfCodePoints);
}

} // namespace blink
