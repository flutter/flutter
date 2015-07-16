// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// DESCRIPTION
// 
// SparseSet<T>(m) is a set of integers in [0, m).
// It requires sizeof(int)*m memory, but it provides
// fast iteration through the elements in the set and fast clearing
// of the set.
// 
// Insertion and deletion are constant time operations.
// 
// Allocating the set is a constant time operation 
// when memory allocation is a constant time operation.
// 
// Clearing the set is a constant time operation (unusual!).
// 
// Iterating through the set is an O(n) operation, where n
// is the number of items in the set (not O(m)).
//
// The set iterator visits entries in the order they were first 
// inserted into the array.  It is safe to add items to the set while
// using an iterator: the iterator will visit indices added to the set
// during the iteration, but will not re-visit indices whose values
// change after visiting.  Thus SparseSet can be a convenient
// implementation of a work queue.
// 
// The SparseSet implementation is NOT thread-safe.  It is up to the
// caller to make sure only one thread is accessing the set.  (Typically
// these sets are temporary values and used in situations where speed is
// important.)
// 
// The SparseSet interface does not present all the usual STL bells and
// whistles.
// 
// Implemented with reference to Briggs & Torczon, An Efficient
// Representation for Sparse Sets, ACM Letters on Programming Languages
// and Systems, Volume 2, Issue 1-4 (March-Dec.  1993), pp.  59-69.
// 
// For a generalization to sparse array, see sparse_array.h.

// IMPLEMENTATION
//
// See sparse_array.h for implementation details

#ifndef RE2_UTIL_SPARSE_SET_H__
#define RE2_UTIL_SPARSE_SET_H__

#include "util/util.h"

namespace re2 {

class SparseSet {
 public:
  SparseSet()
    : size_(0), max_size_(0), sparse_to_dense_(NULL), dense_(NULL),
      valgrind_(RunningOnValgrindOrMemorySanitizer()) {}

  SparseSet(int max_size) {
    max_size_ = max_size;
    sparse_to_dense_ = new int[max_size];
    dense_ = new int[max_size];
    valgrind_ = RunningOnValgrindOrMemorySanitizer();
    // Don't need to zero the memory, but do so anyway
    // to appease Valgrind.
    if (valgrind_) {
      for (int i = 0; i < max_size; i++) {
        dense_[i] = 0xababababU;
        sparse_to_dense_[i] = 0xababababU;
      }
    }
    size_ = 0;
  }

  ~SparseSet() {
    delete[] sparse_to_dense_;
    delete[] dense_;
  }

  typedef int* iterator;
  typedef const int* const_iterator;

  int size() const { return size_; }
  iterator begin() { return dense_; }
  iterator end() { return dense_ + size_; }
  const_iterator begin() const { return dense_; }
  const_iterator end() const { return dense_ + size_; }

  // Change the maximum size of the array.
  // Invalidates all iterators.
  void resize(int new_max_size) {
    if (size_ > new_max_size)
      size_ = new_max_size;
    if (new_max_size > max_size_) {
      int* a = new int[new_max_size];
      if (sparse_to_dense_) {
        memmove(a, sparse_to_dense_, max_size_*sizeof a[0]);
        if (valgrind_) {
          for (int i = max_size_; i < new_max_size; i++)
            a[i] = 0xababababU;
        }
        delete[] sparse_to_dense_;
      }
      sparse_to_dense_ = a;

      a = new int[new_max_size];
      if (dense_) {
        memmove(a, dense_, size_*sizeof a[0]);
        if (valgrind_) {
          for (int i = size_; i < new_max_size; i++)
            a[i] = 0xababababU;
        }
        delete[] dense_;
      }
      dense_ = a;
    }
    max_size_ = new_max_size;
  }

  // Return the maximum size of the array.
  // Indices can be in the range [0, max_size).
  int max_size() const { return max_size_; }

  // Clear the array.
  void clear() { size_ = 0; }

  // Check whether i is in the array.
  bool contains(int i) const {
    DCHECK_GE(i, 0);
    DCHECK_LT(i, max_size_);
    if (static_cast<uint>(i) >= max_size_) {
      return false;
    }
    // Unsigned comparison avoids checking sparse_to_dense_[i] < 0.
    return (uint)sparse_to_dense_[i] < (uint)size_ && 
      dense_[sparse_to_dense_[i]] == i;
  }

  // Adds i to the set.
  void insert(int i) {
    if (!contains(i))
      insert_new(i);
  }

  // Set the value at the new index i to v.
  // Fast but unsafe: only use if contains(i) is false.
  void insert_new(int i) {
    if (static_cast<uint>(i) >= max_size_) {
      // Semantically, end() would be better here, but we already know
      // the user did something stupid, so begin() insulates them from
      // dereferencing an invalid pointer.
      return;
    }
    DCHECK(!contains(i));
    DCHECK_LT(size_, max_size_);
    sparse_to_dense_[i] = size_;
    dense_[size_] = i;
    size_++;
  }

  // Comparison function for sorting.
  // Can sort the sparse array so that future iterations
  // will visit indices in increasing order using
  // sort(arr.begin(), arr.end(), arr.less);
  static bool less(int a, int b) { return a < b; }

 private:
  int size_;
  int max_size_;
  int* sparse_to_dense_;
  int* dense_;
  bool valgrind_;

  DISALLOW_EVIL_CONSTRUCTORS(SparseSet);
};

}  // namespace re2

#endif  // RE2_UTIL_SPARSE_SET_H__
