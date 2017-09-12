/*
 * Copyright (C) 2004, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Alexey Proskuryakov <ap@nypop.com>
 * Copyright (C) 2007-2009 Torch Mobile, Inc.
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

#include "flutter/sky/engine/wtf/text/TextEncoding.h"

#include <unicode/unorm.h>
#include "flutter/sky/engine/wtf/OwnPtr.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/text/CString.h"
#include "flutter/sky/engine/wtf/text/TextEncodingRegistry.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"

namespace WTF {

static const TextEncoding& UTF7Encoding() {
  static TextEncoding globalUTF7Encoding("UTF-7");
  return globalUTF7Encoding;
}

TextEncoding::TextEncoding(const char* name)
    : m_name(atomicCanonicalTextEncodingName(name)) {
  // Aliases are valid, but not "replacement" itself.
  if (m_name && isReplacementEncoding(name))
    m_name = 0;
}

TextEncoding::TextEncoding(const String& name)
    : m_name(atomicCanonicalTextEncodingName(name)) {
  // Aliases are valid, but not "replacement" itself.
  if (m_name && isReplacementEncoding(name))
    m_name = 0;
}

String TextEncoding::decode(const char* data,
                            size_t length,
                            bool stopOnError,
                            bool& sawError) const {
  if (!m_name)
    return String();

  return newTextCodec(*this)->decode(data, length, DataEOF, stopOnError,
                                     sawError);
}

CString TextEncoding::encode(const String& string,
                             UnencodableHandling handling) const {
  if (!m_name)
    return CString();

  if (string.isEmpty())
    return "";

  OwnPtr<TextCodec> textCodec = newTextCodec(*this);
  CString encodedString;
  if (string.is8Bit())
    encodedString =
        textCodec->encode(string.characters8(), string.length(), handling);
  else
    encodedString =
        textCodec->encode(string.characters16(), string.length(), handling);
  return encodedString;
}

CString TextEncoding::normalizeAndEncode(const String& string,
                                         UnencodableHandling handling) const {
  if (!m_name)
    return CString();

  if (string.isEmpty())
    return "";

  // Text exclusively containing Latin-1 characters (U+0000..U+00FF) is left
  // unaffected by NFC. This is effectively the same as saying that all
  // Latin-1 text is already normalized to NFC.
  // Source: http://unicode.org/reports/tr15/
  if (string.is8Bit())
    return newTextCodec(*this)->encode(string.characters8(), string.length(),
                                       handling);

  const UChar* source = string.characters16();
  size_t length = string.length();

  Vector<UChar> normalizedCharacters;

  UErrorCode err = U_ZERO_ERROR;
  if (unorm_quickCheck(source, length, UNORM_NFC, &err) != UNORM_YES) {
    // First try using the length of the original string, since normalization to
    // NFC rarely increases length.
    normalizedCharacters.grow(length);
    int32_t normalizedLength =
        unorm_normalize(source, length, UNORM_NFC, 0,
                        normalizedCharacters.data(), length, &err);
    if (err == U_BUFFER_OVERFLOW_ERROR) {
      err = U_ZERO_ERROR;
      normalizedCharacters.resize(normalizedLength);
      normalizedLength =
          unorm_normalize(source, length, UNORM_NFC, 0,
                          normalizedCharacters.data(), normalizedLength, &err);
    }
    ASSERT(U_SUCCESS(err));

    source = normalizedCharacters.data();
    length = normalizedLength;
  }

  return newTextCodec(*this)->encode(source, length, handling);
}

bool TextEncoding::usesVisualOrdering() const {
  if (noExtendedTextEncodingNameUsed())
    return false;

  static const char* const a = atomicCanonicalTextEncodingName("ISO-8859-8");
  return m_name == a;
}

bool TextEncoding::isNonByteBasedEncoding() const {
  if (noExtendedTextEncodingNameUsed()) {
    return *this == UTF16LittleEndianEncoding() ||
           *this == UTF16BigEndianEncoding();
  }

  return *this == UTF16LittleEndianEncoding() ||
         *this == UTF16BigEndianEncoding() ||
         *this == UTF32BigEndianEncoding() ||
         *this == UTF32LittleEndianEncoding();
}

bool TextEncoding::isUTF7Encoding() const {
  if (noExtendedTextEncodingNameUsed())
    return false;

  return *this == UTF7Encoding();
}

const TextEncoding& TextEncoding::closestByteBasedEquivalent() const {
  if (isNonByteBasedEncoding())
    return UTF8Encoding();
  return *this;
}

// HTML5 specifies that UTF-8 be used in form submission when a form is
// is a part of a document in UTF-16 probably because UTF-16 is not a
// byte-based encoding and can contain 0x00. By extension, the same
// should be done for UTF-32. In case of UTF-7, it is a byte-based encoding,
// but it's fraught with problems and we'd rather steer clear of it.
const TextEncoding& TextEncoding::encodingForFormSubmission() const {
  if (isNonByteBasedEncoding() || isUTF7Encoding())
    return UTF8Encoding();
  return *this;
}

const TextEncoding& ASCIIEncoding() {
  static TextEncoding globalASCIIEncoding("ASCII");
  return globalASCIIEncoding;
}

const TextEncoding& Latin1Encoding() {
  static TextEncoding globalLatin1Encoding("latin1");
  return globalLatin1Encoding;
}

const TextEncoding& UTF16BigEndianEncoding() {
  static TextEncoding globalUTF16BigEndianEncoding("UTF-16BE");
  return globalUTF16BigEndianEncoding;
}

const TextEncoding& UTF16LittleEndianEncoding() {
  static TextEncoding globalUTF16LittleEndianEncoding("UTF-16LE");
  return globalUTF16LittleEndianEncoding;
}

const TextEncoding& UTF32BigEndianEncoding() {
  static TextEncoding globalUTF32BigEndianEncoding("UTF-32BE");
  return globalUTF32BigEndianEncoding;
}

const TextEncoding& UTF32LittleEndianEncoding() {
  static TextEncoding globalUTF32LittleEndianEncoding("UTF-32LE");
  return globalUTF32LittleEndianEncoding;
}

const TextEncoding& UTF8Encoding() {
  static TextEncoding globalUTF8Encoding("UTF-8");
  ASSERT(globalUTF8Encoding.isValid());
  return globalUTF8Encoding;
}

const TextEncoding& WindowsLatin1Encoding() {
  static TextEncoding globalWindowsLatin1Encoding("WinLatin1");
  return globalWindowsLatin1Encoding;
}

}  // namespace WTF
