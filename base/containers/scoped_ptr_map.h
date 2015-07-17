// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_CONTAINERS_SCOPED_PTR_MAP_H_
#define BASE_CONTAINERS_SCOPED_PTR_MAP_H_

#include <functional>
#include <map>
#include <utility>

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/move.h"
#include "base/stl_util.h"

namespace base {

// ScopedPtrMap provides a std::map that supports scoped_ptr values. It ensures
// that the map's values are properly deleted when removed from the map, or when
// the map is destroyed.
//
// |ScopedPtr| must be a type scoped_ptr<T>. This is for compatibility with
// std::map in C++11.
template <class Key, class ScopedPtr, class Compare = std::less<Key>>
class ScopedPtrMap {
  MOVE_ONLY_TYPE_WITH_MOVE_CONSTRUCTOR_FOR_CPP_03(ScopedPtrMap)

  using Container = std::map<Key, typename ScopedPtr::element_type*, Compare>;

 public:
  using allocator_type = typename Container::allocator_type;
  using size_type = typename Container::size_type;
  using difference_type = typename Container::difference_type;
  using reference = typename Container::reference;
  using const_reference = typename Container::const_reference;
  using key_type = typename Container::key_type;
  using mapped_type = ScopedPtr;
  using key_compare = typename Container::key_compare;
  using const_iterator = typename Container::const_iterator;
  using const_reverse_iterator = typename Container::const_reverse_iterator;

  ScopedPtrMap() {}
  ~ScopedPtrMap() { clear(); }
  ScopedPtrMap(ScopedPtrMap<Key, ScopedPtr>&& other) { swap(other); }

  ScopedPtrMap& operator=(ScopedPtrMap<Key, ScopedPtr>&& rhs) {
    swap(rhs);
    return *this;
  }

  const_iterator find(const Key& k) const { return data_.find(k); }
  size_type count(const Key& k) const { return data_.count(k); }

  bool empty() const { return data_.empty(); }
  size_t size() const { return data_.size(); }

  const_reverse_iterator rbegin() const { return data_.rbegin(); }
  const_reverse_iterator rend() const { return data_.rend(); }

  const_iterator begin() const { return data_.begin(); }
  const_iterator end() const { return data_.end(); }

  void swap(ScopedPtrMap<Key, ScopedPtr>& other) { data_.swap(other.data_); }

  void clear() { STLDeleteValues(&data_); }

  // Inserts |val| into the map, associated with |key|.
  std::pair<const_iterator, bool> insert(const Key& key, ScopedPtr val) {
    auto result = data_.insert(std::make_pair(key, val.get()));
    if (result.second)
      ignore_result(val.release());
    return result;
  }

  // Inserts |val| into the map, associated with |key|. Overwrites any existing
  // element at |key|.
  void set(const Key& key, ScopedPtr val) {
    typename ScopedPtr::element_type*& val_ref = data_[key];
    delete val_ref;
    val_ref = val.release();
  }

  void erase(const_iterator position) {
    DCHECK(position != end());
    delete position->second;
    // Key-based lookup (cannot use const_iterator overload in C++03 library).
    data_.erase(position->first);
  }

  size_type erase(const Key& k) {
    typename Container::iterator it = data_.find(k);
    if (it == end())
      return 0;

    delete it->second;
    data_.erase(it);
    return 1;
  }

  void erase(const_iterator first, const_iterator last) {
    STLDeleteContainerPairSecondPointers(first, last);
    // Need non-const iterators as required by the C++03 library.
    data_.erase(ConstIteratorToIterator(first), ConstIteratorToIterator(last));
  }

  // Like |erase()|, but returns the element instead of deleting it.
  ScopedPtr take_and_erase(const_iterator position) {
    DCHECK(position != end());
    if (position == end())
      return ScopedPtr();

    ScopedPtr ret(position->second);
    // Key-based lookup (cannot use const_iterator overload in C++03 library).
    data_.erase(position->first);
    return ret.Pass();
  }

  // Like |erase()|, but returns the element instead of deleting it.
  ScopedPtr take_and_erase(const Key& k) {
    typename Container::iterator it = data_.find(k);
    if (it == end())
      return ScopedPtr();

    ScopedPtr ret(it->second);
    data_.erase(it);
    return ret.Pass();
  }

 private:
  Container data_;

  typename Container::iterator ConstIteratorToIterator(const_iterator it) {
    // This is the only way to convert a const iterator to a non-const iterator
    // in C++03 (get the key and do the lookup again).
    if (it == data_.end())
      return data_.end();
    return data_.find(it->first);
  };
};

}  // namespace base

#endif  // BASE_CONTAINERS_SCOPED_PTR_MAP_H_
