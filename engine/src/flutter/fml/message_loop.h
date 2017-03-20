// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MESSAGE_LOOP_H_
#define FLUTTER_FML_MESSAGE_LOOP_H_

#include "lib/ftl/macros.h"
#include "lib/ftl/tasks/task_runner.h"

namespace fml {

class TaskRunner;
class MessageLoopImpl;

class MessageLoop {
 public:
  static MessageLoop& GetCurrent();

  bool IsValid() const;

  void Run();

  void Terminate();

  using TaskObserver = std::function<void(void)>;

  void SetTaskObserver(TaskObserver observer);

  ftl::RefPtr<ftl::TaskRunner> GetTaskRunner() const;

  static void EnsureInitializedForCurrentThread();

  static bool IsInitializedForCurrentThread();

  ~MessageLoop();

 private:
  friend class TaskRunner;
  friend class MessageLoopImpl;

  ftl::RefPtr<MessageLoopImpl> loop_;
  ftl::RefPtr<fml::TaskRunner> task_runner_;

  MessageLoop();

  ftl::RefPtr<MessageLoopImpl> GetLoopImpl() const;

  FTL_DISALLOW_COPY_AND_ASSIGN(MessageLoop);
};

}  // namespace fml

#endif  // FLUTTER_FML_MESSAGE_LOOP_H_
