/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_TEXT_STRINGCONCATENATE_H_
#define SKY_ENGINE_WTF_TEXT_STRINGCONCATENATE_H_

#include <string.h>

#ifndef WTFString_h
#include "flutter/sky/engine/wtf/text/AtomicString.h"
#endif

// This macro is helpful for testing how many intermediate Strings are created
// while evaluating an expression containing operator+.
#ifndef WTF_STRINGTYPEADAPTER_COPIED_WTF_STRING
#define WTF_STRINGTYPEADAPTER_COPIED_WTF_STRING() ((void)0)
#endif

namespace WTF {

template <typename StringType>
class StringTypeAdapter {};

template <>
class StringTypeAdapter<char> {
 public:
  StringTypeAdapter<char>(char buffer) : m_buffer(buffer) {}

  unsigned length() { return 1; }

  bool is8Bit() { return true; }

  void writeTo(LChar* destination) { *destination = m_buffer; }

  void writeTo(UChar* destination) { *destination = m_buffer; }

 private:
  unsigned char m_buffer;
};

template <>
class StringTypeAdapter<LChar> {
 public:
  StringTypeAdapter<LChar>(LChar buffer) : m_buffer(buffer) {}

  unsigned length() { return 1; }

  bool is8Bit() { return true; }

  void writeTo(LChar* destination) { *destination = m_buffer; }

  void writeTo(UChar* destination) { *destination = m_buffer; }

 private:
  LChar m_buffer;
};

template <>
class StringTypeAdapter<UChar> {
 public:
  StringTypeAdapter<UChar>(UChar buffer) : m_buffer(buffer) {}

  unsigned length() { return 1; }

  bool is8Bit() { return m_buffer <= 0xff; }

  void writeTo(LChar* destination) {
    ASSERT(is8Bit());
    *destination = static_cast<LChar>(m_buffer);
  }

  void writeTo(UChar* destination) { *destination = m_buffer; }

 private:
  UChar m_buffer;
};

template <>
class StringTypeAdapter<char*> {
 public:
  StringTypeAdapter<char*>(char* buffer)
      : m_buffer(buffer), m_length(strlen(buffer)) {}

  unsigned length() { return m_length; }

  bool is8Bit() { return true; }

  void writeTo(LChar* destination) {
    for (unsigned i = 0; i < m_length; ++i)
      destination[i] = static_cast<LChar>(m_buffer[i]);
  }

  void writeTo(UChar* destination) {
    for (unsigned i = 0; i < m_length; ++i) {
      unsigned char c = m_buffer[i];
      destination[i] = c;
    }
  }

 private:
  const char* m_buffer;
  unsigned m_length;
};

template <>
class StringTypeAdapter<LChar*> {
 public:
  StringTypeAdapter<LChar*>(LChar* buffer)
      : m_buffer(buffer), m_length(strlen(reinterpret_cast<char*>(buffer))) {}

  unsigned length() { return m_length; }

  bool is8Bit() { return true; }

  void writeTo(LChar* destination) {
    memcpy(destination, m_buffer, m_length * sizeof(LChar));
  }

  void writeTo(UChar* destination) {
    StringImpl::copyChars(destination, m_buffer, m_length);
  }

 private:
  const LChar* m_buffer;
  unsigned m_length;
};

template <>
class StringTypeAdapter<const UChar*> {
 public:
  StringTypeAdapter<const UChar*>(const UChar* buffer) : m_buffer(buffer) {
    size_t len = 0;
    while (m_buffer[len] != UChar(0))
      ++len;

    RELEASE_ASSERT(len <= std::numeric_limits<unsigned>::max());

    m_length = len;
  }

  unsigned length() { return m_length; }

  bool is8Bit() { return false; }

  NO_RETURN_DUE_TO_CRASH void writeTo(LChar*) { RELEASE_ASSERT(false); }

  void writeTo(UChar* destination) {
    memcpy(destination, m_buffer, m_length * sizeof(UChar));
  }

 private:
  const UChar* m_buffer;
  unsigned m_length;
};

template <>
class StringTypeAdapter<const char*> {
 public:
  StringTypeAdapter<const char*>(const char* buffer)
      : m_buffer(buffer), m_length(strlen(buffer)) {}

  unsigned length() { return m_length; }

  bool is8Bit() { return true; }

  void writeTo(LChar* destination) {
    memcpy(destination, m_buffer,
           static_cast<size_t>(m_length) * sizeof(LChar));
  }

  void writeTo(UChar* destination) {
    for (unsigned i = 0; i < m_length; ++i) {
      unsigned char c = m_buffer[i];
      destination[i] = c;
    }
  }

 private:
  const char* m_buffer;
  unsigned m_length;
};

template <>
class StringTypeAdapter<const LChar*> {
 public:
  StringTypeAdapter<const LChar*>(const LChar* buffer)
      : m_buffer(buffer),
        m_length(strlen(reinterpret_cast<const char*>(buffer))) {}

  unsigned length() { return m_length; }

  bool is8Bit() { return true; }

  void writeTo(LChar* destination) {
    memcpy(destination, m_buffer,
           static_cast<size_t>(m_length) * sizeof(LChar));
  }

  void writeTo(UChar* destination) {
    StringImpl::copyChars(destination, m_buffer, m_length);
  }

 private:
  const LChar* m_buffer;
  unsigned m_length;
};

template <>
class StringTypeAdapter<Vector<char>> {
 public:
  StringTypeAdapter<Vector<char>>(const Vector<char>& buffer)
      : m_buffer(buffer) {}

  size_t length() { return m_buffer.size(); }

  bool is8Bit() { return true; }

  void writeTo(LChar* destination) {
    for (size_t i = 0; i < m_buffer.size(); ++i)
      destination[i] = static_cast<unsigned char>(m_buffer[i]);
  }

  void writeTo(UChar* destination) {
    for (size_t i = 0; i < m_buffer.size(); ++i)
      destination[i] = static_cast<unsigned char>(m_buffer[i]);
  }

 private:
  const Vector<char>& m_buffer;
};

template <>
class StringTypeAdapter<Vector<LChar>> {
 public:
  StringTypeAdapter<Vector<LChar>>(const Vector<LChar>& buffer)
      : m_buffer(buffer) {}

  size_t length() { return m_buffer.size(); }

  bool is8Bit() { return true; }

  void writeTo(LChar* destination) {
    for (size_t i = 0; i < m_buffer.size(); ++i)
      destination[i] = m_buffer[i];
  }

  void writeTo(UChar* destination) {
    for (size_t i = 0; i < m_buffer.size(); ++i)
      destination[i] = m_buffer[i];
  }

 private:
  const Vector<LChar>& m_buffer;
};

template <>
class StringTypeAdapter<String> {
 public:
  StringTypeAdapter<String>(const String& string) : m_buffer(string) {}

  unsigned length() { return m_buffer.length(); }

  bool is8Bit() { return m_buffer.isNull() || m_buffer.is8Bit(); }

  void writeTo(LChar* destination) {
    unsigned length = m_buffer.length();

    ASSERT(is8Bit());
    const LChar* data = m_buffer.characters8();
    for (unsigned i = 0; i < length; ++i)
      destination[i] = data[i];

    WTF_STRINGTYPEADAPTER_COPIED_WTF_STRING();
  }

  void writeTo(UChar* destination) {
    unsigned length = m_buffer.length();

    if (is8Bit()) {
      const LChar* data = m_buffer.characters8();
      for (unsigned i = 0; i < length; ++i)
        destination[i] = data[i];
    } else {
      const UChar* data = m_buffer.characters16();
      for (unsigned i = 0; i < length; ++i)
        destination[i] = data[i];
    }

    WTF_STRINGTYPEADAPTER_COPIED_WTF_STRING();
  }

 private:
  const String& m_buffer;
};

template <>
class StringTypeAdapter<AtomicString> {
 public:
  StringTypeAdapter<AtomicString>(const AtomicString& string)
      : m_adapter(string.string()) {}

  unsigned length() { return m_adapter.length(); }

  bool is8Bit() { return m_adapter.is8Bit(); }

  void writeTo(LChar* destination) { m_adapter.writeTo(destination); }
  void writeTo(UChar* destination) { m_adapter.writeTo(destination); }

 private:
  StringTypeAdapter<String> m_adapter;
};

inline void sumWithOverflow(unsigned& total, unsigned addend, bool& overflow) {
  unsigned oldTotal = total;
  total = oldTotal + addend;
  if (total < oldTotal)
    overflow = true;
}

template <typename StringType1, typename StringType2>
PassRefPtr<StringImpl> makeString(StringType1 string1, StringType2 string2) {
  StringTypeAdapter<StringType1> adapter1(string1);
  StringTypeAdapter<StringType2> adapter2(string2);

  bool overflow = false;
  unsigned length = adapter1.length();
  sumWithOverflow(length, adapter2.length(), overflow);
  if (overflow)
    return nullptr;

  if (adapter1.is8Bit() && adapter2.is8Bit()) {
    LChar* buffer;
    RefPtr<StringImpl> resultImpl =
        StringImpl::createUninitialized(length, buffer);
    if (!resultImpl)
      return nullptr;

    LChar* result = buffer;
    adapter1.writeTo(result);
    result += adapter1.length();
    adapter2.writeTo(result);

    return resultImpl.release();
  }

  UChar* buffer;
  RefPtr<StringImpl> resultImpl =
      StringImpl::createUninitialized(length, buffer);
  if (!resultImpl)
    return nullptr;

  UChar* result = buffer;
  adapter1.writeTo(result);
  result += adapter1.length();
  adapter2.writeTo(result);

  return resultImpl.release();
}

}  // namespace WTF

#include "flutter/sky/engine/wtf/text/StringOperators.h"
#endif  // SKY_ENGINE_WTF_TEXT_STRINGCONCATENATE_H_
