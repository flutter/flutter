// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_THREAD_H_
#define FLUTTER_FML_THREAD_H_

#include <atomic>
#include <memory>
#include <thread>

#include "flutter/fml/macros.h"
#include "flutter/fml/task_runner.h"

namespace fml {

class Thread {
 public:
  explicit Thread(const std::string& name = "");

  ~Thread();

  fml::RefPtr<fml::TaskRunner> GetTaskRunner() const;

  void Join();

  static void SetCurrentThreadName(const std::string& name);

 private:
  std::unique_ptr<std::thread> thread_;
  fml::RefPtr<fml::TaskRunner> task_runner_;
  std::atomic_bool joined_;

  FML_DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace fml

#endif  // FLUTTER_FML_THREAD_H_
