// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// DESCRIPTION
// 
// SparseArray<T>(m) is a map from integers in [0, m) to T values.
// It requires (sizeof(T)+sizeof(int))*m memory, but it provides
// fast iteration through the elements in the array and fast clearing
// of the array.  The array has a concept of certain elements being
// uninitialized (having no value).
// 
// Insertion and deletion are constant time operations.
// 
// Allocating the array is a constant time operation 
// when memory allocation is a constant time operation.
// 
// Clearing the array is a constant time operation (unusual!).
// 
// Iterating through the array is an O(n) operation, where n
// is the number of items in the array (not O(m)).
//
// The array iterator visits entries in the order they were first 
// inserted into the array.  It is safe to add items to the array while
// using an iterator: the iterator will visit indices added to the array
// during the iteration, but will not re-visit indices whose values
// change after visiting.  Thus SparseArray can be a convenient
// implementation of a work queue.
// 
// The SparseArray implementation is NOT thread-safe.  It is up to the
// caller to make sure only one thread is accessing the array.  (Typically
// these arrays are temporary values and used in situations where speed is
// important.)
// 
// The SparseArray interface does not present all the usual STL bells and
// whistles.
// 
// Implemented with reference to Briggs & Torczon, An Efficient
// Representation for Sparse Sets, ACM Letters on Programming Languages
// and Systems, Volume 2, Issue 1-4 (March-Dec.  1993), pp.  59-69.
// 
// Briggs & Torczon popularized this technique, but it had been known
// long before their paper.  They point out that Aho, Hopcroft, and
// Ullman's 1974 Design and Analysis of Computer Algorithms and Bentley's
// 1986 Programming Pearls both hint at the technique in exercises to the
// reader (in Aho & Hopcroft, exercise 2.12; in Bentley, column 1
// exercise 8).
// 
// Briggs & Torczon describe a sparse set implementation.  I have
// trivially generalized it to create a sparse array (actually the original
// target of the AHU and Bentley exercises).

// IMPLEMENTATION
//
// SparseArray uses a vector dense_ and an array sparse_to_dense_, both of
// size max_size_. At any point, the number of elements in the sparse array is
// size_.
// 
// The vector dense_ contains the size_ elements in the sparse array (with
// their indices),
// in the order that the elements were first inserted.  This array is dense:
// the size_ pairs are dense_[0] through dense_[size_-1].
//
// The array sparse_to_dense_ maps from indices in [0,m) to indices in
// [0,size_).
// For indices present in the array, dense_[sparse_to_dense_[i]].index_ == i.
// For indices not present in the array, sparse_to_dense_ can contain 
// any value at all, perhaps outside the range [0, size_) but perhaps not.
// 
// The lax requirement on sparse_to_dense_ values makes clearing
// the array very easy: set size_ to 0.  Lookups are slightly more
// complicated.  An index i has a value in the array if and only if:
//   sparse_to_dense_[i] is in [0, size_) AND
//   dense_[sparse_to_dense_[i]].index_ == i.
// If both these properties hold, only then it is safe to refer to 
//   dense_[sparse_to_dense_[i]].value_
// as the value associated with index i.
//
// To insert a new entry, set sparse_to_dense_[i] to size_,
// initialize dense_[size_], and then increment size_.
//
// Deletion of specific values from the array is implemented by
// swapping dense_[size_-1] and the dense_ being deleted and then
// updating the appropriate sparse_to_dense_ entries.
// 
// To make the sparse array as efficient as possible for non-primitive types,
// elements may or may not be destroyed when they are deleted from the sparse
// array through a call to erase(), erase_existing() or resize(). They
// immediately become inaccessible, but they are only guaranteed to be
// destroyed when the SparseArray destructor is called.

#ifndef RE2_UTIL_SPARSE_ARRAY_H__
#define RE2_UTIL_SPARSE_ARRAY_H__

#include "util/util.h"

namespace re2 {

template<typename Value>
class SparseArray {
 public:
  SparseArray();
  SparseArray(int max_size);
  ~SparseArray();

  // IndexValue pairs: exposed in SparseArray::iterator.
  class IndexValue;

  typedef IndexValue value_type;
  typedef typename vector<IndexValue>::iterator iterator;
  typedef typename vector<IndexValue>::const_iterator const_iterator;

  inline const IndexValue& iv(int i) const;

  // Return the number of entries in the array.
  int size() const {
    return size_;
  }

  // Iterate over the array.
  iterator begin() {
    return dense_.begin();
  }
  iterator end() {
    return dense_.begin() + size_;
  }

  const_iterator begin() const {
    return dense_.begin();
  }
  const_iterator end() const {
    return dense_.begin() + size_;
  }

  // Change the maximum size of the array.
  // Invalidates all iterators.
  void resize(int max_size);

  // Return the maximum size of the array.
  // Indices can be in the range [0, max_size).
  int max_size() const {
    return max_size_;
  }

  // Clear the array.
  void clear() {
    size_ = 0;
  }

  // Check whether index i is in the array.
  inline bool has_index(int i) const;

  // Comparison function for sorting.
  // Can sort the sparse array so that future iterations
  // will visit indices in increasing order using
  // sort(arr.begin(), arr.end(), arr.less);
  static bool less(const IndexValue& a, const IndexValue& b);

 public:
  // Set the value at index i to v.
  inline iterator set(int i, Value v);

  pair<iterator, bool> insert(const value_type& new_value);

  // Returns the value at index i
  // or defaultv if index i is not initialized in the array.
  inline Value get(int i, Value defaultv) const;

  iterator find(int i);

  const_iterator find(int i) const;

  // Change the value at index i to v.
  // Fast but unsafe: only use if has_index(i) is true.
  inline iterator set_existing(int i, Value v);

  // Set the value at the new index i to v.
  // Fast but unsafe: only use if has_index(i) is false.
  inline iterator set_new(int i, Value v);

  // Get the value at index i from the array..
  // Fast but unsafe: only use if has_index(i) is true.
  inline Value get_existing(int i) const;

  // Erasing items from the array during iteration is in general
  // NOT safe.  There is one special case, which is that the current
  // index-value pair can be erased as long as the iterator is then
  // checked for being at the end before being incremented.
  // For example:
  //
  //   for (i = m.begin(); i != m.end(); ++i) {
  //     if (ShouldErase(i->index(), i->value())) {
  //       m.erase(i->index());
  //       --i;
  //     }
  //   }
  //
  // Except in the specific case just described, elements must
  // not be erased from the array (including clearing the array)
  // while iterators are walking over the array.  Otherwise,
  // the iterators could walk past the end of the array.

  // Erases the element at index i from the array.
  inline void erase(int i);

  // Erases the element at index i from the array.
  // Fast but unsafe: only use if has_index(i) is true.
  inline void erase_existing(int i);

 private:
  // Add the index i to the array.
  // Only use if has_index(i) is known to be false.
  // Since it doesn't set the value associated with i,
  // this function is private, only intended as a helper
  // for other methods.
  inline void create_index(int i);

  // In debug mode, verify that some invariant properties of the class
  // are being maintained. This is called at the end of the constructor
  // and at the beginning and end of all public non-const member functions.
  inline void DebugCheckInvariants() const;

  int size_;
  int max_size_;
  int* sparse_to_dense_;
  vector<IndexValue> dense_;
  bool valgrind_;

  DISALLOW_EVIL_CONSTRUCTORS(SparseArray);
};

template<typename Value>
SparseArray<Value>::SparseArray()
    : size_(0), max_size_(0), sparse_to_dense_(NULL), dense_(),
      valgrind_(RunningOnValgrindOrMemorySanitizer()) {}

// IndexValue pairs: exposed in SparseArray::iterator.
template<typename Value>
class SparseArray<Value>::IndexValue {
  friend class SparseArray;
 public:
  typedef int first_type;
  typedef Value second_type;

  IndexValue() {}
  IndexValue(int index, const Value& value) : second(value), index_(index) {}

  int index() const { return index_; }
  Value value() const { return second; }

  // Provide the data in the 'second' member so that the utilities
  // in map-util work.
  Value second;

 private:
  int index_;
};

template<typename Value>
const typename SparseArray<Value>::IndexValue&
SparseArray<Value>::iv(int i) const {
  DCHECK_GE(i, 0);
  DCHECK_LT(i, size_);
  return dense_[i];
}

// Change the maximum size of the array.
// Invalidates all iterators.
template<typename Value>
void SparseArray<Value>::resize(int new_max_size) {
  DebugCheckInvariants();
  if (new_max_size > max_size_) {
    int* a = new int[new_max_size];
    if (sparse_to_dense_) {
      memmove(a, sparse_to_dense_, max_size_*sizeof a[0]);
      // Don't need to zero the memory but appease Valgrind.
      if (valgrind_) {
        for (int i = max_size_; i < new_max_size; i++)
          a[i] = 0xababababU;
      }
      delete[] sparse_to_dense_;
    }
    sparse_to_dense_ = a;

    dense_.resize(new_max_size);
  }
  max_size_ = new_max_size;
  if (size_ > max_size_)
    size_ = max_size_;
  DebugCheckInvariants();
}

// Check whether index i is in the array.
template<typename Value>
bool SparseArray<Value>::has_index(int i) const {
  DCHECK_GE(i, 0);
  DCHECK_LT(i, max_size_);
  if (static_cast<uint>(i) >= max_size_) {
    return false;
  }
  // Unsigned comparison avoids checking sparse_to_dense_[i] < 0.
  return (uint)sparse_to_dense_[i] < (uint)size_ && 
    dense_[sparse_to_dense_[i]].index_ == i;
}

// Set the value at index i to v.
template<typename Value>
typename SparseArray<Value>::iterator SparseArray<Value>::set(int i, Value v) {
  DebugCheckInvariants();
  if (static_cast<uint>(i) >= max_size_) {
    // Semantically, end() would be better here, but we already know
    // the user did something stupid, so begin() insulates them from
    // dereferencing an invalid pointer.
    return begin();
  }
  if (!has_index(i))
    create_index(i);
  return set_existing(i, v);
}

template<typename Value>
pair<typename SparseArray<Value>::iterator, bool> SparseArray<Value>::insert(
    const value_type& new_value) {
  DebugCheckInvariants();
  pair<typename SparseArray<Value>::iterator, bool> p;
  if (has_index(new_value.index_)) {
    p = make_pair(dense_.begin() + sparse_to_dense_[new_value.index_], false);
  } else {
    p = make_pair(set_new(new_value.index_, new_value.second), true);
  }
  DebugCheckInvariants();
  return p;
}

template<typename Value>
Value SparseArray<Value>::get(int i, Value defaultv) const {
  if (!has_index(i))
    return defaultv;
  return get_existing(i);
}

template<typename Value>
typename SparseArray<Value>::iterator SparseArray<Value>::find(int i) {
  if (has_index(i))
    return dense_.begin() + sparse_to_dense_[i];
  return end();
}

template<typename Value>
typename SparseArray<Value>::const_iterator
SparseArray<Value>::find(int i) const {
  if (has_index(i)) {
    return dense_.begin() + sparse_to_dense_[i];
  }
  return end();
}

template<typename Value>
typename SparseArray<Value>::iterator
SparseArray<Value>::set_existing(int i, Value v) {
  DebugCheckInvariants();
  DCHECK(has_index(i));
  dense_[sparse_to_dense_[i]].second = v;
  DebugCheckInvariants();
  return dense_.begin() + sparse_to_dense_[i];
}

template<typename Value>
typename SparseArray<Value>::iterator
SparseArray<Value>::set_new(int i, Value v) {
  DebugCheckInvariants();
  if (static_cast<uint>(i) >= max_size_) {
    // Semantically, end() would be better here, but we already know
    // the user did something stupid, so begin() insulates them from
    // dereferencing an invalid pointer.
    return begin();
  }
  DCHECK(!has_index(i));
  create_index(i);
  return set_existing(i, v);
}

template<typename Value>
Value SparseArray<Value>::get_existing(int i) const {
  DCHECK(has_index(i));
  return dense_[sparse_to_dense_[i]].second;
}

template<typename Value>
void SparseArray<Value>::erase(int i) {
  DebugCheckInvariants();
  if (has_index(i))
    erase_existing(i);
  DebugCheckInvariants();
}

template<typename Value>
void SparseArray<Value>::erase_existing(int i) {
  DebugCheckInvariants();
  DCHECK(has_index(i));
  int di = sparse_to_dense_[i];
  if (di < size_ - 1) {
    dense_[di] = dense_[size_ - 1];
    sparse_to_dense_[dense_[di].index_] = di;
  }
  size_--;
  DebugCheckInvariants();
}

template<typename Value>
void SparseArray<Value>::create_index(int i) {
  DCHECK(!has_index(i));
  DCHECK_LT(size_, max_size_);
  sparse_to_dense_[i] = size_;
  dense_[size_].index_ = i;
  size_++;
}

template<typename Value> SparseArray<Value>::SparseArray(int max_size) {
  max_size_ = max_size;
  sparse_to_dense_ = new int[max_size];
  valgrind_ = RunningOnValgrindOrMemorySanitizer();
  dense_.resize(max_size);
  // Don't need to zero the new memory, but appease Valgrind.
  if (valgrind_) {
    for (int i = 0; i < max_size; i++) {
      sparse_to_dense_[i] = 0xababababU;
      dense_[i].index_ = 0xababababU;
    }
  }
  size_ = 0;
  DebugCheckInvariants();
}

template<typename Value> SparseArray<Value>::~SparseArray() {
  DebugCheckInvariants();
  delete[] sparse_to_dense_;
}

template<typename Value> void SparseArray<Value>::DebugCheckInvariants() const {
  DCHECK_LE(0, size_);
  DCHECK_LE(size_, max_size_);
  DCHECK(size_ == 0 || sparse_to_dense_ != NULL);
}

// Comparison function for sorting.
template<typename Value> bool SparseArray<Value>::less(const IndexValue& a,
                                                       const IndexValue& b) {
  return a.index_ < b.index_;
}

}  // namespace re2

#endif  // RE2_UTIL_SPARSE_ARRAY_H__
