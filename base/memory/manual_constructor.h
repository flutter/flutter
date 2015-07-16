// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ManualConstructor statically-allocates space in which to store some
// object, but does not initialize it.  You can then call the constructor
// and destructor for the object yourself as you see fit.  This is useful
// for memory management optimizations, where you want to initialize and
// destroy an object multiple times but only allocate it once.
//
// (When I say ManualConstructor statically allocates space, I mean that
// the ManualConstructor object itself is forced to be the right size.)
//
// For example usage, check out base/containers/small_map.h.

#ifndef BASE_MEMORY_MANUAL_CONSTRUCTOR_H_
#define BASE_MEMORY_MANUAL_CONSTRUCTOR_H_

#include <stddef.h>

#include "base/compiler_specific.h"
#include "base/memory/aligned_memory.h"

namespace base {

template <typename Type>
class ManualConstructor {
 public:
  // No constructor or destructor because one of the most useful uses of
  // this class is as part of a union, and members of a union cannot have
  // constructors or destructors.  And, anyway, the whole point of this
  // class is to bypass these.

  // Support users creating arrays of ManualConstructor<>s.  This ensures that
  // the array itself has the correct alignment.
  static void* operator new[](size_t size) {
    return AlignedAlloc(size, ALIGNOF(Type));
  }
  static void operator delete[](void* mem) {
    AlignedFree(mem);
  }

  inline Type* get() {
    return space_.template data_as<Type>();
  }
  inline const Type* get() const  {
    return space_.template data_as<Type>();
  }

  inline Type* operator->() { return get(); }
  inline const Type* operator->() const { return get(); }

  inline Type& operator*() { return *get(); }
  inline const Type& operator*() const { return *get(); }

  template <typename... Ts>
  inline void Init(const Ts&... params) {
    new(space_.void_data()) Type(params...);
  }

  inline void Destroy() {
    get()->~Type();
  }

 private:
  AlignedMemory<sizeof(Type), ALIGNOF(Type)> space_;
};

}  // namespace base

#endif  // BASE_MEMORY_MANUAL_CONSTRUCTOR_H_
