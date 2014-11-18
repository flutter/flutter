/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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
#include "core/inspector/JSONParser.h"

#include "platform/JSONValues.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

namespace {

const int stackLimit = 1000;

enum Token {
    ObjectBegin,
    ObjectEnd,
    ArrayBegin,
    ArrayEnd,
    StringLiteral,
    Number,
    BoolTrue,
    BoolFalse,
    NullToken,
    ListSeparator,
    ObjectPairSeparator,
    InvalidToken,
};

const char* const nullString = "null";
const char* const trueString = "true";
const char* const falseString = "false";

template<typename CharType>
bool parseConstToken(const CharType* start, const CharType* end, const CharType** tokenEnd, const char* token)
{
    while (start < end && *token != '\0' && *start++ == *token++) { }
    if (*token != '\0')
        return false;
    *tokenEnd = start;
    return true;
}

template<typename CharType>
bool readInt(const CharType* start, const CharType* end, const CharType** tokenEnd, bool canHaveLeadingZeros)
{
    if (start == end)
        return false;
    bool haveLeadingZero = '0' == *start;
    int length = 0;
    while (start < end && '0' <= *start && *start <= '9') {
        ++start;
        ++length;
    }
    if (!length)
        return false;
    if (!canHaveLeadingZeros && length > 1 && haveLeadingZero)
        return false;
    *tokenEnd = start;
    return true;
}

template<typename CharType>
bool parseNumberToken(const CharType* start, const CharType* end, const CharType** tokenEnd)
{
    // We just grab the number here. We validate the size in DecodeNumber.
    // According to RFC4627, a valid number is: [minus] int [frac] [exp]
    if (start == end)
        return false;
    CharType c = *start;
    if ('-' == c)
        ++start;

    if (!readInt(start, end, &start, false))
        return false;
    if (start == end) {
        *tokenEnd = start;
        return true;
    }

    // Optional fraction part
    c = *start;
    if ('.' == c) {
        ++start;
        if (!readInt(start, end, &start, true))
            return false;
        if (start == end) {
            *tokenEnd = start;
            return true;
        }
        c = *start;
    }

    // Optional exponent part
    if ('e' == c || 'E' == c) {
        ++start;
        if (start == end)
            return false;
        c = *start;
        if ('-' == c || '+' == c) {
            ++start;
            if (start == end)
                return false;
        }
        if (!readInt(start, end, &start, true))
            return false;
    }

    *tokenEnd = start;
    return true;
}

template<typename CharType>
bool readHexDigits(const CharType* start, const CharType* end, const CharType** tokenEnd, int digits)
{
    if (end - start < digits)
        return false;
    for (int i = 0; i < digits; ++i) {
        CharType c = *start++;
        if (!(('0' <= c && c <= '9') || ('a' <= c && c <= 'f') || ('A' <= c && c <= 'F')))
            return false;
    }
    *tokenEnd = start;
    return true;
}

template<typename CharType>
bool parseStringToken(const CharType* start, const CharType* end, const CharType** tokenEnd)
{
    while (start < end) {
        CharType c = *start++;
        if ('\\' == c) {
            c = *start++;
            // Make sure the escaped char is valid.
            switch (c) {
            case 'x':
                if (!readHexDigits(start, end, &start, 2))
                    return false;
                break;
            case 'u':
                if (!readHexDigits(start, end, &start, 4))
                    return false;
                break;
            case '\\':
            case '/':
            case 'b':
            case 'f':
            case 'n':
            case 'r':
            case 't':
            case 'v':
            case '"':
                break;
            default:
                return false;
            }
        } else if ('"' == c) {
            *tokenEnd = start;
            return true;
        }
    }
    return false;
}

template<typename CharType>
Token parseToken(const CharType* start, const CharType* end, const CharType** tokenStart, const CharType** tokenEnd)
{
    while (start < end && isSpaceOrNewline(*start))
        ++start;

    if (start == end)
        return InvalidToken;

    *tokenStart = start;

    switch (*start) {
    case 'n':
        if (parseConstToken(start, end, tokenEnd, nullString))
            return NullToken;
        break;
    case 't':
        if (parseConstToken(start, end, tokenEnd, trueString))
            return BoolTrue;
        break;
    case 'f':
        if (parseConstToken(start, end, tokenEnd, falseString))
            return BoolFalse;
        break;
    case '[':
        *tokenEnd = start + 1;
        return ArrayBegin;
    case ']':
        *tokenEnd = start + 1;
        return ArrayEnd;
    case ',':
        *tokenEnd = start + 1;
        return ListSeparator;
    case '{':
        *tokenEnd = start + 1;
        return ObjectBegin;
    case '}':
        *tokenEnd = start + 1;
        return ObjectEnd;
    case ':':
        *tokenEnd = start + 1;
        return ObjectPairSeparator;
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
    case '-':
        if (parseNumberToken(start, end, tokenEnd))
            return Number;
        break;
    case '"':
        if (parseStringToken(start + 1, end, tokenEnd))
            return StringLiteral;
        break;
    }
    return InvalidToken;
}

template<typename CharType>
inline int hexToInt(CharType c)
{
    if ('0' <= c && c <= '9')
        return c - '0';
    if ('A' <= c && c <= 'F')
        return c - 'A' + 10;
    if ('a' <= c && c <= 'f')
        return c - 'a' + 10;
    ASSERT_NOT_REACHED();
    return 0;
}

template<typename CharType>
bool decodeString(const CharType* start, const CharType* end, StringBuilder* output)
{
    while (start < end) {
        UChar c = *start++;
        if ('\\' != c) {
            output->append(c);
            continue;
        }
        c = *start++;
        switch (c) {
        case '"':
        case '/':
        case '\\':
            break;
        case 'b':
            c = '\b';
            break;
        case 'f':
            c = '\f';
            break;
        case 'n':
            c = '\n';
            break;
        case 'r':
            c = '\r';
            break;
        case 't':
            c = '\t';
            break;
        case 'v':
            c = '\v';
            break;
        case 'x':
            c = (hexToInt(*start) << 4) +
                hexToInt(*(start + 1));
            start += 2;
            break;
        case 'u':
            c = (hexToInt(*start) << 12) +
                (hexToInt(*(start + 1)) << 8) +
                (hexToInt(*(start + 2)) << 4) +
                hexToInt(*(start + 3));
            start += 4;
            break;
        default:
            return false;
        }
        output->append(c);
    }
    return true;
}

template<typename CharType>
bool decodeString(const CharType* start, const CharType* end, String* output)
{
    if (start == end) {
        *output = "";
        return true;
    }
    if (start > end)
        return false;
    StringBuilder buffer;
    buffer.reserveCapacity(end - start);
    if (!decodeString(start, end, &buffer))
        return false;
    *output = buffer.toString();
    return true;
}

template<typename CharType>
PassRefPtr<JSONValue> buildValue(const CharType* start, const CharType* end, const CharType** valueTokenEnd, int depth)
{
    if (depth > stackLimit)
        return nullptr;

    RefPtr<JSONValue> result;
    const CharType* tokenStart;
    const CharType* tokenEnd;
    Token token = parseToken(start, end, &tokenStart, &tokenEnd);
    switch (token) {
    case InvalidToken:
        return nullptr;
    case NullToken:
        result = JSONValue::null();
        break;
    case BoolTrue:
        result = JSONBasicValue::create(true);
        break;
    case BoolFalse:
        result = JSONBasicValue::create(false);
        break;
    case Number: {
        bool ok;
        double value = charactersToDouble(tokenStart, tokenEnd - tokenStart, &ok);
        if (!ok)
            return nullptr;
        result = JSONBasicValue::create(value);
        break;
    }
    case StringLiteral: {
        String value;
        bool ok = decodeString(tokenStart + 1, tokenEnd - 1, &value);
        if (!ok)
            return nullptr;
        result = JSONString::create(value);
        break;
    }
    case ArrayBegin: {
        RefPtr<JSONArray> array = JSONArray::create();
        start = tokenEnd;
        token = parseToken(start, end, &tokenStart, &tokenEnd);
        while (token != ArrayEnd) {
            RefPtr<JSONValue> arrayNode = buildValue(start, end, &tokenEnd, depth + 1);
            if (!arrayNode)
                return nullptr;
            array->pushValue(arrayNode);

            // After a list value, we expect a comma or the end of the list.
            start = tokenEnd;
            token = parseToken(start, end, &tokenStart, &tokenEnd);
            if (token == ListSeparator) {
                start = tokenEnd;
                token = parseToken(start, end, &tokenStart, &tokenEnd);
                if (token == ArrayEnd)
                    return nullptr;
            } else if (token != ArrayEnd) {
                // Unexpected value after list value. Bail out.
                return nullptr;
            }
        }
        if (token != ArrayEnd)
            return nullptr;
        result = array.release();
        break;
    }
    case ObjectBegin: {
        RefPtr<JSONObject> object = JSONObject::create();
        start = tokenEnd;
        token = parseToken(start, end, &tokenStart, &tokenEnd);
        while (token != ObjectEnd) {
            if (token != StringLiteral)
                return nullptr;
            String key;
            if (!decodeString(tokenStart + 1, tokenEnd - 1, &key))
                return nullptr;
            start = tokenEnd;

            token = parseToken(start, end, &tokenStart, &tokenEnd);
            if (token != ObjectPairSeparator)
                return nullptr;
            start = tokenEnd;

            RefPtr<JSONValue> value = buildValue(start, end, &tokenEnd, depth + 1);
            if (!value)
                return nullptr;
            object->setValue(key, value);
            start = tokenEnd;

            // After a key/value pair, we expect a comma or the end of the
            // object.
            token = parseToken(start, end, &tokenStart, &tokenEnd);
            if (token == ListSeparator) {
                start = tokenEnd;
                token = parseToken(start, end, &tokenStart, &tokenEnd);
                if (token == ObjectEnd)
                    return nullptr;
            } else if (token != ObjectEnd) {
                // Unexpected value after last object value. Bail out.
                return nullptr;
            }
        }
        if (token != ObjectEnd)
            return nullptr;
        result = object.release();
        break;
    }

    default:
        // We got a token that's not a value.
        return nullptr;
    }
    *valueTokenEnd = tokenEnd;
    return result.release();
}

template<typename CharType>
PassRefPtr<JSONValue> parseJSONInternal(const CharType* start, unsigned length)
{
    const CharType* end = start + length;
    const CharType *tokenEnd;
    RefPtr<JSONValue> value = buildValue(start, end, &tokenEnd, 0);
    if (!value || tokenEnd != end)
        return nullptr;
    return value.release();
}

} // anonymous namespace

PassRefPtr<JSONValue> parseJSON(const String& json)
{
    if (json.isEmpty())
        return nullptr;
    if (json.is8Bit())
        return parseJSONInternal(json.characters8(), json.length());
    return parseJSONInternal(json.characters16(), json.length());
}

} // namespace blink
