// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/playground/playground_impl.h"

namespace impeller {

class PlaygroundImplMTL final : public PlaygroundImpl {
 public:
  PlaygroundImplMTL();

  ~PlaygroundImplMTL();

 private:
  struct Data;

  WindowHandle handle_ = nullptr;
  // To ensure that ObjC stuff doesn't leak into C++ TUs.
  std::unique_ptr<Data> data_;

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

  FML_DISALLOW_COPY_AND_ASSIGN(PlaygroundImplMTL);
};

}  // namespace impeller
