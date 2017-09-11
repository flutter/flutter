// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MESSAGE_LOOP_H_
#define FLUTTER_FML_MESSAGE_LOOP_H_

#include "flutter/fml/task_observer.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/tasks/task_runner.h"

namespace fml {

class TaskRunner;
class MessageLoopImpl;

class MessageLoop {
 public:
  static MessageLoop& GetCurrent();

  bool IsValid() const;

  void Run();

  void Terminate();

  void AddTaskObserver(TaskObserver* observer);

  void RemoveTaskObserver(TaskObserver* observer);

  fxl::RefPtr<fxl::TaskRunner> GetTaskRunner() const;

  static void EnsureInitializedForCurrentThread();

  static bool IsInitializedForCurrentThread();

  ~MessageLoop();

 private:
  friend class TaskRunner;
  friend class MessageLoopImpl;

  fxl::RefPtr<MessageLoopImpl> loop_;
  fxl::RefPtr<fml::TaskRunner> task_runner_;

  MessageLoop();

  fxl::RefPtr<MessageLoopImpl> GetLoopImpl() const;

  FXL_DISALLOW_COPY_AND_ASSIGN(MessageLoop);
};

}  // namespace fml

#endif  // FLUTTER_FML_MESSAGE_LOOP_H_
