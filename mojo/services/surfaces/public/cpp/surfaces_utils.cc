// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "surfaces/public/cpp/surfaces_utils.h"

#include "geometry/public/interfaces/geometry.mojom.h"

namespace mojo {

namespace {
TransformPtr GetIdentityTransform() {
  TransformPtr transform(Transform::New());
  transform->matrix.resize(16);
  transform->matrix[0] = 1.f;
  transform->matrix[5] = 1.f;
  transform->matrix[10] = 1.f;
  transform->matrix[15] = 1.f;
  return transform.Pass();
}
}

SharedQuadStatePtr CreateDefaultSQS(const Size& size) {
  SharedQuadStatePtr sqs = SharedQuadState::New();
  sqs->content_to_target_transform = GetIdentityTransform();
  sqs->content_bounds = size.Clone();
  Rect rect;
  rect.width = size.width;
  rect.height = size.height;
  sqs->visible_content_rect = rect.Clone();
  sqs->clip_rect = rect.Clone();
  sqs->is_clipped = false;
  sqs->opacity = 1.f;
  sqs->blend_mode = mojo::SK_XFERMODE_kSrc_Mode;
  sqs->sorting_context_id = 0;
  return sqs.Pass();
}

PassPtr CreateDefaultPass(int id, const Rect& rect) {
  PassPtr pass = Pass::New();
  pass->id = id;
  pass->output_rect = rect.Clone();
  pass->damage_rect = rect.Clone();
  pass->transform_to_root_target = GetIdentityTransform();
  pass->has_transparent_background = false;
  return pass.Pass();
}

}  // namespace mojo
