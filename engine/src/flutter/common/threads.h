// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_THREADS_H_
#define FLUTTER_COMMON_THREADS_H_

#include "lib/fxl/tasks/task_runner.h"

#define ASSERT_IS_PLATFORM_THREAD \
  FXL_DCHECK(::blink::Threads::Platform()->RunsTasksOnCurrentThread());
#define ASSERT_IS_GPU_THREAD \
  FXL_DCHECK(::blink::Threads::Gpu()->RunsTasksOnCurrentThread());
#define ASSERT_IS_UI_THREAD \
  FXL_DCHECK(::blink::Threads::UI()->RunsTasksOnCurrentThread());
#define ASSERT_IS_IO_THREAD \
  FXL_DCHECK(::blink::Threads::IO()->RunsTasksOnCurrentThread());

namespace blink {

class Threads {
 public:
  Threads();
  Threads(fxl::RefPtr<fxl::TaskRunner> platform,
          fxl::RefPtr<fxl::TaskRunner> gpu,
          fxl::RefPtr<fxl::TaskRunner> ui,
          fxl::RefPtr<fxl::TaskRunner> io);
  ~Threads();

  static const fxl::RefPtr<fxl::TaskRunner>& Platform();
  static const fxl::RefPtr<fxl::TaskRunner>& Gpu();
  static const fxl::RefPtr<fxl::TaskRunner>& UI();
  static const fxl::RefPtr<fxl::TaskRunner>& IO();

  static void Set(const Threads& settings);

 private:
  static const Threads& Get();

  fxl::RefPtr<fxl::TaskRunner> platform_;
  fxl::RefPtr<fxl::TaskRunner> gpu_;
  fxl::RefPtr<fxl::TaskRunner> ui_;
  fxl::RefPtr<fxl::TaskRunner> io_;
};

}  // namespace blink

#endif  // FLUTTER_COMMON_THREADS_H_
