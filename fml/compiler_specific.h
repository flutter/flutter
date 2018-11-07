// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_COMPILER_SPECIFIC_H_
#define FLUTTER_FML_COMPILER_SPECIFIC_H_

#if !defined(__GNUC__) && !defined(__clang__) && !defined(_MSC_VER)
#error Unsupported compiler.
#endif

// Annotate a variable indicating it's ok if the variable is not used.
// (Typically used to silence a compiler warning when the assignment
// is important for some other reason.)
// Use like:
//   int x = ...;
//   FML_ALLOW_UNUSED_LOCAL(x);
#define FML_ALLOW_UNUSED_LOCAL(x) false ? (void)x : (void)0

// Annotate a typedef or function indicating it's ok if it's not used.
// Use like:
//   typedef Foo Bar ALLOW_UNUSED_TYPE;
#if defined(__GNUC__) || defined(__clang__)
#define FML_ALLOW_UNUSED_TYPE __attribute__((unused))
#else
#define FML_ALLOW_UNUSED_TYPE
#endif

// Annotate a function indicating it should not be inlined.
// Use like:
//   NOINLINE void DoStuff() { ... }
#if defined(__GNUC__) || defined(__clang__)
#define FML_NOINLINE __attribute__((noinline))
#elif defined(_MSC_VER)
#define FML_NOINLINE __declspec(noinline)
#endif

// Specify memory alignment for structs, classes, etc.
// Use like:
//   class FML_ALIGNAS(16) MyClass { ... }
//   FML_ALIGNAS(16) int array[4];
#if defined(__GNUC__) || defined(__clang__)
#define FML_ALIGNAS(byte_alignment) __attribute__((aligned(byte_alignment)))
#elif defined(_MSC_VER)
#define FML_ALIGNAS(byte_alignment) __declspec(align(byte_alignment))
#endif

// Return the byte alignment of the given type (available at compile time).
// Use like:
//   FML_ALIGNOF(int32)  // this would be 4
#if defined(__GNUC__) || defined(__clang__)
#define FML_ALIGNOF(type) __alignof__(type)
#elif defined(_MSC_VER)
#define FML_ALIGNOF(type) __alignof(type)
#endif

// Annotate a function indicating the caller must examine the return value.
// Use like:
//   int foo() FML_WARN_UNUSED_RESULT;
// To explicitly ignore a result, see |ignore_result()| in base/macros.h.
#if defined(__GNUC__) || defined(__clang__)
#define FML_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
#define FML_WARN_UNUSED_RESULT
#endif

// Tell the compiler a function is using a printf-style format string.
// |format_param| is the one-based index of the format string parameter;
// |dots_param| is the one-based index of the "..." parameter.
// For v*printf functions (which take a va_list), pass 0 for dots_param.
// (This is undocumented but matches what the system C headers do.)
#if defined(__GNUC__) || defined(__clang__)
#define FML_PRINTF_FORMAT(format_param, dots_param) \
  __attribute__((format(printf, format_param, dots_param)))
#else
#define FML_PRINTF_FORMAT(format_param, dots_param)
#endif

#endif  // FLUTTER_FML_COMPILER_SPECIFIC_H_
