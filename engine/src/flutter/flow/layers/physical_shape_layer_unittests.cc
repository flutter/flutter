// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/physical_shape_layer.h"

#include "gtest/gtest.h"

namespace flutter {

TEST(PhysicalShapeLayer, TotalElevation) {
  std::shared_ptr<PhysicalShapeLayer> layers[4];

  SkColor dummy_color = 0;
  SkPath dummy_path;
  for (int i = 0; i < 4; i += 1) {
    layers[i] =
        std::make_shared<PhysicalShapeLayer>(dummy_color, dummy_color,
                                             1.0f,            // pixel ratio,
                                             1.0f,            // depth
                                             (float)(i + 1),  // elevation
                                             dummy_path, Clip::none);
  }

  layers[0]->Add(layers[1]);
  layers[0]->Add(layers[2]);
  layers[2]->Add(layers[3]);

  const Stopwatch unused_stopwatch;
  TextureRegistry unused_texture_registry;
  MutatorsStack unused_stack;
  PrerollContext preroll_context{
      nullptr,                  // raster_cache (don't consult the cache)
      nullptr,                  // gr_context  (used for the raster cache)
      nullptr,                  // external view embedder
      unused_stack,             // mutator stack
      nullptr,                  // SkColorSpace* dst_color_space
      kGiantRect,               // SkRect cull_rect
      unused_stopwatch,         // frame time (dont care)
      unused_stopwatch,         // engine time (dont care)
      unused_texture_registry,  // texture registry (not supported)
      false,                    // checkerboard_offscreen_layers
      0.0f,                     // total elevation
  };

  SkMatrix identity;
  identity.setIdentity();

  layers[0]->Preroll(&preroll_context, identity);

  // It should look like this:
  // layers[0] +1.0f
  // |       \
  // |        \
  // |         \
  // |       layers[2] +3.0f
  // |          |
  // |       layers[3] +4.0f
  // |
  // |
  // layers[1] + 2.0f
  EXPECT_EQ(layers[0]->total_elevation_, 1.0f);
  EXPECT_EQ(layers[1]->total_elevation_, 3.0f);
  EXPECT_EQ(layers[2]->total_elevation_, 4.0f);
  EXPECT_EQ(layers[3]->total_elevation_, 8.0f);
}

}  // namespace flutter
