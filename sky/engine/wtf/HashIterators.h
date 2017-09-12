/*
 * Copyright (C) 2007 Apple Inc.  All rights reserved.
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

#ifndef SKY_ENGINE_WTF_HASHITERATORS_H_
#define SKY_ENGINE_WTF_HASHITERATORS_H_

namespace WTF {

template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableConstKeysIterator;
template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableConstValuesIterator;
template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableKeysIterator;
template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableValuesIterator;

template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableConstIteratorAdapter<HashTableType,
                                     KeyValuePair<KeyType, MappedType>> {
 private:
  typedef KeyValuePair<KeyType, MappedType> ValueType;

 public:
  typedef HashTableConstKeysIterator<HashTableType, KeyType, MappedType> Keys;
  typedef HashTableConstValuesIterator<HashTableType, KeyType, MappedType>
      Values;

  HashTableConstIteratorAdapter() {}
  HashTableConstIteratorAdapter(
      const typename HashTableType::const_iterator& impl)
      : m_impl(impl) {}

  const ValueType* get() const { return (const ValueType*)m_impl.get(); }
  const ValueType& operator*() const { return *get(); }
  const ValueType* operator->() const { return get(); }

  HashTableConstIteratorAdapter& operator++() {
    ++m_impl;
    return *this;
  }
  // postfix ++ intentionally omitted

  Keys keys() { return Keys(*this); }
  Values values() { return Values(*this); }

  typename HashTableType::const_iterator m_impl;
};

template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableIteratorAdapter<HashTableType,
                                KeyValuePair<KeyType, MappedType>> {
 private:
  typedef KeyValuePair<KeyType, MappedType> ValueType;

 public:
  typedef HashTableKeysIterator<HashTableType, KeyType, MappedType> Keys;
  typedef HashTableValuesIterator<HashTableType, KeyType, MappedType> Values;

  HashTableIteratorAdapter() {}
  HashTableIteratorAdapter(const typename HashTableType::iterator& impl)
      : m_impl(impl) {}

  ValueType* get() const { return (ValueType*)m_impl.get(); }
  ValueType& operator*() const { return *get(); }
  ValueType* operator->() const { return get(); }

  HashTableIteratorAdapter& operator++() {
    ++m_impl;
    return *this;
  }
  // postfix ++ intentionally omitted

  operator HashTableConstIteratorAdapter<HashTableType, ValueType>() {
    typename HashTableType::const_iterator i = m_impl;
    return i;
  }

  Keys keys() { return Keys(*this); }
  Values values() { return Values(*this); }

  typename HashTableType::iterator m_impl;
};

template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableConstKeysIterator {
 private:
  typedef HashTableConstIteratorAdapter<HashTableType,
                                        KeyValuePair<KeyType, MappedType>>
      ConstIterator;

 public:
  HashTableConstKeysIterator(const ConstIterator& impl) : m_impl(impl) {}

  const KeyType* get() const { return &(m_impl.get()->key); }
  const KeyType& operator*() const { return *get(); }
  const KeyType* operator->() const { return get(); }

  HashTableConstKeysIterator& operator++() {
    ++m_impl;
    return *this;
  }
  // postfix ++ intentionally omitted

  ConstIterator m_impl;
};

template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableConstValuesIterator {
 private:
  typedef HashTableConstIteratorAdapter<HashTableType,
                                        KeyValuePair<KeyType, MappedType>>
      ConstIterator;

 public:
  HashTableConstValuesIterator(const ConstIterator& impl) : m_impl(impl) {}

  const MappedType* get() const { return &(m_impl.get()->value); }
  const MappedType& operator*() const { return *get(); }
  const MappedType* operator->() const { return get(); }

  HashTableConstValuesIterator& operator++() {
    ++m_impl;
    return *this;
  }
  // postfix ++ intentionally omitted

  ConstIterator m_impl;
};

template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableKeysIterator {
 private:
  typedef HashTableIteratorAdapter<HashTableType,
                                   KeyValuePair<KeyType, MappedType>>
      Iterator;
  typedef HashTableConstIteratorAdapter<HashTableType,
                                        KeyValuePair<KeyType, MappedType>>
      ConstIterator;

 public:
  HashTableKeysIterator(const Iterator& impl) : m_impl(impl) {}

  KeyType* get() const { return &(m_impl.get()->key); }
  KeyType& operator*() const { return *get(); }
  KeyType* operator->() const { return get(); }

  HashTableKeysIterator& operator++() {
    ++m_impl;
    return *this;
  }
  // postfix ++ intentionally omitted

  operator HashTableConstKeysIterator<HashTableType, KeyType, MappedType>() {
    ConstIterator i = m_impl;
    return i;
  }

  Iterator m_impl;
};

template <typename HashTableType, typename KeyType, typename MappedType>
struct HashTableValuesIterator {
 private:
  typedef HashTableIteratorAdapter<HashTableType,
                                   KeyValuePair<KeyType, MappedType>>
      Iterator;
  typedef HashTableConstIteratorAdapter<HashTableType,
                                        KeyValuePair<KeyType, MappedType>>
      ConstIterator;

 public:
  HashTableValuesIterator(const Iterator& impl) : m_impl(impl) {}

  MappedType* get() const { return &(m_impl.get()->value); }
  MappedType& operator*() const { return *get(); }
  MappedType* operator->() const { return get(); }

  HashTableValuesIterator& operator++() {
    ++m_impl;
    return *this;
  }
  // postfix ++ intentionally omitted

  operator HashTableConstValuesIterator<HashTableType, KeyType, MappedType>() {
    ConstIterator i = m_impl;
    return i;
  }

  Iterator m_impl;
};

template <typename T, typename U, typename V>
inline bool operator==(const HashTableConstKeysIterator<T, U, V>& a,
                       const HashTableConstKeysIterator<T, U, V>& b) {
  return a.m_impl == b.m_impl;
}

template <typename T, typename U, typename V>
inline bool operator!=(const HashTableConstKeysIterator<T, U, V>& a,
                       const HashTableConstKeysIterator<T, U, V>& b) {
  return a.m_impl != b.m_impl;
}

template <typename T, typename U, typename V>
inline bool operator==(const HashTableConstValuesIterator<T, U, V>& a,
                       const HashTableConstValuesIterator<T, U, V>& b) {
  return a.m_impl == b.m_impl;
}

template <typename T, typename U, typename V>
inline bool operator!=(const HashTableConstValuesIterator<T, U, V>& a,
                       const HashTableConstValuesIterator<T, U, V>& b) {
  return a.m_impl != b.m_impl;
}

template <typename T, typename U, typename V>
inline bool operator==(const HashTableKeysIterator<T, U, V>& a,
                       const HashTableKeysIterator<T, U, V>& b) {
  return a.m_impl == b.m_impl;
}

template <typename T, typename U, typename V>
inline bool operator!=(const HashTableKeysIterator<T, U, V>& a,
                       const HashTableKeysIterator<T, U, V>& b) {
  return a.m_impl != b.m_impl;
}

template <typename T, typename U, typename V>
inline bool operator==(const HashTableValuesIterator<T, U, V>& a,
                       const HashTableValuesIterator<T, U, V>& b) {
  return a.m_impl == b.m_impl;
}

template <typename T, typename U, typename V>
inline bool operator!=(const HashTableValuesIterator<T, U, V>& a,
                       const HashTableValuesIterator<T, U, V>& b) {
  return a.m_impl != b.m_impl;
}

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_HASHITERATORS_H_
