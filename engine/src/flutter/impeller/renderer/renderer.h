// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_RENDERER_H_
#define FLUTTER_IMPELLER_RENDERER_RENDERER_H_

#include <functional>
#include <memory>

#include "flutter/fml/synchronization/semaphore.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

class Surface;

class Renderer {
 public:
  static constexpr size_t kDefaultMaxFramesInFlight = 3u;

  using RenderCallback = std::function<bool(RenderTarget& render_target)>;

  explicit Renderer(std::shared_ptr<Context> context,
                    size_t max_frames_in_flight = kDefaultMaxFramesInFlight);

  ~Renderer();

  bool IsValid() const;

  bool Render(std::unique_ptr<Surface> surface,
              const RenderCallback& callback) const;

  std::shared_ptr<Context> GetContext() const;

 private:
  std::shared_ptr<fml::Semaphore> frames_in_flight_sema_;
  std::shared_ptr<Context> context_;
  bool is_valid_ = false;

  Renderer(const Renderer&) = delete;

  Renderer& operator=(const Renderer&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_RENDERER_H_
