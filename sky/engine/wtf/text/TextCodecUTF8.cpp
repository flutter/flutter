/*
 * Copyright (C) 2004, 2006, 2008, 2011 Apple Inc. All rights reserved.
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

#include "flutter/sky/engine/wtf/text/TextCodecUTF8.h"

#include "flutter/sky/engine/wtf/text/CString.h"
#include "flutter/sky/engine/wtf/text/StringBuffer.h"
#include "flutter/sky/engine/wtf/text/TextCodecASCIIFastPath.h"
#include "flutter/sky/engine/wtf/unicode/CharacterNames.h"

using namespace WTF;
using namespace WTF::Unicode;
using namespace std;

namespace WTF {

const int nonCharacter = -1;

PassOwnPtr<TextCodec> TextCodecUTF8::create(const TextEncoding&, const void*) {
  return adoptPtr(new TextCodecUTF8);
}

void TextCodecUTF8::registerEncodingNames(EncodingNameRegistrar registrar) {
  registrar("UTF-8", "UTF-8");

  // Additional aliases that originally were present in the encoding
  // table in WebKit on Macintosh, and subsequently added by
  // TextCodecICU. Perhaps we can prove some are not used on the web
  // and remove them.
  registrar("unicode11utf8", "UTF-8");
  registrar("unicode20utf8", "UTF-8");
  registrar("utf8", "UTF-8");
  registrar("x-unicode20utf8", "UTF-8");

  // Additional aliases present in the WHATWG Encoding Standard
  // (http://encoding.spec.whatwg.org/) and Firefox (24), but not in ICU 4.6.
  registrar("unicode-1-1-utf-8", "UTF-8");
}

void TextCodecUTF8::registerCodecs(TextCodecRegistrar registrar) {
  registrar("UTF-8", create, 0);
}

static inline int nonASCIISequenceLength(uint8_t firstByte) {
  static const uint8_t lengths[256] = {
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
      4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  return lengths[firstByte];
}

static inline int decodeNonASCIISequence(const uint8_t* sequence,
                                         unsigned length) {
  ASSERT(!isASCII(sequence[0]));
  if (length == 2) {
    ASSERT(sequence[0] <= 0xDF);
    if (sequence[0] < 0xC2)
      return nonCharacter;
    if (sequence[1] < 0x80 || sequence[1] > 0xBF)
      return nonCharacter;
    return ((sequence[0] << 6) + sequence[1]) - 0x00003080;
  }
  if (length == 3) {
    ASSERT(sequence[0] >= 0xE0 && sequence[0] <= 0xEF);
    switch (sequence[0]) {
      case 0xE0:
        if (sequence[1] < 0xA0 || sequence[1] > 0xBF)
          return nonCharacter;
        break;
      case 0xED:
        if (sequence[1] < 0x80 || sequence[1] > 0x9F)
          return nonCharacter;
        break;
      default:
        if (sequence[1] < 0x80 || sequence[1] > 0xBF)
          return nonCharacter;
    }
    if (sequence[2] < 0x80 || sequence[2] > 0xBF)
      return nonCharacter;
    return ((sequence[0] << 12) + (sequence[1] << 6) + sequence[2]) -
           0x000E2080;
  }
  ASSERT(length == 4);
  ASSERT(sequence[0] >= 0xF0 && sequence[0] <= 0xF4);
  switch (sequence[0]) {
    case 0xF0:
      if (sequence[1] < 0x90 || sequence[1] > 0xBF)
        return nonCharacter;
      break;
    case 0xF4:
      if (sequence[1] < 0x80 || sequence[1] > 0x8F)
        return nonCharacter;
      break;
    default:
      if (sequence[1] < 0x80 || sequence[1] > 0xBF)
        return nonCharacter;
  }
  if (sequence[2] < 0x80 || sequence[2] > 0xBF)
    return nonCharacter;
  if (sequence[3] < 0x80 || sequence[3] > 0xBF)
    return nonCharacter;
  return ((sequence[0] << 18) + (sequence[1] << 12) + (sequence[2] << 6) +
          sequence[3]) -
         0x03C82080;
}

static inline UChar* appendCharacter(UChar* destination, int character) {
  ASSERT(character != nonCharacter);
  ASSERT(!U_IS_SURROGATE(character));
  if (U_IS_BMP(character))
    *destination++ = character;
  else {
    *destination++ = U16_LEAD(character);
    *destination++ = U16_TRAIL(character);
  }
  return destination;
}

void TextCodecUTF8::consumePartialSequenceByte() {
  --m_partialSequenceSize;
  memmove(m_partialSequence, m_partialSequence + 1, m_partialSequenceSize);
}

void TextCodecUTF8::handleError(UChar*& destination,
                                bool stopOnError,
                                bool& sawError) {
  sawError = true;
  if (stopOnError)
    return;
  // Each error generates a replacement character and consumes one byte.
  *destination++ = replacementCharacter;
  consumePartialSequenceByte();
}

template <>
bool TextCodecUTF8::handlePartialSequence<LChar>(LChar*& destination,
                                                 const uint8_t*& source,
                                                 const uint8_t* end,
                                                 bool flush,
                                                 bool,
                                                 bool&) {
  ASSERT(m_partialSequenceSize);
  do {
    if (isASCII(m_partialSequence[0])) {
      *destination++ = m_partialSequence[0];
      consumePartialSequenceByte();
      continue;
    }
    int count = nonASCIISequenceLength(m_partialSequence[0]);
    if (!count)
      return true;

    if (count > m_partialSequenceSize) {
      if (count - m_partialSequenceSize > end - source) {
        if (!flush) {
          // The new data is not enough to complete the sequence, so
          // add it to the existing partial sequence.
          memcpy(m_partialSequence + m_partialSequenceSize, source,
                 end - source);
          m_partialSequenceSize += end - source;
          return false;
        }
        // An incomplete partial sequence at the end is an error, but it will
        // create a 16 bit string due to the replacementCharacter. Let the 16
        // bit path handle the error.
        return true;
      }
      memcpy(m_partialSequence + m_partialSequenceSize, source,
             count - m_partialSequenceSize);
      source += count - m_partialSequenceSize;
      m_partialSequenceSize = count;
    }
    int character = decodeNonASCIISequence(m_partialSequence, count);
    if ((character == nonCharacter) || (character > 0xff))
      return true;

    m_partialSequenceSize -= count;
    *destination++ = character;
  } while (m_partialSequenceSize);

  return false;
}

template <>
bool TextCodecUTF8::handlePartialSequence<UChar>(UChar*& destination,
                                                 const uint8_t*& source,
                                                 const uint8_t* end,
                                                 bool flush,
                                                 bool stopOnError,
                                                 bool& sawError) {
  ASSERT(m_partialSequenceSize);
  do {
    if (isASCII(m_partialSequence[0])) {
      *destination++ = m_partialSequence[0];
      consumePartialSequenceByte();
      continue;
    }
    int count = nonASCIISequenceLength(m_partialSequence[0]);
    if (!count) {
      handleError(destination, stopOnError, sawError);
      if (stopOnError)
        return false;
      continue;
    }
    if (count > m_partialSequenceSize) {
      if (count - m_partialSequenceSize > end - source) {
        if (!flush) {
          // The new data is not enough to complete the sequence, so
          // add it to the existing partial sequence.
          memcpy(m_partialSequence + m_partialSequenceSize, source,
                 end - source);
          m_partialSequenceSize += end - source;
          return false;
        }
        // An incomplete partial sequence at the end is an error.
        handleError(destination, stopOnError, sawError);
        if (stopOnError)
          return false;
        continue;
      }
      memcpy(m_partialSequence + m_partialSequenceSize, source,
             count - m_partialSequenceSize);
      source += count - m_partialSequenceSize;
      m_partialSequenceSize = count;
    }
    int character = decodeNonASCIISequence(m_partialSequence, count);
    if (character == nonCharacter) {
      handleError(destination, stopOnError, sawError);
      if (stopOnError)
        return false;
      continue;
    }

    m_partialSequenceSize -= count;
    destination = appendCharacter(destination, character);
  } while (m_partialSequenceSize);

  return false;
}

String TextCodecUTF8::decode(const char* bytes,
                             size_t length,
                             FlushBehavior flush,
                             bool stopOnError,
                             bool& sawError) {
  // Each input byte might turn into a character.
  // That includes all bytes in the partial-sequence buffer because
  // each byte in an invalid sequence will turn into a replacement character.
  StringBuffer<LChar> buffer(m_partialSequenceSize + length);

  const uint8_t* source = reinterpret_cast<const uint8_t*>(bytes);
  const uint8_t* end = source + length;
  const uint8_t* alignedEnd = alignToMachineWord(end);
  LChar* destination = buffer.characters();

  do {
    if (m_partialSequenceSize) {
      // Explicitly copy destination and source pointers to avoid taking
      // pointers to the local variables, which may harm code generation by
      // disabling some optimizations in some compilers.
      LChar* destinationForHandlePartialSequence = destination;
      const uint8_t* sourceForHandlePartialSequence = source;
      if (handlePartialSequence(destinationForHandlePartialSequence,
                                sourceForHandlePartialSequence, end, flush,
                                stopOnError, sawError)) {
        source = sourceForHandlePartialSequence;
        goto upConvertTo16Bit;
      }
      destination = destinationForHandlePartialSequence;
      source = sourceForHandlePartialSequence;
      if (m_partialSequenceSize)
        break;
    }

    while (source < end) {
      if (isASCII(*source)) {
        // Fast path for ASCII. Most UTF-8 text will be ASCII.
        if (isAlignedToMachineWord(source)) {
          while (source < alignedEnd) {
            MachineWord chunk =
                *reinterpret_cast_ptr<const MachineWord*>(source);
            if (!isAllASCII<LChar>(chunk))
              break;
            copyASCIIMachineWord(destination, source);
            source += sizeof(MachineWord);
            destination += sizeof(MachineWord);
          }
          if (source == end)
            break;
          if (!isASCII(*source))
            continue;
        }
        *destination++ = *source++;
        continue;
      }
      int count = nonASCIISequenceLength(*source);
      int character;
      if (!count)
        character = nonCharacter;
      else {
        if (count > end - source) {
          ASSERT_WITH_SECURITY_IMPLICATION(
              end - source < static_cast<ptrdiff_t>(sizeof(m_partialSequence)));
          ASSERT(!m_partialSequenceSize);
          m_partialSequenceSize = end - source;
          memcpy(m_partialSequence, source, m_partialSequenceSize);
          source = end;
          break;
        }
        character = decodeNonASCIISequence(source, count);
      }
      if (character == nonCharacter) {
        sawError = true;
        if (stopOnError)
          break;

        goto upConvertTo16Bit;
      }
      if (character > 0xff)
        goto upConvertTo16Bit;

      source += count;
      *destination++ = character;
    }
  } while (flush && m_partialSequenceSize);

  buffer.shrink(destination - buffer.characters());

  return String::adopt(buffer);

upConvertTo16Bit:
  StringBuffer<UChar> buffer16(m_partialSequenceSize + length);

  UChar* destination16 = buffer16.characters();

  // Copy the already converted characters
  for (LChar* converted8 = buffer.characters(); converted8 < destination;)
    *destination16++ = *converted8++;

  do {
    if (m_partialSequenceSize) {
      // Explicitly copy destination and source pointers to avoid taking
      // pointers to the local variables, which may harm code generation by
      // disabling some optimizations in some compilers.
      UChar* destinationForHandlePartialSequence = destination16;
      const uint8_t* sourceForHandlePartialSequence = source;
      handlePartialSequence(destinationForHandlePartialSequence,
                            sourceForHandlePartialSequence, end, flush,
                            stopOnError, sawError);
      destination16 = destinationForHandlePartialSequence;
      source = sourceForHandlePartialSequence;
      if (m_partialSequenceSize)
        break;
    }

    while (source < end) {
      if (isASCII(*source)) {
        // Fast path for ASCII. Most UTF-8 text will be ASCII.
        if (isAlignedToMachineWord(source)) {
          while (source < alignedEnd) {
            MachineWord chunk =
                *reinterpret_cast_ptr<const MachineWord*>(source);
            if (!isAllASCII<LChar>(chunk))
              break;
            copyASCIIMachineWord(destination16, source);
            source += sizeof(MachineWord);
            destination16 += sizeof(MachineWord);
          }
          if (source == end)
            break;
          if (!isASCII(*source))
            continue;
        }
        *destination16++ = *source++;
        continue;
      }
      int count = nonASCIISequenceLength(*source);
      int character;
      if (!count)
        character = nonCharacter;
      else {
        if (count > end - source) {
          ASSERT_WITH_SECURITY_IMPLICATION(
              end - source < static_cast<ptrdiff_t>(sizeof(m_partialSequence)));
          ASSERT(!m_partialSequenceSize);
          m_partialSequenceSize = end - source;
          memcpy(m_partialSequence, source, m_partialSequenceSize);
          source = end;
          break;
        }
        character = decodeNonASCIISequence(source, count);
      }
      if (character == nonCharacter) {
        sawError = true;
        if (stopOnError)
          break;
        // Each error generates a replacement character and consumes one byte.
        *destination16++ = replacementCharacter;
        ++source;
        continue;
      }
      source += count;
      destination16 = appendCharacter(destination16, character);
    }
  } while (flush && m_partialSequenceSize);

  buffer16.shrink(destination16 - buffer16.characters());

  return String::adopt(buffer16);
}

template <typename CharType>
CString TextCodecUTF8::encodeCommon(const CharType* characters, size_t length) {
  // The maximum number of UTF-8 bytes needed per UTF-16 code unit is 3.
  // BMP characters take only one UTF-16 code unit and can take up to 3 bytes
  // (3x). Non-BMP characters take two UTF-16 code units and can take up to 4
  // bytes (2x).
  if (length > numeric_limits<size_t>::max() / 3)
    CRASH();
  Vector<uint8_t> bytes(length * 3);

  size_t i = 0;
  size_t bytesWritten = 0;
  while (i < length) {
    UChar32 character;
    U16_NEXT(characters, i, length, character);
    // U16_NEXT will simply emit a surrogate code point if an unmatched
    // surrogate is encountered; we must convert it to a U+FFFD (REPLACEMENT
    // CHARACTER) here.
    if (0xD800 <= character && character <= 0xDFFF)
      character = replacementCharacter;
    U8_APPEND_UNSAFE(bytes.data(), bytesWritten, character);
  }

  return CString(reinterpret_cast<char*>(bytes.data()), bytesWritten);
}

CString TextCodecUTF8::encode(const UChar* characters,
                              size_t length,
                              UnencodableHandling) {
  return encodeCommon(characters, length);
}

CString TextCodecUTF8::encode(const LChar* characters,
                              size_t length,
                              UnencodableHandling) {
  return encodeCommon(characters, length);
}

}  // namespace WTF
