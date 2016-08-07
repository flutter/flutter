// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GLUE_THREAD_H_
#define GLUE_THREAD_H_

#include <memory>

#include "lib/ftl/tasks/task_runner.h"

namespace glue {

class Thread {
 public:
  Thread(std::string name);
  ~Thread();

  bool Start();

  const ftl::RefPtr<ftl::TaskRunner>& task_runner() { return task_runner_; }

 private:
  class ThreadImpl;

  std::unique_ptr<ThreadImpl> impl_;
  ftl::RefPtr<ftl::TaskRunner> task_runner_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace glue

#endif  // GLUE_THREAD_H_
