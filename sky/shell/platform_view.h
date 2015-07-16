// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_VIEW_H_
#define SKY_SHELL_PLATFORM_VIEW_H_

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "sky/shell/ui_delegate.h"

namespace sky {
namespace shell {

class PlatformView {
 public:
  struct Config {
    Config();
    ~Config();

    base::WeakPtr<UIDelegate> ui_delegate;
    scoped_refptr<base::SingleThreadTaskRunner> ui_task_runner;
  };

  static PlatformView* Create(const Config& config);

  virtual ~PlatformView();

  void ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request);

 protected:
  explicit PlatformView(const Config& config);

  void SurfaceWasCreated();
  void SurfaceWasDestroyed();

  Config config_;
  gfx::AcceleratedWidget window_;

 private:
  DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_VIEW_H_
