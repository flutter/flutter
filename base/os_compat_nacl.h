// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_OS_COMPAT_NACL_H_
#define BASE_OS_COMPAT_NACL_H_

#include <sys/types.h>

#if !defined (__GLIBC__)
// NaCl has no timegm().
extern "C" time_t timegm(struct tm* const t);
#endif  // !defined (__GLIBC__)

#endif  // BASE_OS_COMPAT_NACL_H_

