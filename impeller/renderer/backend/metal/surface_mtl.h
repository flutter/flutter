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
#pragma GCC diagnostic push
  // Disable the diagnostic for iOS Simulators. Metal without emulation isn't
  // available prior to iOS 13 and that's what the simulator headers say when
  // support for CAMetalLayer begins. CAMetalLayer is available on iOS 8.0 and
  // above which is well below Flutters support level.
#pragma GCC diagnostic ignored "-Wunguarded-availability-new"
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
  static std::unique_ptr<SurfaceMTL> WrapCurrentMetalLayerDrawable(
      const std::shared_ptr<Context>& context,
      CAMetalLayer* layer);
#pragma GCC diagnostic pop

  // |Surface|
  ~SurfaceMTL() override;

  id<MTLDrawable> drawable() const { return drawable_; }

 private:
  std::weak_ptr<Context> context_;
  id<MTLDrawable> drawable_ = nil;

  SurfaceMTL(const std::weak_ptr<Context>& context,
             const RenderTarget& target,
             id<MTLDrawable> drawable);

  // |Surface|
  bool Present() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceMTL);
};

}  // namespace impeller
