/*
 * Copyright (C) 2005, 2006, 2008, 2010, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Patrick Gansterer <paroga@paroga.com>
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
 *
 */

#ifndef SKY_ENGINE_WTF_STRINGHASHER_H_
#define SKY_ENGINE_WTF_STRINGHASHER_H_

#include "flutter/sky/engine/wtf/unicode/Unicode.h"

namespace WTF {

// Paul Hsieh's SuperFastHash
// http://www.azillionmonkeys.com/qed/hash.html

// LChar data is interpreted as Latin-1-encoded (zero extended to 16 bits).

// NOTE: The hash computation here must stay in sync with the create_hash_table
// script in JavaScriptCore and the CodeGeneratorJS.pm script in WebCore.

// Golden ratio. Arbitrary start value to avoid mapping all zeros to a hash
// value of zero.
static const unsigned stringHashingStartValue = 0x9E3779B9U;

class StringHasher {
 public:
  static const unsigned flagCount =
      8;  // Save 8 bits for StringImpl to use as flags.

  StringHasher()
      : m_hash(stringHashingStartValue),
        m_hasPendingCharacter(false),
        m_pendingCharacter(0) {}

  // The hasher hashes two characters at a time, and thus an "aligned" hasher is
  // one where an even number of characters have been added. Callers that always
  // add characters two at a time can use the "assuming aligned" functions.
  void addCharactersAssumingAligned(UChar a, UChar b) {
    ASSERT(!m_hasPendingCharacter);
    m_hash += a;
    m_hash = (m_hash << 16) ^ ((b << 11) ^ m_hash);
    m_hash += m_hash >> 11;
  }

  void addCharacter(UChar character) {
    if (m_hasPendingCharacter) {
      m_hasPendingCharacter = false;
      addCharactersAssumingAligned(m_pendingCharacter, character);
      return;
    }

    m_pendingCharacter = character;
    m_hasPendingCharacter = true;
  }

  void addCharacters(UChar a, UChar b) {
    if (m_hasPendingCharacter) {
#if ENABLE(ASSERT)
      m_hasPendingCharacter = false;
#endif
      addCharactersAssumingAligned(m_pendingCharacter, a);
      m_pendingCharacter = b;
#if ENABLE(ASSERT)
      m_hasPendingCharacter = true;
#endif
      return;
    }

    addCharactersAssumingAligned(a, b);
  }

  template <typename T, UChar Converter(T)>
  void addCharactersAssumingAligned(const T* data, unsigned length) {
    ASSERT(!m_hasPendingCharacter);

    bool remainder = length & 1;
    length >>= 1;

    while (length--) {
      addCharactersAssumingAligned(Converter(data[0]), Converter(data[1]));
      data += 2;
    }

    if (remainder)
      addCharacter(Converter(*data));
  }

  template <typename T>
  void addCharactersAssumingAligned(const T* data, unsigned length) {
    addCharactersAssumingAligned<T, defaultConverter>(data, length);
  }

  template <typename T, UChar Converter(T)>
  void addCharacters(const T* data, unsigned length) {
    if (m_hasPendingCharacter && length) {
      m_hasPendingCharacter = false;
      addCharactersAssumingAligned(m_pendingCharacter, Converter(*data++));
      --length;
    }
    addCharactersAssumingAligned<T, Converter>(data, length);
  }

  template <typename T>
  void addCharacters(const T* data, unsigned length) {
    addCharacters<T, defaultConverter>(data, length);
  }

  unsigned hashWithTop8BitsMasked() const {
    unsigned result = avalancheBits();

    // Reserving space from the high bits for flags preserves most of the hash's
    // value, since hash lookup typically masks out the high bits anyway.
    result &= (1U << (sizeof(result) * 8 - flagCount)) - 1;

    // This avoids ever returning a hash code of 0, since that is used to
    // signal "hash not computed yet". Setting the high bit maintains
    // reasonable fidelity to a hash code of 0 because it is likely to yield
    // exactly 0 when hash lookup masks out the high bits.
    if (!result)
      result = 0x80000000 >> flagCount;

    return result;
  }

  unsigned hash() const {
    unsigned result = avalancheBits();

    // This avoids ever returning a hash code of 0, since that is used to
    // signal "hash not computed yet". Setting the high bit maintains
    // reasonable fidelity to a hash code of 0 because it is likely to yield
    // exactly 0 when hash lookup masks out the high bits.
    if (!result)
      result = 0x80000000;

    return result;
  }

  template <typename T, UChar Converter(T)>
  static unsigned computeHashAndMaskTop8Bits(const T* data, unsigned length) {
    StringHasher hasher;
    hasher.addCharactersAssumingAligned<T, Converter>(data, length);
    return hasher.hashWithTop8BitsMasked();
  }

  template <typename T>
  static unsigned computeHashAndMaskTop8Bits(const T* data, unsigned length) {
    return computeHashAndMaskTop8Bits<T, defaultConverter>(data, length);
  }

  template <typename T, UChar Converter(T)>
  static unsigned computeHash(const T* data, unsigned length) {
    StringHasher hasher;
    hasher.addCharactersAssumingAligned<T, Converter>(data, length);
    return hasher.hash();
  }

  template <typename T>
  static unsigned computeHash(const T* data, unsigned length) {
    return computeHash<T, defaultConverter>(data, length);
  }

  static unsigned hashMemory(const void* data, unsigned length) {
    // FIXME: Why does this function use the version of the hash that drops the
    // top 8 bits? We want that for all string hashing so we can use those bits
    // in StringImpl and hash strings consistently, but I don't see why we'd
    // want that for general memory hashing.
    ASSERT(!(length % 2));
    return computeHashAndMaskTop8Bits<UChar>(static_cast<const UChar*>(data),
                                             length / sizeof(UChar));
  }

  template <size_t length>
  static unsigned hashMemory(const void* data) {
    COMPILE_ASSERT(!(length % 2), length_must_be_a_multiple_of_two);
    return hashMemory(data, length);
  }

 private:
  static UChar defaultConverter(UChar character) { return character; }

  static UChar defaultConverter(LChar character) { return character; }

  unsigned avalancheBits() const {
    unsigned result = m_hash;

    // Handle end case.
    if (m_hasPendingCharacter) {
      result += m_pendingCharacter;
      result ^= result << 11;
      result += result >> 17;
    }

    // Force "avalanching" of final 31 bits.
    result ^= result << 3;
    result += result >> 5;
    result ^= result << 2;
    result += result >> 15;
    result ^= result << 10;

    return result;
  }

  unsigned m_hash;
  bool m_hasPendingCharacter;
  UChar m_pendingCharacter;
};

}  // namespace WTF

using WTF::StringHasher;

#endif  // SKY_ENGINE_WTF_STRINGHASHER_H_
