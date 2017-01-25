// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_CONTENT_HANDLER_THREAD_H_
#define FLUTTER_CONTENT_HANDLER_CONTENT_HANDLER_THREAD_H_

#include <pthread.h>

#include <functional>

#include "lib/ftl/macros.h"
#include "lib/ftl/memory/ref_ptr.h"
#include "lib/ftl/tasks/task_runner.h"

namespace mtl {
namespace internal {
class IncomingTaskQueue;
}  // namespace internal
}  // namespace mtl

namespace flutter_runner {

class Thread {
 public:
  Thread();

  ~Thread();

  ftl::RefPtr<ftl::TaskRunner> TaskRunner() const;

  bool Join();

  bool IsValid() const;

 private:
  bool valid_;
  pthread_t thread_;
  ftl::RefPtr<mtl::internal::IncomingTaskQueue> task_runner_;

  void Main();

  FTL_DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_CONTENT_HANDLER_THREAD_H_
