// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <dispatch/dispatch.h>

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/context.h"
#include "impeller/geometry/size.h"

namespace impeller {

class Surface;
class RenderPass;

class Renderer {
 public:
  virtual ~Renderer();

  bool IsValid() const;

  bool Render(const Surface& surface);

  std::shared_ptr<Context> GetContext() const;

 protected:
  Renderer(std::string shaders_directory);

  virtual bool OnIsValid() const = 0;

  virtual bool OnRender(RenderPass& pass) = 0;

 private:
  dispatch_semaphore_t frames_in_flight_sema_ = nullptr;
  std::shared_ptr<Context> context_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Renderer);
};

}  // namespace impeller
