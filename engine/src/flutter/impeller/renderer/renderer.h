// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <dispatch/dispatch.h>

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"
#include "fml/synchronization/semaphore.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/context.h"

namespace impeller {

class Surface;
class RenderPass;

class Renderer {
 public:
  using RenderCallback = std::function<bool(RenderPass& pass)>;

  Renderer(std::shared_ptr<Context> context);

  ~Renderer();

  bool IsValid() const;

  bool Render(const Surface& surface, RenderCallback callback) const;

  std::shared_ptr<Context> GetContext() const;

 private:
  std::shared_ptr<fml::Semaphore> frames_in_flight_sema_;
  std::shared_ptr<Context> context_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Renderer);
};

}  // namespace impeller
