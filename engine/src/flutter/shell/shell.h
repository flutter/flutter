// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_SHELL_H_
#define SKY_SHELL_SHELL_H_

#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/threading/thread.h"

namespace base {
class SingleThreadTaskRunner;
}

namespace sky {
namespace shell {
class Engine;
class Rasterizer;
class PlatformView;

class Shell {
 public:
  ~Shell();

  static void Init(
      scoped_refptr<base::SingleThreadTaskRunner> java_task_runner);
  static Shell& Shared();

  PlatformView* view() const { return view_.get(); }

 private:
  explicit Shell(scoped_refptr<base::SingleThreadTaskRunner> java_task_runner);

  void InitGPU(const base::Thread::Options& options);
  void InitUI(const base::Thread::Options& options);
  void InitView();

  scoped_refptr<base::SingleThreadTaskRunner> java_task_runner_;
  scoped_ptr<base::Thread> gpu_thread_;
  scoped_ptr<base::Thread> ui_thread_;

  scoped_ptr<PlatformView> view_;
  scoped_ptr<Rasterizer> rasterizer_;
  scoped_ptr<Engine> engine_;

  DISALLOW_COPY_AND_ASSIGN(Shell);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_SHELL_H_
