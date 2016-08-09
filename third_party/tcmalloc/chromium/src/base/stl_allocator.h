/* Copyright (c) 2006, Google Inc.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ---
 * Author: Maxim Lifantsev
 */


#ifndef BASE_STL_ALLOCATOR_H_
#define BASE_STL_ALLOCATOR_H_

#include <config.h>

#include <stddef.h>   // for ptrdiff_t
#include <limits>

#include "base/logging.h"

// Generic allocator class for STL objects
// that uses a given type-less allocator Alloc, which must provide:
//   static void* Alloc::Allocate(size_t size);
//   static void Alloc::Free(void* ptr, size_t size);
//
// STL_Allocator<T, MyAlloc> provides the same thread-safety
// guarantees as MyAlloc.
//
// Usage example:
//   set<T, less<T>, STL_Allocator<T, MyAlloc> > my_set;
// CAVEAT: Parts of the code below are probably specific
//         to the STL version(s) we are using.
//         The code is simply lifted from what std::allocator<> provides.
template <typename T, class Alloc>
class STL_Allocator {
 public:
  typedef size_t     size_type;
  typedef ptrdiff_t  difference_type;
  typedef T*         pointer;
  typedef const T*   const_pointer;
  typedef T&         reference;
  typedef const T&   const_reference;
  typedef T          value_type;

  template <class T1> struct rebind {
    typedef STL_Allocator<T1, Alloc> other;
  };

  STL_Allocator() { }
  STL_Allocator(const STL_Allocator&) { }
  template <class T1> STL_Allocator(const STL_Allocator<T1, Alloc>&) { }
  ~STL_Allocator() { }

  pointer address(reference x) const { return &x; }
  const_pointer address(const_reference x) const { return &x; }

  pointer allocate(size_type n, const void* = 0) {
    RAW_DCHECK((n * sizeof(T)) / sizeof(T) == n, "n is too big to allocate");
    return static_cast<T*>(Alloc::Allocate(n * sizeof(T)));
  }
  void deallocate(pointer p, size_type n) { Alloc::Free(p, n * sizeof(T)); }

  size_type max_size() const { return size_t(-1) / sizeof(T); }

  void construct(pointer p, const T& val) { ::new(p) T(val); }
  void construct(pointer p) { ::new(p) T(); }
  void destroy(pointer p) { p->~T(); }

  // There's no state, so these allocators are always equal
  bool operator==(const STL_Allocator&) const { return true; }
};

#endif  // BASE_STL_ALLOCATOR_H_
