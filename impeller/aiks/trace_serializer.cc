// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/trace_serializer.h"
#include "flutter/fml/logging.h"

namespace impeller {

namespace {

class ImageFilterTraceVisitor : public ImageFilterVisitor {
 public:
  explicit ImageFilterTraceVisitor(std::ostream& os) : os_(os) {}
  void Visit(const BlurImageFilter& filter) override {
    os_ << "BlurImageFilter";
  }
  void Visit(const LocalMatrixImageFilter& filter) override {
    os_ << "LocalMatrixImageFilter";
  }
  void Visit(const DilateImageFilter& filter) override {
    os_ << "DilateImageFilter";
  }
  void Visit(const ErodeImageFilter& filter) override {
    os_ << "ErodeImageFilter";
  }
  void Visit(const MatrixImageFilter& filter) override {
    os_ << "{MatrixImageFilter matrix: " << filter.GetMatrix() << "}";
  }
  void Visit(const ComposeImageFilter& filter) override {
    os_ << "ComposeImageFilter";
  }
  void Visit(const ColorImageFilter& filter) override {
    os_ << "ColorImageFilter";
  }

 private:
  std::ostream& os_;
};

std::ostream& operator<<(std::ostream& os,
                         const std::shared_ptr<ImageFilter>& image_filter) {
  if (image_filter) {
    os << "[";
    ImageFilterTraceVisitor visitor(os);
    image_filter->Visit(visitor);
    os << "]";
  } else {
    os << "[None]";
  }
  return os;
}

std::ostream& operator<<(std::ostream& os, const ColorSource& color_source) {
  os << "{ type: ";
  switch (color_source.GetType()) {
    case ColorSource::Type::kColor:
      os << "kColor";
      break;
    case ColorSource::Type::kImage:
      os << "kImage";
      break;
    case ColorSource::Type::kLinearGradient:
      os << "kLinearGradient";
      break;
    case ColorSource::Type::kRadialGradient:
      os << "kRadialGradient";
      break;
    case ColorSource::Type::kConicalGradient:
      os << "kConicalGradient";
      break;
    case ColorSource::Type::kSweepGradient:
      os << "kSweepGradient";
      break;
    case ColorSource::Type::kRuntimeEffect:
      os << "kRuntimeEffect";
      break;
    case ColorSource::Type::kScene:
      os << "kScene";
      break;
  }
  os << " }";
  return os;
}

std::ostream& operator<<(std::ostream& os, const Paint& paint) {
  os << "{" << std::endl;
  os << "  color: [" << paint.color << "]" << std::endl;
  os << "  color_source:"
     << "[" << paint.color_source << "]" << std::endl;
  os << "  dither: [" << paint.dither << "]" << std::endl;
  os << "  stroke_width: [" << paint.stroke_width << "]" << std::endl;
  os << "  stroke_cap: "
     << "[Paint::Cap]" << std::endl;
  os << "  stroke_join: "
     << "[Paint::Join]" << std::endl;
  os << "  stroke_miter: [" << paint.stroke_miter << "]" << std::endl;
  os << "  style:"
     << "[Paint::Style]" << std::endl;
  os << "  blend_mode: [" << BlendModeToString(paint.blend_mode) << "]"
     << std::endl;
  os << "  invert_colors: [" << paint.invert_colors << "]" << std::endl;
  os << "  image_filter: " << paint.image_filter << std::endl;
  os << "  color_filter: " << paint.color_filter << std::endl;
  os << "  mask_blur_descriptor: "
     << "[std::optional<MaskBlurDescriptor>]" << std::endl;
  os << "}";
  return os;
}
}  // namespace

#define FLT_CANVAS_RECORDER_OP_TO_STRING(name) \
  case CanvasRecorderOp::name:                 \
    return #name

namespace {
std::string_view CanvasRecorderOpToString(CanvasRecorderOp op) {
  switch (op) {
    FLT_CANVAS_RECORDER_OP_TO_STRING(New);
    FLT_CANVAS_RECORDER_OP_TO_STRING(Save);
    FLT_CANVAS_RECORDER_OP_TO_STRING(SaveLayer);
    FLT_CANVAS_RECORDER_OP_TO_STRING(Restore);
    FLT_CANVAS_RECORDER_OP_TO_STRING(RestoreToCount);
    FLT_CANVAS_RECORDER_OP_TO_STRING(ResetTransform);
    FLT_CANVAS_RECORDER_OP_TO_STRING(Transform);
    FLT_CANVAS_RECORDER_OP_TO_STRING(Concat);
    FLT_CANVAS_RECORDER_OP_TO_STRING(PreConcat);
    FLT_CANVAS_RECORDER_OP_TO_STRING(Translate);
    FLT_CANVAS_RECORDER_OP_TO_STRING(Scale2);
    FLT_CANVAS_RECORDER_OP_TO_STRING(Scale3);
    FLT_CANVAS_RECORDER_OP_TO_STRING(Skew);
    FLT_CANVAS_RECORDER_OP_TO_STRING(Rotate);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawPath);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawPaint);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawRect);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawRRect);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawCircle);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawPoints);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawImage);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawImageRect);
    FLT_CANVAS_RECORDER_OP_TO_STRING(ClipPath);
    FLT_CANVAS_RECORDER_OP_TO_STRING(ClipRect);
    FLT_CANVAS_RECORDER_OP_TO_STRING(ClipRRect);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawPicture);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawTextFrame);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawVertices);
    FLT_CANVAS_RECORDER_OP_TO_STRING(DrawAtlas);
  }
}
}  // namespace

TraceSerializer::TraceSerializer() {}

void TraceSerializer::Write(CanvasRecorderOp op) {
  if (op == CanvasRecorderOp::New) {
    FML_LOG(ERROR) << "######################################################";
  } else {
    FML_LOG(ERROR) << CanvasRecorderOpToString(op) << ":" << buffer_.str();
    buffer_.str("");
    buffer_.clear();
  }
}

void TraceSerializer::Write(const Paint& paint) {
  buffer_ << "[" << paint << "] ";
}

void TraceSerializer::Write(const std::optional<Rect> optional_rect) {
  if (optional_rect.has_value()) {
    buffer_ << "[" << optional_rect.value() << "] ";
  } else {
    buffer_ << "[None] ";
  }
}

void TraceSerializer::Write(const std::shared_ptr<ImageFilter>& image_filter) {
  buffer_ << image_filter << " ";
}

void TraceSerializer::Write(size_t size) {
  buffer_ << "[" << size << "] ";
}

void TraceSerializer::Write(const Matrix& matrix) {
  buffer_ << "[" << matrix << "] ";
}

void TraceSerializer::Write(const Vector3& vec3) {
  buffer_ << "[" << vec3 << "] ";
}

void TraceSerializer::Write(const Vector2& vec2) {
  buffer_ << "[" << vec2 << "] ";
}

void TraceSerializer::Write(const Radians& radians) {
  buffer_ << "[" << radians.radians << "] ";
}

void TraceSerializer::Write(const Path& path) {
  buffer_ << "[Path] ";
}

void TraceSerializer::Write(const std::vector<Point>& points) {
  buffer_ << "[std::vector<Point>] ";
}

void TraceSerializer::Write(const PointStyle& point_style) {
  buffer_ << "[PointStyle] ";
}

void TraceSerializer::Write(const std::shared_ptr<Image>& image) {
  buffer_ << "[std::shared_ptr<Image>] ";
}

void TraceSerializer::Write(const SamplerDescriptor& sampler) {
  buffer_ << "[SamplerDescriptor] ";
}

void TraceSerializer::Write(const Entity::ClipOperation& clip_op) {
  switch (clip_op) {
    case Entity::ClipOperation::kDifference:
      buffer_ << "[kDifference] ";
      break;
    case Entity::ClipOperation::kIntersect:
      buffer_ << "[kIntersect] ";
      break;
  }
}

void TraceSerializer::Write(const Picture& clip_op) {
  buffer_ << "[Picture] ";
}

void TraceSerializer::Write(const std::shared_ptr<TextFrame>& text_frame) {
  buffer_ << "[std::shared_ptr<TextFrame>] ";
}

void TraceSerializer::Write(const std::shared_ptr<VerticesGeometry>& vertices) {
  buffer_ << "[std::shared_ptr<VerticesGeometry>] ";
}

void TraceSerializer::Write(const BlendMode& blend_mode) {
  buffer_ << "[" << BlendModeToString(blend_mode) << "] ";
}

void TraceSerializer::Write(const std::vector<Matrix>& matrices) {
  buffer_ << "[std::vector<Matrix>] ";
}

void TraceSerializer::Write(const std::vector<Rect>& matrices) {
  buffer_ << "[std::vector<Rect>] ";
}

void TraceSerializer::Write(const std::vector<Color>& matrices) {
  buffer_ << "[std::vector<Color>] ";
}
}  // namespace impeller
