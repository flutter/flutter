/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 *           (C) 2006 Alexey Proskuryakov (ap@nypop.com)
 * Copyright (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "platform/network/FormDataBuilder.h"

#include <limits>
#include "wtf/CryptographicallyRandomNumber.h"
#include "wtf/HexNumber.h"
#include "wtf/text/CString.h"
#include "wtf/text/TextEncoding.h"

namespace blink {

// Helper functions
static inline void append(Vector<char>& buffer, char string)
{
    buffer.append(string);
}

static inline void append(Vector<char>& buffer, const char* string)
{
    buffer.append(string, strlen(string));
}

static inline void append(Vector<char>& buffer, const CString& string)
{
    buffer.append(string.data(), string.length());
}

static void appendQuotedString(Vector<char>& buffer, const CString& string)
{
    // Append a string as a quoted value, escaping quotes and line breaks.
    // FIXME: Is it correct to use percent escaping here? Other browsers do not encode these characters yet,
    // so we should test popular servers to find out if there is an encoding form they can handle.
    size_t length = string.length();
    for (size_t i = 0; i < length; ++i) {
        char c = string.data()[i];

        switch (c) {
        case  0x0a:
            append(buffer, "%0A");
            break;
        case 0x0d:
            append(buffer, "%0D");
            break;
        case '"':
            append(buffer, "%22");
            break;
        default:
            append(buffer, c);
        }
    }
}

WTF::TextEncoding FormDataBuilder::encodingFromAcceptCharset(const String& acceptCharset, const String& inputEncoding, const String& defaultCharset)
{
    String normalizedAcceptCharset = acceptCharset;
    normalizedAcceptCharset.replace(',', ' ');

    Vector<String> charsets;
    normalizedAcceptCharset.split(' ', charsets);

    WTF::TextEncoding encoding;

    Vector<String>::const_iterator end = charsets.end();
    for (Vector<String>::const_iterator it = charsets.begin(); it != end; ++it) {
        if ((encoding = WTF::TextEncoding(*it)).isValid())
            return encoding;
    }

    if (inputEncoding.isEmpty()) {
        if (defaultCharset.isEmpty())
            return WTF::UTF8Encoding();

        return defaultCharset;
    }

    return inputEncoding;
}

Vector<char> FormDataBuilder::generateUniqueBoundaryString()
{
    Vector<char> boundary;

    // The RFC 2046 spec says the alphanumeric characters plus the
    // following characters are legal for boundaries:  '()+_,-./:=?
    // However the following characters, though legal, cause some sites
    // to fail: (),./:=+
    // Note that our algorithm makes it twice as much likely for 'A' or 'B'
    // to appear in the boundary string, because 0x41 and 0x42 are present in
    // the below array twice.
    static const char alphaNumericEncodingMap[64] = {
        0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
        0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50,
        0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
        0x59, 0x5A, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66,
        0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E,
        0x6F, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76,
        0x77, 0x78, 0x79, 0x7A, 0x30, 0x31, 0x32, 0x33,
        0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x41, 0x42
    };

    // Start with an informative prefix.
    append(boundary, "----WebKitFormBoundary");

    // Append 16 random 7bit ascii AlphaNumeric characters.
    Vector<char> randomBytes;

    for (unsigned i = 0; i < 4; ++i) {
        uint32_t randomness = cryptographicallyRandomNumber();
        randomBytes.append(alphaNumericEncodingMap[(randomness >> 24) & 0x3F]);
        randomBytes.append(alphaNumericEncodingMap[(randomness >> 16) & 0x3F]);
        randomBytes.append(alphaNumericEncodingMap[(randomness >> 8) & 0x3F]);
        randomBytes.append(alphaNumericEncodingMap[randomness & 0x3F]);
    }

    boundary.appendVector(randomBytes);
    boundary.append(0); // Add a 0 at the end so we can use this as a C-style string.
    return boundary;
}

void FormDataBuilder::beginMultiPartHeader(Vector<char>& buffer, const CString& boundary, const CString& name)
{
    addBoundaryToMultiPartHeader(buffer, boundary);

    // FIXME: This loses data irreversibly if the input name includes characters you can't encode
    // in the website's character set.
    append(buffer, "Content-Disposition: form-data; name=\"");
    appendQuotedString(buffer, name);
    append(buffer, '"');
}

void FormDataBuilder::addBoundaryToMultiPartHeader(Vector<char>& buffer, const CString& boundary, bool isLastBoundary)
{
    append(buffer, "--");
    append(buffer, boundary);

    if (isLastBoundary)
        append(buffer, "--");

    append(buffer, "\r\n");
}

void FormDataBuilder::addFilenameToMultiPartHeader(Vector<char>& buffer, const WTF::TextEncoding& encoding, const String& filename)
{
    // FIXME: This loses data irreversibly if the filename includes characters you can't encode
    // in the website's character set.
    append(buffer, "; filename=\"");
    appendQuotedString(buffer, encoding.normalizeAndEncode(filename, WTF::QuestionMarksForUnencodables));
    append(buffer, '"');
}

void FormDataBuilder::addContentTypeToMultiPartHeader(Vector<char>& buffer, const CString& mimeType)
{
    append(buffer, "\r\nContent-Type: ");
    append(buffer, mimeType);
}

void FormDataBuilder::finishMultiPartHeader(Vector<char>& buffer)
{
    append(buffer, "\r\n\r\n");
}

void FormDataBuilder::addKeyValuePairAsFormData(Vector<char>& buffer, const CString& key, const CString& value, FormData::EncodingType encodingType)
{
    if (encodingType == FormData::TextPlain) {
        if (!buffer.isEmpty())
            append(buffer, "\r\n");
        append(buffer, key);
        append(buffer, '=');
        append(buffer, value);
    } else {
        if (!buffer.isEmpty())
            append(buffer, '&');
        encodeStringAsFormData(buffer, key);
        append(buffer, '=');
        encodeStringAsFormData(buffer, value);
    }
}

void FormDataBuilder::encodeStringAsFormData(Vector<char>& buffer, const CString& string)
{
    // Same safe characters as Netscape for compatibility.
    static const char safeCharacters[] = "-._*";

    // http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.1
    unsigned length = string.length();
    for (unsigned i = 0; i < length; ++i) {
        unsigned char c = string.data()[i];

        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || strchr(safeCharacters, c))
            append(buffer, c);
        else if (c == ' ')
            append(buffer, '+');
        else if (c == '\n' || (c == '\r' && (i + 1 >= length || string.data()[i + 1] != '\n')))
            append(buffer, "%0D%0A");
        else if (c != '\r') {
            append(buffer, '%');
            appendByteAsHex(c, buffer);
        }
    }
}

}
