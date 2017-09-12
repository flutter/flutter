/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2013 Apple Inc.
 * All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_TEXT_STRINGIMPL_H_
#define SKY_ENGINE_WTF_TEXT_STRINGIMPL_H_

#include <limits.h>
#include "flutter/sky/engine/wtf/ASCIICType.h"
#include "flutter/sky/engine/wtf/Forward.h"
#include "flutter/sky/engine/wtf/HashMap.h"
#include "flutter/sky/engine/wtf/StringHasher.h"
#include "flutter/sky/engine/wtf/Vector.h"
#include "flutter/sky/engine/wtf/WTFExport.h"
#include "flutter/sky/engine/wtf/unicode/Unicode.h"

namespace WTF {

struct AlreadyHashed;
struct CStringTranslator;
template <typename CharacterType>
struct HashAndCharactersTranslator;
struct HashAndUTF8CharactersTranslator;
struct LCharBufferTranslator;
struct CharBufferFromLiteralDataTranslator;
struct SubstringTranslator;
struct UCharBufferTranslator;

enum TextCaseSensitivity { TextCaseSensitive, TextCaseInsensitive };

enum StripBehavior { StripExtraWhiteSpace, DoNotStripWhiteSpace };

typedef bool (*CharacterMatchFunctionPtr)(UChar);
typedef bool (*IsWhiteSpaceFunctionPtr)(UChar);
typedef HashMap<unsigned, StringImpl*, AlreadyHashed> StaticStringsTable;

// Define STRING_STATS to turn on run time statistics of string sizes and memory
// usage
#undef STRING_STATS

#ifdef STRING_STATS
struct StringStats {
  inline void add8BitString(unsigned length) {
    ++m_totalNumberStrings;
    ++m_number8BitStrings;
    m_total8BitData += length;
  }

  inline void add16BitString(unsigned length) {
    ++m_totalNumberStrings;
    ++m_number16BitStrings;
    m_total16BitData += length;
  }

  void removeString(StringImpl*);
  void printStats();

  static const unsigned s_printStringStatsFrequency = 5000;
  static unsigned s_stringRemovesTillPrintStats;

  unsigned m_totalNumberStrings;
  unsigned m_number8BitStrings;
  unsigned m_number16BitStrings;
  unsigned long long m_total8BitData;
  unsigned long long m_total16BitData;
};

void addStringForStats(StringImpl*);
void removeStringForStats(StringImpl*);

#define STRING_STATS_ADD_8BIT_STRING(length)       \
  StringImpl::stringStats().add8BitString(length); \
  addStringForStats(this)
#define STRING_STATS_ADD_16BIT_STRING(length)       \
  StringImpl::stringStats().add16BitString(length); \
  addStringForStats(this)
#define STRING_STATS_REMOVE_STRING(string)        \
  StringImpl::stringStats().removeString(string); \
  removeStringForStats(this)
#else
#define STRING_STATS_ADD_8BIT_STRING(length) ((void)0)
#define STRING_STATS_ADD_16BIT_STRING(length) ((void)0)
#define STRING_STATS_REMOVE_STRING(string) ((void)0)
#endif

// You can find documentation about this class in this doc:
// https://docs.google.com/document/d/1kOCUlJdh2WJMJGDf-WoEQhmnjKLaOYRbiHz5TiGJl14/edit?usp=sharing
class WTF_EXPORT StringImpl {
  WTF_MAKE_NONCOPYABLE(StringImpl);
  friend struct WTF::CStringTranslator;
  template <typename CharacterType>
  friend struct WTF::HashAndCharactersTranslator;
  friend struct WTF::HashAndUTF8CharactersTranslator;
  friend struct WTF::CharBufferFromLiteralDataTranslator;
  friend struct WTF::LCharBufferTranslator;
  friend struct WTF::SubstringTranslator;
  friend struct WTF::UCharBufferTranslator;

 private:
  // StringImpls are allocated out of the WTF buffer partition.
  void* operator new(size_t);
  void* operator new(size_t, void* ptr) { return ptr; };
  void operator delete(void*);

  // Used to construct static strings, which have an special refCount that can
  // never hit zero. This means that the static string will never be destroyed,
  // which is important because static strings will be shared across threads &
  // ref-counted in a non-threadsafe manner.
  enum ConstructEmptyStringTag { ConstructEmptyString };
  explicit StringImpl(ConstructEmptyStringTag)
      : m_refCount(1),
        m_length(0),
        m_hash(0),
        m_isAtomic(false),
        m_is8Bit(true),
        m_isStatic(true) {
    // Ensure that the hash is computed so that AtomicStringHash can call
    // existingHash() with impunity. The empty string is special because it is
    // never entered into AtomicString's HashKey, but still needs to compare
    // correctly.
    STRING_STATS_ADD_8BIT_STRING(m_length);
    hash();
  }

  // FIXME: there has to be a less hacky way to do this.
  enum Force8Bit { Force8BitConstructor };
  StringImpl(unsigned length, Force8Bit)
      : m_refCount(1),
        m_length(length),
        m_hash(0),
        m_isAtomic(false),
        m_is8Bit(true),
        m_isStatic(false) {
    ASSERT(m_length);
    STRING_STATS_ADD_8BIT_STRING(m_length);
  }

  StringImpl(unsigned length)
      : m_refCount(1),
        m_length(length),
        m_hash(0),
        m_isAtomic(false),
        m_is8Bit(false),
        m_isStatic(false) {
    ASSERT(m_length);
    STRING_STATS_ADD_16BIT_STRING(m_length);
  }

  enum StaticStringTag { StaticString };
  StringImpl(unsigned length, unsigned hash, StaticStringTag)
      : m_refCount(1),
        m_length(length),
        m_hash(hash),
        m_isAtomic(false),
        m_is8Bit(true),
        m_isStatic(true) {}

 public:
  ~StringImpl();

  static StringImpl* createStatic(const char* string,
                                  unsigned length,
                                  unsigned hash);
  static void freezeStaticStrings();
  static const StaticStringsTable& allStaticStrings();
  static unsigned highestStaticStringLength() {
    return m_highestStaticStringLength;
  }

  static PassRefPtr<StringImpl> create(const UChar*, unsigned length);
  static PassRefPtr<StringImpl> create(const LChar*, unsigned length);
  static PassRefPtr<StringImpl> create8BitIfPossible(const UChar*,
                                                     unsigned length);
  template <size_t inlineCapacity>
  static PassRefPtr<StringImpl> create8BitIfPossible(
      const Vector<UChar, inlineCapacity>& vector) {
    return create8BitIfPossible(vector.data(), vector.size());
  }

  ALWAYS_INLINE static PassRefPtr<StringImpl> create(const char* s,
                                                     unsigned length) {
    return create(reinterpret_cast<const LChar*>(s), length);
  }
  static PassRefPtr<StringImpl> create(const LChar*);
  ALWAYS_INLINE static PassRefPtr<StringImpl> create(const char* s) {
    return create(reinterpret_cast<const LChar*>(s));
  }

  static PassRefPtr<StringImpl> createUninitialized(unsigned length,
                                                    LChar*& data);
  static PassRefPtr<StringImpl> createUninitialized(unsigned length,
                                                    UChar*& data);

  // Reallocate the StringImpl. The originalString must be only owned by the
  // PassRefPtr. Just like the input pointer of realloc(), the originalString
  // can't be used after this function.
  static PassRefPtr<StringImpl> reallocate(
      PassRefPtr<StringImpl> originalString,
      unsigned length);

  // If this StringImpl has only one reference, we can truncate the string by
  // updating its m_length property without actually re-allocating its buffer.
  void truncateAssumingIsolated(unsigned length) {
    ASSERT(hasOneRef());
    ASSERT(length <= m_length);
    m_length = length;
  }

  unsigned length() const { return m_length; }
  bool is8Bit() const { return m_is8Bit; }

  ALWAYS_INLINE const LChar* characters8() const {
    ASSERT(is8Bit());
    return reinterpret_cast<const LChar*>(this + 1);
  }
  ALWAYS_INLINE const UChar* characters16() const {
    ASSERT(!is8Bit());
    return reinterpret_cast<const UChar*>(this + 1);
  }

  template <typename CharType>
  ALWAYS_INLINE const CharType* getCharacters() const;

  size_t sizeInBytes() const;

  bool isAtomic() const { return m_isAtomic; }
  void setIsAtomic(bool isAtomic) { m_isAtomic = isAtomic; }

  bool isStatic() const { return m_isStatic; }

 private:
  // The high bits of 'hash' are always empty, but we prefer to store our flags
  // in the low bits because it makes them slightly more efficient to access.
  // So, we shift left and right when setting and getting our hash code.
  void setHash(unsigned hash) const {
    ASSERT(!hasHash());
    // Multiple clients assume that StringHasher is the canonical string hash
    // function.
    ASSERT(hash == (is8Bit() ? StringHasher::computeHashAndMaskTop8Bits(
                                   characters8(), m_length)
                             : StringHasher::computeHashAndMaskTop8Bits(
                                   characters16(), m_length)));
    m_hash = hash;
    ASSERT(hash);  // Verify that 0 is a valid sentinel hash value.
  }

  unsigned rawHash() const { return m_hash; }

  void destroyIfNotStatic();

 public:
  bool hasHash() const { return rawHash() != 0; }

  unsigned existingHash() const {
    ASSERT(hasHash());
    return rawHash();
  }

  unsigned hash() const {
    if (hasHash())
      return existingHash();
    return hashSlowCase();
  }

  ALWAYS_INLINE bool hasOneRef() const { return m_refCount == 1; }

  ALWAYS_INLINE void ref() { ++m_refCount; }

  ALWAYS_INLINE void deref() {
    if (hasOneRef()) {
      destroyIfNotStatic();
      return;
    }

    --m_refCount;
  }

  static StringImpl* empty();

  // FIXME: Does this really belong in StringImpl?
  template <typename T>
  static void copyChars(T* destination,
                        const T* source,
                        unsigned numCharacters) {
    memcpy(destination, source, numCharacters * sizeof(T));
  }

  ALWAYS_INLINE static void copyChars(UChar* destination,
                                      const LChar* source,
                                      unsigned numCharacters) {
    for (unsigned i = 0; i < numCharacters; ++i)
      destination[i] = source[i];
  }

  // Some string features, like refcounting and the atomicity flag, are not
  // thread-safe. We achieve thread safety by isolation, giving each thread
  // its own copy of the string.
  PassRefPtr<StringImpl> isolatedCopy() const;

  PassRefPtr<StringImpl> substring(unsigned pos, unsigned len = UINT_MAX);

  UChar operator[](unsigned i) const {
    ASSERT_WITH_SECURITY_IMPLICATION(i < m_length);
    if (is8Bit())
      return characters8()[i];
    return characters16()[i];
  }
  UChar32 characterStartingAt(unsigned);

  bool containsOnlyWhitespace();

  int toIntStrict(bool* ok = 0, int base = 10);
  unsigned toUIntStrict(bool* ok = 0, int base = 10);
  int64_t toInt64Strict(bool* ok = 0, int base = 10);
  uint64_t toUInt64Strict(bool* ok = 0, int base = 10);
  intptr_t toIntPtrStrict(bool* ok = 0, int base = 10);

  int toInt(bool* ok = 0);          // ignores trailing garbage
  unsigned toUInt(bool* ok = 0);    // ignores trailing garbage
  int64_t toInt64(bool* ok = 0);    // ignores trailing garbage
  uint64_t toUInt64(bool* ok = 0);  // ignores trailing garbage
  intptr_t toIntPtr(bool* ok = 0);  // ignores trailing garbage

  // FIXME: Like the strict functions above, these give false for "ok" when
  // there is trailing garbage. Like the non-strict functions above, these
  // return the value when there is trailing garbage. It would be better if
  // these were more consistent with the above functions instead.
  double toDouble(bool* ok = 0);
  float toFloat(bool* ok = 0);

  PassRefPtr<StringImpl> lower();
  PassRefPtr<StringImpl> upper();
  PassRefPtr<StringImpl> lower(const AtomicString& localeIdentifier);
  PassRefPtr<StringImpl> upper(const AtomicString& localeIdentifier);

  PassRefPtr<StringImpl> fill(UChar);
  // FIXME: Do we need fill(char) or can we just do the right thing if UChar is
  // ASCII?
  PassRefPtr<StringImpl> foldCase();

  PassRefPtr<StringImpl> stripWhiteSpace();
  PassRefPtr<StringImpl> stripWhiteSpace(IsWhiteSpaceFunctionPtr);
  PassRefPtr<StringImpl> simplifyWhiteSpace(
      StripBehavior stripBehavior = StripExtraWhiteSpace);
  PassRefPtr<StringImpl> simplifyWhiteSpace(
      IsWhiteSpaceFunctionPtr,
      StripBehavior stripBehavior = StripExtraWhiteSpace);

  PassRefPtr<StringImpl> removeCharacters(CharacterMatchFunctionPtr);
  template <typename CharType>
  ALWAYS_INLINE PassRefPtr<StringImpl> removeCharacters(
      const CharType* characters,
      CharacterMatchFunctionPtr);

  size_t find(LChar character, unsigned start = 0);
  size_t find(char character, unsigned start = 0);
  size_t find(UChar character, unsigned start = 0);
  size_t find(CharacterMatchFunctionPtr, unsigned index = 0);
  size_t find(const LChar*, unsigned index = 0);
  ALWAYS_INLINE size_t find(const char* s, unsigned index = 0) {
    return find(reinterpret_cast<const LChar*>(s), index);
  }
  size_t find(StringImpl*);
  size_t find(StringImpl*, unsigned index);
  size_t findIgnoringCase(const LChar*, unsigned index = 0);
  ALWAYS_INLINE size_t findIgnoringCase(const char* s, unsigned index = 0) {
    return findIgnoringCase(reinterpret_cast<const LChar*>(s), index);
  }
  size_t findIgnoringCase(StringImpl*, unsigned index = 0);

  size_t findNextLineStart(unsigned index = UINT_MAX);

  size_t reverseFind(UChar, unsigned index = UINT_MAX);
  size_t reverseFind(StringImpl*, unsigned index = UINT_MAX);
  size_t reverseFindIgnoringCase(StringImpl*, unsigned index = UINT_MAX);

  size_t count(LChar) const;

  bool startsWith(StringImpl* str, bool caseSensitive = true) {
    return (caseSensitive ? reverseFind(str, 0)
                          : reverseFindIgnoringCase(str, 0)) == 0;
  }
  bool startsWith(UChar) const;
  bool startsWith(const char*, unsigned matchLength, bool caseSensitive) const;
  template <unsigned matchLength>
  bool startsWith(const char (&prefix)[matchLength],
                  bool caseSensitive = true) const {
    return startsWith(prefix, matchLength - 1, caseSensitive);
  }

  bool endsWith(StringImpl*, bool caseSensitive = true);
  bool endsWith(UChar) const;
  bool endsWith(const char*, unsigned matchLength, bool caseSensitive) const;
  template <unsigned matchLength>
  bool endsWith(const char (&prefix)[matchLength],
                bool caseSensitive = true) const {
    return endsWith(prefix, matchLength - 1, caseSensitive);
  }

  PassRefPtr<StringImpl> replace(UChar, UChar);
  PassRefPtr<StringImpl> replace(UChar, StringImpl*);
  ALWAYS_INLINE PassRefPtr<StringImpl> replace(UChar pattern,
                                               const char* replacement,
                                               unsigned replacementLength) {
    return replace(pattern, reinterpret_cast<const LChar*>(replacement),
                   replacementLength);
  }
  PassRefPtr<StringImpl> replace(UChar,
                                 const LChar*,
                                 unsigned replacementLength);
  PassRefPtr<StringImpl> replace(UChar,
                                 const UChar*,
                                 unsigned replacementLength);
  PassRefPtr<StringImpl> replace(StringImpl*, StringImpl*);
  PassRefPtr<StringImpl> replace(unsigned index, unsigned len, StringImpl*);
  PassRefPtr<StringImpl> upconvertedString();

#ifdef STRING_STATS
  ALWAYS_INLINE static StringStats& stringStats() { return m_stringStats; }
#endif

 private:
  template <typename CharType>
  static size_t allocationSize(unsigned length) {
    RELEASE_ASSERT(
        length <= ((std::numeric_limits<unsigned>::max() - sizeof(StringImpl)) /
                   sizeof(CharType)));
    return sizeof(StringImpl) + length * sizeof(CharType);
  }

  template <class UCharPredicate>
  PassRefPtr<StringImpl> stripMatchedCharacters(UCharPredicate);
  template <typename CharType, class UCharPredicate>
  PassRefPtr<StringImpl> simplifyMatchedCharactersToSpace(UCharPredicate,
                                                          StripBehavior);
  NEVER_INLINE unsigned hashSlowCase() const;

#ifdef STRING_STATS
  static StringStats m_stringStats;
#endif

  static unsigned m_highestStaticStringLength;

#if ENABLE(ASSERT)
  void assertHashIsCorrect() {
    ASSERT(hasHash());
    ASSERT(existingHash() ==
           StringHasher::computeHashAndMaskTop8Bits(characters8(), length()));
  }
#endif

 private:
  unsigned m_refCount;
  unsigned m_length;
  mutable unsigned m_hash : 24;
  unsigned m_isAtomic : 1;
  unsigned m_is8Bit : 1;
  unsigned m_isStatic : 1;
};

template <>
ALWAYS_INLINE const LChar* StringImpl::getCharacters<LChar>() const {
  return characters8();
}

template <>
ALWAYS_INLINE const UChar* StringImpl::getCharacters<UChar>() const {
  return characters16();
}

WTF_EXPORT bool equal(const StringImpl*, const StringImpl*);
WTF_EXPORT bool equal(const StringImpl*, const LChar*);
inline bool equal(const StringImpl* a, const char* b) {
  return equal(a, reinterpret_cast<const LChar*>(b));
}
WTF_EXPORT bool equal(const StringImpl*, const LChar*, unsigned);
WTF_EXPORT bool equal(const StringImpl*, const UChar*, unsigned);
inline bool equal(const StringImpl* a, const char* b, unsigned length) {
  return equal(a, reinterpret_cast<const LChar*>(b), length);
}
inline bool equal(const LChar* a, StringImpl* b) {
  return equal(b, a);
}
inline bool equal(const char* a, StringImpl* b) {
  return equal(b, reinterpret_cast<const LChar*>(a));
}
WTF_EXPORT bool equalNonNull(const StringImpl* a, const StringImpl* b);

template <typename CharType>
ALWAYS_INLINE bool equal(const CharType* a,
                         const CharType* b,
                         unsigned length) {
  return !memcmp(a, b, length * sizeof(CharType));
}

ALWAYS_INLINE bool equal(const LChar* a, const UChar* b, unsigned length) {
  for (unsigned i = 0; i < length; ++i) {
    if (a[i] != b[i])
      return false;
  }
  return true;
}

ALWAYS_INLINE bool equal(const UChar* a, const LChar* b, unsigned length) {
  return equal(b, a, length);
}

WTF_EXPORT bool equalIgnoringCase(const StringImpl*, const StringImpl*);
WTF_EXPORT bool equalIgnoringCase(const StringImpl*, const LChar*);
inline bool equalIgnoringCase(const LChar* a, const StringImpl* b) {
  return equalIgnoringCase(b, a);
}
WTF_EXPORT bool equalIgnoringCase(const LChar*, const LChar*, unsigned);
WTF_EXPORT bool equalIgnoringCase(const UChar*, const LChar*, unsigned);
inline bool equalIgnoringCase(const UChar* a, const char* b, unsigned length) {
  return equalIgnoringCase(a, reinterpret_cast<const LChar*>(b), length);
}
inline bool equalIgnoringCase(const LChar* a, const UChar* b, unsigned length) {
  return equalIgnoringCase(b, a, length);
}
inline bool equalIgnoringCase(const char* a, const UChar* b, unsigned length) {
  return equalIgnoringCase(b, reinterpret_cast<const LChar*>(a), length);
}
inline bool equalIgnoringCase(const char* a, const LChar* b, unsigned length) {
  return equalIgnoringCase(b, reinterpret_cast<const LChar*>(a), length);
}
inline bool equalIgnoringCase(const UChar* a, const UChar* b, int length) {
  ASSERT(length >= 0);
  return !Unicode::umemcasecmp(a, b, length);
}
WTF_EXPORT bool equalIgnoringCaseNonNull(const StringImpl*, const StringImpl*);

WTF_EXPORT bool equalIgnoringNullity(StringImpl*, StringImpl*);

template <typename CharacterType>
inline size_t find(const CharacterType* characters,
                   unsigned length,
                   CharacterType matchCharacter,
                   unsigned index = 0) {
  while (index < length) {
    if (characters[index] == matchCharacter)
      return index;
    ++index;
  }
  return kNotFound;
}

ALWAYS_INLINE size_t find(const UChar* characters,
                          unsigned length,
                          LChar matchCharacter,
                          unsigned index = 0) {
  return find(characters, length, static_cast<UChar>(matchCharacter), index);
}

inline size_t find(const LChar* characters,
                   unsigned length,
                   UChar matchCharacter,
                   unsigned index = 0) {
  if (matchCharacter & ~0xFF)
    return kNotFound;
  return find(characters, length, static_cast<LChar>(matchCharacter), index);
}

inline size_t find(const LChar* characters,
                   unsigned length,
                   CharacterMatchFunctionPtr matchFunction,
                   unsigned index = 0) {
  while (index < length) {
    if (matchFunction(characters[index]))
      return index;
    ++index;
  }
  return kNotFound;
}

inline size_t find(const UChar* characters,
                   unsigned length,
                   CharacterMatchFunctionPtr matchFunction,
                   unsigned index = 0) {
  while (index < length) {
    if (matchFunction(characters[index]))
      return index;
    ++index;
  }
  return kNotFound;
}

template <typename CharacterType>
inline size_t findNextLineStart(const CharacterType* characters,
                                unsigned length,
                                unsigned index = 0) {
  while (index < length) {
    CharacterType c = characters[index++];
    if ((c != '\n') && (c != '\r'))
      continue;

    // There can only be a start of a new line if there are more characters
    // beyond the current character.
    if (index < length) {
      // The 3 common types of line terminators are 1. \r\n (Windows),
      // 2. \r (old MacOS) and 3. \n (Unix'es).

      if (c == '\n')
        return index;  // Case 3: just \n.

      CharacterType c2 = characters[index];
      if (c2 != '\n')
        return index;  // Case 2: just \r.

      // Case 1: \r\n.
      // But, there's only a start of a new line if there are more
      // characters beyond the \r\n.
      if (++index < length)
        return index;
    }
  }
  return kNotFound;
}

template <typename CharacterType>
inline size_t reverseFindLineTerminator(const CharacterType* characters,
                                        unsigned length,
                                        unsigned index = UINT_MAX) {
  if (!length)
    return kNotFound;
  if (index >= length)
    index = length - 1;
  CharacterType c = characters[index];
  while ((c != '\n') && (c != '\r')) {
    if (!index--)
      return kNotFound;
    c = characters[index];
  }
  return index;
}

template <typename CharacterType>
inline size_t reverseFind(const CharacterType* characters,
                          unsigned length,
                          CharacterType matchCharacter,
                          unsigned index = UINT_MAX) {
  if (!length)
    return kNotFound;
  if (index >= length)
    index = length - 1;
  while (characters[index] != matchCharacter) {
    if (!index--)
      return kNotFound;
  }
  return index;
}

ALWAYS_INLINE size_t reverseFind(const UChar* characters,
                                 unsigned length,
                                 LChar matchCharacter,
                                 unsigned index = UINT_MAX) {
  return reverseFind(characters, length, static_cast<UChar>(matchCharacter),
                     index);
}

inline size_t reverseFind(const LChar* characters,
                          unsigned length,
                          UChar matchCharacter,
                          unsigned index = UINT_MAX) {
  if (matchCharacter & ~0xFF)
    return kNotFound;
  return reverseFind(characters, length, static_cast<LChar>(matchCharacter),
                     index);
}

inline size_t StringImpl::find(LChar character, unsigned start) {
  if (is8Bit())
    return WTF::find(characters8(), m_length, character, start);
  return WTF::find(characters16(), m_length, character, start);
}

ALWAYS_INLINE size_t StringImpl::find(char character, unsigned start) {
  return find(static_cast<LChar>(character), start);
}

inline size_t StringImpl::find(UChar character, unsigned start) {
  if (is8Bit())
    return WTF::find(characters8(), m_length, character, start);
  return WTF::find(characters16(), m_length, character, start);
}

inline unsigned lengthOfNullTerminatedString(const UChar* string) {
  size_t length = 0;
  while (string[length] != UChar(0))
    ++length;
  RELEASE_ASSERT(length <= std::numeric_limits<unsigned>::max());
  return static_cast<unsigned>(length);
}

template <size_t inlineCapacity>
bool equalIgnoringNullity(const Vector<UChar, inlineCapacity>& a,
                          StringImpl* b) {
  if (!b)
    return !a.size();
  if (a.size() != b->length())
    return false;
  if (b->is8Bit())
    return equal(a.data(), b->characters8(), b->length());
  return equal(a.data(), b->characters16(), b->length());
}

template <typename CharacterType1, typename CharacterType2>
static inline int codePointCompare(unsigned l1,
                                   unsigned l2,
                                   const CharacterType1* c1,
                                   const CharacterType2* c2) {
  const unsigned lmin = l1 < l2 ? l1 : l2;
  unsigned pos = 0;
  while (pos < lmin && *c1 == *c2) {
    ++c1;
    ++c2;
    ++pos;
  }

  if (pos < lmin)
    return (c1[0] > c2[0]) ? 1 : -1;

  if (l1 == l2)
    return 0;

  return (l1 > l2) ? 1 : -1;
}

static inline int codePointCompare8(const StringImpl* string1,
                                    const StringImpl* string2) {
  return codePointCompare(string1->length(), string2->length(),
                          string1->characters8(), string2->characters8());
}

static inline int codePointCompare16(const StringImpl* string1,
                                     const StringImpl* string2) {
  return codePointCompare(string1->length(), string2->length(),
                          string1->characters16(), string2->characters16());
}

static inline int codePointCompare8To16(const StringImpl* string1,
                                        const StringImpl* string2) {
  return codePointCompare(string1->length(), string2->length(),
                          string1->characters8(), string2->characters16());
}

static inline int codePointCompare(const StringImpl* string1,
                                   const StringImpl* string2) {
  if (!string1)
    return (string2 && string2->length()) ? -1 : 0;

  if (!string2)
    return string1->length() ? 1 : 0;

  bool string1Is8Bit = string1->is8Bit();
  bool string2Is8Bit = string2->is8Bit();
  if (string1Is8Bit) {
    if (string2Is8Bit)
      return codePointCompare8(string1, string2);
    return codePointCompare8To16(string1, string2);
  }
  if (string2Is8Bit)
    return -codePointCompare8To16(string2, string1);
  return codePointCompare16(string1, string2);
}

static inline bool isSpaceOrNewline(UChar c) {
  // Use isASCIISpace() for basic Latin-1.
  // This will include newlines, which aren't included in Unicode DirWS.
  return c <= 0x7F
             ? WTF::isASCIISpace(c)
             : WTF::Unicode::direction(c) == WTF::Unicode::WhiteSpaceNeutral;
}

inline PassRefPtr<StringImpl> StringImpl::isolatedCopy() const {
  if (is8Bit())
    return create(characters8(), m_length);
  return create(characters16(), m_length);
}

struct StringHash;

// StringHash is the default hash for StringImpl* and RefPtr<StringImpl>
template <typename T>
struct DefaultHash;
template <>
struct DefaultHash<StringImpl*> {
  typedef StringHash Hash;
};
template <>
struct DefaultHash<RefPtr<StringImpl>> {
  typedef StringHash Hash;
};

}  // namespace WTF

using WTF::StringImpl;
using WTF::TextCaseInsensitive;
using WTF::TextCaseSensitive;
using WTF::TextCaseSensitivity;
using WTF::equal;
using WTF::equalNonNull;

#endif  // SKY_ENGINE_WTF_TEXT_STRINGIMPL_H_
