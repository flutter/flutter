// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/context.h"
#include "impeller/compositor/surface.h"
#include "impeller/geometry/size.h"

namespace impeller {

class Renderer {
 public:
  Renderer(std::string shaders_directory);

  ~Renderer();

  bool IsValid() const;

  bool SurfaceSizeDidChange(Size size);

  bool Render();

  std::shared_ptr<Context> GetContext() const;

 private:
  std::shared_ptr<Context> context_;
  std::unique_ptr<Surface> surface_;
  Size size_;
  bool is_valid_ = false;

  bool ShouldRender() const;

  FML_DISALLOW_COPY_AND_ASSIGN(Renderer);
};

}  // namespace impeller
