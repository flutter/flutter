/*
 * Copyright (C) 2005, 2006, 2008 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_HASHCOUNTEDSET_H_
#define SKY_ENGINE_WTF_HASHCOUNTEDSET_H_

#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/HashMap.h"
#include "flutter/sky/engine/wtf/Vector.h"

namespace WTF {

// An unordered hash set that keeps track of how many times you added an
// item to the set. The iterators have fields ->key and ->value that return
// the set members and their counts, respectively.
template <typename Value,
          typename HashFunctions = typename DefaultHash<Value>::Hash,
          typename Traits = HashTraits<Value>,
          typename Allocator = DefaultAllocator>
class HashCountedSet {
  WTF_USE_ALLOCATOR(HashCountedSet, Allocator);

 private:
  typedef HashMap<Value,
                  unsigned,
                  HashFunctions,
                  Traits,
                  HashTraits<unsigned>,
                  Allocator>
      ImplType;

 public:
  typedef Value ValueType;
  typedef typename ImplType::iterator iterator;
  typedef typename ImplType::const_iterator const_iterator;
  typedef typename ImplType::AddResult AddResult;

  HashCountedSet() {}

  void swap(HashCountedSet& other) { m_impl.swap(other.m_impl); }

  unsigned size() const { return m_impl.size(); }
  unsigned capacity() const { return m_impl.capacity(); }
  bool isEmpty() const { return m_impl.isEmpty(); }

  // Iterators iterate over pairs of values (called key) and counts (called
  // value).
  iterator begin() { return m_impl.begin(); }
  iterator end() { return m_impl.end(); }
  const_iterator begin() const { return m_impl.begin(); }
  const_iterator end() const { return m_impl.end(); }

  iterator find(const ValueType& value) { return m_impl.find(value); }
  const_iterator find(const ValueType& value) const {
    return m_impl.find(value);
  }
  bool contains(const ValueType& value) const { return m_impl.contains(value); }
  unsigned count(const ValueType& value) const { return m_impl.get(value); }

  // Increases the count if an equal value is already present
  // the return value is a pair of an iterator to the new value's
  // location, and a bool that is true if an new entry was added.
  AddResult add(const ValueType&);

  // Reduces the count of the value, and removes it if count
  // goes down to zero, returns true if the value is removed.
  bool remove(const ValueType& value) { return remove(find(value)); }
  bool remove(iterator);

  // Removes the value, regardless of its count.
  void removeAll(const ValueType& value) { removeAll(find(value)); }
  void removeAll(iterator);

  // Clears the whole set.
  void clear() { m_impl.clear(); }

 private:
  ImplType m_impl;
};

template <typename T, typename U, typename V, typename W>
inline typename HashCountedSet<T, U, V, W>::AddResult
HashCountedSet<T, U, V, W>::add(const ValueType& value) {
  AddResult result = m_impl.add(value, 0);
  ++result.storedValue->value;
  return result;
}

template <typename T, typename U, typename V, typename W>
inline bool HashCountedSet<T, U, V, W>::remove(iterator it) {
  if (it == end())
    return false;

  unsigned oldVal = it->value;
  ASSERT(oldVal);
  unsigned newVal = oldVal - 1;
  if (newVal) {
    it->value = newVal;
    return false;
  }

  m_impl.remove(it);
  return true;
}

template <typename T, typename U, typename V, typename W>
inline void HashCountedSet<T, U, V, W>::removeAll(iterator it) {
  if (it == end())
    return;

  m_impl.remove(it);
}

template <typename T, typename U, typename V, typename W, typename VectorType>
inline void copyToVector(const HashCountedSet<T, U, V, W>& collection,
                         VectorType& vector) {
  typedef typename HashCountedSet<T, U, V, W>::const_iterator iterator;

  vector.resize(collection.size());

  iterator it = collection.begin();
  iterator end = collection.end();
  for (unsigned i = 0; it != end; ++it, ++i)
    vector[i] = *it;
}

template <typename Value,
          typename HashFunctions,
          typename Traits,
          typename Allocator,
          size_t inlineCapacity,
          typename VectorAllocator>
inline void copyToVector(
    const HashCountedSet<Value, HashFunctions, Traits, Allocator>& collection,
    Vector<Value, inlineCapacity, VectorAllocator>& vector) {
  typedef typename HashCountedSet<Value, HashFunctions, Traits,
                                  Allocator>::const_iterator iterator;

  vector.resize(collection.size());

  iterator it = collection.begin();
  iterator end = collection.end();
  for (unsigned i = 0; it != end; ++it, ++i)
    vector[i] = (*it).key;
}

}  // namespace WTF

using WTF::HashCountedSet;

#endif  // SKY_ENGINE_WTF_HASHCOUNTEDSET_H_
