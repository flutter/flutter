/*
 * Copyright (c) 2009, Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_PLATFORM_FONTS_FONTFACECREATIONPARAMS_H_
#define SKY_ENGINE_PLATFORM_FONTS_FONTFACECREATIONPARAMS_H_

#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/StringHasher.h"
#include "flutter/sky/engine/wtf/text/AtomicString.h"
#include "flutter/sky/engine/wtf/text/StringHash.h"

namespace blink {

enum FontFaceCreationType { CreateFontByFamily, CreateFontByFciIdAndTtcIndex };

class FontFaceCreationParams {
  FontFaceCreationType m_creationType;
  AtomicString m_family;
  CString m_filename;
  int m_fontconfigInterfaceId;
  int m_ttcIndex;

 public:
  FontFaceCreationParams()
      : m_creationType(CreateFontByFamily),
        m_family(AtomicString()),
        m_filename(CString()),
        m_fontconfigInterfaceId(0),
        m_ttcIndex(0) {}

  explicit FontFaceCreationParams(AtomicString family)
      : m_creationType(CreateFontByFamily),
        m_family(family),
        m_filename(CString()),
        m_fontconfigInterfaceId(0),
        m_ttcIndex(0) {}

  FontFaceCreationParams(CString filename,
                         int fontconfigInterfaceId,
                         int ttcIndex = 0)
      : m_creationType(CreateFontByFciIdAndTtcIndex),
        m_filename(filename),
        m_fontconfigInterfaceId(fontconfigInterfaceId),
        m_ttcIndex(ttcIndex) {}

  FontFaceCreationType creationType() const { return m_creationType; }
  AtomicString family() const {
    ASSERT(m_creationType == CreateFontByFamily);
    return m_family;
  }
  CString filename() const {
    ASSERT(m_creationType == CreateFontByFciIdAndTtcIndex);
    return m_filename;
  }
  int fontconfigInterfaceId() const {
    ASSERT(m_creationType == CreateFontByFciIdAndTtcIndex);
    return m_fontconfigInterfaceId;
  }
  int ttcIndex() const {
    ASSERT(m_creationType == CreateFontByFciIdAndTtcIndex);
    return m_ttcIndex;
  }

  unsigned hash() const {
    if (m_creationType == CreateFontByFciIdAndTtcIndex) {
      StringHasher hasher;
      // Hashing the filename and ints in this way is sensitive to character
      // encoding and endianness. However, since the hash is not transferred
      // over a network or permanently stored and only used for the runtime of
      // Chromium, this is not a concern.
      hasher.addCharacters(reinterpret_cast<const LChar*>(m_filename.data()),
                           m_filename.length());
      hasher.addCharacters(reinterpret_cast<const LChar*>(&m_ttcIndex),
                           sizeof(m_ttcIndex));
      hasher.addCharacters(
          reinterpret_cast<const LChar*>(&m_fontconfigInterfaceId),
          sizeof(m_fontconfigInterfaceId));
      return hasher.hash();
    }
    return CaseFoldingHash::hash(m_family.isEmpty() ? "" : m_family);
  }

  bool operator==(const FontFaceCreationParams& other) const {
    return m_creationType == other.m_creationType &&
           equalIgnoringCase(m_family, other.m_family) &&
           m_filename == other.m_filename &&
           m_fontconfigInterfaceId == other.m_fontconfigInterfaceId &&
           m_ttcIndex == other.m_ttcIndex;
  }
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FONTS_FONTFACECREATIONPARAMS_H_
