// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/playground/playground.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class PlaygroundImpl {
 public:
  static std::unique_ptr<PlaygroundImpl> Create(PlaygroundBackend backend);

  virtual ~PlaygroundImpl();

  virtual std::shared_ptr<Context> CreateContext() const = 0;

  using WindowHandle = void*;

  virtual bool SetupWindow(WindowHandle handle,
                           std::shared_ptr<Context> context) = 0;

  virtual bool TeardownWindow(WindowHandle handle,
                              std::shared_ptr<Context> context) = 0;

  virtual std::unique_ptr<Surface> AcquireSurfaceFrame(
      std::shared_ptr<Context> context) = 0;

 protected:
  PlaygroundImpl();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(PlaygroundImpl);
};

}  // namespace impeller
