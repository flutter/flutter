// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// YASM is written in C99 and requires <stdint.h> and <inttypes.h>.

#ifndef THIRD_PARTY_YASM_SOURCE_CONFIG_WIN_STDINT_H_
#define THIRD_PARTY_YASM_SOURCE_CONFIG_WIN_STDINT_H_

#if !defined(_MSC_VER)
#error This file should only be included when compiling with MSVC.
#endif

// Define C99 equivalent types.
typedef signed char           int8_t;
typedef signed short          int16_t;
typedef signed int            int32_t;
typedef signed long long      int64_t;
typedef unsigned char         uint8_t;
typedef unsigned short        uint16_t;
typedef unsigned int          uint32_t;
typedef unsigned long long    uint64_t;

// Define the C99 INT64_C macro that is used for declaring 64-bit literals.
// Technically, these should only be definied when __STDC_CONSTANT_MACROS
// is defined.
#define INT64_C(value) value##LL
#define UINT64_C(value) value##ULL

#endif  // THIRD_PARTY_YASM_SOURCE_CONFIG_WIN_STDINT_H_
