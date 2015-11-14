// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_VIEW_H_
#define SKY_SHELL_PLATFORM_VIEW_H_

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "sky/shell/ui_delegate.h"
#include "sky/shell/rasterizer.h"

namespace sky {
namespace shell {

class PlatformView {
 public:
  struct Config {
    Config();
    ~Config();

    base::WeakPtr<UIDelegate> ui_delegate;
    Rasterizer* rasterizer;
    scoped_refptr<base::SingleThreadTaskRunner> ui_task_runner;
  };

  // Implemented by each platform.
  static PlatformView* Create(const Config& config);

  virtual ~PlatformView();

  void ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request);

 protected:
  explicit PlatformView(const Config& config);

  Config config_;

 private:
  DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_VIEW_H_
