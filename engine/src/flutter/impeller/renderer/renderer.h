// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <dispatch/dispatch.h>

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/context.h"

namespace impeller {

class Surface;
class RenderPass;

class Renderer {
 public:
  using RenderCallback =
      std::function<bool(const Surface& surface, RenderPass& pass)>;

  Renderer(std::string shaders_directory, std::string main_library_file);

  ~Renderer();

  bool IsValid() const;

  bool Render(const Surface& surface, RenderCallback callback) const;

  std::shared_ptr<Context> GetContext() const;

 private:
  dispatch_semaphore_t frames_in_flight_sema_ = nullptr;
  std::shared_ptr<Context> context_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Renderer);
};

}  // namespace impeller
