// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "impeller/playground/playground_impl.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class PlaygroundImplVK final : public PlaygroundImpl {
 public:
  PlaygroundImplVK();

  ~PlaygroundImplVK();

 private:
  std::shared_ptr<fml::ConcurrentMessageLoop> concurrent_loop_;
  std::shared_ptr<Context> context_;

  // Windows management.
  static void DestroyWindowHandle(WindowHandle handle);
  using UniqueHandle = std::unique_ptr<void, decltype(&DestroyWindowHandle)>;
  UniqueHandle handle_;

  // |PlaygroundImpl|
  std::shared_ptr<Context> GetContext() const override;

  // |PlaygroundImpl|
  WindowHandle GetWindowHandle() const override;

  // |PlaygroundImpl|
  std::unique_ptr<Surface> AcquireSurfaceFrame(
      std::shared_ptr<Context> context) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlaygroundImplVK);
};

}  // namespace impeller
