// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/toolkit/egl/config.h"
#include "impeller/toolkit/egl/egl.h"

namespace impeller {
namespace egl {

class Context;
class Surface;

class Display {
 public:
  Display();

  virtual ~Display();

  virtual bool IsValid() const;

  virtual std::unique_ptr<Config> ChooseConfig(ConfigDescriptor config) const;

  virtual std::unique_ptr<Context> CreateContext(const Config& config,
                                                 const Context* share_context);

  virtual std::unique_ptr<Surface> CreateWindowSurface(
      const Config& config,
      EGLNativeWindowType window);

  virtual std::unique_ptr<Surface>
  CreatePixelBufferSurface(const Config& config, size_t width, size_t height);

 private:
  EGLDisplay display_ = EGL_NO_DISPLAY;

  Display(const Display&) = delete;

  Display& operator=(const Display&) = delete;
};

}  // namespace egl
}  // namespace impeller
