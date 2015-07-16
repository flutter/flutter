// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file defines preprocessor macros for stringizing preprocessor
// symbols (or their output) and manipulating preprocessor symbols
// that define strings.

#ifndef BASE_STRINGS_STRINGIZE_MACROS_H_
#define BASE_STRINGS_STRINGIZE_MACROS_H_

#include "build/build_config.h"

// This is not very useful as it does not expand defined symbols if
// called directly. Use its counterpart without the _NO_EXPANSION
// suffix, below.
#define STRINGIZE_NO_EXPANSION(x) #x

// Use this to quote the provided parameter, first expanding it if it
// is a preprocessor symbol.
//
// For example, if:
//   #define A FOO
//   #define B(x) myobj->FunctionCall(x)
//
// Then:
//   STRINGIZE(A) produces "FOO"
//   STRINGIZE(B(y)) produces "myobj->FunctionCall(y)"
#define STRINGIZE(x) STRINGIZE_NO_EXPANSION(x)

#endif  // BASE_STRINGS_STRINGIZE_MACROS_H_
