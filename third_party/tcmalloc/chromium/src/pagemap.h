// Copyright (c) 2005, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Sanjay Ghemawat <opensource@google.com>
//
// A data structure used by the caching malloc.  It maps from page# to
// a pointer that contains info about that page.  We use two
// representations: one for 32-bit addresses, and another for 64 bit
// addresses.  Both representations provide the same interface.  The
// first representation is implemented as a flat array, the seconds as
// a three-level radix tree that strips away approximately 1/3rd of
// the bits every time.
//
// The BITS parameter should be the number of bits required to hold
// a page number.  E.g., with 32 bit pointers and 4K pages (i.e.,
// page offset fits in lower 12 bits), BITS == 20.

#ifndef TCMALLOC_PAGEMAP_H_
#define TCMALLOC_PAGEMAP_H_

#include "config.h"

#include <stddef.h>                     // for NULL, size_t
#include <string.h>                     // for memset
#if defined HAVE_STDINT_H
#include <stdint.h>
#elif defined HAVE_INTTYPES_H
#include <inttypes.h>
#else
#include <sys/types.h>
#endif
#ifdef WIN32
// TODO(jar): This is not needed when TCMalloc_PageMap1_LazyCommit has an API
// supporting commit and reservation of memory.
#include "common.h"
#endif

#include "internal_logging.h"  // for ASSERT

// Single-level array
template <int BITS>
class TCMalloc_PageMap1 {
 private:
  static const int LENGTH = 1 << BITS;

  void** array_;

 public:
  typedef uintptr_t Number;

  explicit TCMalloc_PageMap1(void* (*allocator)(size_t)) {
    array_ = reinterpret_cast<void**>((*allocator)(sizeof(void*) << BITS));
    memset(array_, 0, sizeof(void*) << BITS);
  }

  // Ensure that the map contains initialized entries "x .. x+n-1".
  // Returns true if successful, false if we could not allocate memory.
  bool Ensure(Number x, size_t n) {
    // Nothing to do since flat array was allocated at start.  All
    // that's left is to check for overflow (that is, we don't want to
    // ensure a number y where array_[y] would be an out-of-bounds
    // access).
    return n <= LENGTH - x;   // an overflow-free way to do "x + n <= LENGTH"
  }

  void PreallocateMoreMemory() {}

  // Return the current value for KEY.  Returns NULL if not yet set,
  // or if k is out of range.
  void* get(Number k) const {
    if ((k >> BITS) > 0) {
      return NULL;
    }
    return array_[k];
  }

  // REQUIRES "k" is in range "[0,2^BITS-1]".
  // REQUIRES "k" has been ensured before.
  //
  // Sets the value 'v' for key 'k'.
  void set(Number k, void* v) {
    array_[k] = v;
  }

  // Return the first non-NULL pointer found in this map for
  // a page number >= k.  Returns NULL if no such number is found.
  void* Next(Number k) const {
    while (k < (1 << BITS)) {
      if (array_[k] != NULL) return array_[k];
      k++;
    }
    return NULL;
  }
};

#ifdef WIN32
// Lazy commit, single-level array.
// Very similar to PageMap1, except the page map is only committed as needed.
// Since we don't return memory to the OS, the committed portion of the map will
// only grow, and we'll only be called to Ensure when we really grow the heap.
// We maintain a bit map to help us deduce if we've already committed a range
// in our map.
template <int BITS>
class TCMalloc_PageMap1_LazyCommit {
 private:
  // Dimension of our page map array_.
  static const int LENGTH = 1 << BITS;

  // The page map array that sits in reserved virtual space.  Pages of this
  // array are committed as they are needed.  For each page of virtual memory,
  // we potentially have a pointer to a span instance.
  void** array_;

  // A bit vector that allows us to deduce what pages in array_ are committed.
  // Note that 2^3 = 8 bits per char, and hence the use of the magical "3" in
  // the array range gives us the effective "divide by 8".
  char committed_[sizeof(void*) << (BITS - kPageShift - 3)];

  // Given an |index| into |array_|, find the page number in |array_| that holds
  // that element.
  size_t ContainingPage(size_t index) const {
    return (index * sizeof(*array_)) >> kPageShift;
  }

  // Find out if the given page_num index in array_ is in committed memory.
  bool IsCommitted(size_t page_num) const {
    return committed_[page_num >> 3] & (1 << (page_num & 0x7));
  }

  // Remember that the given page_num index in array_ is in committed memory.
  void SetCommitted(size_t page_num) {
    committed_[page_num >> 3] |= (1 << (page_num & 0x7));
  }

 public:
  typedef uintptr_t Number;

  explicit TCMalloc_PageMap1_LazyCommit(void* (*allocator)(size_t)) {
    // TODO(jar): We need a reservation function, but current API to this class
    // only provides an allocator.
    // Get decommitted memory.  We will commit as necessary.
    size_t size = sizeof(*array_) << BITS;
    array_ = reinterpret_cast<void**>(VirtualAlloc(
        NULL, size, MEM_RESERVE, PAGE_READWRITE));
    tcmalloc::update_metadata_system_bytes(size);
    tcmalloc::update_metadata_unmapped_bytes(size);

    // Make sure we divided LENGTH evenly.
    ASSERT(sizeof(committed_) * 8 == (LENGTH * sizeof(*array_)) >> kPageShift);
    // Indicate that none of the pages of array_ have been committed yet.
    memset(committed_, 0, sizeof(committed_));
  }

  // Ensure that the map contains initialized and committed entries in array_ to
  // describe pages "x .. x+n-1".
  // Returns true if successful, false if we could not ensure this.
  // If we have to commit more memory in array_ (which also clears said memory),
  // then we'll set some of the bits in committed_ to remember this fact.
  // Only the bits of committed_ near end-points for calls to Ensure() are ever
  // set, as the calls to Ensure() will never have overlapping ranges other than
  // at their end-points.
  //
  // Example: Suppose the OS allocates memory in pages including 40...50, and
  // later the OS allocates memory in pages 51...83.  When the first allocation
  // of 40...50 is observed, then Ensure of (39,51) will be called.  The range
  // shown in the arguments is extended so that tcmalloc can look to see if
  // adjacent pages are part of a span that can be coaleced.  Later, when pages
  // 51...83 are allocated, Ensure() will be called with arguments (50,84),
  // broadened again for the same reason.
  //
  // After the above, we would NEVER get a call such as Ensure(45,60), as that
  // overlaps with the interior of prior ensured regions.  We ONLY get an Ensure
  // call when the OS has allocated memory, and since we NEVER give memory back
  // to the OS, the OS can't possible allocate the same region to us twice, and
  // can't induce an Ensure() on an interior of previous Ensure call.
  //
  // Also note that OS allocations are NOT guaranteed to be consecutive (there
  // may be "holes" where code etc. uses the virtual addresses), or to appear in
  // any order, such as lowest to highest, or vice versa (as other independent
  // allocation systems in the process may be performing VirtualAllocations and
  // VirtualFrees asynchronously.)
  bool Ensure(Number x, size_t n) {
    if (n > LENGTH - x)
      return false;  // We won't Ensure mapping for last pages in memory.
    ASSERT(n > 0);

    // For a given page number in memory, calculate what page in array_ needs to
    // be memory resident.  Note that we really only need a few bytes in array_
    // for each page of virtual space we have to map, but we can only commit
    // whole pages of array_.  For instance, a 4K page of array_ has about 1k
    // entries, and hence can map about 1K pages, or a total of about 4MB
    // typically. As a result, it is possible that the first entry in array_,
    // and the n'th entry in array_, will sit in the same page of array_.
    size_t first_page = ContainingPage(x);
    size_t last_page = ContainingPage(x + n - 1);

    // Check at each boundary, to see if we need to commit at that end.  Some
    // other neighbor may have already forced us to commit at either or both
    // boundaries.
    if (IsCommitted(first_page)) {
      if (first_page == last_page) return true;
      ++first_page;
      if (IsCommitted(first_page)) {
        if (first_page == last_page) return true;
        ++first_page;
      }
    }

    if (IsCommitted(last_page)) {
      if (first_page == last_page) return true;
      --last_page;
      if (IsCommitted(last_page)) {
        if (first_page == last_page) return true;
        --last_page;
      }
    }

    ASSERT(!IsCommitted(last_page));
    ASSERT(!IsCommitted(first_page));

    void* start = reinterpret_cast<char*>(array_) + (first_page << kPageShift);
    size_t length = (last_page - first_page + 1) << kPageShift;

#ifndef NDEBUG
    // Validate we are committing new sections, and hence we're not clearing any
    // existing data.
    MEMORY_BASIC_INFORMATION info = {0};
    size_t result = VirtualQuery(start, &info, sizeof(info));
    ASSERT(result);
    ASSERT(0 == (info.State & MEM_COMMIT));  // It starts with uncommitted.
    ASSERT(info.RegionSize >= length);       // Entire length is uncommitted.
#endif

    TCMalloc_SystemCommit(start, length);
    tcmalloc::update_metadata_unmapped_bytes(-length);

#ifndef NDEBUG
    result = VirtualQuery(start, &info, sizeof(info));
    ASSERT(result);
    ASSERT(0 != (info.State & MEM_COMMIT));  // Now it is committed.
    ASSERT(info.RegionSize >= length);       // Entire length is committed.
#endif

    // As noted in the large comment/example describing this method, we will
    // never be called with a range of pages very much inside this |first_page|
    // to |last_page| range.
    // As a result, we only need to set bits for each end of that range, and one
    // page inside each end.
    SetCommitted(first_page);
    if (first_page < last_page) {
      SetCommitted(last_page);
      SetCommitted(first_page + 1);  // These may be duplicates now.
      SetCommitted(last_page - 1);
    }

    return true;
  }

  // This is a premature call to get all the meta-memory allocated, so as to
  // avoid virtual space fragmentation.  Since we pre-reserved all memory, we
  // don't need to do anything here (we won't fragment virtual space).
  void PreallocateMoreMemory() {}

  // Return the current value for KEY.  Returns NULL if not yet set,
  // or if k is out of range.
  void* get(Number k) const {
    if ((k >> BITS) > 0) {
      return NULL;
    }
    return array_[k];
  }

  // REQUIRES "k" is in range "[0,2^BITS-1]".
  // REQUIRES "k" has been ensured before.
  //
  // Sets the value for KEY.
  void set(Number k, void* v) {
    array_[k] = v;
  }
  // Return the first non-NULL pointer found in this map for
  // a page number >= k.  Returns NULL if no such number is found.
  void* Next(Number k) const {
    while (k < (1 << BITS)) {
      if (array_[k] != NULL) return array_[k];
      k++;
    }
    return NULL;
  }
};
#endif  // WIN32


// Two-level radix tree
template <int BITS>
class TCMalloc_PageMap2 {
 private:
  // Put 32 entries in the root and (2^BITS)/32 entries in each leaf.
  static const int ROOT_BITS = 5;
  static const int ROOT_LENGTH = 1 << ROOT_BITS;

  static const int LEAF_BITS = BITS - ROOT_BITS;
  static const int LEAF_LENGTH = 1 << LEAF_BITS;

  // Leaf node
  struct Leaf {
    void* values[LEAF_LENGTH];
  };

  Leaf* root_[ROOT_LENGTH];             // Pointers to 32 child nodes
  void* (*allocator_)(size_t);          // Memory allocator

 public:
  typedef uintptr_t Number;

  explicit TCMalloc_PageMap2(void* (*allocator)(size_t)) {
    allocator_ = allocator;
    memset(root_, 0, sizeof(root_));
  }

  void* get(Number k) const {
    const Number i1 = k >> LEAF_BITS;
    const Number i2 = k & (LEAF_LENGTH-1);
    if ((k >> BITS) > 0 || root_[i1] == NULL) {
      return NULL;
    }
    return root_[i1]->values[i2];
  }

  void set(Number k, void* v) {
    ASSERT(k >> BITS == 0);
    const Number i1 = k >> LEAF_BITS;
    const Number i2 = k & (LEAF_LENGTH-1);
    root_[i1]->values[i2] = v;
  }

  bool Ensure(Number start, size_t n) {
    for (Number key = start; key <= start + n - 1; ) {
      const Number i1 = key >> LEAF_BITS;

      // Check for overflow
      if (i1 >= ROOT_LENGTH)
        return false;

      // Make 2nd level node if necessary
      if (root_[i1] == NULL) {
        Leaf* leaf = reinterpret_cast<Leaf*>((*allocator_)(sizeof(Leaf)));
        if (leaf == NULL) return false;
        memset(leaf, 0, sizeof(*leaf));
        root_[i1] = leaf;
      }

      // Advance key past whatever is covered by this leaf node
      key = ((key >> LEAF_BITS) + 1) << LEAF_BITS;
    }
    return true;
  }

  void PreallocateMoreMemory() {
    // Allocate enough to keep track of all possible pages
    Ensure(0, 1 << BITS);
  }

  void* Next(Number k) const {
    while (k < (1 << BITS)) {
      const Number i1 = k >> LEAF_BITS;
      Leaf* leaf = root_[i1];
      if (leaf != NULL) {
        // Scan forward in leaf
        for (Number i2 = k & (LEAF_LENGTH - 1); i2 < LEAF_LENGTH; i2++) {
          if (leaf->values[i2] != NULL) {
            return leaf->values[i2];
          }
        }
      }
      // Skip to next top-level entry
      k = (i1 + 1) << LEAF_BITS;
    }
    return NULL;
  }
};

// Three-level radix tree
template <int BITS>
class TCMalloc_PageMap3 {
 private:
  // How many bits should we consume at each interior level
  static const int INTERIOR_BITS = (BITS + 2) / 3; // Round-up
  static const int INTERIOR_LENGTH = 1 << INTERIOR_BITS;

  // How many bits should we consume at leaf level
  static const int LEAF_BITS = BITS - 2*INTERIOR_BITS;
  static const int LEAF_LENGTH = 1 << LEAF_BITS;

  // Interior node
  struct Node {
    Node* ptrs[INTERIOR_LENGTH];
  };

  // Leaf node
  struct Leaf {
    void* values[LEAF_LENGTH];
  };

  Node* root_;                          // Root of radix tree
  void* (*allocator_)(size_t);          // Memory allocator

  Node* NewNode() {
    Node* result = reinterpret_cast<Node*>((*allocator_)(sizeof(Node)));
    if (result != NULL) {
      memset(result, 0, sizeof(*result));
    }
    return result;
  }

 public:
  typedef uintptr_t Number;

  explicit TCMalloc_PageMap3(void* (*allocator)(size_t)) {
    allocator_ = allocator;
    root_ = NewNode();
  }

  void* get(Number k) const {
    const Number i1 = k >> (LEAF_BITS + INTERIOR_BITS);
    const Number i2 = (k >> LEAF_BITS) & (INTERIOR_LENGTH-1);
    const Number i3 = k & (LEAF_LENGTH-1);
    if ((k >> BITS) > 0 ||
        root_->ptrs[i1] == NULL || root_->ptrs[i1]->ptrs[i2] == NULL) {
      return NULL;
    }
    return reinterpret_cast<Leaf*>(root_->ptrs[i1]->ptrs[i2])->values[i3];
  }

  void set(Number k, void* v) {
    ASSERT(k >> BITS == 0);
    const Number i1 = k >> (LEAF_BITS + INTERIOR_BITS);
    const Number i2 = (k >> LEAF_BITS) & (INTERIOR_LENGTH-1);
    const Number i3 = k & (LEAF_LENGTH-1);
    reinterpret_cast<Leaf*>(root_->ptrs[i1]->ptrs[i2])->values[i3] = v;
  }

  bool Ensure(Number start, size_t n) {
    for (Number key = start; key <= start + n - 1; ) {
      const Number i1 = key >> (LEAF_BITS + INTERIOR_BITS);
      const Number i2 = (key >> LEAF_BITS) & (INTERIOR_LENGTH-1);

      // Check for overflow
      if (i1 >= INTERIOR_LENGTH || i2 >= INTERIOR_LENGTH)
        return false;

      // Make 2nd level node if necessary
      if (root_->ptrs[i1] == NULL) {
        Node* n = NewNode();
        if (n == NULL) return false;
        root_->ptrs[i1] = n;
      }

      // Make leaf node if necessary
      if (root_->ptrs[i1]->ptrs[i2] == NULL) {
        Leaf* leaf = reinterpret_cast<Leaf*>((*allocator_)(sizeof(Leaf)));
        if (leaf == NULL) return false;
        memset(leaf, 0, sizeof(*leaf));
        root_->ptrs[i1]->ptrs[i2] = reinterpret_cast<Node*>(leaf);
      }

      // Advance key past whatever is covered by this leaf node
      key = ((key >> LEAF_BITS) + 1) << LEAF_BITS;
    }
    return true;
  }

  void PreallocateMoreMemory() {
  }

  void* Next(Number k) const {
    while (k < (Number(1) << BITS)) {
      const Number i1 = k >> (LEAF_BITS + INTERIOR_BITS);
      const Number i2 = (k >> LEAF_BITS) & (INTERIOR_LENGTH-1);
      if (root_->ptrs[i1] == NULL) {
        // Advance to next top-level entry
        k = (i1 + 1) << (LEAF_BITS + INTERIOR_BITS);
      } else {
        Leaf* leaf = reinterpret_cast<Leaf*>(root_->ptrs[i1]->ptrs[i2]);
        if (leaf != NULL) {
          for (Number i3 = (k & (LEAF_LENGTH-1)); i3 < LEAF_LENGTH; i3++) {
            if (leaf->values[i3] != NULL) {
              return leaf->values[i3];
            }
          }
        }
        // Advance to next interior entry
        k = ((k >> LEAF_BITS) + 1) << LEAF_BITS;
      }
    }
    return NULL;
  }
};

#endif  // TCMALLOC_PAGEMAP_H_
