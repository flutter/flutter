/*
 * Copyright (C) 2007 Apple Inc.  All rights reserved.
 * Copyright (C) 2010 Patrick Gansterer <paroga@paroga.com>
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

#include "flutter/sky/engine/wtf/unicode/UTF8.h"

#include "flutter/sky/engine/wtf/ASCIICType.h"
#include "flutter/sky/engine/wtf/StringHasher.h"
#include "flutter/sky/engine/wtf/unicode/CharacterNames.h"

namespace WTF {
namespace Unicode {

inline int inlineUTF8SequenceLengthNonASCII(char b0) {
  if ((b0 & 0xC0) != 0xC0)
    return 0;
  if ((b0 & 0xE0) == 0xC0)
    return 2;
  if ((b0 & 0xF0) == 0xE0)
    return 3;
  if ((b0 & 0xF8) == 0xF0)
    return 4;
  return 0;
}

inline int inlineUTF8SequenceLength(char b0) {
  return isASCII(b0) ? 1 : inlineUTF8SequenceLengthNonASCII(b0);
}

int UTF8SequenceLength(char b0) {
  return isASCII(b0) ? 1 : inlineUTF8SequenceLengthNonASCII(b0);
}

int decodeUTF8Sequence(const char* sequence) {
  // Handle 0-byte sequences (never valid).
  const unsigned char b0 = sequence[0];
  const int length = inlineUTF8SequenceLength(b0);
  if (length == 0)
    return -1;

  // Handle 1-byte sequences (plain ASCII).
  const unsigned char b1 = sequence[1];
  if (length == 1) {
    if (b1)
      return -1;
    return b0;
  }

  // Handle 2-byte sequences.
  if ((b1 & 0xC0) != 0x80)
    return -1;
  const unsigned char b2 = sequence[2];
  if (length == 2) {
    if (b2)
      return -1;
    const int c = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
    if (c < 0x80)
      return -1;
    return c;
  }

  // Handle 3-byte sequences.
  if ((b2 & 0xC0) != 0x80)
    return -1;
  const unsigned char b3 = sequence[3];
  if (length == 3) {
    if (b3)
      return -1;
    const int c = ((b0 & 0xF) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    if (c < 0x800)
      return -1;
    // UTF-16 surrogates should never appear in UTF-8 data.
    if (c >= 0xD800 && c <= 0xDFFF)
      return -1;
    return c;
  }

  // Handle 4-byte sequences.
  if ((b3 & 0xC0) != 0x80)
    return -1;
  const unsigned char b4 = sequence[4];
  if (length == 4) {
    if (b4)
      return -1;
    const int c = ((b0 & 0x7) << 18) | ((b1 & 0x3F) << 12) |
                  ((b2 & 0x3F) << 6) | (b3 & 0x3F);
    if (c < 0x10000 || c > 0x10FFFF)
      return -1;
    return c;
  }

  return -1;
}

// Once the bits are split out into bytes of UTF-8, this is a mask OR-ed
// into the first byte, depending on how many bytes follow.  There are
// as many entries in this table as there are UTF-8 sequence types.
// (I.e., one byte sequence, two byte... etc.). Remember that sequencs
// for *legal* UTF-8 will be 4 or fewer bytes total.
static const unsigned char firstByteMark[7] = {0x00, 0x00, 0xC0, 0xE0,
                                               0xF0, 0xF8, 0xFC};

ConversionResult convertLatin1ToUTF8(const LChar** sourceStart,
                                     const LChar* sourceEnd,
                                     char** targetStart,
                                     char* targetEnd) {
  ConversionResult result = conversionOK;
  const LChar* source = *sourceStart;
  char* target = *targetStart;
  while (source < sourceEnd) {
    UChar32 ch;
    unsigned short bytesToWrite = 0;
    const UChar32 byteMask = 0xBF;
    const UChar32 byteMark = 0x80;
    const LChar* oldSource =
        source;  // In case we have to back up because of target overflow.
    ch = static_cast<unsigned short>(*source++);

    // Figure out how many bytes the result will require
    if (ch < (UChar32)0x80)
      bytesToWrite = 1;
    else
      bytesToWrite = 2;

    target += bytesToWrite;
    if (target > targetEnd) {
      source = oldSource;  // Back up source pointer!
      target -= bytesToWrite;
      result = targetExhausted;
      break;
    }
    switch (bytesToWrite) {  // note: everything falls through.
      case 2:
        *--target = (char)((ch | byteMark) & byteMask);
        ch >>= 6;
      case 1:
        *--target = (char)(ch | firstByteMark[bytesToWrite]);
    }
    target += bytesToWrite;
  }
  *sourceStart = source;
  *targetStart = target;
  return result;
}

ConversionResult convertUTF16ToUTF8(const UChar** sourceStart,
                                    const UChar* sourceEnd,
                                    char** targetStart,
                                    char* targetEnd,
                                    bool strict) {
  ConversionResult result = conversionOK;
  const UChar* source = *sourceStart;
  char* target = *targetStart;
  while (source < sourceEnd) {
    UChar32 ch;
    unsigned short bytesToWrite = 0;
    const UChar32 byteMask = 0xBF;
    const UChar32 byteMark = 0x80;
    const UChar* oldSource =
        source;  // In case we have to back up because of target overflow.
    ch = static_cast<unsigned short>(*source++);
    // If we have a surrogate pair, convert to UChar32 first.
    if (ch >= 0xD800 && ch <= 0xDBFF) {
      // If the 16 bits following the high surrogate are in the source buffer...
      if (source < sourceEnd) {
        UChar32 ch2 = static_cast<unsigned short>(*source);
        // If it's a low surrogate, convert to UChar32.
        if (ch2 >= 0xDC00 && ch2 <= 0xDFFF) {
          ch = ((ch - 0xD800) << 10) + (ch2 - 0xDC00) + 0x0010000;
          ++source;
        } else if (strict) {  // it's an unpaired high surrogate
          --source;           // return to the illegal value itself
          result = sourceIllegal;
          break;
        }
      } else {     // We don't have the 16 bits following the high surrogate.
        --source;  // return to the high surrogate
        result = sourceExhausted;
        break;
      }
    } else if (strict) {
      // UTF-16 surrogate values are illegal in UTF-32
      if (ch >= 0xDC00 && ch <= 0xDFFF) {
        --source;  // return to the illegal value itself
        result = sourceIllegal;
        break;
      }
    }
    // Figure out how many bytes the result will require
    if (ch < (UChar32)0x80) {
      bytesToWrite = 1;
    } else if (ch < (UChar32)0x800) {
      bytesToWrite = 2;
    } else if (ch < (UChar32)0x10000) {
      bytesToWrite = 3;
    } else if (ch < (UChar32)0x110000) {
      bytesToWrite = 4;
    } else {
      bytesToWrite = 3;
      ch = replacementCharacter;
    }

    target += bytesToWrite;
    if (target > targetEnd) {
      source = oldSource;  // Back up source pointer!
      target -= bytesToWrite;
      result = targetExhausted;
      break;
    }
    switch (bytesToWrite) {  // note: everything falls through.
      case 4:
        *--target = (char)((ch | byteMark) & byteMask);
        ch >>= 6;
      case 3:
        *--target = (char)((ch | byteMark) & byteMask);
        ch >>= 6;
      case 2:
        *--target = (char)((ch | byteMark) & byteMask);
        ch >>= 6;
      case 1:
        *--target = (char)(ch | firstByteMark[bytesToWrite]);
    }
    target += bytesToWrite;
  }
  *sourceStart = source;
  *targetStart = target;
  return result;
}

// This must be called with the length pre-determined by the first byte.
// If presented with a length > 4, this returns false.  The Unicode
// definition of UTF-8 goes up to 4-byte sequences.
static bool isLegalUTF8(const unsigned char* source, int length) {
  unsigned char a;
  const unsigned char* srcptr = source + length;
  switch (length) {
    default:
      return false;
    // Everything else falls through when "true"...
    case 4:
      if ((a = (*--srcptr)) < 0x80 || a > 0xBF)
        return false;
    case 3:
      if ((a = (*--srcptr)) < 0x80 || a > 0xBF)
        return false;
    case 2:
      if ((a = (*--srcptr)) > 0xBF)
        return false;

      switch (*source) {
        // no fall-through in this inner switch
        case 0xE0:
          if (a < 0xA0)
            return false;
          break;
        case 0xED:
          if (a > 0x9F)
            return false;
          break;
        case 0xF0:
          if (a < 0x90)
            return false;
          break;
        case 0xF4:
          if (a > 0x8F)
            return false;
          break;
        default:
          if (a < 0x80)
            return false;
      }

    case 1:
      if (*source >= 0x80 && *source < 0xC2)
        return false;
  }
  if (*source > 0xF4)
    return false;
  return true;
}

// Magic values subtracted from a buffer value during UTF8 conversion.
// This table contains as many values as there might be trailing bytes
// in a UTF-8 sequence.
static const UChar32 offsetsFromUTF8[6] = {0x00000000UL,
                                           0x00003080UL,
                                           0x000E2080UL,
                                           0x03C82080UL,
                                           static_cast<UChar32>(0xFA082080UL),
                                           static_cast<UChar32>(0x82082080UL)};

static inline UChar32 readUTF8Sequence(const char*& sequence, unsigned length) {
  UChar32 character = 0;

  // The cases all fall through.
  switch (length) {
    case 6:
      character += static_cast<unsigned char>(*sequence++);
      character <<= 6;
    case 5:
      character += static_cast<unsigned char>(*sequence++);
      character <<= 6;
    case 4:
      character += static_cast<unsigned char>(*sequence++);
      character <<= 6;
    case 3:
      character += static_cast<unsigned char>(*sequence++);
      character <<= 6;
    case 2:
      character += static_cast<unsigned char>(*sequence++);
      character <<= 6;
    case 1:
      character += static_cast<unsigned char>(*sequence++);
  }

  return character - offsetsFromUTF8[length - 1];
}

ConversionResult convertUTF8ToUTF16(const char** sourceStart,
                                    const char* sourceEnd,
                                    UChar** targetStart,
                                    UChar* targetEnd,
                                    bool* sourceAllASCII,
                                    bool strict) {
  ConversionResult result = conversionOK;
  const char* source = *sourceStart;
  UChar* target = *targetStart;
  UChar orAllData = 0;
  while (source < sourceEnd) {
    int utf8SequenceLength = inlineUTF8SequenceLength(*source);
    if (sourceEnd - source < utf8SequenceLength) {
      result = sourceExhausted;
      break;
    }
    // Do this check whether lenient or strict
    if (!isLegalUTF8(reinterpret_cast<const unsigned char*>(source),
                     utf8SequenceLength)) {
      result = sourceIllegal;
      break;
    }

    UChar32 character = readUTF8Sequence(source, utf8SequenceLength);

    if (target >= targetEnd) {
      source -= utf8SequenceLength;  // Back up source pointer!
      result = targetExhausted;
      break;
    }

    if (U_IS_BMP(character)) {
      // UTF-16 surrogate values are illegal in UTF-32
      if (U_IS_SURROGATE(character)) {
        if (strict) {
          source -= utf8SequenceLength;  // return to the illegal value itself
          result = sourceIllegal;
          break;
        } else {
          *target++ = replacementCharacter;
          orAllData |= replacementCharacter;
        }
      } else {
        *target++ = character;  // normal case
        orAllData |= character;
      }
    } else if (U_IS_SUPPLEMENTARY(character)) {
      // target is a character in range 0xFFFF - 0x10FFFF
      if (target + 1 >= targetEnd) {
        source -= utf8SequenceLength;  // Back up source pointer!
        result = targetExhausted;
        break;
      }
      *target++ = U16_LEAD(character);
      *target++ = U16_TRAIL(character);
      orAllData = 0xffff;
    } else {
      if (strict) {
        source -= utf8SequenceLength;  // return to the start
        result = sourceIllegal;
        break;  // Bail out; shouldn't continue
      } else {
        *target++ = replacementCharacter;
        orAllData |= replacementCharacter;
      }
    }
  }
  *sourceStart = source;
  *targetStart = target;

  if (sourceAllASCII)
    *sourceAllASCII = !(orAllData & ~0x7f);

  return result;
}

unsigned calculateStringHashAndLengthFromUTF8MaskingTop8Bits(
    const char* data,
    const char* dataEnd,
    unsigned& dataLength,
    unsigned& utf16Length) {
  if (!data)
    return 0;

  StringHasher stringHasher;
  dataLength = 0;
  utf16Length = 0;

  while (data < dataEnd || (!dataEnd && *data)) {
    if (isASCII(*data)) {
      stringHasher.addCharacter(*data++);
      dataLength++;
      utf16Length++;
      continue;
    }

    int utf8SequenceLength = inlineUTF8SequenceLengthNonASCII(*data);
    dataLength += utf8SequenceLength;

    if (!dataEnd) {
      for (int i = 1; i < utf8SequenceLength; ++i) {
        if (!data[i])
          return 0;
      }
    } else if (dataEnd - data < utf8SequenceLength)
      return 0;

    if (!isLegalUTF8(reinterpret_cast<const unsigned char*>(data),
                     utf8SequenceLength))
      return 0;

    UChar32 character = readUTF8Sequence(data, utf8SequenceLength);
    ASSERT(!isASCII(character));

    if (U_IS_BMP(character)) {
      // UTF-16 surrogate values are illegal in UTF-32
      if (U_IS_SURROGATE(character))
        return 0;
      stringHasher.addCharacter(static_cast<UChar>(character));  // normal case
      utf16Length++;
    } else if (U_IS_SUPPLEMENTARY(character)) {
      stringHasher.addCharacters(static_cast<UChar>(U16_LEAD(character)),
                                 static_cast<UChar>(U16_TRAIL(character)));
      utf16Length += 2;
    } else
      return 0;
  }

  return stringHasher.hashWithTop8BitsMasked();
}

template <typename CharType>
ALWAYS_INLINE bool equalWithUTF8Internal(const CharType* a,
                                         const CharType* aEnd,
                                         const char* b,
                                         const char* bEnd) {
  while (b < bEnd) {
    if (isASCII(*b)) {
      if (*a++ != *b++)
        return false;
      continue;
    }

    int utf8SequenceLength = inlineUTF8SequenceLengthNonASCII(*b);

    if (bEnd - b < utf8SequenceLength)
      return false;

    if (!isLegalUTF8(reinterpret_cast<const unsigned char*>(b),
                     utf8SequenceLength))
      return 0;

    UChar32 character = readUTF8Sequence(b, utf8SequenceLength);
    ASSERT(!isASCII(character));

    if (U_IS_BMP(character)) {
      // UTF-16 surrogate values are illegal in UTF-32
      if (U_IS_SURROGATE(character))
        return false;
      if (*a++ != character)
        return false;
    } else if (U_IS_SUPPLEMENTARY(character)) {
      if (*a++ != U16_LEAD(character))
        return false;
      if (*a++ != U16_TRAIL(character))
        return false;
    } else
      return false;
  }

  return a == aEnd;
}

bool equalUTF16WithUTF8(const UChar* a,
                        const UChar* aEnd,
                        const char* b,
                        const char* bEnd) {
  return equalWithUTF8Internal(a, aEnd, b, bEnd);
}

bool equalLatin1WithUTF8(const LChar* a,
                         const LChar* aEnd,
                         const char* b,
                         const char* bEnd) {
  return equalWithUTF8Internal(a, aEnd, b, bEnd);
}

}  // namespace Unicode
}  // namespace WTF
