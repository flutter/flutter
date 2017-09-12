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

#ifndef SKY_ENGINE_WTF_HASHSET_H_
#define SKY_ENGINE_WTF_HASHSET_H_

#include "flutter/sky/engine/wtf/DefaultAllocator.h"
#include "flutter/sky/engine/wtf/HashTable.h"

namespace WTF {

struct IdentityExtractor;

// Note: empty or deleted values are not allowed, using them may lead to
// undefined behavior. For pointer valuess this means that null pointers are not
// allowed unless you supply custom traits.
template <typename ValueArg,
          typename HashArg = typename DefaultHash<ValueArg>::Hash,
          typename TraitsArg = HashTraits<ValueArg>,
          typename Allocator = DefaultAllocator>
class HashSet {
  WTF_USE_ALLOCATOR(HashSet, Allocator);

 private:
  typedef HashArg HashFunctions;
  typedef TraitsArg ValueTraits;
  typedef typename ValueTraits::PeekInType ValuePeekInType;
  typedef typename ValueTraits::PassInType ValuePassInType;
  typedef typename ValueTraits::PassOutType ValuePassOutType;

 public:
  typedef typename ValueTraits::TraitType ValueType;

 private:
  typedef HashTable<ValueType,
                    ValueType,
                    IdentityExtractor,
                    HashFunctions,
                    ValueTraits,
                    ValueTraits,
                    Allocator>
      HashTableType;

 public:
  typedef HashTableConstIteratorAdapter<HashTableType, ValueTraits> iterator;
  typedef HashTableConstIteratorAdapter<HashTableType, ValueTraits>
      const_iterator;
  typedef typename HashTableType::AddResult AddResult;

  void swap(HashSet& ref) { m_impl.swap(ref.m_impl); }

  void swap(typename Allocator::template OtherType<HashSet>::Type other) {
    HashSet& ref = Allocator::getOther(other);
    m_impl.swap(ref.m_impl);
  }

  unsigned size() const;
  unsigned capacity() const;
  bool isEmpty() const;

  iterator begin() const;
  iterator end() const;

  iterator find(ValuePeekInType) const;
  bool contains(ValuePeekInType) const;

  // An alternate version of find() that finds the object by hashing and
  // comparing with some other type, to avoid the cost of type conversion.
  // HashTranslator must have the following function members:
  //   static unsigned hash(const T&);
  //   static bool equal(const ValueType&, const T&);
  template <typename HashTranslator, typename T>
  iterator find(const T&) const;
  template <typename HashTranslator, typename T>
  bool contains(const T&) const;

  // The return value is a pair of an iterator to the new value's location,
  // and a bool that is true if an new entry was added.
  AddResult add(ValuePassInType);

  // An alternate version of add() that finds the object by hashing and
  // comparing with some other type, to avoid the cost of type conversion if the
  // object is already in the table. HashTranslator must have the following
  // function members:
  //   static unsigned hash(const T&);
  //   static bool equal(const ValueType&, const T&);
  //   static translate(ValueType&, const T&, unsigned hashCode);
  template <typename HashTranslator, typename T>
  AddResult add(const T&);

  void remove(ValuePeekInType);
  void remove(iterator);
  void clear();
  template <typename Collection>
  void removeAll(const Collection& toBeRemoved) {
    WTF::removeAll(*this, toBeRemoved);
  }

  static bool isValidValue(ValuePeekInType);

  ValuePassOutType take(iterator);
  ValuePassOutType take(ValuePeekInType);
  ValuePassOutType takeAny();

 private:
  HashTableType m_impl;
};

struct IdentityExtractor {
  template <typename T>
  static const T& extract(const T& t) {
    return t;
  }
};

template <typename Translator>
struct HashSetTranslatorAdapter {
  template <typename T>
  static unsigned hash(const T& key) {
    return Translator::hash(key);
  }
  template <typename T, typename U>
  static bool equal(const T& a, const U& b) {
    return Translator::equal(a, b);
  }
  template <typename T, typename U>
  static void translate(T& location,
                        const U& key,
                        const U&,
                        unsigned hashCode) {
    Translator::translate(location, key, hashCode);
  }
};

template <typename T, typename U, typename V, typename W>
inline unsigned HashSet<T, U, V, W>::size() const {
  return m_impl.size();
}

template <typename T, typename U, typename V, typename W>
inline unsigned HashSet<T, U, V, W>::capacity() const {
  return m_impl.capacity();
}

template <typename T, typename U, typename V, typename W>
inline bool HashSet<T, U, V, W>::isEmpty() const {
  return m_impl.isEmpty();
}

template <typename T, typename U, typename V, typename W>
inline typename HashSet<T, U, V, W>::iterator HashSet<T, U, V, W>::begin()
    const {
  return m_impl.begin();
}

template <typename T, typename U, typename V, typename W>
inline typename HashSet<T, U, V, W>::iterator HashSet<T, U, V, W>::end() const {
  return m_impl.end();
}

template <typename T, typename U, typename V, typename W>
inline typename HashSet<T, U, V, W>::iterator HashSet<T, U, V, W>::find(
    ValuePeekInType value) const {
  return m_impl.find(value);
}

template <typename Value,
          typename HashFunctions,
          typename Traits,
          typename Allocator>
inline bool HashSet<Value, HashFunctions, Traits, Allocator>::contains(
    ValuePeekInType value) const {
  return m_impl.contains(value);
}

template <typename Value,
          typename HashFunctions,
          typename Traits,
          typename Allocator>
template <typename HashTranslator, typename T>
typename HashSet<Value, HashFunctions, Traits, Allocator>::
    iterator inline HashSet<Value, HashFunctions, Traits, Allocator>::find(
        const T& value) const {
  return m_impl.template find<HashSetTranslatorAdapter<HashTranslator>>(value);
}

template <typename Value,
          typename HashFunctions,
          typename Traits,
          typename Allocator>
template <typename HashTranslator, typename T>
inline bool HashSet<Value, HashFunctions, Traits, Allocator>::contains(
    const T& value) const {
  return m_impl.template contains<HashSetTranslatorAdapter<HashTranslator>>(
      value);
}

template <typename T, typename U, typename V, typename W>
inline typename HashSet<T, U, V, W>::AddResult HashSet<T, U, V, W>::add(
    ValuePassInType value) {
  return m_impl.add(value);
}

template <typename Value,
          typename HashFunctions,
          typename Traits,
          typename Allocator>
template <typename HashTranslator, typename T>
inline typename HashSet<Value, HashFunctions, Traits, Allocator>::AddResult
HashSet<Value, HashFunctions, Traits, Allocator>::add(const T& value) {
  return m_impl
      .template addPassingHashCode<HashSetTranslatorAdapter<HashTranslator>>(
          value, value);
}

template <typename T, typename U, typename V, typename W>
inline void HashSet<T, U, V, W>::remove(iterator it) {
  m_impl.remove(it.m_impl);
}

template <typename T, typename U, typename V, typename W>
inline void HashSet<T, U, V, W>::remove(ValuePeekInType value) {
  remove(find(value));
}

template <typename T, typename U, typename V, typename W>
inline void HashSet<T, U, V, W>::clear() {
  m_impl.clear();
}

template <typename T, typename U, typename V, typename W>
inline bool HashSet<T, U, V, W>::isValidValue(ValuePeekInType value) {
  if (ValueTraits::isDeletedValue(value))
    return false;

  if (HashFunctions::safeToCompareToEmptyOrDeleted) {
    if (value == ValueTraits::emptyValue())
      return false;
  } else {
    if (isHashTraitsEmptyValue<ValueTraits>(value))
      return false;
  }

  return true;
}

template <typename T, typename U, typename V, typename W>
inline typename HashSet<T, U, V, W>::ValuePassOutType HashSet<T, U, V, W>::take(
    iterator it) {
  if (it == end())
    return ValueTraits::emptyValue();

  ValuePassOutType result = ValueTraits::passOut(const_cast<ValueType&>(*it));
  remove(it);

  return result;
}

template <typename T, typename U, typename V, typename W>
inline typename HashSet<T, U, V, W>::ValuePassOutType HashSet<T, U, V, W>::take(
    ValuePeekInType value) {
  return take(find(value));
}

template <typename T, typename U, typename V, typename W>
inline typename HashSet<T, U, V, W>::ValuePassOutType
HashSet<T, U, V, W>::takeAny() {
  return take(begin());
}

template <typename C, typename W>
inline void copyToVector(const C& collection, W& vector) {
  typedef typename C::const_iterator iterator;

  vector.resize(collection.size());

  iterator it = collection.begin();
  iterator end = collection.end();
  for (unsigned i = 0; it != end; ++it, ++i)
    vector[i] = *it;
}

}  // namespace WTF

using WTF::HashSet;

#endif  // SKY_ENGINE_WTF_HASHSET_H_
