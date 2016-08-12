// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_THREADS_H_
#define FLUTTER_COMMON_THREADS_H_

#include "lib/ftl/tasks/task_runner.h"

namespace blink {

class Threads {
 public:
  Threads();
  Threads(ftl::RefPtr<ftl::TaskRunner> gpu,
          ftl::RefPtr<ftl::TaskRunner> ui,
          ftl::RefPtr<ftl::TaskRunner> io);
  ~Threads();

  static const ftl::RefPtr<ftl::TaskRunner>& Gpu();
  static const ftl::RefPtr<ftl::TaskRunner>& UI();
  static const ftl::RefPtr<ftl::TaskRunner>& IO();

  static void Set(const Threads& settings);

 private:
  static const Threads& Get();

  ftl::RefPtr<ftl::TaskRunner> gpu_;
  ftl::RefPtr<ftl::TaskRunner> ui_;
  ftl::RefPtr<ftl::TaskRunner> io_;
};

}  // namespace blink

#endif  // FLUTTER_COMMON_THREADS_H_
