// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "gtest/gtest.h"
#include "impeller/geometry/point.h"
#include "impeller/renderer/renderer.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class Playground : public ::testing::Test {
 public:
  Playground();

  ~Playground();

  Point GetCursorPosition() const;

  ISize GetWindowSize() const;

  std::shared_ptr<Context> GetContext() const;

  bool OpenPlaygroundHere(Renderer::RenderCallback render_callback);

  std::shared_ptr<Texture> CreateTextureForFixture(
      const char* fixture_name) const;

 private:
  Renderer renderer_;
  Point cursor_position_;

  void SetCursorPosition(Point pos);

  FML_DISALLOW_COPY_AND_ASSIGN(Playground);
};

}  // namespace impeller
