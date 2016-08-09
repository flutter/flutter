// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides an implementation of |mojo::platform::MessageLoop| that
// wraps a |base::MessageLoop|.

#ifndef MOJO_EDK_BASE_EDK_PLATFORM_MESSAGE_LOOP_IMPL_H_
#define MOJO_EDK_BASE_EDK_PLATFORM_MESSAGE_LOOP_IMPL_H_

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/task_runner.h"

namespace base_edk {

class PlatformMessageLoopImpl : public mojo::platform::MessageLoop {
 public:
  explicit PlatformMessageLoopImpl(
      base::MessageLoop::Type type = base::MessageLoop::TYPE_DEFAULT);
  explicit PlatformMessageLoopImpl(scoped_ptr<base::MessagePump> pump);
  ~PlatformMessageLoopImpl() override;

  const base::MessageLoop& base_message_loop() const {
    return base_message_loop_;
  }
  base::MessageLoop& base_message_loop() { return base_message_loop_; }

  // |mojo::platform::MessageLoop| implementation:
  void Run() override;
  void RunUntilIdle() override;
  void QuitWhenIdle() override;
  void QuitNow() override;
  const mojo::util::RefPtr<mojo::platform::TaskRunner>& GetTaskRunner()
      const override;
  bool IsRunningOnCurrentThread() const override;

 private:
  base::MessageLoop base_message_loop_;
  mojo::util::RefPtr<mojo::platform::TaskRunner> task_runner_;

  DISALLOW_COPY_AND_ASSIGN(PlatformMessageLoopImpl);
};

}  // namespace base_edk

#endif  // MOJO_EDK_BASE_EDK_PLATFORM_MESSAGE_LOOP_IMPL_H_
