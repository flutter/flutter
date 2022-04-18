// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/playground/playground_impl.h"

namespace impeller {

class PlaygroundImplGLES final : public PlaygroundImpl {
 public:
  PlaygroundImplGLES();

  ~PlaygroundImplGLES();

 private:
  // |PlaygroundImpl|
  std::shared_ptr<Context> CreateContext() const override;

  // |PlaygroundImpl|
  bool SetupWindow(WindowHandle handle,
                   std::shared_ptr<Context> context) override;

  // |PlaygroundImpl|
  bool TeardownWindow(WindowHandle handle,
                      std::shared_ptr<Context> context) override;

  // |PlaygroundImpl|
  std::unique_ptr<Surface> AcquireSurfaceFrame(
      std::shared_ptr<Context> context) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlaygroundImplGLES);
};

}  // namespace impeller
