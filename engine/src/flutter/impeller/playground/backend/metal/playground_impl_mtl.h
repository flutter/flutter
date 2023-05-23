// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/synchronization/sync_switch.h"
#include "impeller/playground/playground_impl.h"

namespace impeller {

class PlaygroundImplMTL final : public PlaygroundImpl {
 public:
  explicit PlaygroundImplMTL(PlaygroundSwitches switches);

  ~PlaygroundImplMTL();

 private:
  struct Data;

  static void DestroyWindowHandle(WindowHandle handle);
  using UniqueHandle = std::unique_ptr<void, decltype(&DestroyWindowHandle)>;
  UniqueHandle handle_;

  // To ensure that ObjC stuff doesn't leak into C++ TUs.
  std::unique_ptr<Data> data_;
  std::shared_ptr<Context> context_;
  std::shared_ptr<fml::ConcurrentMessageLoop> concurrent_loop_;
  std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch_;

  // |PlaygroundImpl|
  std::shared_ptr<Context> GetContext() const override;

  // |PlaygroundImpl|
  WindowHandle GetWindowHandle() const override;

  // |PlaygroundImpl|
  std::unique_ptr<Surface> AcquireSurfaceFrame(
      std::shared_ptr<Context> context) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlaygroundImplMTL);
};

}  // namespace impeller
