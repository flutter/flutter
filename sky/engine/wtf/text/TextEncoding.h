/*
 * Copyright (C) 2004, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_TEXT_TEXTENCODING_H_
#define SKY_ENGINE_WTF_TEXT_TEXTENCODING_H_

#include "flutter/sky/engine/wtf/Forward.h"
#include "flutter/sky/engine/wtf/WTFExport.h"
#include "flutter/sky/engine/wtf/text/TextCodec.h"
#include "flutter/sky/engine/wtf/unicode/Unicode.h"

namespace WTF {

class WTF_EXPORT TextEncoding {
 public:
  TextEncoding() : m_name(0) {}
  TextEncoding(const char* name);
  TextEncoding(const String& name);

  bool isValid() const { return m_name; }
  const char* name() const { return m_name; }
  bool usesVisualOrdering() const;
  const TextEncoding& closestByteBasedEquivalent() const;
  const TextEncoding& encodingForFormSubmission() const;

  String decode(const char* str, size_t length) const {
    bool ignored;
    return decode(str, length, false, ignored);
  }
  String decode(const char*,
                size_t length,
                bool stopOnError,
                bool& sawError) const;

  // Encodes the string, but does *not* normalize first.
  CString encode(const String&, UnencodableHandling) const;

  // Applies Unicode NFC normalization, then encodes the normalized string.
  CString normalizeAndEncode(const String&, UnencodableHandling) const;

 private:
  bool isNonByteBasedEncoding() const;
  bool isUTF7Encoding() const;

  const char* m_name;
};

inline bool operator==(const TextEncoding& a, const TextEncoding& b) {
  return a.name() == b.name();
}
inline bool operator!=(const TextEncoding& a, const TextEncoding& b) {
  return a.name() != b.name();
}

WTF_EXPORT const TextEncoding& ASCIIEncoding();
WTF_EXPORT const TextEncoding& Latin1Encoding();
WTF_EXPORT const TextEncoding& UTF16BigEndianEncoding();
WTF_EXPORT const TextEncoding& UTF16LittleEndianEncoding();
WTF_EXPORT const TextEncoding& UTF32BigEndianEncoding();
WTF_EXPORT const TextEncoding& UTF32LittleEndianEncoding();
WTF_EXPORT const TextEncoding& UTF8Encoding();
WTF_EXPORT const TextEncoding& WindowsLatin1Encoding();

}  // namespace WTF

using WTF::ASCIIEncoding;
using WTF::Latin1Encoding;
using WTF::UTF16BigEndianEncoding;
using WTF::UTF16LittleEndianEncoding;
using WTF::UTF32BigEndianEncoding;
using WTF::UTF32LittleEndianEncoding;
using WTF::UTF8Encoding;
using WTF::WindowsLatin1Encoding;

#endif  // SKY_ENGINE_WTF_TEXT_TEXTENCODING_H_
