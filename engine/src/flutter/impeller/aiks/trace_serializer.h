// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_TRACE_SERIALIZER_H_
#define FLUTTER_IMPELLER_AIKS_TRACE_SERIALIZER_H_

#include <iostream>
#include "impeller/aiks/canvas_recorder.h"

namespace impeller {

class TraceSerializer {
 public:
  TraceSerializer();

  void Write(CanvasRecorderOp op);

  void Write(const Paint& paint);

  void Write(const std::optional<Rect> optional_rect);

  void Write(const std::shared_ptr<ImageFilter>& image_filter);

  void Write(size_t size);

  void Write(const Matrix& matrix);

  void Write(const Vector3& vec3);

  void Write(const Vector2& vec2);

  void Write(const Radians& vec2);

  void Write(const Path& path);

  void Write(const std::vector<Point>& points);

  void Write(const PointStyle& point_style);

  void Write(const std::shared_ptr<Image>& image);

  void Write(const SamplerDescriptor& sampler);

  void Write(const Entity::ClipOperation& clip_op);

  void Write(const Picture& clip_op);

  void Write(const std::shared_ptr<TextFrame>& text_frame);

  void Write(const std::shared_ptr<VerticesGeometry>& vertices);

  void Write(const BlendMode& blend_mode);

  void Write(const std::vector<Matrix>& matrices);

  void Write(const std::vector<Rect>& matrices);

  void Write(const std::vector<Color>& matrices);

  void Write(const SourceRectConstraint& src_rect_constraint);

  void Write(const ContentBoundsPromise& promise);

 private:
  std::stringstream buffer_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_TRACE_SERIALIZER_H_
