// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_SURFACES_PUBLIC_CPP_SURFACES_UTILS_H_
#define MOJO_SERVICES_SURFACES_PUBLIC_CPP_SURFACES_UTILS_H_

#include "surfaces/public/interfaces/quads.mojom.h"

namespace mojo {
class Rect;
class Size;

SharedQuadStatePtr CreateDefaultSQS(const Size& size);

// Constructs a pass with the given id, output_rect and damage_rect set to rect,
// transform_to_root_target set to identity and has_transparent_background set
// to false.
PassPtr CreateDefaultPass(int id, const Rect& rect);

}  // namespace mojo

#endif  // MOJO_SERVICES_SURFACES_PUBLIC_CPP_SURFACES_UTILS_H_
