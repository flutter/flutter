// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <QuartzCore/CAMetalLayer.h>

#include "flutter/fml/macros.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class SurfaceMTL final : public Surface {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Wraps the current drawable of the given Metal layer to create
  ///             a surface Impeller can render to. The surface must be created
  ///             as late as possible and discarded immediately after rendering
  ///             to it.
  ///
  /// @param[in]  context  The context
  /// @param[in]    layer  The layer whose current drawable to wrap to create a
  ///                      surface.
  ///
  /// @return     A pointer to the wrapped surface or null.
  ///
  static std::unique_ptr<Surface> WrapCurrentMetalLayerDrawable(
      std::shared_ptr<Context> context,
      CAMetalLayer* layer);

  // |Surface|
  ~SurfaceMTL() override;

  // |Surface|
  bool Present() const override;

 private:
  id<MTLDrawable> drawable_ = nil;

  SurfaceMTL(RenderTarget target, id<MTLDrawable> drawable);

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceMTL);
};

}  // namespace impeller
