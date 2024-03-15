// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/aiks/canvas_recorder.h"
namespace impeller {
namespace testing {

namespace {
class Serializer {
 public:
  void Write(CanvasRecorderOp op) { last_op_ = op; }

  void Write(const Paint& paint) {}

  void Write(const std::optional<Rect> optional_rect) {}

  void Write(const std::shared_ptr<ImageFilter>& image_filter) {}

  void Write(size_t size) {}

  void Write(const Matrix& matrix) {}

  void Write(const Vector3& vec3) {}

  void Write(const Vector2& vec2) {}

  void Write(const Radians& vec2) {}

  void Write(const Path& path) {}

  void Write(const std::vector<Point>& points) {}

  void Write(const PointStyle& point_style) {}

  void Write(const std::shared_ptr<Image>& image) {}

  void Write(const SamplerDescriptor& sampler) {}

  void Write(const Entity::ClipOperation& clip_op) {}

  void Write(const Picture& clip_op) {}

  void Write(const std::shared_ptr<TextFrame>& text_frame) {}

  void Write(const std::shared_ptr<VerticesGeometry>& vertices) {}

  void Write(const BlendMode& blend_mode) {}

  void Write(const std::vector<Matrix>& matrices) {}

  void Write(const std::vector<Rect>& matrices) {}

  void Write(const std::vector<Color>& matrices) {}

  void Write(const SourceRectConstraint& src_rect_constraint) {}

  void Write(const ContentBoundsPromise& promise) {}

  CanvasRecorderOp last_op_;
};
}  // namespace

TEST(CanvasRecorder, Save) {
  CanvasRecorder<Serializer> recorder;
  recorder.Save();
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kSave);
}

TEST(CanvasRecorder, SaveLayer) {
  CanvasRecorder<Serializer> recorder;
  Paint paint;
  recorder.SaveLayer(paint);
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kSaveLayer);
}

TEST(CanvasRecorder, Restore) {
  CanvasRecorder<Serializer> recorder;
  recorder.Restore();
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kRestore);
}

TEST(CanvasRecorder, RestoreToCount) {
  CanvasRecorder<Serializer> recorder;
  recorder.Save();
  recorder.RestoreToCount(0);
  ASSERT_EQ(recorder.GetSerializer().last_op_,
            CanvasRecorderOp::kRestoreToCount);
}

TEST(CanvasRecorder, ResetTransform) {
  CanvasRecorder<Serializer> recorder;
  recorder.ResetTransform();
  ASSERT_EQ(recorder.GetSerializer().last_op_,
            CanvasRecorderOp::kResetTransform);
}

TEST(CanvasRecorder, Transform) {
  CanvasRecorder<Serializer> recorder;
  recorder.Transform(Matrix());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kTransform);
}

TEST(CanvasRecorder, Concat) {
  CanvasRecorder<Serializer> recorder;
  recorder.Concat(Matrix());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kConcat);
}

TEST(CanvasRecorder, PreConcat) {
  CanvasRecorder<Serializer> recorder;
  recorder.PreConcat(Matrix());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kPreConcat);
}

TEST(CanvasRecorder, Translate) {
  CanvasRecorder<Serializer> recorder;
  recorder.Translate(Vector3());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kTranslate);
}

TEST(CanvasRecorder, Scale2) {
  CanvasRecorder<Serializer> recorder;
  recorder.Scale(Vector2());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kScale2);
}

TEST(CanvasRecorder, Scale3) {
  CanvasRecorder<Serializer> recorder;
  recorder.Scale(Vector3());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kScale3);
}

TEST(CanvasRecorder, Skew) {
  CanvasRecorder<Serializer> recorder;
  recorder.Skew(0, 0);
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kSkew);
}

TEST(CanvasRecorder, Rotate) {
  CanvasRecorder<Serializer> recorder;
  recorder.Rotate(Radians(0));
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kRotate);
}

TEST(CanvasRecorder, DrawPath) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawPath(Path(), Paint());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawPath);
}

TEST(CanvasRecorder, DrawPaint) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawPaint(Paint());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawPaint);
}

TEST(CanvasRecorder, DrawLine) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawLine(Point(), Point(), Paint());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawLine);
}

TEST(CanvasRecorder, DrawRect) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawRect(Rect(), Paint());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawRect);
}

TEST(CanvasRecorder, DrawOval) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawOval(Rect(), Paint());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawOval);
}

TEST(CanvasRecorder, DrawRRect) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawRRect(Rect(), {}, Paint());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawRRect);
}

TEST(CanvasRecorder, DrawCircle) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawCircle(Point(), 0, Paint());
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawCircle);
}

TEST(CanvasRecorder, DrawPoints) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawPoints(std::vector<Point>{}, 0, Paint(), PointStyle::kRound);
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawPoints);
}

TEST(CanvasRecorder, DrawImage) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawImage({}, {}, {}, {});
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawImage);
}

TEST(CanvasRecorder, DrawImageRect) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawImageRect({}, {}, {}, {}, {}, SourceRectConstraint::kFast);
  ASSERT_EQ(recorder.GetSerializer().last_op_,
            CanvasRecorderOp::kDrawImageRect);
}

TEST(CanvasRecorder, ClipPath) {
  CanvasRecorder<Serializer> recorder;
  recorder.ClipPath({});
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kClipPath);
}

TEST(CanvasRecorder, ClipRect) {
  CanvasRecorder<Serializer> recorder;
  recorder.ClipRect({});
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kClipRect);
}

TEST(CanvasRecorder, ClipOval) {
  CanvasRecorder<Serializer> recorder;
  recorder.ClipOval({});
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kClipOval);
}

TEST(CanvasRecorder, ClipRRect) {
  CanvasRecorder<Serializer> recorder;
  recorder.ClipRRect({}, {});
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kClipRRect);
}

TEST(CanvasRecorder, DrawTextFrame) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawTextFrame({}, {}, {});
  ASSERT_EQ(recorder.GetSerializer().last_op_,
            CanvasRecorderOp::kDrawTextFrame);
}

TEST(CanvasRecorder, DrawVertices) {
  CanvasRecorder<Serializer> recorder;
  auto geometry = std::shared_ptr<VerticesGeometry>(
      new VerticesGeometry({}, {}, {}, {}, {}, {}));
  recorder.DrawVertices(geometry, {}, {});
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawVertices);
}

TEST(CanvasRecorder, DrawAtlas) {
  CanvasRecorder<Serializer> recorder;
  recorder.DrawAtlas({}, {}, {}, {}, {}, {}, {}, {});
  ASSERT_EQ(recorder.GetSerializer().last_op_, CanvasRecorderOp::kDrawAtlas);
}

}  // namespace testing
}  // namespace impeller
