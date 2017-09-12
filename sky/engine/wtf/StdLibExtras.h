/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_STDLIBEXTRAS_H_
#define SKY_ENGINE_WTF_STDLIBEXTRAS_H_

#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/CPU.h"
#include "flutter/sky/engine/wtf/CheckedArithmetic.h"

// Use this to declare and define a static local variable (static T;) so that
//  it is leaked so that its destructors are not called at exit.
#ifndef DEFINE_STATIC_LOCAL
#define DEFINE_STATIC_LOCAL(type, name, arguments) \
  static type& name = *new type arguments
#endif

// Use this to declare and define a static local pointer to a ref-counted object
// so that it is leaked so that the object's destructors are not called at exit.
// This macro should be used with ref-counted objects rather than
// DEFINE_STATIC_LOCAL macro, as this macro does not lead to an extra memory
// allocation.
#ifndef DEFINE_STATIC_REF
#define DEFINE_STATIC_REF(type, name, arguments) \
  static type* name = PassRefPtr<type>(arguments).leakRef();
#endif

// Use this macro to declare and define a debug-only global variable that may
// have a non-trivial constructor and destructor. When building with clang, this
// will suppress warnings about global constructors and exit-time destructors.
#ifndef NDEBUG
#if COMPILER(CLANG)
#define DEFINE_DEBUG_ONLY_GLOBAL(type, name, arguments)                       \
  _Pragma("clang diagnostic push")                                            \
      _Pragma("clang diagnostic ignored \"-Wglobal-constructors\"") _Pragma(  \
          "clang diagnostic ignored \"-Wexit-time-destructors\"") static type \
          name arguments;                                                     \
  _Pragma("clang diagnostic pop")
#else
#define DEFINE_DEBUG_ONLY_GLOBAL(type, name, arguments) \
  static type name arguments;
#endif  // COMPILER(CLANG)
#else
#define DEFINE_DEBUG_ONLY_GLOBAL(type, name, arguments)
#endif  // NDEBUG

/*
 * The reinterpret_cast<Type1*>([pointer to Type2]) expressions - where
 * sizeof(Type1) > sizeof(Type2) - cause the following warning on ARM with GCC:
 * increases required alignment of target type.
 *
 * An implicit or an extra static_cast<void*> bypasses the warning.
 * For more info see the following bugzilla entries:
 * - https://bugs.webkit.org/show_bug.cgi?id=38045
 * - http://gcc.gnu.org/bugzilla/show_bug.cgi?id=43976
 */
#if CPU(ARM) && COMPILER(GCC)
template <typename Type>
bool isPointerTypeAlignmentOkay(Type* ptr) {
  return !(reinterpret_cast<intptr_t>(ptr) % __alignof__(Type));
}

template <typename TypePtr>
TypePtr reinterpret_cast_ptr(void* ptr) {
  ASSERT(isPointerTypeAlignmentOkay(reinterpret_cast<TypePtr>(ptr)));
  return reinterpret_cast<TypePtr>(ptr);
}

template <typename TypePtr>
TypePtr reinterpret_cast_ptr(const void* ptr) {
  ASSERT(isPointerTypeAlignmentOkay(reinterpret_cast<TypePtr>(ptr)));
  return reinterpret_cast<TypePtr>(ptr);
}
#else
template <typename Type>
bool isPointerTypeAlignmentOkay(Type*) {
  return true;
}
#define reinterpret_cast_ptr reinterpret_cast
#endif

namespace WTF {

/*
 * C++'s idea of a reinterpret_cast lacks sufficient cojones.
 */
template <typename TO, typename FROM>
inline TO bitwise_cast(FROM from) {
  COMPILE_ASSERT(sizeof(TO) == sizeof(FROM),
                 WTF_bitwise_cast_sizeof_casted_types_is_equal);
  union {
    FROM from;
    TO to;
  } u;
  u.from = from;
  return u.to;
}

template <typename To, typename From>
inline To safeCast(From value) {
  ASSERT(isInBounds<To>(value));
  return static_cast<To>(value);
}

// Macro that returns a compile time constant with the length of an array, but
// gives an error if passed a non-array.
template <typename T, size_t Size>
char (&ArrayLengthHelperFunction(T (&)[Size]))[Size];
// GCC needs some help to deduce a 0 length array.
#if COMPILER(GCC)
template <typename T>
char (&ArrayLengthHelperFunction(T (&)[0]))[0];
#endif
#define WTF_ARRAY_LENGTH(array) sizeof(::WTF::ArrayLengthHelperFunction(array))

}  // namespace WTF

// This version of placement new omits a 0 check.
enum NotNullTag { NotNull };
inline void* operator new(size_t, NotNullTag, void* location) {
  ASSERT(location);
  return location;
}

using WTF::bitwise_cast;
using WTF::safeCast;

#endif  // SKY_ENGINE_WTF_STDLIBEXTRAS_H_
