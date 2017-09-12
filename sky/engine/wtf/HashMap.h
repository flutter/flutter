/*
 * Copyright (C) 2005, 2006, 2007, 2008, 2011 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_HASHMAP_H_
#define SKY_ENGINE_WTF_HASHMAP_H_

#include "flutter/sky/engine/wtf/DefaultAllocator.h"
#include "flutter/sky/engine/wtf/HashTable.h"

namespace WTF {

template <typename KeyTraits, typename MappedTraits>
struct HashMapValueTraits;

template <typename T>
struct ReferenceTypeMaker {
  typedef T& ReferenceType;
};
template <typename T>
struct ReferenceTypeMaker<T&> {
  typedef T& ReferenceType;
};

struct KeyValuePairKeyExtractor {
  template <typename T>
  static const typename T::KeyType& extract(const T& p) {
    return p.key;
  }
};

// Note: empty or deleted key values are not allowed, using them may lead to
// undefined behavior. For pointer keys this means that null pointers are not
// allowed unless you supply custom key traits.
template <typename KeyArg,
          typename MappedArg,
          typename HashArg = typename DefaultHash<KeyArg>::Hash,
          typename KeyTraitsArg = HashTraits<KeyArg>,
          typename MappedTraitsArg = HashTraits<MappedArg>,
          typename Allocator = DefaultAllocator>
class HashMap {
  WTF_USE_ALLOCATOR(HashMap, Allocator);

 private:
  typedef KeyTraitsArg KeyTraits;
  typedef MappedTraitsArg MappedTraits;
  typedef HashMapValueTraits<KeyTraits, MappedTraits> ValueTraits;

 public:
  typedef typename KeyTraits::TraitType KeyType;
  typedef typename KeyTraits::PassInType KeyPassInType;
  typedef const typename KeyTraits::PeekInType& KeyPeekInType;
  typedef typename MappedTraits::TraitType MappedType;
  typedef typename ValueTraits::TraitType ValueType;

 private:
  typedef typename MappedTraits::PassInType MappedPassInType;
  typedef typename MappedTraits::PassOutType MappedPassOutType;
  typedef typename MappedTraits::PeekOutType MappedPeekType;

  typedef typename ReferenceTypeMaker<MappedPassInType>::ReferenceType
      MappedPassInReferenceType;

  typedef HashArg HashFunctions;

  typedef HashTable<KeyType,
                    ValueType,
                    KeyValuePairKeyExtractor,
                    HashFunctions,
                    ValueTraits,
                    KeyTraits,
                    Allocator>
      HashTableType;

  class HashMapKeysProxy;
  class HashMapValuesProxy;

 public:
  typedef HashTableIteratorAdapter<HashTableType, ValueType> iterator;
  typedef HashTableConstIteratorAdapter<HashTableType, ValueType>
      const_iterator;
  typedef typename HashTableType::AddResult AddResult;

 public:
  void swap(HashMap& ref) { m_impl.swap(ref.m_impl); }

  void swap(typename Allocator::template OtherType<HashMap>::Type other) {
    HashMap& ref = Allocator::getOther(other);
    m_impl.swap(ref.m_impl);
  }

  unsigned size() const;
  unsigned capacity() const;
  bool isEmpty() const;

  // iterators iterate over pairs of keys and values
  iterator begin();
  iterator end();
  const_iterator begin() const;
  const_iterator end() const;

  HashMapKeysProxy& keys() { return static_cast<HashMapKeysProxy&>(*this); }
  const HashMapKeysProxy& keys() const {
    return static_cast<const HashMapKeysProxy&>(*this);
  }

  HashMapValuesProxy& values() {
    return static_cast<HashMapValuesProxy&>(*this);
  }
  const HashMapValuesProxy& values() const {
    return static_cast<const HashMapValuesProxy&>(*this);
  }

  iterator find(KeyPeekInType);
  const_iterator find(KeyPeekInType) const;
  bool contains(KeyPeekInType) const;
  MappedPeekType get(KeyPeekInType) const;

  // replaces value but not key if key is already present
  // return value is a pair of the iterator to the key location,
  // and a boolean that's true if a new value was actually added
  AddResult set(KeyPassInType, MappedPassInType);

  // does nothing if key is already present
  // return value is a pair of the iterator to the key location,
  // and a boolean that's true if a new value was actually added
  AddResult add(KeyPassInType, MappedPassInType);

  void remove(KeyPeekInType);
  void remove(iterator);
  void clear();
  template <typename Collection>
  void removeAll(const Collection& toBeRemoved) {
    WTF::removeAll(*this, toBeRemoved);
  }

  MappedPassOutType take(
      KeyPeekInType);  // efficient combination of get with remove

  // An alternate version of find() that finds the object by hashing and
  // comparing with some other type, to avoid the cost of type conversion.
  // HashTranslator must have the following function members:
  //   static unsigned hash(const T&);
  //   static bool equal(const ValueType&, const T&);
  template <typename HashTranslator, typename T>
  iterator find(const T&);
  template <typename HashTranslator, typename T>
  const_iterator find(const T&) const;
  template <typename HashTranslator, typename T>
  bool contains(const T&) const;

  // An alternate version of add() that finds the object by hashing and
  // comparing with some other type, to avoid the cost of type conversion if the
  // object is already in the table. HashTranslator must have the following
  // function members:
  //   static unsigned hash(const T&);
  //   static bool equal(const ValueType&, const T&);
  //   static translate(ValueType&, const T&, unsigned hashCode);
  template <typename HashTranslator, typename T>
  AddResult add(const T&, MappedPassInType);

  static bool isValidKey(KeyPeekInType);

 private:
  AddResult inlineAdd(KeyPassInType, MappedPassInReferenceType);

  HashTableType m_impl;
};

template <typename KeyArg,
          typename MappedArg,
          typename HashArg,
          typename KeyTraitsArg,
          typename MappedTraitsArg,
          typename Allocator>
class HashMap<KeyArg,
              MappedArg,
              HashArg,
              KeyTraitsArg,
              MappedTraitsArg,
              Allocator>::HashMapKeysProxy : private HashMap<KeyArg,
                                                             MappedArg,
                                                             HashArg,
                                                             KeyTraitsArg,
                                                             MappedTraitsArg,
                                                             Allocator> {
 public:
  typedef HashMap<KeyArg,
                  MappedArg,
                  HashArg,
                  KeyTraitsArg,
                  MappedTraitsArg,
                  Allocator>
      HashMapType;
  typedef typename HashMapType::iterator::Keys iterator;
  typedef typename HashMapType::const_iterator::Keys const_iterator;

  iterator begin() { return HashMapType::begin().keys(); }

  iterator end() { return HashMapType::end().keys(); }

  const_iterator begin() const { return HashMapType::begin().keys(); }

  const_iterator end() const { return HashMapType::end().keys(); }

 private:
  friend class HashMap;

  // These are intentionally not implemented.
  HashMapKeysProxy();
  HashMapKeysProxy(const HashMapKeysProxy&);
  HashMapKeysProxy& operator=(const HashMapKeysProxy&);
  ~HashMapKeysProxy();
};

template <typename KeyArg,
          typename MappedArg,
          typename HashArg,
          typename KeyTraitsArg,
          typename MappedTraitsArg,
          typename Allocator>
class HashMap<KeyArg,
              MappedArg,
              HashArg,
              KeyTraitsArg,
              MappedTraitsArg,
              Allocator>::HashMapValuesProxy : private HashMap<KeyArg,
                                                               MappedArg,
                                                               HashArg,
                                                               KeyTraitsArg,
                                                               MappedTraitsArg,
                                                               Allocator> {
 public:
  typedef HashMap<KeyArg,
                  MappedArg,
                  HashArg,
                  KeyTraitsArg,
                  MappedTraitsArg,
                  Allocator>
      HashMapType;
  typedef typename HashMapType::iterator::Values iterator;
  typedef typename HashMapType::const_iterator::Values const_iterator;

  iterator begin() { return HashMapType::begin().values(); }

  iterator end() { return HashMapType::end().values(); }

  const_iterator begin() const { return HashMapType::begin().values(); }

  const_iterator end() const { return HashMapType::end().values(); }

 private:
  friend class HashMap;

  // These are intentionally not implemented.
  HashMapValuesProxy();
  HashMapValuesProxy(const HashMapValuesProxy&);
  HashMapValuesProxy& operator=(const HashMapValuesProxy&);
  ~HashMapValuesProxy();
};

template <typename KeyTraits, typename MappedTraits>
struct HashMapValueTraits : KeyValuePairHashTraits<KeyTraits, MappedTraits> {
  static const bool hasIsEmptyValueFunction = true;
  static bool isEmptyValue(
      const typename KeyValuePairHashTraits<KeyTraits, MappedTraits>::TraitType&
          value) {
    return isHashTraitsEmptyValue<KeyTraits>(value.key);
  }
};

template <typename ValueTraits, typename HashFunctions>
struct HashMapTranslator {
  template <typename T>
  static unsigned hash(const T& key) {
    return HashFunctions::hash(key);
  }
  template <typename T, typename U>
  static bool equal(const T& a, const U& b) {
    return HashFunctions::equal(a, b);
  }
  template <typename T, typename U, typename V>
  static void translate(T& location, const U& key, const V& mapped) {
    location.key = key;
    ValueTraits::ValueTraits::store(mapped, location.value);
  }
};

template <typename ValueTraits, typename Translator>
struct HashMapTranslatorAdapter {
  template <typename T>
  static unsigned hash(const T& key) {
    return Translator::hash(key);
  }
  template <typename T, typename U>
  static bool equal(const T& a, const U& b) {
    return Translator::equal(a, b);
  }
  template <typename T, typename U, typename V>
  static void translate(T& location,
                        const U& key,
                        const V& mapped,
                        unsigned hashCode) {
    Translator::translate(location.key, key, hashCode);
    ValueTraits::ValueTraits::store(mapped, location.value);
  }
};

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline unsigned HashMap<T, U, V, W, X, Y>::size() const {
  return m_impl.size();
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline unsigned HashMap<T, U, V, W, X, Y>::capacity() const {
  return m_impl.capacity();
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline bool HashMap<T, U, V, W, X, Y>::isEmpty() const {
  return m_impl.isEmpty();
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline typename HashMap<T, U, V, W, X, Y>::iterator
HashMap<T, U, V, W, X, Y>::begin() {
  return m_impl.begin();
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline typename HashMap<T, U, V, W, X, Y>::iterator
HashMap<T, U, V, W, X, Y>::end() {
  return m_impl.end();
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline typename HashMap<T, U, V, W, X, Y>::const_iterator
HashMap<T, U, V, W, X, Y>::begin() const {
  return m_impl.begin();
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline typename HashMap<T, U, V, W, X, Y>::const_iterator
HashMap<T, U, V, W, X, Y>::end() const {
  return m_impl.end();
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline typename HashMap<T, U, V, W, X, Y>::iterator
HashMap<T, U, V, W, X, Y>::find(KeyPeekInType key) {
  return m_impl.find(key);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline typename HashMap<T, U, V, W, X, Y>::const_iterator
HashMap<T, U, V, W, X, Y>::find(KeyPeekInType key) const {
  return m_impl.find(key);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline bool HashMap<T, U, V, W, X, Y>::contains(KeyPeekInType key) const {
  return m_impl.contains(key);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
template <typename HashTranslator, typename TYPE>
inline typename HashMap<T, U, V, W, X, Y>::iterator
HashMap<T, U, V, W, X, Y>::find(const TYPE& value) {
  return m_impl
      .template find<HashMapTranslatorAdapter<ValueTraits, HashTranslator>>(
          value);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
template <typename HashTranslator, typename TYPE>
inline typename HashMap<T, U, V, W, X, Y>::const_iterator
HashMap<T, U, V, W, X, Y>::find(const TYPE& value) const {
  return m_impl
      .template find<HashMapTranslatorAdapter<ValueTraits, HashTranslator>>(
          value);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
template <typename HashTranslator, typename TYPE>
inline bool HashMap<T, U, V, W, X, Y>::contains(const TYPE& value) const {
  return m_impl
      .template contains<HashMapTranslatorAdapter<ValueTraits, HashTranslator>>(
          value);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
typename HashMap<T, U, V, W, X, Y>::AddResult
HashMap<T, U, V, W, X, Y>::inlineAdd(KeyPassInType key,
                                     MappedPassInReferenceType mapped) {
  return m_impl.template add<HashMapTranslator<ValueTraits, HashFunctions>>(
      key, mapped);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
typename HashMap<T, U, V, W, X, Y>::AddResult HashMap<T, U, V, W, X, Y>::set(
    KeyPassInType key,
    MappedPassInType mapped) {
  AddResult result = inlineAdd(key, mapped);
  if (!result.isNewEntry) {
    // The inlineAdd call above found an existing hash table entry; we need to
    // set the mapped value.
    MappedTraits::store(mapped, result.storedValue->value);
  }
  return result;
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
template <typename HashTranslator, typename TYPE>
typename HashMap<T, U, V, W, X, Y>::AddResult HashMap<T, U, V, W, X, Y>::add(
    const TYPE& key,
    MappedPassInType value) {
  return m_impl.template addPassingHashCode<
      HashMapTranslatorAdapter<ValueTraits, HashTranslator>>(key, value);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
typename HashMap<T, U, V, W, X, Y>::AddResult HashMap<T, U, V, W, X, Y>::add(
    KeyPassInType key,
    MappedPassInType mapped) {
  return inlineAdd(key, mapped);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
typename HashMap<T, U, V, W, X, Y>::MappedPeekType
HashMap<T, U, V, W, X, Y>::get(KeyPeekInType key) const {
  ValueType* entry = const_cast<HashTableType&>(m_impl).lookup(key);
  if (!entry)
    return MappedTraits::peek(MappedTraits::emptyValue());
  return MappedTraits::peek(entry->value);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline void HashMap<T, U, V, W, X, Y>::remove(iterator it) {
  m_impl.remove(it.m_impl);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline void HashMap<T, U, V, W, X, Y>::remove(KeyPeekInType key) {
  remove(find(key));
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline void HashMap<T, U, V, W, X, Y>::clear() {
  m_impl.clear();
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
typename HashMap<T, U, V, W, X, Y>::MappedPassOutType
HashMap<T, U, V, W, X, Y>::take(KeyPeekInType key) {
  iterator it = find(key);
  if (it == end())
    return MappedTraits::passOut(MappedTraits::emptyValue());
  MappedPassOutType result = MappedTraits::passOut(it->value);
  remove(it);
  return result;
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline bool HashMap<T, U, V, W, X, Y>::isValidKey(KeyPeekInType key) {
  if (KeyTraits::isDeletedValue(key))
    return false;

  if (HashFunctions::safeToCompareToEmptyOrDeleted) {
    if (key == KeyTraits::emptyValue())
      return false;
  } else {
    if (isHashTraitsEmptyValue<KeyTraits>(key))
      return false;
  }

  return true;
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
bool operator==(const HashMap<T, U, V, W, X, Y>& a,
                const HashMap<T, U, V, W, X, Y>& b) {
  if (a.size() != b.size())
    return false;

  typedef typename HashMap<T, U, V, W, X, Y>::const_iterator const_iterator;

  const_iterator aEnd = a.end();
  const_iterator bEnd = b.end();
  for (const_iterator it = a.begin(); it != aEnd; ++it) {
    const_iterator bPos = b.find(it->key);
    if (bPos == bEnd || it->value != bPos->value)
      return false;
  }

  return true;
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y>
inline bool operator!=(const HashMap<T, U, V, W, X, Y>& a,
                       const HashMap<T, U, V, W, X, Y>& b) {
  return !(a == b);
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y,
          typename Z>
inline void copyKeysToVector(const HashMap<T, U, V, W, X, Y>& collection,
                             Z& vector) {
  typedef typename HashMap<T, U, V, W, X, Y>::const_iterator::Keys iterator;

  vector.resize(collection.size());

  iterator it = collection.begin().keys();
  iterator end = collection.end().keys();
  for (unsigned i = 0; it != end; ++it, ++i)
    vector[i] = *it;
}

template <typename T,
          typename U,
          typename V,
          typename W,
          typename X,
          typename Y,
          typename Z>
inline void copyValuesToVector(const HashMap<T, U, V, W, X, Y>& collection,
                               Z& vector) {
  typedef typename HashMap<T, U, V, W, X, Y>::const_iterator::Values iterator;

  vector.resize(collection.size());

  iterator it = collection.begin().values();
  iterator end = collection.end().values();
  for (unsigned i = 0; it != end; ++it, ++i)
    vector[i] = *it;
}

}  // namespace WTF

using WTF::HashMap;

#endif  // SKY_ENGINE_WTF_HASHMAP_H_
