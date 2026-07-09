// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_TASK_RUNNER_UTIL_H_
#define FLUTTER_FML_TASK_RUNNER_UTIL_H_

#include <functional>

#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/task_runner.h"

namespace fml {

/// A BasicTaskRunner that posts tasks to another task runner.
///
/// This can be used to adapt an fml::RefPtr<fml::TaskRunner> to APIs that
/// take a BasicTaskRunner that is not managed by fml::RefPtr.
class WrapperBasicTaskRunner : public BasicTaskRunner {
 public:
  explicit WrapperBasicTaskRunner(fml::RefPtr<fml::TaskRunner> task_runner);

  virtual ~WrapperBasicTaskRunner() = default;

  void PostTask(const fml::closure& task) override;

 private:
  fml::RefPtr<fml::TaskRunner> task_runner_;

  FML_DISALLOW_COPY_AND_ASSIGN(WrapperBasicTaskRunner);
};

/// A BasicTaskRunner that wraps another task runner and takes a function
/// that indicates whether that task runner is still usable.
///
/// Before each posted task is run, ConditionalBasicTaskRunner will call the
/// is_usable function on the underlying task runner's thread.  If is_usable
/// returns false, then the task will not be executed.
class ConditionalBasicTaskRunner : public BasicTaskRunner {
 public:
  explicit ConditionalBasicTaskRunner(fml::RefPtr<fml::TaskRunner> task_runner,
                                      std::function<bool()> is_usable);

  virtual ~ConditionalBasicTaskRunner() = default;

  void PostTask(const fml::closure& task) override;

 private:
  fml::RefPtr<fml::TaskRunner> task_runner_;
  const std::function<bool()> is_usable_;

  FML_DISALLOW_COPY_AND_ASSIGN(ConditionalBasicTaskRunner);
};

}  // namespace fml

#endif  // FLUTTER_FML_TASK_RUNNER_UTIL_H_
