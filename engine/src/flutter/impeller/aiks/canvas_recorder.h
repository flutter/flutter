// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_CANVAS_RECORDER_H_
#define FLUTTER_IMPELLER_AIKS_CANVAS_RECORDER_H_

#include <cstdint>

#include "impeller/aiks/canvas.h"

#define FLT_CANVAS_RECORDER_OP_ARG(name) \
  CanvasRecorderOp::k##name, &Canvas::name

namespace impeller {
/// TODO(tbd): These are very similar to `flutter::DisplayListOpType`. When
/// golden tests can be written at a higher level, migrate these to
/// flutter::DisplayListOpType.
enum CanvasRecorderOp : uint16_t {
  kNew,
  kSave,
  kSaveLayer,
  kRestore,
  kRestoreToCount,
  kResetTransform,
  kTransform,
  kConcat,
  kPreConcat,
  kTranslate,
  kScale2,
  kScale3,
  kSkew,
  kRotate,
  kDrawPath,
  kDrawPaint,
  kDrawLine,
  kDrawRect,
  kDrawOval,
  kDrawRRect,
  kDrawCircle,
  kDrawPoints,
  kDrawImage,
  kDrawImageRect,
  kClipPath,
  kClipRect,
  kClipOval,
  kClipRRect,
  kDrawTextFrame,
  kDrawVertices,
  kDrawAtlas,
};

// Canvas recorder should only be used when IMPELLER_TRACE_CANVAS is defined
// (never in production code).
#ifdef IMPELLER_TRACE_CANVAS
/// Static polymorphic replacement for impeller::Canvas that records methods
/// called on an impeller::Canvas and forwards it to a real instance.
/// TODO(https://github.com/flutter/flutter/issues/135718): Move this recorder
/// to the DisplayList level when golden tests can be written at the ui.Canvas
/// layer.
template <typename Serializer>
class CanvasRecorder {
 public:
  CanvasRecorder() : canvas_() { serializer_.Write(CanvasRecorderOp::kNew); }

  explicit CanvasRecorder(Rect cull_rect) : canvas_(cull_rect) {
    serializer_.Write(CanvasRecorderOp::kNew);
  }

  explicit CanvasRecorder(IRect cull_rect) : canvas_(cull_rect) {
    serializer_.Write(CanvasRecorderOp::kNew);
  }

  ~CanvasRecorder() {}

  const Serializer& GetSerializer() const { return serializer_; }

  template <typename ReturnType>
  ReturnType ExecuteAndSerialize(CanvasRecorderOp op,
                                 ReturnType (Canvas::*canvasMethod)()) {
    serializer_.Write(op);
    return (canvas_.*canvasMethod)();
  }

  template <typename FuncType, typename... Args>
  auto ExecuteAndSerialize(CanvasRecorderOp op,
                           FuncType canvasMethod,
                           Args&&... args)
      -> decltype((std::declval<Canvas>().*
                   canvasMethod)(std::forward<Args>(args)...)) {
    // Serialize each argument
    (serializer_.Write(std::forward<Args>(args)), ...);
    serializer_.Write(op);
    return (canvas_.*canvasMethod)(std::forward<Args>(args)...);
  }

  template <typename FuncType, typename... Args>
  auto ExecuteAndSkipArgSerialize(CanvasRecorderOp op,
                                  FuncType canvasMethod,
                                  Args&&... args)
      -> decltype((std::declval<Canvas>().*
                   canvasMethod)(std::forward<Args>(args)...)) {
    serializer_.Write(op);
    return (canvas_.*canvasMethod)(std::forward<Args>(args)...);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Canvas Static Polymorphism
  // ////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  void Save() {
    return ExecuteAndSerialize(CanvasRecorderOp::kSave, &Canvas::Save);
  }

  void SaveLayer(
      const Paint& paint,
      std::optional<Rect> bounds = std::nullopt,
      const std::shared_ptr<ImageFilter>& backdrop_filter = nullptr,
      ContentBoundsPromise bounds_promise = ContentBoundsPromise::kUnknown) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(SaveLayer), paint,
                               bounds, backdrop_filter, bounds_promise);
  }

  bool Restore() {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(Restore));
  }

  size_t GetSaveCount() const { return canvas_.GetSaveCount(); }

  void RestoreToCount(size_t count) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(RestoreToCount),
                               count);
  }

  const Matrix& GetCurrentTransform() const {
    return canvas_.GetCurrentTransform();
  }

  const std::optional<Rect> GetCurrentLocalCullingBounds() const {
    return canvas_.GetCurrentLocalCullingBounds();
  }

  void ResetTransform() {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(ResetTransform));
  }

  void Transform(const Matrix& transform) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(Transform),
                               transform);
  }

  void Concat(const Matrix& transform) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(Concat), transform);
  }

  void PreConcat(const Matrix& transform) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(PreConcat),
                               transform);
  }

  void Translate(const Vector3& offset) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(Translate), offset);
  }

  void Scale(const Vector2& scale) {
    return ExecuteAndSerialize(
        CanvasRecorderOp::kScale2,
        static_cast<void (Canvas::*)(const Vector2&)>(&Canvas::Scale), scale);
  }

  void Scale(const Vector3& scale) {
    return ExecuteAndSerialize(
        CanvasRecorderOp::kScale3,
        static_cast<void (Canvas::*)(const Vector3&)>(&Canvas::Scale), scale);
  }

  void Skew(Scalar sx, Scalar sy) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(Skew), sx, sy);
  }

  void Rotate(Radians radians) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(Rotate), radians);
  }

  void DrawPath(Path path, const Paint& paint) {
    serializer_.Write(path);
    serializer_.Write(paint);
    return ExecuteAndSkipArgSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawPath),
                                      std::move(path), paint);
  }

  void DrawPaint(const Paint& paint) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawPaint), paint);
  }

  void DrawLine(const Point& p0, const Point& p1, const Paint& paint) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawLine), p0, p1,
                               paint);
  }

  void DrawRect(Rect rect, const Paint& paint) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawRect), rect,
                               paint);
  }

  void DrawOval(const Rect& rect, const Paint& paint) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawOval), rect,
                               paint);
  }

  void DrawRRect(const Rect& rect,
                 const Size& corner_radii,
                 const Paint& paint) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawRRect), rect,
                               corner_radii, paint);
  }

  void DrawCircle(Point center, Scalar radius, const Paint& paint) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawCircle), center,
                               radius, paint);
  }

  void DrawPoints(std::vector<Point> points,
                  Scalar radius,
                  const Paint& paint,
                  PointStyle point_style) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawPoints), points,
                               radius, paint, point_style);
  }

  void DrawImage(const std::shared_ptr<Image>& image,
                 Point offset,
                 const Paint& paint,
                 SamplerDescriptor sampler = {}) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawImage), image,
                               offset, paint, sampler);
  }

  void DrawImageRect(
      const std::shared_ptr<Image>& image,
      Rect source,
      Rect dest,
      const Paint& paint,
      SamplerDescriptor sampler = {},
      SourceRectConstraint src_rect_constraint = SourceRectConstraint::kFast) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawImageRect), image,
                               source, dest, paint, sampler,
                               src_rect_constraint);
  }

  void ClipPath(
      Path path,
      Entity::ClipOperation clip_op = Entity::ClipOperation::kIntersect) {
    serializer_.Write(path);
    serializer_.Write(clip_op);
    return ExecuteAndSkipArgSerialize(FLT_CANVAS_RECORDER_OP_ARG(ClipPath),
                                      std::move(path), clip_op);
  }

  void ClipRect(
      const Rect& rect,
      Entity::ClipOperation clip_op = Entity::ClipOperation::kIntersect) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(ClipRect), rect,
                               clip_op);
  }

  void ClipOval(
      const Rect& bounds,
      Entity::ClipOperation clip_op = Entity::ClipOperation::kIntersect) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(ClipOval), bounds,
                               clip_op);
  }

  void ClipRRect(
      const Rect& rect,
      const Size& corner_radii,
      Entity::ClipOperation clip_op = Entity::ClipOperation::kIntersect) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(ClipRRect), rect,
                               corner_radii, clip_op);
  }

  void DrawTextFrame(const std::shared_ptr<TextFrame>& text_frame,
                     Point position,
                     const Paint& paint) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawTextFrame),
                               text_frame, position, paint);
  }

  void DrawVertices(const std::shared_ptr<VerticesGeometry>& vertices,
                    BlendMode blend_mode,
                    const Paint& paint) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawVertices),
                               vertices, blend_mode, paint);
  }

  void DrawAtlas(const std::shared_ptr<Image>& atlas,
                 std::vector<Matrix> transforms,
                 std::vector<Rect> texture_coordinates,
                 std::vector<Color> colors,
                 BlendMode blend_mode,
                 SamplerDescriptor sampler,
                 std::optional<Rect> cull_rect,
                 const Paint& paint) {
    return ExecuteAndSerialize(FLT_CANVAS_RECORDER_OP_ARG(DrawAtlas),  //
                               atlas,                                  //
                               transforms,                             //
                               texture_coordinates,                    //
                               colors,                                 //
                               blend_mode,                             //
                               sampler,                                //
                               cull_rect,                              //
                               paint);
  }

  Picture EndRecordingAsPicture() { return canvas_.EndRecordingAsPicture(); }

 private:
  Canvas canvas_;
  Serializer serializer_;
};
#endif

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_CANVAS_RECORDER_H_
