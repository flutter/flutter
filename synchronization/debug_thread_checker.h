// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SYNCHRONIZATION_DEBUG_THREAD_CHECKER_H_
#define FLUTTER_SYNCHRONIZATION_DEBUG_THREAD_CHECKER_H_

#ifndef NDEBUG

#include <pthread.h>
#include "lib/fxl/synchronization/thread_checker.h"

#define FLUTTER_THREAD_CHECKER_DECLARE(x) ::fxl::ThreadChecker x;

#define FLUTTER_THREAD_CHECKER_CHECK(x) FXL_CHECK(x.IsCreationThreadCurrent());

#else  // NDEBUG

#define FLUTTER_THREAD_CHECKER_DECLARE(x)

#define FLUTTER_THREAD_CHECKER_CHECK(x)

#endif  // NDEBUG

#endif  // FLUTTER_SYNCHRONIZATION_DEBUG_THREAD_CHECKER_H_
