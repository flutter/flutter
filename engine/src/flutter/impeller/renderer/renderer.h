// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/synchronization/semaphore.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

class Surface;
class RenderPass;

class Renderer {
 public:
  static constexpr size_t kDefaultMaxFramesInFlight = 3u;

  using RenderCallback = std::function<bool(RenderTarget& render_target)>;

  Renderer(std::shared_ptr<Context> context,
           size_t max_frames_in_flight = kDefaultMaxFramesInFlight);

  ~Renderer();

  bool IsValid() const;

  bool Render(std::unique_ptr<Surface> surface, RenderCallback callback) const;

  std::shared_ptr<Context> GetContext() const;

 private:
  std::shared_ptr<fml::Semaphore> frames_in_flight_sema_;
  std::shared_ptr<Context> context_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Renderer);
};

}  // namespace impeller
