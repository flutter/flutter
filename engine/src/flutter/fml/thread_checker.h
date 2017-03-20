// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_THREAD_CHECKER_H_
#define FLUTTER_FML_THREAD_CHECKER_H_

#include <thread>

#include "lib/ftl/macros.h"

namespace fml {

class ThreadChecker {
 public:
  ThreadChecker();

  ~ThreadChecker();

  bool IsCalledOnValidThread() const;

 private:
  const std::thread::id handle_;

  FTL_DISALLOW_COPY_AND_ASSIGN(ThreadChecker);
};

}  // namespace fml

#endif  // FLUTTER_FML_THREAD_CHECKER_H_
