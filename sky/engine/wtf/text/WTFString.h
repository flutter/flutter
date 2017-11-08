/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012, 2013 Apple Inc.
 * All rights reserved.
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

#ifndef SKY_ENGINE_WTF_TEXT_WTFSTRING_H_
#define SKY_ENGINE_WTF_TEXT_WTFSTRING_H_

// This file would be called String.h, but that conflicts with <string.h>
// on systems without case-sensitive file systems.
#include <string>

#include "flutter/sky/engine/wtf/HashTableDeletedValueType.h"
#include "flutter/sky/engine/wtf/WTFExport.h"
#include "flutter/sky/engine/wtf/text/ASCIIFastPath.h"
#include "flutter/sky/engine/wtf/text/StringImpl.h"
#include "flutter/sky/engine/wtf/text/StringView.h"

namespace WTF {

class CString;
struct StringHash;

// Declarations of string operations

WTF_EXPORT int charactersToIntStrict(const LChar*,
                                     size_t,
                                     bool* ok = 0,
                                     int base = 10);
WTF_EXPORT int charactersToIntStrict(const UChar*,
                                     size_t,
                                     bool* ok = 0,
                                     int base = 10);
WTF_EXPORT unsigned charactersToUIntStrict(const LChar*,
                                           size_t,
                                           bool* ok = 0,
                                           int base = 10);
WTF_EXPORT unsigned charactersToUIntStrict(const UChar*,
                                           size_t,
                                           bool* ok = 0,
                                           int base = 10);
WTF_EXPORT int64_t charactersToInt64Strict(const LChar*,
                                           size_t,
                                           bool* ok = 0,
                                           int base = 10);
WTF_EXPORT int64_t charactersToInt64Strict(const UChar*,
                                           size_t,
                                           bool* ok = 0,
                                           int base = 10);
WTF_EXPORT uint64_t charactersToUInt64Strict(const LChar*,
                                             size_t,
                                             bool* ok = 0,
                                             int base = 10);
WTF_EXPORT uint64_t charactersToUInt64Strict(const UChar*,
                                             size_t,
                                             bool* ok = 0,
                                             int base = 10);
WTF_EXPORT intptr_t charactersToIntPtrStrict(const LChar*,
                                             size_t,
                                             bool* ok = 0,
                                             int base = 10);
WTF_EXPORT intptr_t charactersToIntPtrStrict(const UChar*,
                                             size_t,
                                             bool* ok = 0,
                                             int base = 10);

WTF_EXPORT int charactersToInt(const LChar*,
                               size_t,
                               bool* ok = 0);  // ignores trailing garbage
WTF_EXPORT int charactersToInt(const UChar*,
                               size_t,
                               bool* ok = 0);  // ignores trailing garbage
WTF_EXPORT unsigned charactersToUInt(const LChar*,
                                     size_t,
                                     bool* ok = 0);  // ignores trailing garbage
WTF_EXPORT unsigned charactersToUInt(const UChar*,
                                     size_t,
                                     bool* ok = 0);  // ignores trailing garbage
WTF_EXPORT int64_t charactersToInt64(const LChar*,
                                     size_t,
                                     bool* ok = 0);  // ignores trailing garbage
WTF_EXPORT int64_t charactersToInt64(const UChar*,
                                     size_t,
                                     bool* ok = 0);  // ignores trailing garbage
WTF_EXPORT uint64_t
charactersToUInt64(const LChar*,
                   size_t,
                   bool* ok = 0);  // ignores trailing garbage
WTF_EXPORT uint64_t
charactersToUInt64(const UChar*,
                   size_t,
                   bool* ok = 0);  // ignores trailing garbage
WTF_EXPORT intptr_t
charactersToIntPtr(const LChar*,
                   size_t,
                   bool* ok = 0);  // ignores trailing garbage
WTF_EXPORT intptr_t
charactersToIntPtr(const UChar*,
                   size_t,
                   bool* ok = 0);  // ignores trailing garbage

// FIXME: Like the strict functions above, these give false for "ok" when there
// is trailing garbage. Like the non-strict functions above, these return the
// value when there is trailing garbage. It would be better if these were more
// consistent with the above functions instead.
WTF_EXPORT double charactersToDouble(const LChar*, size_t, bool* ok = 0);
WTF_EXPORT double charactersToDouble(const UChar*, size_t, bool* ok = 0);
WTF_EXPORT float charactersToFloat(const LChar*, size_t, bool* ok = 0);
WTF_EXPORT float charactersToFloat(const UChar*, size_t, bool* ok = 0);
WTF_EXPORT float charactersToFloat(const LChar*, size_t, size_t& parsedLength);
WTF_EXPORT float charactersToFloat(const UChar*, size_t, size_t& parsedLength);

enum TrailingZerosTruncatingPolicy { KeepTrailingZeros, TruncateTrailingZeros };

enum UTF8ConversionMode {
  LenientUTF8Conversion,
  StrictUTF8Conversion,
  StrictUTF8ConversionReplacingUnpairedSurrogatesWithFFFD
};

template <bool isSpecialCharacter(UChar), typename CharacterType>
bool isAllSpecialCharacters(const CharacterType*, size_t);

// You can find documentation about this class in this doc:
// https://docs.google.com/document/d/1kOCUlJdh2WJMJGDf-WoEQhmnjKLaOYRbiHz5TiGJl14/edit?usp=sharing
class WTF_EXPORT String {
 public:
  // Construct a null string, distinguishable from an empty string.
  String() {}

  // Construct a string with UTF-16 data.
  String(const UChar* characters, unsigned length);

  // Construct a string by copying the contents of a vector.
  // This method will never create a null string. Vectors with size() == 0
  // will return the empty string.
  // NOTE: This is different from String(vector.data(), vector.size())
  // which will sometimes return a null string when vector.data() is null
  // which can only occur for vectors without inline capacity.
  // See: https://bugs.webkit.org/show_bug.cgi?id=109792
  template <size_t inlineCapacity>
  explicit String(const Vector<UChar, inlineCapacity>&);

  // Construct a string with UTF-16 data, from a null-terminated source.
  String(const UChar*);

  // Construct a string with latin1 data.
  String(const LChar* characters, unsigned length);
  String(const char* characters, unsigned length);

  // Construct a string with latin1 data, from a null-terminated source.
  String(const LChar* characters);
  String(const char* characters);

  // Construct a string referencing an existing StringImpl.
  String(StringImpl* impl) : m_impl(impl) {}
  String(PassRefPtr<StringImpl> impl) : m_impl(impl) {}

  void swap(String& o) { m_impl.swap(o.m_impl); }

  template <typename CharType>
  static String adopt(StringBuffer<CharType>& buffer) {
    if (!buffer.length())
      return StringImpl::empty();
    return String(buffer.release());
  }

  bool isNull() const { return !m_impl; }
  bool isEmpty() const { return !m_impl || !m_impl->length(); }

  StringImpl* impl() const { return m_impl.get(); }
  PassRefPtr<StringImpl> releaseImpl() { return m_impl.release(); }

  unsigned length() const {
    if (!m_impl)
      return 0;
    return m_impl->length();
  }

  const LChar* characters8() const {
    if (!m_impl)
      return 0;
    ASSERT(m_impl->is8Bit());
    return m_impl->characters8();
  }

  const UChar* characters16() const {
    if (!m_impl)
      return 0;
    ASSERT(!m_impl->is8Bit());
    return m_impl->characters16();
  }

  // Return characters8() or characters16() depending on CharacterType.
  template <typename CharacterType>
  inline const CharacterType* getCharacters() const;

  bool is8Bit() const { return m_impl->is8Bit(); }

  unsigned sizeInBytes() const {
    if (!m_impl)
      return 0;
    return m_impl->length() * (is8Bit() ? sizeof(LChar) : sizeof(UChar));
  }

  CString ascii() const;
  CString latin1() const;
  CString utf8(UTF8ConversionMode = LenientUTF8Conversion) const;

  // We should replace CString with std::string.
  std::string toUTF8() const;

  UChar operator[](unsigned index) const {
    if (!m_impl || index >= m_impl->length())
      return 0;
    return (*m_impl)[index];
  }

  static String number(int);
  static String number(unsigned);
  static String number(long);
  static String number(unsigned long);
  static String number(long long);
  static String number(unsigned long long);

  static String number(double,
                       unsigned precision = 6,
                       TrailingZerosTruncatingPolicy = TruncateTrailingZeros);

  // Number to String conversion following the ECMAScript definition.
  static String numberToStringECMAScript(double);
  static String numberToStringFixedWidth(double, unsigned decimalPlaces);

  // Find a single character or string, also with match function & latin1 forms.
  size_t find(UChar c, unsigned start = 0) const {
    return m_impl ? m_impl->find(c, start) : kNotFound;
  }

  size_t find(const String& str) const {
    return m_impl ? m_impl->find(str.impl()) : kNotFound;
  }
  size_t find(const String& str, unsigned start) const {
    return m_impl ? m_impl->find(str.impl(), start) : kNotFound;
  }

  size_t find(CharacterMatchFunctionPtr matchFunction,
              unsigned start = 0) const {
    return m_impl ? m_impl->find(matchFunction, start) : kNotFound;
  }
  size_t find(const LChar* str, unsigned start = 0) const {
    return m_impl ? m_impl->find(str, start) : kNotFound;
  }

  size_t findNextLineStart(unsigned start = 0) const {
    return m_impl ? m_impl->findNextLineStart(start) : kNotFound;
  }

  // Find the last instance of a single character or string.
  size_t reverseFind(UChar c, unsigned start = UINT_MAX) const {
    return m_impl ? m_impl->reverseFind(c, start) : kNotFound;
  }
  size_t reverseFind(const String& str, unsigned start = UINT_MAX) const {
    return m_impl ? m_impl->reverseFind(str.impl(), start) : kNotFound;
  }

  // Case insensitive string matching.
  size_t findIgnoringCase(const LChar* str, unsigned start = 0) const {
    return m_impl ? m_impl->findIgnoringCase(str, start) : kNotFound;
  }
  size_t findIgnoringCase(const String& str, unsigned start = 0) const {
    return m_impl ? m_impl->findIgnoringCase(str.impl(), start) : kNotFound;
  }
  size_t reverseFindIgnoringCase(const String& str,
                                 unsigned start = UINT_MAX) const {
    return m_impl ? m_impl->reverseFindIgnoringCase(str.impl(), start)
                  : kNotFound;
  }

  // Wrappers for find & reverseFind adding dynamic sensitivity check.
  size_t find(const LChar* str, unsigned start, bool caseSensitive) const {
    return caseSensitive ? find(str, start) : findIgnoringCase(str, start);
  }
  size_t find(const String& str, unsigned start, bool caseSensitive) const {
    return caseSensitive ? find(str, start) : findIgnoringCase(str, start);
  }
  size_t reverseFind(const String& str,
                     unsigned start,
                     bool caseSensitive) const {
    return caseSensitive ? reverseFind(str, start)
                         : reverseFindIgnoringCase(str, start);
  }

  Vector<UChar> charactersWithNullTermination() const;
  unsigned copyTo(UChar* buffer, unsigned pos, unsigned maxLength) const;

  template <size_t inlineCapacity>
  void appendTo(Vector<UChar, inlineCapacity>&,
                unsigned pos = 0,
                unsigned len = UINT_MAX) const;

  template <typename BufferType>
  void appendTo(BufferType&, unsigned pos = 0, unsigned len = UINT_MAX) const;

  template <size_t inlineCapacity>
  void prependTo(Vector<UChar, inlineCapacity>&,
                 unsigned pos = 0,
                 unsigned len = UINT_MAX) const;

  UChar32 characterStartingAt(unsigned) const;

  bool contains(UChar c) const { return find(c) != kNotFound; }
  bool contains(const LChar* str, bool caseSensitive = true) const {
    return find(str, 0, caseSensitive) != kNotFound;
  }
  bool contains(const String& str, bool caseSensitive = true) const {
    return find(str, 0, caseSensitive) != kNotFound;
  }

  bool startsWith(const String& s, bool caseSensitive = true) const {
    return m_impl ? m_impl->startsWith(s.impl(), caseSensitive) : s.isEmpty();
  }
  bool startsWith(UChar character) const {
    return m_impl ? m_impl->startsWith(character) : false;
  }
  template <unsigned matchLength>
  bool startsWith(const char (&prefix)[matchLength],
                  bool caseSensitive = true) const {
    return m_impl ? m_impl->startsWith<matchLength>(prefix, caseSensitive)
                  : !matchLength;
  }

  bool endsWith(const String& s, bool caseSensitive = true) const {
    return m_impl ? m_impl->endsWith(s.impl(), caseSensitive) : s.isEmpty();
  }
  bool endsWith(UChar character) const {
    return m_impl ? m_impl->endsWith(character) : false;
  }
  template <unsigned matchLength>
  bool endsWith(const char (&prefix)[matchLength],
                bool caseSensitive = true) const {
    return m_impl ? m_impl->endsWith<matchLength>(prefix, caseSensitive)
                  : !matchLength;
  }

  void append(const String&);
  void append(LChar);
  void append(char c) { append(static_cast<LChar>(c)); }
  void append(UChar);
  void append(const LChar*, unsigned length);
  void append(const char* charactersToAppend, unsigned length) {
    append(reinterpret_cast<const LChar*>(charactersToAppend), length);
  }
  void append(const UChar*, unsigned length);
  void insert(const String&, unsigned pos);
  void insert(const LChar*, unsigned length, unsigned pos);
  void insert(const UChar*, unsigned length, unsigned pos);

  String& replace(UChar a, UChar b) {
    if (m_impl)
      m_impl = m_impl->replace(a, b);
    return *this;
  }
  String& replace(UChar a, const String& b) {
    if (m_impl)
      m_impl = m_impl->replace(a, b.impl());
    return *this;
  }
  String& replace(const String& a, const String& b) {
    if (m_impl)
      m_impl = m_impl->replace(a.impl(), b.impl());
    return *this;
  }
  String& replace(unsigned index, unsigned len, const String& b) {
    if (m_impl)
      m_impl = m_impl->replace(index, len, b.impl());
    return *this;
  }

  template <unsigned charactersCount>
  ALWAYS_INLINE String& replaceWithLiteral(
      UChar a,
      const char (&characters)[charactersCount]) {
    if (m_impl)
      m_impl = m_impl->replace(a, characters, charactersCount - 1);

    return *this;
  }

  void fill(UChar c) {
    if (m_impl)
      m_impl = m_impl->fill(c);
  }

  void ensure16Bit();

  void truncate(unsigned len);
  void remove(unsigned pos, int len = 1);

  String substring(unsigned pos, unsigned len = UINT_MAX) const;
  String left(unsigned len) const { return substring(0, len); }
  String right(unsigned len) const { return substring(length() - len, len); }

  StringView createView() const { return StringView(impl()); }
  StringView createView(unsigned offset, unsigned length) const {
    return StringView(impl(), offset, length);
  }

  // Returns a lowercase/uppercase version of the string
  String lower() const;
  String upper() const;

  String lower(const AtomicString& localeIdentifier) const;
  String upper(const AtomicString& localeIdentifier) const;

  String stripWhiteSpace() const;
  String stripWhiteSpace(IsWhiteSpaceFunctionPtr) const;
  String simplifyWhiteSpace(
      StripBehavior stripBehavior = StripExtraWhiteSpace) const;
  String simplifyWhiteSpace(
      IsWhiteSpaceFunctionPtr,
      StripBehavior stripBehavior = StripExtraWhiteSpace) const;

  String removeCharacters(CharacterMatchFunctionPtr) const;
  template <bool isSpecialCharacter(UChar)>
  bool isAllSpecialCharacters() const;

  // Return the string with case folded for case insensitive comparison.
  String foldCase() const;

  static String format(const char*, ...) WTF_ATTRIBUTE_PRINTF(1, 2);

  // Returns an uninitialized string. The characters needs to be written
  // into the buffer returned in data before the returned string is used.
  // Failure to do this will have unpredictable results.
  static String createUninitialized(unsigned length, UChar*& data) {
    return StringImpl::createUninitialized(length, data);
  }
  static String createUninitialized(unsigned length, LChar*& data) {
    return StringImpl::createUninitialized(length, data);
  }

  void split(const String& separator,
             bool allowEmptyEntries,
             Vector<String>& result) const;
  void split(const String& separator, Vector<String>& result) const {
    split(separator, false, result);
  }
  void split(UChar separator,
             bool allowEmptyEntries,
             Vector<String>& result) const;
  void split(UChar separator, Vector<String>& result) const {
    split(separator, false, result);
  }

  int toIntStrict(bool* ok = 0, int base = 10) const;
  unsigned toUIntStrict(bool* ok = 0, int base = 10) const;
  int64_t toInt64Strict(bool* ok = 0, int base = 10) const;
  uint64_t toUInt64Strict(bool* ok = 0, int base = 10) const;
  intptr_t toIntPtrStrict(bool* ok = 0, int base = 10) const;

  int toInt(bool* ok = 0) const;
  unsigned toUInt(bool* ok = 0) const;
  int64_t toInt64(bool* ok = 0) const;
  uint64_t toUInt64(bool* ok = 0) const;
  intptr_t toIntPtr(bool* ok = 0) const;

  // FIXME: Like the strict functions above, these give false for "ok" when
  // there is trailing garbage. Like the non-strict functions above, these
  // return the value when there is trailing garbage. It would be better if
  // these were more consistent with the above functions instead.
  double toDouble(bool* ok = 0) const;
  float toFloat(bool* ok = 0) const;

  bool percentage(int& percentage) const;

  String isolatedCopy() const;
  bool isSafeToSendToAnotherThread() const;

#if USE(CF)
  String(CFStringRef);
  RetainPtr<CFStringRef> createCFString() const;
#endif

  static String make8BitFrom16BitSource(const UChar*, size_t);
  template <size_t inlineCapacity>
  static String make8BitFrom16BitSource(
      const Vector<UChar, inlineCapacity>& buffer) {
    return make8BitFrom16BitSource(buffer.data(), buffer.size());
  }

  static String make16BitFrom8BitSource(const LChar*, size_t);

  // String::fromUTF8 will return a null string if
  // the input data contains invalid UTF-8 sequences.
  static String fromUTF8(const LChar*, size_t);
  static String fromUTF8(const LChar*);
  static String fromUTF8(const char* s, size_t length) {
    return fromUTF8(reinterpret_cast<const LChar*>(s), length);
  };
  static String fromUTF8(const char* s) {
    return fromUTF8(reinterpret_cast<const LChar*>(s));
  };
  static String fromUTF8(const CString&);
  static String fromUTF8(const std::string& s) {
    return fromUTF8(s.data(), s.size());
  }

  // Tries to convert the passed in string to UTF-8, but will fall back to
  // Latin-1 if the string is not valid UTF-8.
  static String fromUTF8WithLatin1Fallback(const LChar*, size_t);
  static String fromUTF8WithLatin1Fallback(const char* s, size_t length) {
    return fromUTF8WithLatin1Fallback(reinterpret_cast<const LChar*>(s),
                                      length);
  };

  bool containsOnlyASCII() const;
  bool containsOnlyLatin1() const;
  bool containsOnlyWhitespace() const {
    return !m_impl || m_impl->containsOnlyWhitespace();
  }

  // Hash table deleted values, which are only constructed and never copied or
  // destroyed.
  String(WTF::HashTableDeletedValueType) : m_impl(WTF::HashTableDeletedValue) {}
  bool isHashTableDeletedValue() const {
    return m_impl.isHashTableDeletedValue();
  }

#ifndef NDEBUG
  void show() const;
#endif

  // Workaround for a compiler bug. Use operator[] instead.
  UChar characterAt(unsigned index) const {
    if (!m_impl || index >= m_impl->length())
      return 0;
    return (*m_impl)[index];
  }

 private:
  typedef struct ImplicitConversionFromWTFStringToBoolDisallowed*(
      String::*UnspecifiedBoolType);
  operator UnspecifiedBoolType() const;

  template <typename CharacterType>
  void removeInternal(const CharacterType*, unsigned, int);

  template <typename CharacterType>
  void appendInternal(CharacterType);

  RefPtr<StringImpl> m_impl;
};

inline bool operator==(const String& a, const String& b) {
  return equal(a.impl(), b.impl());
}
inline bool operator==(const String& a, const LChar* b) {
  return equal(a.impl(), b);
}
inline bool operator==(const String& a, const char* b) {
  return equal(a.impl(), reinterpret_cast<const LChar*>(b));
}
inline bool operator==(const LChar* a, const String& b) {
  return equal(a, b.impl());
}
inline bool operator==(const char* a, const String& b) {
  return equal(reinterpret_cast<const LChar*>(a), b.impl());
}
template <size_t inlineCapacity>
inline bool operator==(const Vector<char, inlineCapacity>& a, const String& b) {
  return equal(b.impl(), a.data(), a.size());
}
template <size_t inlineCapacity>
inline bool operator==(const String& a, const Vector<char, inlineCapacity>& b) {
  return b == a;
}

inline bool operator!=(const String& a, const String& b) {
  return !equal(a.impl(), b.impl());
}
inline bool operator!=(const String& a, const LChar* b) {
  return !equal(a.impl(), b);
}
inline bool operator!=(const String& a, const char* b) {
  return !equal(a.impl(), reinterpret_cast<const LChar*>(b));
}
inline bool operator!=(const LChar* a, const String& b) {
  return !equal(a, b.impl());
}
inline bool operator!=(const char* a, const String& b) {
  return !equal(reinterpret_cast<const LChar*>(a), b.impl());
}
template <size_t inlineCapacity>
inline bool operator!=(const Vector<char, inlineCapacity>& a, const String& b) {
  return !(a == b);
}
template <size_t inlineCapacity>
inline bool operator!=(const String& a, const Vector<char, inlineCapacity>& b) {
  return b != a;
}

inline bool equalIgnoringCase(const String& a, const String& b) {
  return equalIgnoringCase(a.impl(), b.impl());
}
inline bool equalIgnoringCase(const String& a, const LChar* b) {
  return equalIgnoringCase(a.impl(), b);
}
inline bool equalIgnoringCase(const String& a, const char* b) {
  return equalIgnoringCase(a.impl(), reinterpret_cast<const LChar*>(b));
}
inline bool equalIgnoringCase(const LChar* a, const String& b) {
  return equalIgnoringCase(a, b.impl());
}
inline bool equalIgnoringCase(const char* a, const String& b) {
  return equalIgnoringCase(reinterpret_cast<const LChar*>(a), b.impl());
}

inline bool equalIgnoringNullity(const String& a, const String& b) {
  return equalIgnoringNullity(a.impl(), b.impl());
}

template <size_t inlineCapacity>
inline bool equalIgnoringNullity(const Vector<UChar, inlineCapacity>& a,
                                 const String& b) {
  return equalIgnoringNullity(a, b.impl());
}

inline bool operator!(const String& str) {
  return str.isNull();
}

inline void swap(String& a, String& b) {
  a.swap(b);
}

// Definitions of string operations

template <size_t inlineCapacity>
String::String(const Vector<UChar, inlineCapacity>& vector)
    : m_impl(vector.size() ? StringImpl::create(vector.data(), vector.size())
                           : StringImpl::empty()) {}

template <>
inline const LChar* String::getCharacters<LChar>() const {
  ASSERT(is8Bit());
  return characters8();
}

template <>
inline const UChar* String::getCharacters<UChar>() const {
  ASSERT(!is8Bit());
  return characters16();
}

inline bool String::containsOnlyLatin1() const {
  if (isEmpty())
    return true;

  if (is8Bit())
    return true;

  const UChar* characters = characters16();
  UChar ored = 0;
  for (size_t i = 0; i < m_impl->length(); ++i)
    ored |= characters[i];
  return !(ored & 0xFF00);
}

inline bool String::containsOnlyASCII() const {
  if (isEmpty())
    return true;

  if (is8Bit())
    return charactersAreAllASCII(characters8(), m_impl->length());

  return charactersAreAllASCII(characters16(), m_impl->length());
}

WTF_EXPORT int codePointCompare(const String&, const String&);

inline bool codePointCompareLessThan(const String& a, const String& b) {
  return codePointCompare(a.impl(), b.impl()) < 0;
}

template <size_t inlineCapacity>
inline void append(Vector<UChar, inlineCapacity>& vector,
                   const String& string) {
  unsigned length = string.length();
  if (!length)
    return;
  if (string.is8Bit()) {
    const LChar* characters8 = string.characters8();
    vector.reserveCapacity(vector.size() + length);
    for (size_t i = 0; i < length; ++i)
      vector.uncheckedAppend(characters8[i]);
  } else {
    vector.append(string.characters16(), length);
  }
}

template <typename CharacterType>
inline void appendNumber(Vector<CharacterType>& vector, unsigned char number) {
  int numberLength = number > 99 ? 3 : (number > 9 ? 2 : 1);
  size_t vectorSize = vector.size();
  vector.grow(vectorSize + numberLength);

  switch (numberLength) {
    case 3:
      vector[vectorSize + 2] = number % 10 + '0';
      number /= 10;

    case 2:
      vector[vectorSize + 1] = number % 10 + '0';
      number /= 10;

    case 1:
      vector[vectorSize] = number % 10 + '0';
  }
}

template <bool isSpecialCharacter(UChar), typename CharacterType>
inline bool isAllSpecialCharacters(const CharacterType* characters,
                                   size_t length) {
  for (size_t i = 0; i < length; ++i) {
    if (!isSpecialCharacter(characters[i]))
      return false;
  }
  return true;
}

template <bool isSpecialCharacter(UChar)>
inline bool String::isAllSpecialCharacters() const {
  size_t len = length();

  if (!len)
    return true;

  if (is8Bit())
    return WTF::isAllSpecialCharacters<isSpecialCharacter, LChar>(characters8(),
                                                                  len);
  return WTF::isAllSpecialCharacters<isSpecialCharacter, UChar>(characters16(),
                                                                len);
}

template <size_t inlineCapacity>
inline void String::appendTo(Vector<UChar, inlineCapacity>& result,
                             unsigned pos,
                             unsigned len) const {
  unsigned numberOfCharactersToCopy = std::min(len, length() - pos);
  if (!numberOfCharactersToCopy)
    return;
  result.reserveCapacity(result.size() + numberOfCharactersToCopy);
  if (is8Bit()) {
    const LChar* characters8 = m_impl->characters8();
    for (size_t i = 0; i < numberOfCharactersToCopy; ++i)
      result.uncheckedAppend(characters8[pos + i]);
  } else {
    const UChar* characters16 = m_impl->characters16();
    result.append(characters16 + pos, numberOfCharactersToCopy);
  }
}

template <typename BufferType>
inline void String::appendTo(BufferType& result,
                             unsigned pos,
                             unsigned len) const {
  unsigned numberOfCharactersToCopy = std::min(len, length() - pos);
  if (!numberOfCharactersToCopy)
    return;
  if (is8Bit())
    result.append(m_impl->characters8() + pos, numberOfCharactersToCopy);
  else
    result.append(m_impl->characters16() + pos, numberOfCharactersToCopy);
}

template <size_t inlineCapacity>
inline void String::prependTo(Vector<UChar, inlineCapacity>& result,
                              unsigned pos,
                              unsigned len) const {
  unsigned numberOfCharactersToCopy = std::min(len, length() - pos);
  if (!numberOfCharactersToCopy)
    return;
  if (is8Bit()) {
    size_t oldSize = result.size();
    result.resize(oldSize + numberOfCharactersToCopy);
    memmove(result.data() + numberOfCharactersToCopy, result.data(),
            oldSize * sizeof(UChar));
    StringImpl::copyChars(result.data(), m_impl->characters8() + pos,
                          numberOfCharactersToCopy);
  } else {
    result.prepend(m_impl->characters16() + pos, numberOfCharactersToCopy);
  }
}

// StringHash is the default hash for String
template <typename T>
struct DefaultHash;
template <>
struct DefaultHash<String> {
  typedef StringHash Hash;
};

// Shared global empty string.
WTF_EXPORT const String& emptyString();
WTF_EXPORT extern const String& xmlnsWithColon;

}  // namespace WTF

WTF_ALLOW_MOVE_AND_INIT_WITH_MEM_FUNCTIONS(String);

using WTF::append;
using WTF::appendNumber;
using WTF::charactersAreAllASCII;
using WTF::charactersToDouble;
using WTF::charactersToFloat;
using WTF::charactersToInt;
using WTF::charactersToInt64;
using WTF::charactersToInt64Strict;
using WTF::charactersToIntPtr;
using WTF::charactersToIntPtrStrict;
using WTF::charactersToIntStrict;
using WTF::charactersToUInt;
using WTF::charactersToUInt64;
using WTF::charactersToUInt64Strict;
using WTF::charactersToUIntStrict;
using WTF::CString;
using WTF::emptyString;
using WTF::equal;
using WTF::equalIgnoringCase;
using WTF::find;
using WTF::isAllSpecialCharacters;
using WTF::isSpaceOrNewline;
using WTF::KeepTrailingZeros;
using WTF::reverseFind;
using WTF::StrictUTF8Conversion;
using WTF::StrictUTF8ConversionReplacingUnpairedSurrogatesWithFFFD;
using WTF::String;

#include "flutter/sky/engine/wtf/text/AtomicString.h"
#endif  // SKY_ENGINE_WTF_TEXT_WTFSTRING_H_
