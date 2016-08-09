// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_DELEGATE_H_
#define SKY_SHELL_UI_DELEGATE_H_

#include "lib/ftl/functional/closure.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "sky/services/engine/sky_engine.mojom.h"

namespace sky {
namespace shell {

class UIDelegate {
 public:
  virtual void ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request) = 0;

  virtual void OnOutputSurfaceCreated(const ftl::Closure& gpu_continuation) = 0;

  virtual void OnOutputSurfaceDestroyed(
      const ftl::Closure& gpu_continuation) = 0;

 protected:
  virtual ~UIDelegate();
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_DELEGATE_H_
