/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_TEXT_STRINGUTF8ADAPTOR_H_
#define SKY_ENGINE_WTF_TEXT_STRINGUTF8ADAPTOR_H_

#include "flutter/sky/engine/wtf/text/CString.h"
#include "flutter/sky/engine/wtf/text/TextEncoding.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"

namespace WTF {

// This class lets you get UTF-8 data out of a String without mallocing a
// separate buffer to hold the data if the String happens to be 8 bit and
// contain only ASCII characters.
class StringUTF8Adaptor {
 public:
  enum ShouldNormalize { DoNotNormalize, Normalize };

  explicit StringUTF8Adaptor(
      const String& string,
      ShouldNormalize normalize = DoNotNormalize,
      UnencodableHandling handling = EntitiesForUnencodables)
      : m_data(0), m_length(0) {
    if (string.isEmpty())
      return;
    // Unfortunately, 8 bit WTFStrings are encoded in Latin-1 and GURL uses
    // UTF-8 when processing 8 bit strings. If |relative| is entirely ASCII, we
    // luck out and can avoid mallocing a new buffer to hold the UTF-8 data
    // because UTF-8 and Latin-1 use the same code units for ASCII code points.
    if (string.is8Bit() && string.containsOnlyASCII()) {
      m_data = reinterpret_cast<const char*>(string.characters8());
      m_length = string.length();
    } else {
      if (normalize == Normalize)
        m_utf8Buffer = UTF8Encoding().normalizeAndEncode(string, handling);
      else
        m_utf8Buffer = string.utf8();
      m_data = m_utf8Buffer.data();
      m_length = m_utf8Buffer.length();
    }
  }

  const char* data() const { return m_data; }
  size_t length() const { return m_length; }

 private:
  CString m_utf8Buffer;
  const char* m_data;
  size_t m_length;
};

}  // namespace WTF

using WTF::StringUTF8Adaptor;

#endif  // SKY_ENGINE_WTF_TEXT_STRINGUTF8ADAPTOR_H_
