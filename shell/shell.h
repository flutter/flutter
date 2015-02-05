// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_SHELL_H_
#define SKY_SHELL_SHELL_H_

#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "sky/shell/gpu/rasterizer.h"
#include "sky/shell/sky_view.h"
#include "sky/shell/ui/engine.h"

namespace base {
class Thread;
class SingleThreadTaskRunner;
}

namespace sky {
namespace shell {
class SkyView;

class Shell : public SkyView::Delegate {
 public:
  explicit Shell(scoped_refptr<base::SingleThreadTaskRunner> java_task_runner);
  ~Shell();

  void Init();

 private:
  void OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) override;
  void OnDestroyed() override;

  scoped_refptr<base::SingleThreadTaskRunner> java_task_runner_;
  scoped_ptr<base::Thread> gpu_thread_;
  scoped_ptr<base::Thread> ui_thread_;

  scoped_ptr<SkyView> view_;
  scoped_ptr<Rasterizer> rasterizer_;
  scoped_ptr<Engine> engine_;

  DISALLOW_COPY_AND_ASSIGN(Shell);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_SHELL_H_
