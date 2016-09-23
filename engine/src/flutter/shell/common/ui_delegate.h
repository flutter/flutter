// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_DELEGATE_H_
#define SHELL_COMMON_DELEGATE_H_

#include "flutter/services/engine/sky_engine.mojom.h"
#include "lib/ftl/functional/closure.h"
#include "mojo/public/cpp/bindings/interface_request.h"

namespace shell {

class UIDelegate {
 public:
  virtual void ConnectToEngine(
      mojo::InterfaceRequest<sky::SkyEngine> request) = 0;

  virtual void OnOutputSurfaceCreated(const ftl::Closure& gpu_continuation) = 0;

  virtual void OnOutputSurfaceDestroyed(
      const ftl::Closure& gpu_continuation) = 0;

 protected:
  virtual ~UIDelegate();
};

}  // namespace shell

#endif  // SHELL_COMMON_DELEGATE_H_
