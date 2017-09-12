/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2013 Apple Inc.
 * All rights reserved.
 * Copyright (C) 2010 Patrick Gansterer <paroga@paroga.com>
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "flutter/sky/engine/wtf/text/AtomicString.h"

#include "flutter/sky/engine/wtf/HashSet.h"
#include "flutter/sky/engine/wtf/WTFThreadData.h"
#include "flutter/sky/engine/wtf/dtoa.h"
#include "flutter/sky/engine/wtf/text/IntegerToStringConversion.h"
#include "flutter/sky/engine/wtf/text/StringHash.h"
#include "flutter/sky/engine/wtf/unicode/UTF8.h"

namespace WTF {

using namespace Unicode;

COMPILE_ASSERT(sizeof(AtomicString) == sizeof(String),
               atomic_string_and_string_must_be_same_size);

class AtomicStringTable {
  WTF_MAKE_NONCOPYABLE(AtomicStringTable);

 public:
  static AtomicStringTable* create(WTFThreadData& data) {
    data.m_atomicStringTable = new AtomicStringTable;
    data.m_atomicStringTableDestructor = AtomicStringTable::destroy;
    data.m_atomicStringTable->addStaticStrings();
    return data.m_atomicStringTable;
  }

  StringImpl* addStringImpl(StringImpl* string) {
    if (!string->length())
      return StringImpl::empty();

    StringImpl* result = *m_table.add(string).storedValue;

    if (!result->isAtomic())
      result->setIsAtomic(true);

    ASSERT(!string->isStatic() || result->isStatic());
    return result;
  }

  HashSet<StringImpl*>& table() { return m_table; }

 private:
  AtomicStringTable() {}

  void addStaticStrings() {
    const StaticStringsTable& staticStrings = StringImpl::allStaticStrings();

    StaticStringsTable::const_iterator it = staticStrings.begin();
    for (; it != staticStrings.end(); ++it) {
      addStringImpl(it->value);
    }
  }

  static void destroy(AtomicStringTable* table) {
    HashSet<StringImpl*>::iterator end = table->m_table.end();
    for (HashSet<StringImpl*>::iterator iter = table->m_table.begin();
         iter != end; ++iter) {
      StringImpl* string = *iter;
      if (!string->isStatic()) {
        ASSERT(string->isAtomic());
        string->setIsAtomic(false);
      }
    }
    delete table;
  }

  HashSet<StringImpl*> m_table;
};

static inline AtomicStringTable& atomicStringTable() {
  // Once possible we should make this non-lazy (constructed in WTFThreadData's
  // constructor).
  WTFThreadData& data = wtfThreadData();
  AtomicStringTable* table = data.atomicStringTable();
  if (UNLIKELY(!table))
    table = AtomicStringTable::create(data);
  return *table;
}

static inline HashSet<StringImpl*>& atomicStrings() {
  return atomicStringTable().table();
}

template <typename T, typename HashTranslator>
static inline PassRefPtr<StringImpl> addToStringTable(const T& value) {
  HashSet<StringImpl*>::AddResult addResult =
      atomicStrings().add<HashTranslator>(value);

  // If the string is newly-translated, then we need to adopt it.
  // The boolean in the pair tells us if that is so.
  return addResult.isNewEntry ? adoptRef(*addResult.storedValue)
                              : *addResult.storedValue;
}

PassRefPtr<StringImpl> AtomicString::add(const LChar* c) {
  if (!c)
    return nullptr;
  if (!*c)
    return StringImpl::empty();

  return add(c, strlen(reinterpret_cast<const char*>(c)));
}

template <typename CharacterType>
struct HashTranslatorCharBuffer {
  const CharacterType* s;
  unsigned length;
};

typedef HashTranslatorCharBuffer<UChar> UCharBuffer;
struct UCharBufferTranslator {
  static unsigned hash(const UCharBuffer& buf) {
    return StringHasher::computeHashAndMaskTop8Bits(buf.s, buf.length);
  }

  static bool equal(StringImpl* const& str, const UCharBuffer& buf) {
    return WTF::equal(str, buf.s, buf.length);
  }

  static void translate(StringImpl*& location,
                        const UCharBuffer& buf,
                        unsigned hash) {
    location = StringImpl::create8BitIfPossible(buf.s, buf.length).leakRef();
    location->setHash(hash);
    location->setIsAtomic(true);
  }
};

template <typename CharacterType>
struct HashAndCharacters {
  unsigned hash;
  const CharacterType* characters;
  unsigned length;
};

template <typename CharacterType>
struct HashAndCharactersTranslator {
  static unsigned hash(const HashAndCharacters<CharacterType>& buffer) {
    ASSERT(buffer.hash == StringHasher::computeHashAndMaskTop8Bits(
                              buffer.characters, buffer.length));
    return buffer.hash;
  }

  static bool equal(StringImpl* const& string,
                    const HashAndCharacters<CharacterType>& buffer) {
    return WTF::equal(string, buffer.characters, buffer.length);
  }

  static void translate(StringImpl*& location,
                        const HashAndCharacters<CharacterType>& buffer,
                        unsigned hash) {
    location = StringImpl::create(buffer.characters, buffer.length).leakRef();
    location->setHash(hash);
    location->setIsAtomic(true);
  }
};

struct HashAndUTF8Characters {
  unsigned hash;
  const char* characters;
  unsigned length;
  unsigned utf16Length;
};

struct HashAndUTF8CharactersTranslator {
  static unsigned hash(const HashAndUTF8Characters& buffer) {
    return buffer.hash;
  }

  static bool equal(StringImpl* const& string,
                    const HashAndUTF8Characters& buffer) {
    if (buffer.utf16Length != string->length())
      return false;

    // If buffer contains only ASCII characters UTF-8 and UTF16 length are the
    // same.
    if (buffer.utf16Length != buffer.length) {
      if (string->is8Bit()) {
        const LChar* characters8 = string->characters8();
        return equalLatin1WithUTF8(characters8, characters8 + string->length(),
                                   buffer.characters,
                                   buffer.characters + buffer.length);
      }
      const UChar* characters16 = string->characters16();
      return equalUTF16WithUTF8(characters16, characters16 + string->length(),
                                buffer.characters,
                                buffer.characters + buffer.length);
    }

    if (string->is8Bit()) {
      const LChar* stringCharacters = string->characters8();

      for (unsigned i = 0; i < buffer.length; ++i) {
        ASSERT(isASCII(buffer.characters[i]));
        if (stringCharacters[i] != buffer.characters[i])
          return false;
      }

      return true;
    }

    const UChar* stringCharacters = string->characters16();

    for (unsigned i = 0; i < buffer.length; ++i) {
      ASSERT(isASCII(buffer.characters[i]));
      if (stringCharacters[i] != buffer.characters[i])
        return false;
    }

    return true;
  }

  static void translate(StringImpl*& location,
                        const HashAndUTF8Characters& buffer,
                        unsigned hash) {
    UChar* target;
    RefPtr<StringImpl> newString =
        StringImpl::createUninitialized(buffer.utf16Length, target);

    bool isAllASCII;
    const char* source = buffer.characters;
    if (convertUTF8ToUTF16(&source, source + buffer.length, &target,
                           target + buffer.utf16Length,
                           &isAllASCII) != conversionOK)
      ASSERT_NOT_REACHED();

    if (isAllASCII)
      newString = StringImpl::create(buffer.characters, buffer.length);

    location = newString.release().leakRef();
    location->setHash(hash);
    location->setIsAtomic(true);
  }
};

PassRefPtr<StringImpl> AtomicString::add(const UChar* s, unsigned length) {
  if (!s)
    return nullptr;

  if (!length)
    return StringImpl::empty();

  UCharBuffer buffer = {s, length};
  return addToStringTable<UCharBuffer, UCharBufferTranslator>(buffer);
}

PassRefPtr<StringImpl> AtomicString::add(const UChar* s,
                                         unsigned length,
                                         unsigned existingHash) {
  ASSERT(s);
  ASSERT(existingHash);

  if (!length)
    return StringImpl::empty();

  HashAndCharacters<UChar> buffer = {existingHash, s, length};
  return addToStringTable<HashAndCharacters<UChar>,
                          HashAndCharactersTranslator<UChar>>(buffer);
}

PassRefPtr<StringImpl> AtomicString::add(const UChar* s) {
  if (!s)
    return nullptr;

  unsigned length = 0;
  while (s[length] != UChar(0))
    ++length;

  if (!length)
    return StringImpl::empty();

  UCharBuffer buffer = {s, length};
  return addToStringTable<UCharBuffer, UCharBufferTranslator>(buffer);
}

struct SubstringLocation {
  StringImpl* baseString;
  unsigned start;
  unsigned length;
};

struct SubstringTranslator {
  static unsigned hash(const SubstringLocation& buffer) {
    if (buffer.baseString->is8Bit())
      return StringHasher::computeHashAndMaskTop8Bits(
          buffer.baseString->characters8() + buffer.start, buffer.length);
    return StringHasher::computeHashAndMaskTop8Bits(
        buffer.baseString->characters16() + buffer.start, buffer.length);
  }

  static bool equal(StringImpl* const& string,
                    const SubstringLocation& buffer) {
    if (buffer.baseString->is8Bit())
      return WTF::equal(string, buffer.baseString->characters8() + buffer.start,
                        buffer.length);
    return WTF::equal(string, buffer.baseString->characters16() + buffer.start,
                      buffer.length);
  }

  static void translate(StringImpl*& location,
                        const SubstringLocation& buffer,
                        unsigned hash) {
    location =
        buffer.baseString->substring(buffer.start, buffer.length).leakRef();
    location->setHash(hash);
    location->setIsAtomic(true);
  }
};

PassRefPtr<StringImpl> AtomicString::add(StringImpl* baseString,
                                         unsigned start,
                                         unsigned length) {
  if (!baseString)
    return nullptr;

  if (!length || start >= baseString->length())
    return StringImpl::empty();

  unsigned maxLength = baseString->length() - start;
  if (length >= maxLength) {
    if (!start)
      return add(baseString);
    length = maxLength;
  }

  SubstringLocation buffer = {baseString, start, length};
  return addToStringTable<SubstringLocation, SubstringTranslator>(buffer);
}

typedef HashTranslatorCharBuffer<LChar> LCharBuffer;
struct LCharBufferTranslator {
  static unsigned hash(const LCharBuffer& buf) {
    return StringHasher::computeHashAndMaskTop8Bits(buf.s, buf.length);
  }

  static bool equal(StringImpl* const& str, const LCharBuffer& buf) {
    return WTF::equal(str, buf.s, buf.length);
  }

  static void translate(StringImpl*& location,
                        const LCharBuffer& buf,
                        unsigned hash) {
    location = StringImpl::create(buf.s, buf.length).leakRef();
    location->setHash(hash);
    location->setIsAtomic(true);
  }
};

typedef HashTranslatorCharBuffer<char> CharBuffer;
struct CharBufferFromLiteralDataTranslator {
  static unsigned hash(const CharBuffer& buf) {
    return StringHasher::computeHashAndMaskTop8Bits(
        reinterpret_cast<const LChar*>(buf.s), buf.length);
  }

  static bool equal(StringImpl* const& str, const CharBuffer& buf) {
    return WTF::equal(str, buf.s, buf.length);
  }

  static void translate(StringImpl*& location,
                        const CharBuffer& buf,
                        unsigned hash) {
    location = StringImpl::create(buf.s, buf.length).leakRef();
    location->setHash(hash);
    location->setIsAtomic(true);
  }
};

PassRefPtr<StringImpl> AtomicString::add(const LChar* s, unsigned length) {
  if (!s)
    return nullptr;

  if (!length)
    return StringImpl::empty();

  LCharBuffer buffer = {s, length};
  return addToStringTable<LCharBuffer, LCharBufferTranslator>(buffer);
}

PassRefPtr<StringImpl> AtomicString::addFromLiteralData(const char* characters,
                                                        unsigned length) {
  ASSERT(characters);
  ASSERT(length);

  CharBuffer buffer = {characters, length};
  return addToStringTable<CharBuffer, CharBufferFromLiteralDataTranslator>(
      buffer);
}

PassRefPtr<StringImpl> AtomicString::addSlowCase(StringImpl* string) {
  return atomicStringTable().addStringImpl(string);
}

template <typename CharacterType>
static inline HashSet<StringImpl*>::iterator findString(
    const StringImpl* stringImpl) {
  HashAndCharacters<CharacterType> buffer = {
      stringImpl->existingHash(), stringImpl->getCharacters<CharacterType>(),
      stringImpl->length()};
  return atomicStrings().find<HashAndCharactersTranslator<CharacterType>>(
      buffer);
}

StringImpl* AtomicString::find(const StringImpl* stringImpl) {
  ASSERT(stringImpl);
  ASSERT(stringImpl->existingHash());

  if (!stringImpl->length())
    return StringImpl::empty();

  HashSet<StringImpl*>::iterator iterator;
  if (stringImpl->is8Bit())
    iterator = findString<LChar>(stringImpl);
  else
    iterator = findString<UChar>(stringImpl);
  if (iterator == atomicStrings().end())
    return 0;
  return *iterator;
}

void AtomicString::remove(StringImpl* r) {
  HashSet<StringImpl*>::iterator iterator;
  if (r->is8Bit())
    iterator = findString<LChar>(r);
  else
    iterator = findString<UChar>(r);
  RELEASE_ASSERT(iterator != atomicStrings().end());
  atomicStrings().remove(iterator);
}

AtomicString AtomicString::lower() const {
  // Note: This is a hot function in the Dromaeo benchmark.
  StringImpl* impl = this->impl();
  if (UNLIKELY(!impl))
    return *this;
  RefPtr<StringImpl> newImpl = impl->lower();
  if (LIKELY(newImpl == impl))
    return *this;
  return AtomicString(newImpl.release());
}

AtomicString AtomicString::fromUTF8Internal(const char* charactersStart,
                                            const char* charactersEnd) {
  HashAndUTF8Characters buffer;
  buffer.characters = charactersStart;
  buffer.hash = calculateStringHashAndLengthFromUTF8MaskingTop8Bits(
      charactersStart, charactersEnd, buffer.length, buffer.utf16Length);

  if (!buffer.hash)
    return nullAtom;

  AtomicString atomicString;
  atomicString.m_string =
      addToStringTable<HashAndUTF8Characters, HashAndUTF8CharactersTranslator>(
          buffer);
  return atomicString;
}

AtomicString AtomicString::number(int number) {
  return numberToStringSigned<AtomicString>(number);
}

AtomicString AtomicString::number(unsigned number) {
  return numberToStringUnsigned<AtomicString>(number);
}

AtomicString AtomicString::number(long number) {
  return numberToStringSigned<AtomicString>(number);
}

AtomicString AtomicString::number(unsigned long number) {
  return numberToStringUnsigned<AtomicString>(number);
}

AtomicString AtomicString::number(long long number) {
  return numberToStringSigned<AtomicString>(number);
}

AtomicString AtomicString::number(unsigned long long number) {
  return numberToStringUnsigned<AtomicString>(number);
}

AtomicString AtomicString::number(
    double number,
    unsigned precision,
    TrailingZerosTruncatingPolicy trailingZerosTruncatingPolicy) {
  NumberToStringBuffer buffer;
  return AtomicString(numberToFixedPrecisionString(
      number, precision, buffer,
      trailingZerosTruncatingPolicy == TruncateTrailingZeros));
}

#ifndef NDEBUG
void AtomicString::show() const {
  m_string.show();
}
#endif

}  // namespace WTF
