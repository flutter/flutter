/*
 * Copyright (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Torch Mobile Inc. http://www.torchmobile.com/
 * Copyright (C) 2009 Google Inc. All rights reserved.
 * Copyright (C) 2011 Apple Inc. All Rights Reserved.
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

#include "config.h"
#include "platform/network/HTTPParsers.h"

#include "wtf/DateMath.h"
#include "wtf/MathExtras.h"
#include "wtf/text/CString.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/WTFString.h"
#include "wtf/unicode/CharacterNames.h"

using namespace WTF;

namespace blink {

// true if there is more to parse, after incrementing pos past whitespace.
// Note: Might return pos == str.length()
static inline bool skipWhiteSpace(const String& str, unsigned& pos, bool fromHttpEquivMeta)
{
    unsigned len = str.length();

    if (fromHttpEquivMeta) {
        while (pos < len && str[pos] <= ' ')
            ++pos;
    } else {
        while (pos < len && (str[pos] == '\t' || str[pos] == ' '))
            ++pos;
    }

    return pos < len;
}

// Returns true if the function can match the whole token (case insensitive)
// incrementing pos on match, otherwise leaving pos unchanged.
// Note: Might return pos == str.length()
static inline bool skipToken(const String& str, unsigned& pos, const char* token)
{
    unsigned len = str.length();
    unsigned current = pos;

    while (current < len && *token) {
        if (toASCIILower(str[current]) != *token++)
            return false;
        ++current;
    }

    if (*token)
        return false;

    pos = current;
    return true;
}

// True if the expected equals sign is seen and there is more to follow.
static inline bool skipEquals(const String& str, unsigned &pos)
{
    return skipWhiteSpace(str, pos, false) && str[pos++] == '=' && skipWhiteSpace(str, pos, false);
}

// True if a value present, incrementing pos to next space or semicolon, if any.
// Note: might return pos == str.length().
static inline bool skipValue(const String& str, unsigned& pos)
{
    unsigned start = pos;
    unsigned len = str.length();
    while (pos < len) {
        if (str[pos] == ' ' || str[pos] == '\t' || str[pos] == ';')
            break;
        ++pos;
    }
    return pos != start;
}

bool isValidHTTPHeaderValue(const String& name)
{
    // FIXME: This should really match name against
    // field-value in section 4.2 of RFC 2616.

    return name.containsOnlyLatin1() && !name.contains('\r') && !name.contains('\n');
}

// See RFC 2616, Section 2.2.
bool isValidHTTPToken(const String& characters)
{
    if (characters.isEmpty())
        return false;
    for (unsigned i = 0; i < characters.length(); ++i) {
        UChar c = characters[i];
        if (c <= 0x20 || c >= 0x7F
            || c == '(' || c == ')' || c == '<' || c == '>' || c == '@'
            || c == ',' || c == ';' || c == ':' || c == '\\' || c == '"'
            || c == '/' || c == '[' || c == ']' || c == '?' || c == '='
            || c == '{' || c == '}')
        return false;
    }
    return true;
}

static const size_t maxInputSampleSize = 128;
static String trimInputSample(const char* p, size_t length)
{
    if (length > maxInputSampleSize)
        return String(p, maxInputSampleSize) + horizontalEllipsis;
    return String(p, length);
}

ContentDispositionType contentDispositionType(const String& contentDisposition)
{
    if (contentDisposition.isEmpty())
        return ContentDispositionNone;

    Vector<String> parameters;
    contentDisposition.split(';', parameters);

    if (parameters.isEmpty())
        return ContentDispositionNone;

    String dispositionType = parameters[0];
    dispositionType.stripWhiteSpace();

    if (equalIgnoringCase(dispositionType, "inline"))
        return ContentDispositionInline;

    // Some broken sites just send bogus headers like
    //
    //   Content-Disposition: ; filename="file"
    //   Content-Disposition: filename="file"
    //   Content-Disposition: name="file"
    //
    // without a disposition token... screen those out.
    if (!isValidHTTPToken(dispositionType))
        return ContentDispositionNone;

    // We have a content-disposition of "attachment" or unknown.
    // RFC 2183, section 2.8 says that an unknown disposition
    // value should be treated as "attachment"
    return ContentDispositionAttachment;
}

double parseDate(const String& value)
{
    return parseDateFromNullTerminatedCharacters(value.utf8().data());
}

// FIXME: This function doesn't comply with RFC 6266.
// For example, this function doesn't handle the interaction between " and ;
// that arises from quoted-string, nor does this function properly unquote
// attribute values. Further this function appears to process parameter names
// in a case-sensitive manner. (There are likely other bugs as well.)
String filenameFromHTTPContentDisposition(const String& value)
{
    Vector<String> keyValuePairs;
    value.split(';', keyValuePairs);

    unsigned length = keyValuePairs.size();
    for (unsigned i = 0; i < length; i++) {
        size_t valueStartPos = keyValuePairs[i].find('=');
        if (valueStartPos == kNotFound)
            continue;

        String key = keyValuePairs[i].left(valueStartPos).stripWhiteSpace();

        if (key.isEmpty() || key != "filename")
            continue;

        String value = keyValuePairs[i].substring(valueStartPos + 1).stripWhiteSpace();

        // Remove quotes if there are any
        if (value[0] == '\"')
            value = value.substring(1, value.length() - 2);

        return value;
    }

    return String();
}

AtomicString extractMIMETypeFromMediaType(const AtomicString& mediaType)
{
    StringBuilder mimeType;
    unsigned length = mediaType.length();
    mimeType.reserveCapacity(length);
    for (unsigned i = 0; i < length; i++) {
        UChar c = mediaType[i];

        if (c == ';')
            break;

        // While RFC 2616 does not allow it, other browsers allow multiple values in the HTTP media
        // type header field, Content-Type. In such cases, the media type string passed here may contain
        // the multiple values separated by commas. For now, this code ignores text after the first comma,
        // which prevents it from simply failing to parse such types altogether. Later for better
        // compatibility we could consider using the first or last valid MIME type instead.
        // See https://bugs.webkit.org/show_bug.cgi?id=25352 for more discussion.
        if (c == ',')
            break;

        // FIXME: The following is not correct. RFC 2616 allows linear white space before and
        // after the MIME type, but not within the MIME type itself. And linear white space
        // includes only a few specific ASCII characters; a small subset of isSpaceOrNewline.
        // See https://bugs.webkit.org/show_bug.cgi?id=8644 for a bug tracking part of this.
        if (isSpaceOrNewline(c))
            continue;

        mimeType.append(c);
    }

    if (mimeType.length() == length)
        return mediaType;
    return mimeType.toAtomicString();
}

String extractCharsetFromMediaType(const String& mediaType)
{
    unsigned pos, len;
    findCharsetInMediaType(mediaType, pos, len);
    return mediaType.substring(pos, len);
}

void findCharsetInMediaType(const String& mediaType, unsigned& charsetPos, unsigned& charsetLen, unsigned start)
{
    charsetPos = start;
    charsetLen = 0;

    size_t pos = start;
    unsigned length = mediaType.length();

    while (pos < length) {
        pos = mediaType.find("charset", pos, false);
        if (pos == kNotFound || !pos) {
            charsetLen = 0;
            return;
        }

        // is what we found a beginning of a word?
        if (mediaType[pos-1] > ' ' && mediaType[pos-1] != ';') {
            pos += 7;
            continue;
        }

        pos += 7;

        // skip whitespace
        while (pos != length && mediaType[pos] <= ' ')
            ++pos;

        if (mediaType[pos++] != '=') // this "charset" substring wasn't a parameter name, but there may be others
            continue;

        while (pos != length && (mediaType[pos] <= ' ' || mediaType[pos] == '"' || mediaType[pos] == '\''))
            ++pos;

        // we don't handle spaces within quoted parameter values, because charset names cannot have any
        unsigned endpos = pos;
        while (pos != length && mediaType[endpos] > ' ' && mediaType[endpos] != '"' && mediaType[endpos] != '\'' && mediaType[endpos] != ';')
            ++endpos;

        charsetPos = pos;
        charsetLen = endpos - pos;
        return;
    }
}

ReflectedXSSDisposition parseXSSProtectionHeader(const String& header, String& failureReason, unsigned& failurePosition, String& reportURL)
{
    DEFINE_STATIC_LOCAL(String, failureReasonInvalidToggle, ("expected 0 or 1"));
    DEFINE_STATIC_LOCAL(String, failureReasonInvalidSeparator, ("expected semicolon"));
    DEFINE_STATIC_LOCAL(String, failureReasonInvalidEquals, ("expected equals sign"));
    DEFINE_STATIC_LOCAL(String, failureReasonInvalidMode, ("invalid mode directive"));
    DEFINE_STATIC_LOCAL(String, failureReasonInvalidReport, ("invalid report directive"));
    DEFINE_STATIC_LOCAL(String, failureReasonDuplicateMode, ("duplicate mode directive"));
    DEFINE_STATIC_LOCAL(String, failureReasonDuplicateReport, ("duplicate report directive"));
    DEFINE_STATIC_LOCAL(String, failureReasonInvalidDirective, ("unrecognized directive"));

    unsigned pos = 0;

    if (!skipWhiteSpace(header, pos, false))
        return ReflectedXSSUnset;

    if (header[pos] == '0')
        return AllowReflectedXSS;

    if (header[pos++] != '1') {
        failureReason = failureReasonInvalidToggle;
        return ReflectedXSSInvalid;
    }

    ReflectedXSSDisposition result = FilterReflectedXSS;
    bool modeDirectiveSeen = false;
    bool reportDirectiveSeen = false;

    while (1) {
        // At end of previous directive: consume whitespace, semicolon, and whitespace.
        if (!skipWhiteSpace(header, pos, false))
            return result;

        if (header[pos++] != ';') {
            failureReason = failureReasonInvalidSeparator;
            failurePosition = pos;
            return ReflectedXSSInvalid;
        }

        if (!skipWhiteSpace(header, pos, false))
            return result;

        // At start of next directive.
        if (skipToken(header, pos, "mode")) {
            if (modeDirectiveSeen) {
                failureReason = failureReasonDuplicateMode;
                failurePosition = pos;
                return ReflectedXSSInvalid;
            }
            modeDirectiveSeen = true;
            if (!skipEquals(header, pos)) {
                failureReason = failureReasonInvalidEquals;
                failurePosition = pos;
                return ReflectedXSSInvalid;
            }
            if (!skipToken(header, pos, "block")) {
                failureReason = failureReasonInvalidMode;
                failurePosition = pos;
                return ReflectedXSSInvalid;
            }
            result = BlockReflectedXSS;
        } else if (skipToken(header, pos, "report")) {
            if (reportDirectiveSeen) {
                failureReason = failureReasonDuplicateReport;
                failurePosition = pos;
                return ReflectedXSSInvalid;
            }
            reportDirectiveSeen = true;
            if (!skipEquals(header, pos)) {
                failureReason = failureReasonInvalidEquals;
                failurePosition = pos;
                return ReflectedXSSInvalid;
            }
            size_t startPos = pos;
            if (!skipValue(header, pos)) {
                failureReason = failureReasonInvalidReport;
                failurePosition = pos;
                return ReflectedXSSInvalid;
            }
            reportURL = header.substring(startPos, pos - startPos);
            failurePosition = startPos; // If later semantic check deems unacceptable.
        } else {
            failureReason = failureReasonInvalidDirective;
            failurePosition = pos;
            return ReflectedXSSInvalid;
        }
    }
}

ContentTypeOptionsDisposition parseContentTypeOptionsHeader(const String& header)
{
    if (header.stripWhiteSpace().lower() == "nosniff")
        return ContentTypeOptionsNosniff;
    return ContentTypeOptionsNone;
}

String extractReasonPhraseFromHTTPStatusLine(const String& statusLine)
{
    size_t spacePos = statusLine.find(' ');
    // Remove status code from the status line.
    spacePos = statusLine.find(' ', spacePos + 1);
    return statusLine.substring(spacePos + 1);
}

bool parseRange(const String& range, long long& rangeOffset, long long& rangeEnd, long long& rangeSuffixLength)
{
    // The format of "Range" header is defined in RFC 2616 Section 14.35.1.
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.1
    // We don't support multiple range requests.

    rangeOffset = rangeEnd = rangeSuffixLength = -1;

    // The "bytes" unit identifier should be present.
    static const char bytesStart[] = "bytes=";
    if (!range.startsWith(bytesStart, false))
        return false;
    String byteRange = range.substring(sizeof(bytesStart) - 1);

    // The '-' character needs to be present.
    int index = byteRange.find('-');
    if (index == -1)
        return false;

    // If the '-' character is at the beginning, the suffix length, which specifies the last N bytes, is provided.
    // Example:
    //     -500
    if (!index) {
        String suffixLengthString = byteRange.substring(index + 1).stripWhiteSpace();
        bool ok;
        long long value = suffixLengthString.toInt64Strict(&ok);
        if (ok)
            rangeSuffixLength = value;
        return true;
    }

    // Otherwise, the first-byte-position and the last-byte-position are provied.
    // Examples:
    //     0-499
    //     500-
    String firstBytePosStr = byteRange.left(index).stripWhiteSpace();
    bool ok;
    long long firstBytePos = firstBytePosStr.toInt64Strict(&ok);
    if (!ok)
        return false;

    String lastBytePosStr = byteRange.substring(index + 1).stripWhiteSpace();
    long long lastBytePos = -1;
    if (!lastBytePosStr.isEmpty()) {
        lastBytePos = lastBytePosStr.toInt64Strict(&ok);
        if (!ok)
            return false;
    }

    if (firstBytePos < 0 || !(lastBytePos == -1 || lastBytePos >= firstBytePos))
        return false;

    rangeOffset = firstBytePos;
    rangeEnd = lastBytePos;
    return true;
}

// HTTP/1.1 - RFC 2616
// http://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html#sec5.1
// Request-Line = Method SP Request-URI SP HTTP-Version CRLF
size_t parseHTTPRequestLine(const char* data, size_t length, String& failureReason, String& method, String& url, HTTPVersion& httpVersion)
{
    method = String();
    url = String();
    httpVersion = Unknown;

    const char* space1 = 0;
    const char* space2 = 0;
    const char* p;
    size_t consumedLength;

    for (p = data, consumedLength = 0; consumedLength < length; p++, consumedLength++) {
        if (*p == ' ') {
            if (!space1)
                space1 = p;
            else if (!space2)
                space2 = p;
        } else if (*p == '\n') {
            break;
        }
    }

    // Haven't finished header line.
    if (consumedLength == length) {
        failureReason = "Incomplete Request Line";
        return 0;
    }

    // RequestLine does not contain 3 parts.
    if (!space1 || !space2) {
        failureReason = "Request Line does not appear to contain: <Method> <Url> <HTTPVersion>.";
        return 0;
    }

    // The line must end with "\r\n".
    const char* end = p + 1;
    if (*(end - 2) != '\r') {
        failureReason = "Request line does not end with CRLF";
        return 0;
    }

    // Request Method.
    method = String(data, space1 - data); // For length subtract 1 for space, but add 1 for data being the first character.

    // Request URI.
    url = String(space1 + 1, space2 - space1 - 1); // For length subtract 1 for space.

    // HTTP Version.
    String httpVersionString(space2 + 1, end - space2 - 3); // For length subtract 1 for space, and 2 for "\r\n".
    if (httpVersionString.length() != 8 || !httpVersionString.startsWith("HTTP/1."))
        httpVersion = Unknown;
    else if (httpVersionString[7] == '0')
        httpVersion = HTTP_1_0;
    else if (httpVersionString[7] == '1')
        httpVersion = HTTP_1_1;
    else
        httpVersion = Unknown;

    return end - data;
}

static bool parseHTTPHeaderName(const char* s, size_t start, size_t size, String& failureReason, size_t* position, AtomicString* name)
{
    size_t nameBegin = start;
    for (size_t i = start; i < size; ++i) {
        switch (s[i]) {
        case '\r':
            failureReason = "Unexpected CR in name at " + trimInputSample(&s[nameBegin], i - nameBegin);
            return false;
        case '\n':
            failureReason = "Unexpected LF in name at " + trimInputSample(&s[nameBegin], i - nameBegin);
            return false;
        case ':':
            if (i == nameBegin) {
                failureReason = "Header name is missing";
                return false;
            }
            *name = AtomicString::fromUTF8(&s[nameBegin], i - nameBegin);
            if (name->isNull()) {
                failureReason = "Invalid UTF-8 sequence in header name";
                return false;
            }
            *position = i;
            return true;
        default:
            break;
        }
    }
    failureReason = "Unterminated header name";
    return false;
}

static bool parseHTTPHeaderValue(const char* s, size_t start, size_t size, String& failureReason, size_t* position, AtomicString* value)
{
    size_t i = start;
    for (; i < size && s[i] == ' '; ++i) {
    }
    size_t valueBegin = i;

    for (; i < size && s[i] != '\r'; ++i) {
        if (s[i] == '\n') {
            failureReason = "Unexpected LF in value at " + trimInputSample(&s[valueBegin], i - valueBegin);
            return false;
        }
    }
    if (i == size) {
        failureReason = "Unterminated header value";
        return false;
    }

    ASSERT(i < size && s[i] == '\r');
    if (i + 1 >= size || s[i + 1] != '\n') {
        failureReason = "LF doesn't follow CR after value at " + trimInputSample(&s[i + 1], size - i - 1);
        return false;
    }

    *value = AtomicString::fromUTF8(&s[valueBegin], i - valueBegin);
    if (i != valueBegin && value->isNull()) {
        failureReason = "Invalid UTF-8 sequence in header value";
        return false;
    }

    // 2 for strlen("\r\n")
    *position = i + 2;
    return true;
}

// Note that the header is already parsed and re-formatted in chromium side.
// We assume that the input is more restricted than RFC2616.
size_t parseHTTPHeader(const char* s, size_t size, String& failureReason, AtomicString& name, AtomicString& value)
{
    name = nullAtom;
    value = nullAtom;
    if (size >= 1 && s[0] == '\r') {
        if (size >= 2 && s[1] == '\n') {
            // Skip an empty line.
            return 2;
        }
        failureReason = "LF doesn't follow CR at " + trimInputSample(0, size);
        return 0;
    }
    size_t current = 0;
    if (!parseHTTPHeaderName(s, current, size, failureReason, &current, &name)) {
        return 0;
    }
    ASSERT(s[current] == ':');
    ++current;

    if (!parseHTTPHeaderValue(s, current, size, failureReason, &current, &value)) {
        return 0;
    }

    return current;
}

size_t parseHTTPRequestBody(const char* data, size_t length, Vector<unsigned char>& body)
{
    body.clear();
    body.append(data, length);

    return length;
}

static bool isCacheHeaderSeparator(UChar c)
{
    // See RFC 2616, Section 2.2
    switch (c) {
    case '(':
    case ')':
    case '<':
    case '>':
    case '@':
    case ',':
    case ';':
    case ':':
    case '\\':
    case '"':
    case '/':
    case '[':
    case ']':
    case '?':
    case '=':
    case '{':
    case '}':
    case ' ':
    case '\t':
        return true;
    default:
        return false;
    }
}

static bool isControlCharacter(UChar c)
{
    return c < ' ' || c == 127;
}

static inline String trimToNextSeparator(const String& str)
{
    return str.substring(0, str.find(isCacheHeaderSeparator));
}

static void parseCacheHeader(const String& header, Vector<pair<String, String> >& result)
{
    const String safeHeader = header.removeCharacters(isControlCharacter);
    unsigned max = safeHeader.length();
    for (unsigned pos = 0; pos < max; /* pos incremented in loop */) {
        size_t nextCommaPosition = safeHeader.find(',', pos);
        size_t nextEqualSignPosition = safeHeader.find('=', pos);
        if (nextEqualSignPosition != kNotFound && (nextEqualSignPosition < nextCommaPosition || nextCommaPosition == kNotFound)) {
            // Get directive name, parse right hand side of equal sign, then add to map
            String directive = trimToNextSeparator(safeHeader.substring(pos, nextEqualSignPosition - pos).stripWhiteSpace());
            pos += nextEqualSignPosition - pos + 1;

            String value = safeHeader.substring(pos, max - pos).stripWhiteSpace();
            if (value[0] == '"') {
                // The value is a quoted string
                size_t nextDoubleQuotePosition = value.find('"', 1);
                if (nextDoubleQuotePosition != kNotFound) {
                    // Store the value as a quoted string without quotes
                    result.append(pair<String, String>(directive, value.substring(1, nextDoubleQuotePosition - 1).stripWhiteSpace()));
                    pos += (safeHeader.find('"', pos) - pos) + nextDoubleQuotePosition + 1;
                    // Move past next comma, if there is one
                    size_t nextCommaPosition2 = safeHeader.find(',', pos);
                    if (nextCommaPosition2 != kNotFound)
                        pos += nextCommaPosition2 - pos + 1;
                    else
                        return; // Parse error if there is anything left with no comma
                } else {
                    // Parse error; just use the rest as the value
                    result.append(pair<String, String>(directive, trimToNextSeparator(value.substring(1, value.length() - 1).stripWhiteSpace())));
                    return;
                }
            } else {
                // The value is a token until the next comma
                size_t nextCommaPosition2 = value.find(',');
                if (nextCommaPosition2 != kNotFound) {
                    // The value is delimited by the next comma
                    result.append(pair<String, String>(directive, trimToNextSeparator(value.substring(0, nextCommaPosition2).stripWhiteSpace())));
                    pos += (safeHeader.find(',', pos) - pos) + 1;
                } else {
                    // The rest is the value; no change to value needed
                    result.append(pair<String, String>(directive, trimToNextSeparator(value)));
                    return;
                }
            }
        } else if (nextCommaPosition != kNotFound && (nextCommaPosition < nextEqualSignPosition || nextEqualSignPosition == kNotFound)) {
            // Add directive to map with empty string as value
            result.append(pair<String, String>(trimToNextSeparator(safeHeader.substring(pos, nextCommaPosition - pos).stripWhiteSpace()), ""));
            pos += nextCommaPosition - pos + 1;
        } else {
            // Add last directive to map with empty string as value
            result.append(pair<String, String>(trimToNextSeparator(safeHeader.substring(pos, max - pos).stripWhiteSpace()), ""));
            return;
        }
    }
}

CacheControlHeader parseCacheControlDirectives(const AtomicString& cacheControlValue, const AtomicString& pragmaValue)
{
    CacheControlHeader cacheControlHeader;
    cacheControlHeader.parsed = true;
    cacheControlHeader.maxAge = std::numeric_limits<double>::quiet_NaN();

    DEFINE_STATIC_LOCAL(const AtomicString, noCacheDirective, ("no-cache", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, noStoreDirective, ("no-store", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, mustRevalidateDirective, ("must-revalidate", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, maxAgeDirective, ("max-age", AtomicString::ConstructFromLiteral));

    if (!cacheControlValue.isEmpty()) {
        Vector<pair<String, String> > directives;
        parseCacheHeader(cacheControlValue, directives);

        size_t directivesSize = directives.size();
        for (size_t i = 0; i < directivesSize; ++i) {
            // RFC2616 14.9.1: A no-cache directive with a value is only meaningful for proxy caches.
            // It should be ignored by a browser level cache.
            if (equalIgnoringCase(directives[i].first, noCacheDirective) && directives[i].second.isEmpty()) {
                cacheControlHeader.containsNoCache = true;
            } else if (equalIgnoringCase(directives[i].first, noStoreDirective)) {
                cacheControlHeader.containsNoStore = true;
            } else if (equalIgnoringCase(directives[i].first, mustRevalidateDirective)) {
                cacheControlHeader.containsMustRevalidate = true;
            } else if (equalIgnoringCase(directives[i].first, maxAgeDirective)) {
                if (!std::isnan(cacheControlHeader.maxAge)) {
                    // First max-age directive wins if there are multiple ones.
                    continue;
                }
                bool ok;
                double maxAge = directives[i].second.toDouble(&ok);
                if (ok)
                    cacheControlHeader.maxAge = maxAge;
            }
        }
    }

    if (!cacheControlHeader.containsNoCache) {
        // Handle Pragma: no-cache
        // This is deprecated and equivalent to Cache-control: no-cache
        // Don't bother tokenizing the value, it is not important
        cacheControlHeader.containsNoCache = pragmaValue.lower().contains(noCacheDirective);
    }
    return cacheControlHeader;
}

}
