// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

vec4 ImpellerTexture(sampler2D texture_sampler,
                     vec2 coords,
                     float y_coord_scale) {
  if (y_coord_scale < 0.0) {
    coords.y = 1.0 - coords.y;
  }
  return texture(texture_sampler, coords);
}
