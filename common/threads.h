// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_THREADS_H_
#define FLUTTER_COMMON_THREADS_H_

#include "lib/ftl/tasks/task_runner.h"

#define ASSERT_IS_PLATFORM_THREAD \
  FTL_DCHECK(::blink::Threads::Platform()->RunsTasksOnCurrentThread());
#define ASSERT_IS_GPU_THREAD \
  FTL_DCHECK(::blink::Threads::Gpu()->RunsTasksOnCurrentThread());
#define ASSERT_IS_UI_THREAD \
  FTL_DCHECK(::blink::Threads::UI()->RunsTasksOnCurrentThread());
#define ASSERT_IS_IO_THREAD \
  FTL_DCHECK(::blink::Threads::IO()->RunsTasksOnCurrentThread());

namespace blink {

class Threads {
 public:
  Threads();
  Threads(ftl::RefPtr<ftl::TaskRunner> platform,
          ftl::RefPtr<ftl::TaskRunner> gpu,
          ftl::RefPtr<ftl::TaskRunner> ui,
          ftl::RefPtr<ftl::TaskRunner> io);
  ~Threads();

  static const ftl::RefPtr<ftl::TaskRunner>& Platform();
  static const ftl::RefPtr<ftl::TaskRunner>& Gpu();
  static const ftl::RefPtr<ftl::TaskRunner>& UI();
  static const ftl::RefPtr<ftl::TaskRunner>& IO();

  static void Set(const Threads& settings);

 private:
  static const Threads& Get();

  ftl::RefPtr<ftl::TaskRunner> platform_;
  ftl::RefPtr<ftl::TaskRunner> gpu_;
  ftl::RefPtr<ftl::TaskRunner> ui_;
  ftl::RefPtr<ftl::TaskRunner> io_;
};

}  // namespace blink

#endif  // FLUTTER_COMMON_THREADS_H_
