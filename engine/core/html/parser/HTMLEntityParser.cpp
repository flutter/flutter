// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/html/parser/HTMLEntityParser.h"

#include "sky/engine/wtf/unicode/CharacterNames.h"

using namespace WTF;

namespace blink {

static const UChar32 kInvalidUnicode = -1;

static UChar asHexDigit(UChar cc)
{
    if (cc >= '0' && cc <= '9')
      return cc - '0';
    if (cc >= 'a' && cc <= 'f')
      return 10 + cc - 'a';
    if (cc >= 'A' && cc <= 'F')
      return 10 + cc - 'A';
    ASSERT_NOT_REACHED();
    return 0;
}

static bool isAlphaNumeric(UChar cc)
{
    return (cc >= '0' && cc <= '9') || (cc >= 'a' && cc <= 'z') || (cc >= 'A' && cc <= 'Z');
}

static bool isHexDigit(UChar cc)
{
    return (cc >= '0' && cc <= '9') || (cc >= 'a' && cc <= 'f') || (cc >= 'A' && cc <= 'F');
}

static UChar decodeEntity(HTMLEntityParser::OutputBuffer buffer)
{
    if (equalIgnoringNullity(buffer, "&amp"))
        return '&';
    if (equalIgnoringNullity(buffer, "&apos"))
        return '\'';
    if (equalIgnoringNullity(buffer, "&gt"))
        return '>';
    if (equalIgnoringNullity(buffer, "&lt"))
        return '<';
    if (equalIgnoringNullity(buffer, "&quot"))
        return '"';
    return replacementCharacter;
}

HTMLEntityParser::HTMLEntityParser()
{
}

HTMLEntityParser::~HTMLEntityParser()
{
}

void HTMLEntityParser::reset()
{
    m_state = Initial;
    m_result = '\0';
    m_buffer.clear();
    m_buffer.append('&');
}

bool HTMLEntityParser::parse(SegmentedString& source)
{
    while (!source.isEmpty()) {
        UChar cc = source.currentChar();
        switch (m_state) {
        case Initial: {
            if (cc == '#') {
                m_state = Numeric;
                break;
            }
            if (isAlphaNumeric(cc)) {
                m_state = Named;
                continue;
            }
            return true;
        }
        case Numeric: {
            if (cc == 'x' || cc == 'X') {
                m_state = PossiblyHex;
                break;
            }
            if (cc >= '0' && cc <= '9') {
                m_state = Decimal;
                continue;
            }
            return true;
        }
        case PossiblyHex: {
            if (isHexDigit(cc)) {
                m_state = Hex;
                continue;
            }
            return true;
        }
        case Hex: {
            if (isHexDigit(cc)) {
                if (m_result != kInvalidUnicode)
                    m_result = m_result * 16 + asHexDigit(cc);
                break;
            }
            if (cc == ';') {
                source.advanceAndASSERT(cc);
                finalizeNumericEntity();
                return true;
            }
            return true;
        }
        case Decimal: {
            if (cc >= '0' && cc <= '9') {
                if (m_result != kInvalidUnicode)
                    m_result = m_result * 10 + cc - '0';
                break;
            }
            if (cc == ';') {
                source.advanceAndASSERT(cc);
                finalizeNumericEntity();
                return true;
            }
            return true;
        }
        case Named: {
            if (isAlphaNumeric(cc))
                break;
            if (cc == ';') {
                source.advanceAndASSERT(cc);
                finalizeNamedEntity();
                return true;
            }
            return true;
        }
        }

        if (m_result > UCHAR_MAX_VALUE)
            m_result = kInvalidUnicode;

        m_buffer.append(cc);
        source.advanceAndASSERT(cc);
    }
    ASSERT(source.isEmpty());
    return false;
}

void HTMLEntityParser::finalizeNumericEntity()
{
    m_buffer.clear();
    if (m_result <= 0 || m_result > 0x10FFFF || (m_result >= 0xD800 && m_result <= 0xDFFF)) {
        m_buffer.append(replacementCharacter);
    } else if (U_IS_BMP(m_result)) {
        m_buffer.append(m_result);
    } else {
        m_buffer.append(U16_LEAD(m_result));
        m_buffer.append(U16_TRAIL(m_result));
    }
}

void HTMLEntityParser::finalizeNamedEntity()
{
    UChar decodedEntity = decodeEntity(m_buffer);
    m_buffer.clear();
    m_buffer.append(decodedEntity);
}

} // namespace blink
