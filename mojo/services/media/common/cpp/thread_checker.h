// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_THREAD_CHECKER_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_THREAD_CHECKER_H_

#if defined(NDEBUG)

#define DECLARE_THREAD_CHECKER(name)
#define CHECK_THREAD(name) ((void)0)

#else

#include <thread>

#include "mojo/public/cpp/environment/logging.h"

#define DECLARE_THREAD_CHECKER(name) \
  std::thread::id name = std::this_thread::get_id()
#define CHECK_THREAD(name) MOJO_DCHECK(name == std::this_thread::get_id())

#endif

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_THREAD_CHECKER_H_
