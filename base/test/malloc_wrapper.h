// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_MALLOC_WRAPPER_H_
#define BASE_TEST_MALLOC_WRAPPER_H_

#include "base/basictypes.h"

// BASE_EXPORT depends on COMPONENT_BUILD.
// This will always be a separate shared library, so don't use BASE_EXPORT here.
#if defined(WIN32)
#define MALLOC_WRAPPER_EXPORT __declspec(dllexport)
#else
#define MALLOC_WRAPPER_EXPORT __attribute__((visibility("default")))
#endif  // defined(WIN32)

// Calls malloc directly.
MALLOC_WRAPPER_EXPORT void* MallocWrapper(size_t size);

#endif  // BASE_TEST_MALLOC_WRAPPER_H_
