/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller ( mueller@kde.org )
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2013 Apple Inc. All
 * rights reserved.
 * Copyright (C) 2006 Andrew Wellington (proton@wiretapped.net)
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

#include "flutter/sky/engine/wtf/text/StringImpl.h"

#include <unicode/translit.h>
#include <unicode/unistr.h>
#include "flutter/sky/engine/wtf/DynamicAnnotations.h"
#include "flutter/sky/engine/wtf/LeakAnnotations.h"
#include "flutter/sky/engine/wtf/MainThread.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"
#include "flutter/sky/engine/wtf/PartitionAlloc.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/WTF.h"
#include "flutter/sky/engine/wtf/text/AtomicString.h"
#include "flutter/sky/engine/wtf/text/StringBuffer.h"
#include "flutter/sky/engine/wtf/text/StringHash.h"
#include "flutter/sky/engine/wtf/unicode/CharacterNames.h"

#ifdef STRING_STATS
#include <unistd.h>
#include "flutter/sky/engine/wtf/DataLog.h"
#include "flutter/sky/engine/wtf/HashMap.h"
#include "flutter/sky/engine/wtf/HashSet.h"
#include "flutter/sky/engine/wtf/RefCounted.h"
#include "flutter/sky/engine/wtf/ThreadingPrimitives.h"
#endif

using namespace std;

namespace WTF {

using namespace Unicode;

COMPILE_ASSERT(sizeof(StringImpl) == 3 * sizeof(int),
               StringImpl_should_stay_small);

#ifdef STRING_STATS

static Mutex& statsMutex() {
  DEFINE_STATIC_LOCAL(Mutex, mutex, ());
  return mutex;
}

static HashSet<void*>& liveStrings() {
  // Notice that we can't use HashSet<StringImpl*> because then HashSet would
  // dedup identical strings.
  DEFINE_STATIC_LOCAL(HashSet<void*>, strings, ());
  return strings;
}

void addStringForStats(StringImpl* string) {
  MutexLocker locker(statsMutex());
  liveStrings().add(string);
}

void removeStringForStats(StringImpl* string) {
  MutexLocker locker(statsMutex());
  liveStrings().remove(string);
}

static void fillWithSnippet(const StringImpl* string, Vector<char>& snippet) {
  const unsigned kMaxSnippetLength = 64;
  snippet.clear();

  size_t expectedLength = std::min(string->length(), kMaxSnippetLength);
  if (expectedLength == kMaxSnippetLength)
    expectedLength += 3;  // For the "...".
  ++expectedLength;       // For the terminating '\0'.
  snippet.reserveCapacity(expectedLength);

  size_t i;
  for (i = 0; i < string->length() && i < kMaxSnippetLength; ++i) {
    UChar c = (*string)[i];
    if (isASCIIPrintable(c))
      snippet.append(c);
    else
      snippet.append('?');
  }
  if (i < string->length()) {
    snippet.append('.');
    snippet.append('.');
    snippet.append('.');
  }
  snippet.append('\0');
}

static bool isUnnecessarilyWide(const StringImpl* string) {
  if (string->is8Bit())
    return false;
  UChar c = 0;
  for (unsigned i = 0; i < string->length(); ++i)
    c |= (*string)[i] >> 8;
  return !c;
}

class PerStringStats : public RefCounted<PerStringStats> {
 public:
  static PassRefPtr<PerStringStats> create() {
    return adoptRef(new PerStringStats);
  }

  void add(const StringImpl* string) {
    ++m_numberOfCopies;
    if (!m_length) {
      m_length = string->length();
      fillWithSnippet(string, m_snippet);
    }
    if (string->isAtomic())
      ++m_numberOfAtomicCopies;
    if (isUnnecessarilyWide(string))
      m_unnecessarilyWide = true;
  }

  size_t totalCharacters() const { return m_numberOfCopies * m_length; }

  void print() {
    const char* status = "ok";
    if (m_unnecessarilyWide)
      status = "16";
    dataLogF("%8u copies (%s) of length %8u %s\n", m_numberOfCopies, status,
             m_length, m_snippet.data());
  }

  bool m_unnecessarilyWide;
  unsigned m_numberOfCopies;
  unsigned m_length;
  unsigned m_numberOfAtomicCopies;
  Vector<char> m_snippet;

 private:
  PerStringStats()
      : m_unnecessarilyWide(false),
        m_numberOfCopies(0),
        m_length(0),
        m_numberOfAtomicCopies(0) {}
};

bool operator<(const RefPtr<PerStringStats>& a,
               const RefPtr<PerStringStats>& b) {
  if (a->m_unnecessarilyWide != b->m_unnecessarilyWide)
    return !a->m_unnecessarilyWide && b->m_unnecessarilyWide;
  if (a->totalCharacters() != b->totalCharacters())
    return a->totalCharacters() < b->totalCharacters();
  if (a->m_numberOfCopies != b->m_numberOfCopies)
    return a->m_numberOfCopies < b->m_numberOfCopies;
  if (a->m_length != b->m_length)
    return a->m_length < b->m_length;
  return a->m_numberOfAtomicCopies < b->m_numberOfAtomicCopies;
}

static void printLiveStringStats() {
  MutexLocker locker(statsMutex());
  HashSet<void*>& strings = liveStrings();

  HashMap<StringImpl*, RefPtr<PerStringStats>> stats;
  for (HashSet<void*>::iterator iter = strings.begin(); iter != strings.end();
       ++iter) {
    StringImpl* string = static_cast<StringImpl*>(*iter);
    HashMap<StringImpl*, RefPtr<PerStringStats>>::iterator entry =
        stats.find(string);
    RefPtr<PerStringStats> value =
        entry == stats.end() ? RefPtr<PerStringStats>(PerStringStats::create())
                             : entry->value;
    value->add(string);
    stats.set(string, value.release());
  }

  Vector<RefPtr<PerStringStats>> all;
  for (HashMap<StringImpl*, RefPtr<PerStringStats>>::iterator iter =
           stats.begin();
       iter != stats.end(); ++iter)
    all.append(iter->value);

  std::sort(all.begin(), all.end());
  std::reverse(all.begin(), all.end());
  for (size_t i = 0; i < 20 && i < all.size(); ++i)
    all[i]->print();
}

StringStats StringImpl::m_stringStats;

unsigned StringStats::s_stringRemovesTillPrintStats =
    StringStats::s_printStringStatsFrequency;

void StringStats::removeString(StringImpl* string) {
  unsigned length = string->length();
  --m_totalNumberStrings;

  if (string->is8Bit()) {
    --m_number8BitStrings;
    m_total8BitData -= length;
  } else {
    --m_number16BitStrings;
    m_total16BitData -= length;
  }

  if (!--s_stringRemovesTillPrintStats) {
    s_stringRemovesTillPrintStats = s_printStringStatsFrequency;
    printStats();
  }
}

void StringStats::printStats() {
  dataLogF("String stats\n");

  unsigned long long totalNumberCharacters = m_total8BitData + m_total16BitData;
  double percent8Bit =
      m_totalNumberStrings
          ? ((double)m_number8BitStrings * 100) / (double)m_totalNumberStrings
          : 0.0;
  double average8bitLength =
      m_number8BitStrings
          ? (double)m_total8BitData / (double)m_number8BitStrings
          : 0.0;
  dataLogF(
      "%8u (%5.2f%%) 8 bit        %12llu chars  %12llu bytes  avg length "
      "%6.1f\n",
      m_number8BitStrings, percent8Bit, m_total8BitData, m_total8BitData,
      average8bitLength);

  double percent16Bit =
      m_totalNumberStrings
          ? ((double)m_number16BitStrings * 100) / (double)m_totalNumberStrings
          : 0.0;
  double average16bitLength =
      m_number16BitStrings
          ? (double)m_total16BitData / (double)m_number16BitStrings
          : 0.0;
  dataLogF(
      "%8u (%5.2f%%) 16 bit       %12llu chars  %12llu bytes  avg length "
      "%6.1f\n",
      m_number16BitStrings, percent16Bit, m_total16BitData,
      m_total16BitData * 2, average16bitLength);

  double averageLength = m_totalNumberStrings ? (double)totalNumberCharacters /
                                                    (double)m_totalNumberStrings
                                              : 0.0;
  unsigned long long totalDataBytes = m_total8BitData + m_total16BitData * 2;
  dataLogF(
      "%8u Total                 %12llu chars  %12llu bytes  avg length "
      "%6.1f\n",
      m_totalNumberStrings, totalNumberCharacters, totalDataBytes,
      averageLength);
  unsigned long long totalSavedBytes = m_total8BitData;
  double percentSavings = totalSavedBytes
                              ? ((double)totalSavedBytes * 100) /
                                    (double)(totalDataBytes + totalSavedBytes)
                              : 0.0;
  dataLogF("         Total savings %12llu bytes (%5.2f%%)\n", totalSavedBytes,
           percentSavings);

  unsigned totalOverhead = m_totalNumberStrings * sizeof(StringImpl);
  double overheadPercent = (double)totalOverhead / (double)totalDataBytes * 100;
  dataLogF("         StringImpl overheader: %8u (%5.2f%%)\n", totalOverhead,
           overheadPercent);

  printLiveStringStats();
}
#endif

void* StringImpl::operator new(size_t size) {
  ASSERT(size == sizeof(StringImpl));
  return partitionAllocGeneric(Partitions::getBufferPartition(), size);
}

void StringImpl::operator delete(void* ptr) {
  partitionFreeGeneric(Partitions::getBufferPartition(), ptr);
}

inline StringImpl::~StringImpl() {
  ASSERT(!isStatic());

  STRING_STATS_REMOVE_STRING(this);

  if (isAtomic())
    AtomicString::remove(this);
}

void StringImpl::destroyIfNotStatic() {
  if (!isStatic())
    delete this;
}

PassRefPtr<StringImpl> StringImpl::createUninitialized(unsigned length,
                                                       LChar*& data) {
  if (!length) {
    data = 0;
    return empty();
  }

  // Allocate a single buffer large enough to contain the StringImpl
  // struct as well as the data which it contains. This removes one
  // heap allocation from this call.
  StringImpl* string = static_cast<StringImpl*>(partitionAllocGeneric(
      Partitions::getBufferPartition(), allocationSize<LChar>(length)));

  data = reinterpret_cast<LChar*>(string + 1);
  return adoptRef(new (string) StringImpl(length, Force8BitConstructor));
}

PassRefPtr<StringImpl> StringImpl::createUninitialized(unsigned length,
                                                       UChar*& data) {
  if (!length) {
    data = 0;
    return empty();
  }

  // Allocate a single buffer large enough to contain the StringImpl
  // struct as well as the data which it contains. This removes one
  // heap allocation from this call.
  StringImpl* string = static_cast<StringImpl*>(partitionAllocGeneric(
      Partitions::getBufferPartition(), allocationSize<UChar>(length)));

  data = reinterpret_cast<UChar*>(string + 1);
  return adoptRef(new (string) StringImpl(length));
}

PassRefPtr<StringImpl> StringImpl::reallocate(
    PassRefPtr<StringImpl> originalString,
    unsigned length) {
  ASSERT(originalString->hasOneRef());

  if (!length)
    return empty();

  bool is8Bit = originalString->is8Bit();
  // Same as createUninitialized() except here we use realloc.
  size_t size =
      is8Bit ? allocationSize<LChar>(length) : allocationSize<UChar>(length);
  originalString->~StringImpl();
  StringImpl* string = static_cast<StringImpl*>(partitionReallocGeneric(
      Partitions::getBufferPartition(), originalString.leakRef(), size));
  if (is8Bit)
    return adoptRef(new (string) StringImpl(length, Force8BitConstructor));
  return adoptRef(new (string) StringImpl(length));
}

static StaticStringsTable& staticStrings() {
  DEFINE_STATIC_LOCAL(StaticStringsTable, staticStrings, ());
  return staticStrings;
}

#if ENABLE(ASSERT)
static bool s_allowCreationOfStaticStrings = true;
#endif

const StaticStringsTable& StringImpl::allStaticStrings() {
  return staticStrings();
}

void StringImpl::freezeStaticStrings() {
  ASSERT(isMainThread());

#if ENABLE(ASSERT)
  s_allowCreationOfStaticStrings = false;
#endif
}

unsigned StringImpl::m_highestStaticStringLength = 0;

StringImpl* StringImpl::createStatic(const char* string,
                                     unsigned length,
                                     unsigned hash) {
  ASSERT(s_allowCreationOfStaticStrings);
  ASSERT(string);
  ASSERT(length);

  StaticStringsTable::const_iterator it = staticStrings().find(hash);
  if (it != staticStrings().end()) {
    ASSERT(!memcmp(string, it->value + 1, length * sizeof(LChar)));
    return it->value;
  }

  // Allocate a single buffer large enough to contain the StringImpl
  // struct as well as the data which it contains. This removes one
  // heap allocation from this call.
  RELEASE_ASSERT(length <=
                 ((std::numeric_limits<unsigned>::max() - sizeof(StringImpl)) /
                  sizeof(LChar)));
  size_t size = sizeof(StringImpl) + length * sizeof(LChar);

  WTF_ANNOTATE_SCOPED_MEMORY_LEAK;
  StringImpl* impl = static_cast<StringImpl*>(
      partitionAllocGeneric(Partitions::getBufferPartition(), size));

  LChar* data = reinterpret_cast<LChar*>(impl + 1);
  impl = new (impl) StringImpl(length, hash, StaticString);
  memcpy(data, string, length * sizeof(LChar));
#if ENABLE(ASSERT)
  impl->assertHashIsCorrect();
#endif

  ASSERT(isMainThread());
  m_highestStaticStringLength = std::max(m_highestStaticStringLength, length);
  staticStrings().add(hash, impl);
  WTF_ANNOTATE_BENIGN_RACE(impl,
                           "Benign race on the reference counter of a static "
                           "string created by StringImpl::createStatic");

  return impl;
}

PassRefPtr<StringImpl> StringImpl::create(const UChar* characters,
                                          unsigned length) {
  if (!characters || !length)
    return empty();

  UChar* data;
  RefPtr<StringImpl> string = createUninitialized(length, data);
  memcpy(data, characters, length * sizeof(UChar));
  return string.release();
}

PassRefPtr<StringImpl> StringImpl::create(const LChar* characters,
                                          unsigned length) {
  if (!characters || !length)
    return empty();

  LChar* data;
  RefPtr<StringImpl> string = createUninitialized(length, data);
  memcpy(data, characters, length * sizeof(LChar));
  return string.release();
}

PassRefPtr<StringImpl> StringImpl::create8BitIfPossible(const UChar* characters,
                                                        unsigned length) {
  if (!characters || !length)
    return empty();

  LChar* data;
  RefPtr<StringImpl> string = createUninitialized(length, data);

  for (size_t i = 0; i < length; ++i) {
    if (characters[i] & 0xff00)
      return create(characters, length);
    data[i] = static_cast<LChar>(characters[i]);
  }

  return string.release();
}

PassRefPtr<StringImpl> StringImpl::create(const LChar* string) {
  if (!string)
    return empty();
  size_t length = strlen(reinterpret_cast<const char*>(string));
  RELEASE_ASSERT(length <= numeric_limits<unsigned>::max());
  return create(string, length);
}

bool StringImpl::containsOnlyWhitespace() {
  // FIXME: The definition of whitespace here includes a number of characters
  // that are not whitespace from the point of view of RenderText; I wonder if
  // that's a problem in practice.
  if (is8Bit()) {
    for (unsigned i = 0; i < m_length; ++i) {
      UChar c = characters8()[i];
      if (!isASCIISpace(c))
        return false;
    }

    return true;
  }

  for (unsigned i = 0; i < m_length; ++i) {
    UChar c = characters16()[i];
    if (!isASCIISpace(c))
      return false;
  }
  return true;
}

PassRefPtr<StringImpl> StringImpl::substring(unsigned start, unsigned length) {
  if (start >= m_length)
    return empty();
  unsigned maxLength = m_length - start;
  if (length >= maxLength) {
    if (!start)
      return this;
    length = maxLength;
  }
  if (is8Bit())
    return create(characters8() + start, length);

  return create(characters16() + start, length);
}

UChar32 StringImpl::characterStartingAt(unsigned i) {
  if (is8Bit())
    return characters8()[i];
  if (U16_IS_SINGLE(characters16()[i]))
    return characters16()[i];
  if (i + 1 < m_length && U16_IS_LEAD(characters16()[i]) &&
      U16_IS_TRAIL(characters16()[i + 1]))
    return U16_GET_SUPPLEMENTARY(characters16()[i], characters16()[i + 1]);
  return 0;
}

PassRefPtr<StringImpl> StringImpl::lower() {
  // Note: This is a hot function in the Dromaeo benchmark, specifically the
  // no-op code path up through the first 'return' statement.

  // First scan the string for uppercase and non-ASCII characters:
  bool noUpper = true;
  UChar ored = 0;
  if (is8Bit()) {
    const LChar* end = characters8() + m_length;
    for (const LChar* chp = characters8(); chp != end; ++chp) {
      if (UNLIKELY(isASCIIUpper(*chp)))
        noUpper = false;
      ored |= *chp;
    }
    // Nothing to do if the string is all ASCII with no uppercase.
    if (noUpper && !(ored & ~0x7F))
      return this;

    RELEASE_ASSERT(m_length <=
                   static_cast<unsigned>(numeric_limits<int32_t>::max()));
    int32_t length = m_length;

    LChar* data8;
    RefPtr<StringImpl> newImpl = createUninitialized(length, data8);

    if (!(ored & ~0x7F)) {
      for (int32_t i = 0; i < length; ++i)
        data8[i] = toASCIILower(characters8()[i]);

      return newImpl.release();
    }

    // Do a slower implementation for cases that include non-ASCII Latin-1
    // characters.
    for (int32_t i = 0; i < length; ++i)
      data8[i] = static_cast<LChar>(Unicode::toLower(characters8()[i]));

    return newImpl.release();
  }

  const UChar* end = characters16() + m_length;
  for (const UChar* chp = characters16(); chp != end; ++chp) {
    if (UNLIKELY(isASCIIUpper(*chp)))
      noUpper = false;
    ored |= *chp;
  }
  // Nothing to do if the string is all ASCII with no uppercase.
  if (noUpper && !(ored & ~0x7F))
    return this;

  RELEASE_ASSERT(m_length <=
                 static_cast<unsigned>(numeric_limits<int32_t>::max()));
  int32_t length = m_length;

  if (!(ored & ~0x7F)) {
    UChar* data16;
    RefPtr<StringImpl> newImpl = createUninitialized(m_length, data16);

    for (int32_t i = 0; i < length; ++i) {
      UChar c = characters16()[i];
      data16[i] = toASCIILower(c);
    }
    return newImpl.release();
  }

  // Do a slower implementation for cases that include non-ASCII characters.
  UChar* data16;
  RefPtr<StringImpl> newImpl = createUninitialized(m_length, data16);

  bool error;
  int32_t realLength =
      Unicode::toLower(data16, length, characters16(), m_length, &error);
  if (!error && realLength == length)
    return newImpl.release();

  newImpl = createUninitialized(realLength, data16);
  Unicode::toLower(data16, realLength, characters16(), m_length, &error);
  if (error)
    return this;
  return newImpl.release();
}

PassRefPtr<StringImpl> StringImpl::upper() {
  // This function could be optimized for no-op cases the way lower() is,
  // but in empirical testing, few actual calls to upper() are no-ops, so
  // it wouldn't be worth the extra time for pre-scanning.

  RELEASE_ASSERT(m_length <=
                 static_cast<unsigned>(numeric_limits<int32_t>::max()));
  int32_t length = m_length;

  if (is8Bit()) {
    LChar* data8;
    RefPtr<StringImpl> newImpl = createUninitialized(m_length, data8);

    // Do a faster loop for the case where all the characters are ASCII.
    LChar ored = 0;
    for (int i = 0; i < length; ++i) {
      LChar c = characters8()[i];
      ored |= c;
      data8[i] = toASCIIUpper(c);
    }
    if (!(ored & ~0x7F))
      return newImpl.release();

    // Do a slower implementation for cases that include non-ASCII Latin-1
    // characters.
    int numberSharpSCharacters = 0;

    // There are two special cases.
    //  1. latin-1 characters when converted to upper case are 16 bit
    //  characters.
    //  2. Lower case sharp-S converts to "SS" (two characters)
    for (int32_t i = 0; i < length; ++i) {
      LChar c = characters8()[i];
      if (UNLIKELY(c == smallLetterSharpS))
        ++numberSharpSCharacters;
      UChar upper = Unicode::toUpper(c);
      if (UNLIKELY(upper > 0xff)) {
        // Since this upper-cased character does not fit in an 8-bit string, we
        // need to take the 16-bit path.
        goto upconvert;
      }
      data8[i] = static_cast<LChar>(upper);
    }

    if (!numberSharpSCharacters)
      return newImpl.release();

    // We have numberSSCharacters sharp-s characters, but none of the other
    // special characters.
    newImpl = createUninitialized(m_length + numberSharpSCharacters, data8);

    LChar* dest = data8;

    for (int32_t i = 0; i < length; ++i) {
      LChar c = characters8()[i];
      if (c == smallLetterSharpS) {
        *dest++ = 'S';
        *dest++ = 'S';
      } else
        *dest++ = static_cast<LChar>(Unicode::toUpper(c));
    }

    return newImpl.release();
  }

upconvert:
  RefPtr<StringImpl> upconverted = upconvertedString();
  const UChar* source16 = upconverted->characters16();

  UChar* data16;
  RefPtr<StringImpl> newImpl = createUninitialized(m_length, data16);

  // Do a faster loop for the case where all the characters are ASCII.
  UChar ored = 0;
  for (int i = 0; i < length; ++i) {
    UChar c = source16[i];
    ored |= c;
    data16[i] = toASCIIUpper(c);
  }
  if (!(ored & ~0x7F))
    return newImpl.release();

  // Do a slower implementation for cases that include non-ASCII characters.
  bool error;
  int32_t realLength =
      Unicode::toUpper(data16, length, source16, m_length, &error);
  if (!error && realLength == length)
    return newImpl;
  newImpl = createUninitialized(realLength, data16);
  Unicode::toUpper(data16, realLength, source16, m_length, &error);
  if (error)
    return this;
  return newImpl.release();
}

static bool inline localeIdMatchesLang(const AtomicString& localeId,
                                       const char* lang) {
  if (equalIgnoringCase(localeId, lang))
    return true;
  static char localeIdPrefix[4];
  static const char delimeter[4] = "-_@";

  size_t langLength = strlen(lang);
  RELEASE_ASSERT(langLength >= 2 && langLength <= 3);
  strncpy(localeIdPrefix, lang, langLength);
  for (int i = 0; i < 3; ++i) {
    localeIdPrefix[langLength] = delimeter[i];
    // case-insensitive comparison
    if (localeId.impl() &&
        localeId.impl()->startsWith(localeIdPrefix, langLength + 1, false))
      return true;
  }
  return false;
}

typedef int32_t (*icuCaseConverter)(UChar*,
                                    int32_t,
                                    const UChar*,
                                    int32_t,
                                    const char*,
                                    UErrorCode*);

static PassRefPtr<StringImpl> caseConvert(const UChar* source16,
                                          size_t length,
                                          icuCaseConverter converter,
                                          const char* locale,
                                          StringImpl* originalString) {
  UChar* data16;
  int32_t targetLength = length;
  RefPtr<StringImpl> output = StringImpl::createUninitialized(length, data16);
  do {
    UErrorCode status = U_ZERO_ERROR;
    targetLength =
        converter(data16, targetLength, source16, length, locale, &status);
    if (U_SUCCESS(status)) {
      output->truncateAssumingIsolated(targetLength);
      return output.release();
    }
    if (status != U_BUFFER_OVERFLOW_ERROR)
      return originalString;
    // Expand the buffer.
    output = StringImpl::createUninitialized(targetLength, data16);
  } while (true);
}

PassRefPtr<StringImpl> StringImpl::lower(const AtomicString& localeIdentifier) {
  // Use the more-optimized code path most of the time.
  // Only Turkic (tr and az) languages and Lithuanian requires
  // locale-specific lowercasing rules. Even though CLDR has el-Lower,
  // it's identical to the locale-agnostic lowercasing. Context-dependent
  // handling of Greek capital sigma is built into the common lowercasing
  // function in ICU.
  const char* localeForConversion = 0;
  if (localeIdMatchesLang(localeIdentifier, "tr") ||
      localeIdMatchesLang(localeIdentifier, "az"))
    localeForConversion = "tr";
  else if (localeIdMatchesLang(localeIdentifier, "lt"))
    localeForConversion = "lt";
  else
    return lower();

  if (m_length > static_cast<unsigned>(numeric_limits<int32_t>::max()))
    CRASH();
  int length = m_length;

  RefPtr<StringImpl> upconverted = upconvertedString();
  const UChar* source16 = upconverted->characters16();
  return caseConvert(source16, length, u_strToLower, localeForConversion, this);
}

PassRefPtr<StringImpl> StringImpl::upper(const AtomicString& localeIdentifier) {
  // Use the more-optimized code path most of the time.
  // Only Turkic (tr and az) languages and Greek require locale-specific
  // lowercasing rules.
  icu::UnicodeString transliteratorId;
  const char* localeForConversion = 0;
  if (localeIdMatchesLang(localeIdentifier, "tr") ||
      localeIdMatchesLang(localeIdentifier, "az"))
    localeForConversion = "tr";
  else if (localeIdMatchesLang(localeIdentifier, "el"))
    transliteratorId = UNICODE_STRING_SIMPLE("el-Upper");
  else if (localeIdMatchesLang(localeIdentifier, "lt"))
    localeForConversion = "lt";
  else
    return upper();

  if (m_length > static_cast<unsigned>(numeric_limits<int32_t>::max()))
    CRASH();
  int length = m_length;

  RefPtr<StringImpl> upconverted = upconvertedString();
  const UChar* source16 = upconverted->characters16();

  if (localeForConversion)
    return caseConvert(source16, length, u_strToUpper, localeForConversion,
                       this);

  // TODO(jungshik): Cache transliterator if perf penaly warrants it for Greek.
  UErrorCode status = U_ZERO_ERROR;
  OwnPtr<icu::Transliterator> translit =
      adoptPtr(icu::Transliterator::createInstance(transliteratorId,
                                                   UTRANS_FORWARD, status));
  if (U_FAILURE(status))
    return upper();

  // target will be copy-on-write.
  icu::UnicodeString target(false, source16, length);
  translit->transliterate(target);

  return create(reinterpret_cast<const UChar*>(target.getBuffer()),
                target.length());
}

PassRefPtr<StringImpl> StringImpl::fill(UChar character) {
  if (!(character & ~0x7F)) {
    LChar* data;
    RefPtr<StringImpl> newImpl = createUninitialized(m_length, data);
    for (unsigned i = 0; i < m_length; ++i)
      data[i] = character;
    return newImpl.release();
  }
  UChar* data;
  RefPtr<StringImpl> newImpl = createUninitialized(m_length, data);
  for (unsigned i = 0; i < m_length; ++i)
    data[i] = character;
  return newImpl.release();
}

PassRefPtr<StringImpl> StringImpl::foldCase() {
  RELEASE_ASSERT(m_length <=
                 static_cast<unsigned>(numeric_limits<int32_t>::max()));
  int32_t length = m_length;

  if (is8Bit()) {
    // Do a faster loop for the case where all the characters are ASCII.
    LChar* data;
    RefPtr<StringImpl> newImpl = createUninitialized(m_length, data);
    LChar ored = 0;

    for (int32_t i = 0; i < length; ++i) {
      LChar c = characters8()[i];
      data[i] = toASCIILower(c);
      ored |= c;
    }

    if (!(ored & ~0x7F))
      return newImpl.release();

    // Do a slower implementation for cases that include non-ASCII Latin-1
    // characters.
    for (int32_t i = 0; i < length; ++i)
      data[i] = static_cast<LChar>(Unicode::toLower(characters8()[i]));

    return newImpl.release();
  }

  // Do a faster loop for the case where all the characters are ASCII.
  UChar* data;
  RefPtr<StringImpl> newImpl = createUninitialized(m_length, data);
  UChar ored = 0;
  for (int32_t i = 0; i < length; ++i) {
    UChar c = characters16()[i];
    ored |= c;
    data[i] = toASCIILower(c);
  }
  if (!(ored & ~0x7F))
    return newImpl.release();

  // Do a slower implementation for cases that include non-ASCII characters.
  bool error;
  int32_t realLength =
      Unicode::foldCase(data, length, characters16(), m_length, &error);
  if (!error && realLength == length)
    return newImpl.release();
  newImpl = createUninitialized(realLength, data);
  Unicode::foldCase(data, realLength, characters16(), m_length, &error);
  if (error)
    return this;
  return newImpl.release();
}

template <class UCharPredicate>
inline PassRefPtr<StringImpl> StringImpl::stripMatchedCharacters(
    UCharPredicate predicate) {
  if (!m_length)
    return empty();

  unsigned start = 0;
  unsigned end = m_length - 1;

  // skip white space from start
  while (start <= end &&
         predicate(is8Bit() ? characters8()[start] : characters16()[start]))
    ++start;

  // only white space
  if (start > end)
    return empty();

  // skip white space from end
  while (end && predicate(is8Bit() ? characters8()[end] : characters16()[end]))
    --end;

  if (!start && end == m_length - 1)
    return this;
  if (is8Bit())
    return create(characters8() + start, end + 1 - start);
  return create(characters16() + start, end + 1 - start);
}

class UCharPredicate {
 public:
  inline UCharPredicate(CharacterMatchFunctionPtr function)
      : m_function(function) {}

  inline bool operator()(UChar ch) const { return m_function(ch); }

 private:
  const CharacterMatchFunctionPtr m_function;
};

class SpaceOrNewlinePredicate {
 public:
  inline bool operator()(UChar ch) const { return isSpaceOrNewline(ch); }
};

PassRefPtr<StringImpl> StringImpl::stripWhiteSpace() {
  return stripMatchedCharacters(SpaceOrNewlinePredicate());
}

PassRefPtr<StringImpl> StringImpl::stripWhiteSpace(
    IsWhiteSpaceFunctionPtr isWhiteSpace) {
  return stripMatchedCharacters(UCharPredicate(isWhiteSpace));
}

template <typename CharType>
ALWAYS_INLINE PassRefPtr<StringImpl> StringImpl::removeCharacters(
    const CharType* characters,
    CharacterMatchFunctionPtr findMatch) {
  const CharType* from = characters;
  const CharType* fromend = from + m_length;

  // Assume the common case will not remove any characters
  while (from != fromend && !findMatch(*from))
    ++from;
  if (from == fromend)
    return this;

  StringBuffer<CharType> data(m_length);
  CharType* to = data.characters();
  unsigned outc = from - characters;

  if (outc)
    memcpy(to, characters, outc * sizeof(CharType));

  while (true) {
    while (from != fromend && findMatch(*from))
      ++from;
    while (from != fromend && !findMatch(*from))
      to[outc++] = *from++;
    if (from == fromend)
      break;
  }

  data.shrink(outc);

  return data.release();
}

PassRefPtr<StringImpl> StringImpl::removeCharacters(
    CharacterMatchFunctionPtr findMatch) {
  if (is8Bit())
    return removeCharacters(characters8(), findMatch);
  return removeCharacters(characters16(), findMatch);
}

template <typename CharType, class UCharPredicate>
inline PassRefPtr<StringImpl> StringImpl::simplifyMatchedCharactersToSpace(
    UCharPredicate predicate,
    StripBehavior stripBehavior) {
  StringBuffer<CharType> data(m_length);

  const CharType* from = getCharacters<CharType>();
  const CharType* fromend = from + m_length;
  int outc = 0;
  bool changedToSpace = false;

  CharType* to = data.characters();

  if (stripBehavior == StripExtraWhiteSpace) {
    while (true) {
      while (from != fromend && predicate(*from)) {
        if (*from != ' ')
          changedToSpace = true;
        ++from;
      }
      while (from != fromend && !predicate(*from))
        to[outc++] = *from++;
      if (from != fromend)
        to[outc++] = ' ';
      else
        break;
    }

    if (outc > 0 && to[outc - 1] == ' ')
      --outc;
  } else {
    for (; from != fromend; ++from) {
      if (predicate(*from)) {
        if (*from != ' ')
          changedToSpace = true;
        to[outc++] = ' ';
      } else {
        to[outc++] = *from;
      }
    }
  }

  if (static_cast<unsigned>(outc) == m_length && !changedToSpace)
    return this;

  data.shrink(outc);

  return data.release();
}

PassRefPtr<StringImpl> StringImpl::simplifyWhiteSpace(
    StripBehavior stripBehavior) {
  if (is8Bit())
    return StringImpl::simplifyMatchedCharactersToSpace<LChar>(
        SpaceOrNewlinePredicate(), stripBehavior);
  return StringImpl::simplifyMatchedCharactersToSpace<UChar>(
      SpaceOrNewlinePredicate(), stripBehavior);
}

PassRefPtr<StringImpl> StringImpl::simplifyWhiteSpace(
    IsWhiteSpaceFunctionPtr isWhiteSpace,
    StripBehavior stripBehavior) {
  if (is8Bit())
    return StringImpl::simplifyMatchedCharactersToSpace<LChar>(
        UCharPredicate(isWhiteSpace), stripBehavior);
  return StringImpl::simplifyMatchedCharactersToSpace<UChar>(
      UCharPredicate(isWhiteSpace), stripBehavior);
}

int StringImpl::toIntStrict(bool* ok, int base) {
  if (is8Bit())
    return charactersToIntStrict(characters8(), m_length, ok, base);
  return charactersToIntStrict(characters16(), m_length, ok, base);
}

unsigned StringImpl::toUIntStrict(bool* ok, int base) {
  if (is8Bit())
    return charactersToUIntStrict(characters8(), m_length, ok, base);
  return charactersToUIntStrict(characters16(), m_length, ok, base);
}

int64_t StringImpl::toInt64Strict(bool* ok, int base) {
  if (is8Bit())
    return charactersToInt64Strict(characters8(), m_length, ok, base);
  return charactersToInt64Strict(characters16(), m_length, ok, base);
}

uint64_t StringImpl::toUInt64Strict(bool* ok, int base) {
  if (is8Bit())
    return charactersToUInt64Strict(characters8(), m_length, ok, base);
  return charactersToUInt64Strict(characters16(), m_length, ok, base);
}

intptr_t StringImpl::toIntPtrStrict(bool* ok, int base) {
  if (is8Bit())
    return charactersToIntPtrStrict(characters8(), m_length, ok, base);
  return charactersToIntPtrStrict(characters16(), m_length, ok, base);
}

int StringImpl::toInt(bool* ok) {
  if (is8Bit())
    return charactersToInt(characters8(), m_length, ok);
  return charactersToInt(characters16(), m_length, ok);
}

unsigned StringImpl::toUInt(bool* ok) {
  if (is8Bit())
    return charactersToUInt(characters8(), m_length, ok);
  return charactersToUInt(characters16(), m_length, ok);
}

int64_t StringImpl::toInt64(bool* ok) {
  if (is8Bit())
    return charactersToInt64(characters8(), m_length, ok);
  return charactersToInt64(characters16(), m_length, ok);
}

uint64_t StringImpl::toUInt64(bool* ok) {
  if (is8Bit())
    return charactersToUInt64(characters8(), m_length, ok);
  return charactersToUInt64(characters16(), m_length, ok);
}

intptr_t StringImpl::toIntPtr(bool* ok) {
  if (is8Bit())
    return charactersToIntPtr(characters8(), m_length, ok);
  return charactersToIntPtr(characters16(), m_length, ok);
}

double StringImpl::toDouble(bool* ok) {
  if (is8Bit())
    return charactersToDouble(characters8(), m_length, ok);
  return charactersToDouble(characters16(), m_length, ok);
}

float StringImpl::toFloat(bool* ok) {
  if (is8Bit())
    return charactersToFloat(characters8(), m_length, ok);
  return charactersToFloat(characters16(), m_length, ok);
}

bool equalIgnoringCase(const LChar* a, const LChar* b, unsigned length) {
  while (length--) {
    LChar bc = *b++;
    if (foldCase(*a++) != foldCase(bc))
      return false;
  }
  return true;
}

bool equalIgnoringCase(const UChar* a, const LChar* b, unsigned length) {
  while (length--) {
    LChar bc = *b++;
    if (foldCase(*a++) != foldCase(bc))
      return false;
  }
  return true;
}

size_t StringImpl::find(CharacterMatchFunctionPtr matchFunction,
                        unsigned start) {
  if (is8Bit())
    return WTF::find(characters8(), m_length, matchFunction, start);
  return WTF::find(characters16(), m_length, matchFunction, start);
}

size_t StringImpl::find(const LChar* matchString, unsigned index) {
  // Check for null or empty string to match against
  if (!matchString)
    return kNotFound;
  size_t matchStringLength = strlen(reinterpret_cast<const char*>(matchString));
  RELEASE_ASSERT(matchStringLength <= numeric_limits<unsigned>::max());
  unsigned matchLength = matchStringLength;
  if (!matchLength)
    return min(index, length());

  // Optimization 1: fast case for strings of length 1.
  if (matchLength == 1)
    return WTF::find(characters16(), length(), *matchString, index);

  // Check index & matchLength are in range.
  if (index > length())
    return kNotFound;
  unsigned searchLength = length() - index;
  if (matchLength > searchLength)
    return kNotFound;
  // delta is the number of additional times to test; delta == 0 means test only
  // once.
  unsigned delta = searchLength - matchLength;

  const UChar* searchCharacters = characters16() + index;

  // Optimization 2: keep a running hash of the strings,
  // only call equal if the hashes match.
  unsigned searchHash = 0;
  unsigned matchHash = 0;
  for (unsigned i = 0; i < matchLength; ++i) {
    searchHash += searchCharacters[i];
    matchHash += matchString[i];
  }

  unsigned i = 0;
  // keep looping until we match
  while (searchHash != matchHash ||
         !equal(searchCharacters + i, matchString, matchLength)) {
    if (i == delta)
      return kNotFound;
    searchHash += searchCharacters[i + matchLength];
    searchHash -= searchCharacters[i];
    ++i;
  }
  return index + i;
}

template <typename CharType>
ALWAYS_INLINE size_t findIgnoringCaseInternal(const CharType* searchCharacters,
                                              const LChar* matchString,
                                              unsigned index,
                                              unsigned searchLength,
                                              unsigned matchLength) {
  // delta is the number of additional times to test; delta == 0 means test only
  // once.
  unsigned delta = searchLength - matchLength;

  unsigned i = 0;
  while (!equalIgnoringCase(searchCharacters + i, matchString, matchLength)) {
    if (i == delta)
      return kNotFound;
    ++i;
  }
  return index + i;
}

size_t StringImpl::findIgnoringCase(const LChar* matchString, unsigned index) {
  // Check for null or empty string to match against
  if (!matchString)
    return kNotFound;
  size_t matchStringLength = strlen(reinterpret_cast<const char*>(matchString));
  RELEASE_ASSERT(matchStringLength <= numeric_limits<unsigned>::max());
  unsigned matchLength = matchStringLength;
  if (!matchLength)
    return min(index, length());

  // Check index & matchLength are in range.
  if (index > length())
    return kNotFound;
  unsigned searchLength = length() - index;
  if (matchLength > searchLength)
    return kNotFound;

  if (is8Bit())
    return findIgnoringCaseInternal(characters8() + index, matchString, index,
                                    searchLength, matchLength);
  return findIgnoringCaseInternal(characters16() + index, matchString, index,
                                  searchLength, matchLength);
}

template <typename SearchCharacterType, typename MatchCharacterType>
ALWAYS_INLINE static size_t findInternal(
    const SearchCharacterType* searchCharacters,
    const MatchCharacterType* matchCharacters,
    unsigned index,
    unsigned searchLength,
    unsigned matchLength) {
  // Optimization: keep a running hash of the strings,
  // only call equal() if the hashes match.

  // delta is the number of additional times to test; delta == 0 means test only
  // once.
  unsigned delta = searchLength - matchLength;

  unsigned searchHash = 0;
  unsigned matchHash = 0;

  for (unsigned i = 0; i < matchLength; ++i) {
    searchHash += searchCharacters[i];
    matchHash += matchCharacters[i];
  }

  unsigned i = 0;
  // keep looping until we match
  while (searchHash != matchHash ||
         !equal(searchCharacters + i, matchCharacters, matchLength)) {
    if (i == delta)
      return kNotFound;
    searchHash += searchCharacters[i + matchLength];
    searchHash -= searchCharacters[i];
    ++i;
  }
  return index + i;
}

size_t StringImpl::find(StringImpl* matchString) {
  // Check for null string to match against
  if (UNLIKELY(!matchString))
    return kNotFound;
  unsigned matchLength = matchString->length();

  // Optimization 1: fast case for strings of length 1.
  if (matchLength == 1) {
    if (is8Bit()) {
      if (matchString->is8Bit())
        return WTF::find(characters8(), length(),
                         matchString->characters8()[0]);
      return WTF::find(characters8(), length(), matchString->characters16()[0]);
    }
    if (matchString->is8Bit())
      return WTF::find(characters16(), length(), matchString->characters8()[0]);
    return WTF::find(characters16(), length(), matchString->characters16()[0]);
  }

  // Check matchLength is in range.
  if (matchLength > length())
    return kNotFound;

  // Check for empty string to match against
  if (UNLIKELY(!matchLength))
    return 0;

  if (is8Bit()) {
    if (matchString->is8Bit())
      return findInternal(characters8(), matchString->characters8(), 0,
                          length(), matchLength);
    return findInternal(characters8(), matchString->characters16(), 0, length(),
                        matchLength);
  }

  if (matchString->is8Bit())
    return findInternal(characters16(), matchString->characters8(), 0, length(),
                        matchLength);

  return findInternal(characters16(), matchString->characters16(), 0, length(),
                      matchLength);
}

size_t StringImpl::find(StringImpl* matchString, unsigned index) {
  // Check for null or empty string to match against
  if (UNLIKELY(!matchString))
    return kNotFound;

  unsigned matchLength = matchString->length();

  // Optimization 1: fast case for strings of length 1.
  if (matchLength == 1) {
    if (is8Bit())
      return WTF::find(characters8(), length(), (*matchString)[0], index);
    return WTF::find(characters16(), length(), (*matchString)[0], index);
  }

  if (UNLIKELY(!matchLength))
    return min(index, length());

  // Check index & matchLength are in range.
  if (index > length())
    return kNotFound;
  unsigned searchLength = length() - index;
  if (matchLength > searchLength)
    return kNotFound;

  if (is8Bit()) {
    if (matchString->is8Bit())
      return findInternal(characters8() + index, matchString->characters8(),
                          index, searchLength, matchLength);
    return findInternal(characters8() + index, matchString->characters16(),
                        index, searchLength, matchLength);
  }

  if (matchString->is8Bit())
    return findInternal(characters16() + index, matchString->characters8(),
                        index, searchLength, matchLength);

  return findInternal(characters16() + index, matchString->characters16(),
                      index, searchLength, matchLength);
}

template <typename SearchCharacterType, typename MatchCharacterType>
ALWAYS_INLINE static size_t findIgnoringCaseInner(
    const SearchCharacterType* searchCharacters,
    const MatchCharacterType* matchCharacters,
    unsigned index,
    unsigned searchLength,
    unsigned matchLength) {
  // delta is the number of additional times to test; delta == 0 means test only
  // once.
  unsigned delta = searchLength - matchLength;

  unsigned i = 0;
  // keep looping until we match
  while (
      !equalIgnoringCase(searchCharacters + i, matchCharacters, matchLength)) {
    if (i == delta)
      return kNotFound;
    ++i;
  }
  return index + i;
}

size_t StringImpl::findIgnoringCase(StringImpl* matchString, unsigned index) {
  // Check for null or empty string to match against
  if (!matchString)
    return kNotFound;
  unsigned matchLength = matchString->length();
  if (!matchLength)
    return min(index, length());

  // Check index & matchLength are in range.
  if (index > length())
    return kNotFound;
  unsigned searchLength = length() - index;
  if (matchLength > searchLength)
    return kNotFound;

  if (is8Bit()) {
    if (matchString->is8Bit())
      return findIgnoringCaseInner(characters8() + index,
                                   matchString->characters8(), index,
                                   searchLength, matchLength);
    return findIgnoringCaseInner(characters8() + index,
                                 matchString->characters16(), index,
                                 searchLength, matchLength);
  }

  if (matchString->is8Bit())
    return findIgnoringCaseInner(characters16() + index,
                                 matchString->characters8(), index,
                                 searchLength, matchLength);

  return findIgnoringCaseInner(characters16() + index,
                               matchString->characters16(), index, searchLength,
                               matchLength);
}

size_t StringImpl::findNextLineStart(unsigned index) {
  if (is8Bit())
    return WTF::findNextLineStart(characters8(), m_length, index);
  return WTF::findNextLineStart(characters16(), m_length, index);
}

size_t StringImpl::count(LChar c) const {
  int count = 0;
  if (is8Bit()) {
    for (size_t i = 0; i < m_length; ++i)
      count += characters8()[i] == c;
  } else {
    for (size_t i = 0; i < m_length; ++i)
      count += characters16()[i] == c;
  }
  return count;
}

size_t StringImpl::reverseFind(UChar c, unsigned index) {
  if (is8Bit())
    return WTF::reverseFind(characters8(), m_length, c, index);
  return WTF::reverseFind(characters16(), m_length, c, index);
}

template <typename SearchCharacterType, typename MatchCharacterType>
ALWAYS_INLINE static size_t reverseFindInner(
    const SearchCharacterType* searchCharacters,
    const MatchCharacterType* matchCharacters,
    unsigned index,
    unsigned length,
    unsigned matchLength) {
  // Optimization: keep a running hash of the strings,
  // only call equal if the hashes match.

  // delta is the number of additional times to test; delta == 0 means test only
  // once.
  unsigned delta = min(index, length - matchLength);

  unsigned searchHash = 0;
  unsigned matchHash = 0;
  for (unsigned i = 0; i < matchLength; ++i) {
    searchHash += searchCharacters[delta + i];
    matchHash += matchCharacters[i];
  }

  // keep looping until we match
  while (searchHash != matchHash ||
         !equal(searchCharacters + delta, matchCharacters, matchLength)) {
    if (!delta)
      return kNotFound;
    --delta;
    searchHash -= searchCharacters[delta + matchLength];
    searchHash += searchCharacters[delta];
  }
  return delta;
}

size_t StringImpl::reverseFind(StringImpl* matchString, unsigned index) {
  // Check for null or empty string to match against
  if (!matchString)
    return kNotFound;
  unsigned matchLength = matchString->length();
  unsigned ourLength = length();
  if (!matchLength)
    return min(index, ourLength);

  // Optimization 1: fast case for strings of length 1.
  if (matchLength == 1) {
    if (is8Bit())
      return WTF::reverseFind(characters8(), ourLength, (*matchString)[0],
                              index);
    return WTF::reverseFind(characters16(), ourLength, (*matchString)[0],
                            index);
  }

  // Check index & matchLength are in range.
  if (matchLength > ourLength)
    return kNotFound;

  if (is8Bit()) {
    if (matchString->is8Bit())
      return reverseFindInner(characters8(), matchString->characters8(), index,
                              ourLength, matchLength);
    return reverseFindInner(characters8(), matchString->characters16(), index,
                            ourLength, matchLength);
  }

  if (matchString->is8Bit())
    return reverseFindInner(characters16(), matchString->characters8(), index,
                            ourLength, matchLength);

  return reverseFindInner(characters16(), matchString->characters16(), index,
                          ourLength, matchLength);
}

template <typename SearchCharacterType, typename MatchCharacterType>
ALWAYS_INLINE static size_t reverseFindIgnoringCaseInner(
    const SearchCharacterType* searchCharacters,
    const MatchCharacterType* matchCharacters,
    unsigned index,
    unsigned length,
    unsigned matchLength) {
  // delta is the number of additional times to test; delta == 0 means test only
  // once.
  unsigned delta = min(index, length - matchLength);

  // keep looping until we match
  while (!equalIgnoringCase(searchCharacters + delta, matchCharacters,
                            matchLength)) {
    if (!delta)
      return kNotFound;
    --delta;
  }
  return delta;
}

size_t StringImpl::reverseFindIgnoringCase(StringImpl* matchString,
                                           unsigned index) {
  // Check for null or empty string to match against
  if (!matchString)
    return kNotFound;
  unsigned matchLength = matchString->length();
  unsigned ourLength = length();
  if (!matchLength)
    return min(index, ourLength);

  // Check index & matchLength are in range.
  if (matchLength > ourLength)
    return kNotFound;

  if (is8Bit()) {
    if (matchString->is8Bit())
      return reverseFindIgnoringCaseInner(characters8(),
                                          matchString->characters8(), index,
                                          ourLength, matchLength);
    return reverseFindIgnoringCaseInner(characters8(),
                                        matchString->characters16(), index,
                                        ourLength, matchLength);
  }

  if (matchString->is8Bit())
    return reverseFindIgnoringCaseInner(characters16(),
                                        matchString->characters8(), index,
                                        ourLength, matchLength);

  return reverseFindIgnoringCaseInner(characters16(),
                                      matchString->characters16(), index,
                                      ourLength, matchLength);
}

ALWAYS_INLINE static bool equalInner(const StringImpl* stringImpl,
                                     unsigned startOffset,
                                     const char* matchString,
                                     unsigned matchLength,
                                     bool caseSensitive) {
  ASSERT(stringImpl);
  ASSERT(matchLength <= stringImpl->length());
  ASSERT(startOffset + matchLength <= stringImpl->length());

  if (caseSensitive) {
    if (stringImpl->is8Bit())
      return equal(stringImpl->characters8() + startOffset,
                   reinterpret_cast<const LChar*>(matchString), matchLength);
    return equal(stringImpl->characters16() + startOffset,
                 reinterpret_cast<const LChar*>(matchString), matchLength);
  }
  if (stringImpl->is8Bit())
    return equalIgnoringCase(stringImpl->characters8() + startOffset,
                             reinterpret_cast<const LChar*>(matchString),
                             matchLength);
  return equalIgnoringCase(stringImpl->characters16() + startOffset,
                           reinterpret_cast<const LChar*>(matchString),
                           matchLength);
}

bool StringImpl::startsWith(UChar character) const {
  return m_length && (*this)[0] == character;
}

bool StringImpl::startsWith(const char* matchString,
                            unsigned matchLength,
                            bool caseSensitive) const {
  ASSERT(matchLength);
  if (matchLength > length())
    return false;
  return equalInner(this, 0, matchString, matchLength, caseSensitive);
}

bool StringImpl::endsWith(StringImpl* matchString, bool caseSensitive) {
  ASSERT(matchString);
  if (m_length >= matchString->m_length) {
    unsigned start = m_length - matchString->m_length;
    return (caseSensitive ? find(matchString, start)
                          : findIgnoringCase(matchString, start)) == start;
  }
  return false;
}

bool StringImpl::endsWith(UChar character) const {
  return m_length && (*this)[m_length - 1] == character;
}

bool StringImpl::endsWith(const char* matchString,
                          unsigned matchLength,
                          bool caseSensitive) const {
  ASSERT(matchLength);
  if (matchLength > length())
    return false;
  unsigned startOffset = length() - matchLength;
  return equalInner(this, startOffset, matchString, matchLength, caseSensitive);
}

PassRefPtr<StringImpl> StringImpl::replace(UChar oldC, UChar newC) {
  if (oldC == newC)
    return this;

  if (find(oldC) == kNotFound)
    return this;

  unsigned i;
  if (is8Bit()) {
    if (newC <= 0xff) {
      LChar* data;
      LChar oldChar = static_cast<LChar>(oldC);
      LChar newChar = static_cast<LChar>(newC);

      RefPtr<StringImpl> newImpl = createUninitialized(m_length, data);

      for (i = 0; i != m_length; ++i) {
        LChar ch = characters8()[i];
        if (ch == oldChar)
          ch = newChar;
        data[i] = ch;
      }
      return newImpl.release();
    }

    // There is the possibility we need to up convert from 8 to 16 bit,
    // create a 16 bit string for the result.
    UChar* data;
    RefPtr<StringImpl> newImpl = createUninitialized(m_length, data);

    for (i = 0; i != m_length; ++i) {
      UChar ch = characters8()[i];
      if (ch == oldC)
        ch = newC;
      data[i] = ch;
    }

    return newImpl.release();
  }

  UChar* data;
  RefPtr<StringImpl> newImpl = createUninitialized(m_length, data);

  for (i = 0; i != m_length; ++i) {
    UChar ch = characters16()[i];
    if (ch == oldC)
      ch = newC;
    data[i] = ch;
  }
  return newImpl.release();
}

PassRefPtr<StringImpl> StringImpl::replace(unsigned position,
                                           unsigned lengthToReplace,
                                           StringImpl* str) {
  position = min(position, length());
  lengthToReplace = min(lengthToReplace, length() - position);
  unsigned lengthToInsert = str ? str->length() : 0;
  if (!lengthToReplace && !lengthToInsert)
    return this;

  RELEASE_ASSERT((length() - lengthToReplace) <
                 (numeric_limits<unsigned>::max() - lengthToInsert));

  if (is8Bit() && (!str || str->is8Bit())) {
    LChar* data;
    RefPtr<StringImpl> newImpl =
        createUninitialized(length() - lengthToReplace + lengthToInsert, data);
    memcpy(data, characters8(), position * sizeof(LChar));
    if (str)
      memcpy(data + position, str->characters8(),
             lengthToInsert * sizeof(LChar));
    memcpy(data + position + lengthToInsert,
           characters8() + position + lengthToReplace,
           (length() - position - lengthToReplace) * sizeof(LChar));
    return newImpl.release();
  }
  UChar* data;
  RefPtr<StringImpl> newImpl =
      createUninitialized(length() - lengthToReplace + lengthToInsert, data);
  if (is8Bit())
    for (unsigned i = 0; i < position; ++i)
      data[i] = characters8()[i];
  else
    memcpy(data, characters16(), position * sizeof(UChar));
  if (str) {
    if (str->is8Bit())
      for (unsigned i = 0; i < lengthToInsert; ++i)
        data[i + position] = str->characters8()[i];
    else
      memcpy(data + position, str->characters16(),
             lengthToInsert * sizeof(UChar));
  }
  if (is8Bit()) {
    for (unsigned i = 0; i < length() - position - lengthToReplace; ++i)
      data[i + position + lengthToInsert] =
          characters8()[i + position + lengthToReplace];
  } else {
    memcpy(data + position + lengthToInsert,
           characters16() + position + lengthToReplace,
           (length() - position - lengthToReplace) * sizeof(UChar));
  }
  return newImpl.release();
}

PassRefPtr<StringImpl> StringImpl::replace(UChar pattern,
                                           StringImpl* replacement) {
  if (!replacement)
    return this;

  if (replacement->is8Bit())
    return replace(pattern, replacement->characters8(), replacement->length());

  return replace(pattern, replacement->characters16(), replacement->length());
}

PassRefPtr<StringImpl> StringImpl::replace(UChar pattern,
                                           const LChar* replacement,
                                           unsigned repStrLength) {
  ASSERT(replacement);

  size_t srcSegmentStart = 0;
  unsigned matchCount = 0;

  // Count the matches.
  while ((srcSegmentStart = find(pattern, srcSegmentStart)) != kNotFound) {
    ++matchCount;
    ++srcSegmentStart;
  }

  // If we have 0 matches then we don't have to do any more work.
  if (!matchCount)
    return this;

  RELEASE_ASSERT(!repStrLength ||
                 matchCount <= numeric_limits<unsigned>::max() / repStrLength);

  unsigned replaceSize = matchCount * repStrLength;
  unsigned newSize = m_length - matchCount;
  RELEASE_ASSERT(newSize < (numeric_limits<unsigned>::max() - replaceSize));

  newSize += replaceSize;

  // Construct the new data.
  size_t srcSegmentEnd;
  unsigned srcSegmentLength;
  srcSegmentStart = 0;
  unsigned dstOffset = 0;

  if (is8Bit()) {
    LChar* data;
    RefPtr<StringImpl> newImpl = createUninitialized(newSize, data);

    while ((srcSegmentEnd = find(pattern, srcSegmentStart)) != kNotFound) {
      srcSegmentLength = srcSegmentEnd - srcSegmentStart;
      memcpy(data + dstOffset, characters8() + srcSegmentStart,
             srcSegmentLength * sizeof(LChar));
      dstOffset += srcSegmentLength;
      memcpy(data + dstOffset, replacement, repStrLength * sizeof(LChar));
      dstOffset += repStrLength;
      srcSegmentStart = srcSegmentEnd + 1;
    }

    srcSegmentLength = m_length - srcSegmentStart;
    memcpy(data + dstOffset, characters8() + srcSegmentStart,
           srcSegmentLength * sizeof(LChar));

    ASSERT(dstOffset + srcSegmentLength == newImpl->length());

    return newImpl.release();
  }

  UChar* data;
  RefPtr<StringImpl> newImpl = createUninitialized(newSize, data);

  while ((srcSegmentEnd = find(pattern, srcSegmentStart)) != kNotFound) {
    srcSegmentLength = srcSegmentEnd - srcSegmentStart;
    memcpy(data + dstOffset, characters16() + srcSegmentStart,
           srcSegmentLength * sizeof(UChar));

    dstOffset += srcSegmentLength;
    for (unsigned i = 0; i < repStrLength; ++i)
      data[i + dstOffset] = replacement[i];

    dstOffset += repStrLength;
    srcSegmentStart = srcSegmentEnd + 1;
  }

  srcSegmentLength = m_length - srcSegmentStart;
  memcpy(data + dstOffset, characters16() + srcSegmentStart,
         srcSegmentLength * sizeof(UChar));

  ASSERT(dstOffset + srcSegmentLength == newImpl->length());

  return newImpl.release();
}

PassRefPtr<StringImpl> StringImpl::replace(UChar pattern,
                                           const UChar* replacement,
                                           unsigned repStrLength) {
  ASSERT(replacement);

  size_t srcSegmentStart = 0;
  unsigned matchCount = 0;

  // Count the matches.
  while ((srcSegmentStart = find(pattern, srcSegmentStart)) != kNotFound) {
    ++matchCount;
    ++srcSegmentStart;
  }

  // If we have 0 matches then we don't have to do any more work.
  if (!matchCount)
    return this;

  RELEASE_ASSERT(!repStrLength ||
                 matchCount <= numeric_limits<unsigned>::max() / repStrLength);

  unsigned replaceSize = matchCount * repStrLength;
  unsigned newSize = m_length - matchCount;
  RELEASE_ASSERT(newSize < (numeric_limits<unsigned>::max() - replaceSize));

  newSize += replaceSize;

  // Construct the new data.
  size_t srcSegmentEnd;
  unsigned srcSegmentLength;
  srcSegmentStart = 0;
  unsigned dstOffset = 0;

  if (is8Bit()) {
    UChar* data;
    RefPtr<StringImpl> newImpl = createUninitialized(newSize, data);

    while ((srcSegmentEnd = find(pattern, srcSegmentStart)) != kNotFound) {
      srcSegmentLength = srcSegmentEnd - srcSegmentStart;
      for (unsigned i = 0; i < srcSegmentLength; ++i)
        data[i + dstOffset] = characters8()[i + srcSegmentStart];

      dstOffset += srcSegmentLength;
      memcpy(data + dstOffset, replacement, repStrLength * sizeof(UChar));

      dstOffset += repStrLength;
      srcSegmentStart = srcSegmentEnd + 1;
    }

    srcSegmentLength = m_length - srcSegmentStart;
    for (unsigned i = 0; i < srcSegmentLength; ++i)
      data[i + dstOffset] = characters8()[i + srcSegmentStart];

    ASSERT(dstOffset + srcSegmentLength == newImpl->length());

    return newImpl.release();
  }

  UChar* data;
  RefPtr<StringImpl> newImpl = createUninitialized(newSize, data);

  while ((srcSegmentEnd = find(pattern, srcSegmentStart)) != kNotFound) {
    srcSegmentLength = srcSegmentEnd - srcSegmentStart;
    memcpy(data + dstOffset, characters16() + srcSegmentStart,
           srcSegmentLength * sizeof(UChar));

    dstOffset += srcSegmentLength;
    memcpy(data + dstOffset, replacement, repStrLength * sizeof(UChar));

    dstOffset += repStrLength;
    srcSegmentStart = srcSegmentEnd + 1;
  }

  srcSegmentLength = m_length - srcSegmentStart;
  memcpy(data + dstOffset, characters16() + srcSegmentStart,
         srcSegmentLength * sizeof(UChar));

  ASSERT(dstOffset + srcSegmentLength == newImpl->length());

  return newImpl.release();
}

PassRefPtr<StringImpl> StringImpl::replace(StringImpl* pattern,
                                           StringImpl* replacement) {
  if (!pattern || !replacement)
    return this;

  unsigned patternLength = pattern->length();
  if (!patternLength)
    return this;

  unsigned repStrLength = replacement->length();
  size_t srcSegmentStart = 0;
  unsigned matchCount = 0;

  // Count the matches.
  while ((srcSegmentStart = find(pattern, srcSegmentStart)) != kNotFound) {
    ++matchCount;
    srcSegmentStart += patternLength;
  }

  // If we have 0 matches, we don't have to do any more work
  if (!matchCount)
    return this;

  unsigned newSize = m_length - matchCount * patternLength;
  RELEASE_ASSERT(!repStrLength ||
                 matchCount <= numeric_limits<unsigned>::max() / repStrLength);

  RELEASE_ASSERT(newSize <=
                 (numeric_limits<unsigned>::max() - matchCount * repStrLength));

  newSize += matchCount * repStrLength;

  // Construct the new data
  size_t srcSegmentEnd;
  unsigned srcSegmentLength;
  srcSegmentStart = 0;
  unsigned dstOffset = 0;
  bool srcIs8Bit = is8Bit();
  bool replacementIs8Bit = replacement->is8Bit();

  // There are 4 cases:
  // 1. This and replacement are both 8 bit.
  // 2. This and replacement are both 16 bit.
  // 3. This is 8 bit and replacement is 16 bit.
  // 4. This is 16 bit and replacement is 8 bit.
  if (srcIs8Bit && replacementIs8Bit) {
    // Case 1
    LChar* data;
    RefPtr<StringImpl> newImpl = createUninitialized(newSize, data);
    while ((srcSegmentEnd = find(pattern, srcSegmentStart)) != kNotFound) {
      srcSegmentLength = srcSegmentEnd - srcSegmentStart;
      memcpy(data + dstOffset, characters8() + srcSegmentStart,
             srcSegmentLength * sizeof(LChar));
      dstOffset += srcSegmentLength;
      memcpy(data + dstOffset, replacement->characters8(),
             repStrLength * sizeof(LChar));
      dstOffset += repStrLength;
      srcSegmentStart = srcSegmentEnd + patternLength;
    }

    srcSegmentLength = m_length - srcSegmentStart;
    memcpy(data + dstOffset, characters8() + srcSegmentStart,
           srcSegmentLength * sizeof(LChar));

    ASSERT(dstOffset + srcSegmentLength == newImpl->length());

    return newImpl.release();
  }

  UChar* data;
  RefPtr<StringImpl> newImpl = createUninitialized(newSize, data);
  while ((srcSegmentEnd = find(pattern, srcSegmentStart)) != kNotFound) {
    srcSegmentLength = srcSegmentEnd - srcSegmentStart;
    if (srcIs8Bit) {
      // Case 3.
      for (unsigned i = 0; i < srcSegmentLength; ++i)
        data[i + dstOffset] = characters8()[i + srcSegmentStart];
    } else {
      // Case 2 & 4.
      memcpy(data + dstOffset, characters16() + srcSegmentStart,
             srcSegmentLength * sizeof(UChar));
    }
    dstOffset += srcSegmentLength;
    if (replacementIs8Bit) {
      // Cases 2 & 3.
      for (unsigned i = 0; i < repStrLength; ++i)
        data[i + dstOffset] = replacement->characters8()[i];
    } else {
      // Case 4
      memcpy(data + dstOffset, replacement->characters16(),
             repStrLength * sizeof(UChar));
    }
    dstOffset += repStrLength;
    srcSegmentStart = srcSegmentEnd + patternLength;
  }

  srcSegmentLength = m_length - srcSegmentStart;
  if (srcIs8Bit) {
    // Case 3.
    for (unsigned i = 0; i < srcSegmentLength; ++i)
      data[i + dstOffset] = characters8()[i + srcSegmentStart];
  } else {
    // Cases 2 & 4.
    memcpy(data + dstOffset, characters16() + srcSegmentStart,
           srcSegmentLength * sizeof(UChar));
  }

  ASSERT(dstOffset + srcSegmentLength == newImpl->length());

  return newImpl.release();
}

PassRefPtr<StringImpl> StringImpl::upconvertedString() {
  if (is8Bit())
    return String::make16BitFrom8BitSource(characters8(), m_length)
        .releaseImpl();
  return this;
}

static inline bool stringImplContentEqual(const StringImpl* a,
                                          const StringImpl* b) {
  unsigned aLength = a->length();
  unsigned bLength = b->length();
  if (aLength != bLength)
    return false;

  if (a->is8Bit()) {
    if (b->is8Bit())
      return equal(a->characters8(), b->characters8(), aLength);

    return equal(a->characters8(), b->characters16(), aLength);
  }

  if (b->is8Bit())
    return equal(a->characters16(), b->characters8(), aLength);

  return equal(a->characters16(), b->characters16(), aLength);
}

bool equal(const StringImpl* a, const StringImpl* b) {
  if (a == b)
    return true;
  if (!a || !b)
    return false;
  if (a->isAtomic() && b->isAtomic())
    return false;

  return stringImplContentEqual(a, b);
}

template <typename CharType>
inline bool equalInternal(const StringImpl* a,
                          const CharType* b,
                          unsigned length) {
  if (!a)
    return !b;
  if (!b)
    return false;

  if (a->length() != length)
    return false;
  if (a->is8Bit())
    return equal(a->characters8(), b, length);
  return equal(a->characters16(), b, length);
}

bool equal(const StringImpl* a, const LChar* b, unsigned length) {
  return equalInternal(a, b, length);
}

bool equal(const StringImpl* a, const UChar* b, unsigned length) {
  return equalInternal(a, b, length);
}

bool equal(const StringImpl* a, const LChar* b) {
  if (!a)
    return !b;
  if (!b)
    return !a;

  unsigned length = a->length();

  if (a->is8Bit()) {
    const LChar* aPtr = a->characters8();
    for (unsigned i = 0; i != length; ++i) {
      LChar bc = b[i];
      LChar ac = aPtr[i];
      if (!bc)
        return false;
      if (ac != bc)
        return false;
    }

    return !b[length];
  }

  const UChar* aPtr = a->characters16();
  for (unsigned i = 0; i != length; ++i) {
    LChar bc = b[i];
    if (!bc)
      return false;
    if (aPtr[i] != bc)
      return false;
  }

  return !b[length];
}

bool equalNonNull(const StringImpl* a, const StringImpl* b) {
  ASSERT(a && b);
  if (a == b)
    return true;

  return stringImplContentEqual(a, b);
}

bool equalIgnoringCase(const StringImpl* a, const StringImpl* b) {
  if (a == b)
    return true;
  if (!a || !b)
    return false;

  return CaseFoldingHash::equal(a, b);
}

bool equalIgnoringCase(const StringImpl* a, const LChar* b) {
  if (!a)
    return !b;
  if (!b)
    return !a;

  unsigned length = a->length();

  // Do a faster loop for the case where all the characters are ASCII.
  UChar ored = 0;
  bool equal = true;
  if (a->is8Bit()) {
    const LChar* as = a->characters8();
    for (unsigned i = 0; i != length; ++i) {
      LChar bc = b[i];
      if (!bc)
        return false;
      UChar ac = as[i];
      ored |= ac;
      equal = equal && (toASCIILower(ac) == toASCIILower(bc));
    }

    // Do a slower implementation for cases that include non-ASCII characters.
    if (ored & ~0x7F) {
      equal = true;
      for (unsigned i = 0; i != length; ++i)
        equal = equal && (foldCase(as[i]) == foldCase(b[i]));
    }

    return equal && !b[length];
  }

  const UChar* as = a->characters16();
  for (unsigned i = 0; i != length; ++i) {
    LChar bc = b[i];
    if (!bc)
      return false;
    UChar ac = as[i];
    ored |= ac;
    equal = equal && (toASCIILower(ac) == toASCIILower(bc));
  }

  // Do a slower implementation for cases that include non-ASCII characters.
  if (ored & ~0x7F) {
    equal = true;
    for (unsigned i = 0; i != length; ++i) {
      equal = equal && (foldCase(as[i]) == foldCase(b[i]));
    }
  }

  return equal && !b[length];
}

bool equalIgnoringCaseNonNull(const StringImpl* a, const StringImpl* b) {
  ASSERT(a && b);
  if (a == b)
    return true;

  unsigned length = a->length();
  if (length != b->length())
    return false;

  if (a->is8Bit()) {
    if (b->is8Bit())
      return equalIgnoringCase(a->characters8(), b->characters8(), length);

    return equalIgnoringCase(b->characters16(), a->characters8(), length);
  }

  if (b->is8Bit())
    return equalIgnoringCase(a->characters16(), b->characters8(), length);

  return equalIgnoringCase(a->characters16(), b->characters16(), length);
}

bool equalIgnoringNullity(StringImpl* a, StringImpl* b) {
  if (!a && b && !b->length())
    return true;
  if (!b && a && !a->length())
    return true;
  return equal(a, b);
}

size_t StringImpl::sizeInBytes() const {
  size_t size = length();
  if (!is8Bit())
    size *= 2;
  return size + sizeof(*this);
}

}  // namespace WTF
