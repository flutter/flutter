// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Define a set of C++ specific macros.
// Mojo C++ API users can assume that mojo/public/cpp/system/macros.h
// includes mojo/public/c/system/macros.h.

#ifndef MOJO_PUBLIC_CPP_SYSTEM_MACROS_H_
#define MOJO_PUBLIC_CPP_SYSTEM_MACROS_H_

#include "mojo/public/c/system/macros.h"  // Symbols exposed.

// A macro to disallow the copy constructor and operator= functions.
#define MOJO_DISALLOW_COPY_AND_ASSIGN(TypeName) \
  TypeName(const TypeName&) = delete;           \
  void operator=(const TypeName&) = delete

// Used to calculate the number of elements in an array.
// (See |arraysize()| in Chromium's base/macros.h for more details.)
namespace mojo {
namespace internal {
template <typename T, size_t N>
char(&ArraySizeHelper(T(&array)[N]))[N];
#if !defined(_MSC_VER)
template <typename T, size_t N>
char(&ArraySizeHelper(const T(&array)[N]))[N];
#endif
}  // namespace internal
}  // namespace mojo
#define MOJO_ARRAYSIZE(array) (sizeof(::mojo::internal::ArraySizeHelper(array)))

// Used to make a type move-only. See Chromium's base/move.h for more
// details. The MoveOnlyTypeForCPP03 typedef is for Chromium's base/callback.h
// to tell that this type is move-only.
#define MOJO_MOVE_ONLY_TYPE(type)                                              \
 private:                                                                      \
  type(type&);                                                                 \
  void operator=(type&);                                                       \
                                                                               \
 public:                                                                       \
  type&& Pass() MOJO_WARN_UNUSED_RESULT { return static_cast<type&&>(*this); } \
  typedef void MoveOnlyTypeForCPP03;                                           \
                                                                               \
 private:

// The C++ standard requires that static const members have an out-of-class
// definition (in a single compilation unit), but MSVC chokes on this (when
// language extensions, which are required, are enabled). (You're only likely to
// notice the need for a definition if you take the address of the member or,
// more commonly, pass it to a function that takes it as a reference argument --
// probably an STL function.) This macro makes MSVC do the right thing. See
// http://msdn.microsoft.com/en-us/library/34h23df8(v=vs.100).aspx for more
// information. This workaround does not appear to be necessary after VS2015.
// Use like:
//
// In the .h file:
//   struct Foo {
//     static const int kBar = 5;
//   };
//
// In the .cc file:
//   MOJO_STATIC_CONST_MEMBER_DEFINITION const int Foo::kBar;
#if defined(_MSC_VER) && _MSC_VER < 1900
#define MOJO_STATIC_CONST_MEMBER_DEFINITION __declspec(selectany)
#else
#define MOJO_STATIC_CONST_MEMBER_DEFINITION
#endif

namespace mojo {

// Used to explicitly mark the return value of a function as unused. (You this
// if you are really sure you don't want to do anything with the return value of
// a function marked with |MOJO_WARN_UNUSED_RESULT|.
template <typename T>
inline void ignore_result(const T&) {
}

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_SYSTEM_MACROS_H_
