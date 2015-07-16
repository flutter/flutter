// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_SHELL_H_
#define SKY_SHELL_SHELL_H_

#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/threading/thread.h"
#include "sky/shell/service_provider.h"

namespace sky {
namespace shell {
class ServiceProviderContext;

class Shell {
 public:
  ~Shell();

  static void Init(
      scoped_ptr<ServiceProviderContext> service_provider_context);
  static Shell& Shared();

  scoped_refptr<base::SingleThreadTaskRunner> gpu_task_runner() const {
    return gpu_thread_->message_loop()->task_runner();
  }

  scoped_refptr<base::SingleThreadTaskRunner> ui_task_runner() const {
    return ui_thread_->message_loop()->task_runner();
  }

  ServiceProviderContext* service_provider_context() const {
    return service_provider_context_.get();
  }

 private:
  explicit Shell(scoped_ptr<ServiceProviderContext> service_provider_context);

  void InitGPU(const base::Thread::Options& options);
  void InitUI(const base::Thread::Options& options);

  scoped_ptr<base::Thread> gpu_thread_;
  scoped_ptr<base::Thread> ui_thread_;
  scoped_ptr<ServiceProviderContext> service_provider_context_;

  DISALLOW_COPY_AND_ASSIGN(Shell);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_SHELL_H_
