// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_H_
#define FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_H_

#include "flutter/display_list/display_list_benchmarks_canvas_provider.h"

#include "third_party/benchmark/include/benchmark/benchmark.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkVertices.h"

#ifdef ENABLE_SOFTWARE_BENCHMARKS
#include "flutter/display_list/display_list_benchmarks_software.h"
#endif
#ifdef ENABLE_OPENGL_BENCHMARKS
#include "flutter/display_list/display_list_benchmarks_gl.h"
#endif
#ifdef ENABLE_METAL_BENCHMARKS
#include "flutter/display_list/display_list_benchmarks_metal.h"
#endif

namespace flutter {
namespace testing {

typedef enum { kSoftware_Backend, kOpenGL_Backend, kMetal_Backend } BackendType;

std::unique_ptr<CanvasProvider> CreateCanvasProvider(BackendType backend_type);

// Benchmarks

void BM_DrawLine(benchmark::State& state, BackendType backend_type);
void BM_DrawRect(benchmark::State& state, BackendType backend_type);
void BM_DrawCircle(benchmark::State& state, BackendType backend_type);
void BM_DrawOval(benchmark::State& state, BackendType backend_type);
void BM_DrawArc(benchmark::State& state, BackendType backend_type);
void BM_DrawRRect(benchmark::State& state,
                  BackendType backend_type,
                  SkRRect::Type type);
void BM_DrawPath(benchmark::State& state,
                 BackendType backend_type,
                 SkPath::Verb type);
void BM_DrawPoints(benchmark::State& state,
                   BackendType backend_type,
                   SkCanvas::PointMode mode);
void BM_DrawVertices(benchmark::State& state,
                     BackendType backend_type,
                     SkVertices::VertexMode mode);
void BM_DrawImage(benchmark::State& state,
                  BackendType backend_type,
                  const SkSamplingOptions& options,
                  bool upload_bitmap);
void BM_DrawImageRect(benchmark::State& state,
                      BackendType backend_type,
                      const SkSamplingOptions& options,
                      SkCanvas::SrcRectConstraint constraint,
                      bool upload_bitmap);
void BM_DrawImageNine(benchmark::State& state,
                      BackendType backend_type,
                      const SkFilterMode filter,
                      bool upload_bitmap);
void BM_DrawTextBlob(benchmark::State& state, BackendType backend_type);
void BM_DrawShadow(benchmark::State& state,
                   BackendType backend_type,
                   bool transparent_occluder,
                   SkPath::Verb type);

// clang-format off

#define RUN_DISPLAYLIST_BENCHMARKS(BACKEND)                             \
                                                                        \
  /*                                                                    \
   *  DrawLine                                                          \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawLine, BACKEND,                               \
                    BackendType::k##BACKEND##_Backend)                  \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawRect                                                          \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawRect, BACKEND,                               \
                    BackendType::k##BACKEND##_Backend)                  \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawOval                                                          \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawOval, BACKEND,                               \
                    BackendType::k##BACKEND##_Backend)                  \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawCircle                                                        \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawCircle, BACKEND,                             \
                    BackendType::k##BACKEND##_Backend)                  \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawArc                                                           \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawArc, BACKEND,                                \
                    BackendType::k##BACKEND##_Backend)                  \
      ->RangeMultiplier(2)                                              \
      ->Range(128, 2048)                                                \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawPath                                                          \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawPath,                                        \
                    Lines/BACKEND,                                      \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkPath::Verb::kLine_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(8, 512)                                                   \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPath,                                        \
                    Quads/BACKEND,                                      \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkPath::Verb::kQuad_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(8, 512)                                                   \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPath,                                        \
                    Conics/BACKEND,                                     \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkPath::Verb::kConic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(8, 512)                                                   \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPath,                                        \
                    Cubics/BACKEND,                                     \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkPath::Verb::kCubic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(8, 512)                                                   \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  /*                                                                    \
   *  DrawPoints                                                        \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawPoints, Points/BACKEND,                      \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkCanvas::kPoints_PointMode)                        \
      ->RangeMultiplier(2)                                              \
      ->Range(1024, 32768)                                              \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPoints, Lines/BACKEND,                       \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkCanvas::kLines_PointMode)                         \
      ->RangeMultiplier(2)                                              \
      ->Range(1024, 32768)                                              \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPoints, Polygon/BACKEND,                     \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkCanvas::kPolygon_PointMode)                       \
      ->RangeMultiplier(2)                                              \
      ->Range(1024, 32768)                                              \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawVertices                                                      \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawVertices,                                    \
                    TriangleStrip/BACKEND,                              \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkVertices::VertexMode::kTriangleStrip_VertexMode)  \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawVertices,                                    \
                    TriangleFan/BACKEND,                                \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkVertices::VertexMode::kTriangleFan_VertexMode)    \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawVertices,                                    \
                    Triangles/BACKEND,                                  \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkVertices::VertexMode::kTriangles_VertexMode)      \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  /*                                                                    \
   *  DrawRRect                                                         \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawRRect, Symmetric/BACKEND,                    \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkRRect::Type::kSimple_Type)                        \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawRRect, NinePatch/BACKEND,                    \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkRRect::Type::kNinePatch_Type)                     \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawRRect, Complex/BACKEND,                      \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkRRect::Type::kComplex_Type)                       \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawImage                                                         \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawImage, Texture/BACKEND,                      \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkSamplingOptions(), false)                         \
      ->RangeMultiplier(2)                                              \
      ->Range(128, 512)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawImage, Upload/BACKEND,                       \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkSamplingOptions(), true)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(128, 512)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawImageRect                                                     \
   */                                                                   \
  BENCHMARK_CAPTURE(                                                    \
      BM_DrawImageRect, Texture/Strict/BACKEND,                         \
      BackendType::k##BACKEND##_Backend, SkSamplingOptions(),           \
      SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint, false)    \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(                                                    \
      BM_DrawImageRect, Texture/Fast/BACKEND,                           \
      BackendType::k##BACKEND##_Backend, SkSamplingOptions(),           \
      SkCanvas::SrcRectConstraint::kFast_SrcRectConstraint, false)      \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(                                                    \
      BM_DrawImageRect, Upload/Strict/BACKEND,                          \
      BackendType::k##BACKEND##_Backend, SkSamplingOptions(),           \
      SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint, true)     \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(                                                    \
      BM_DrawImageRect, Upload/Fast/BACKEND,                            \
      BackendType::k##BACKEND##_Backend, SkSamplingOptions(),           \
      SkCanvas::SrcRectConstraint::kFast_SrcRectConstraint, true)       \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawImageNine                                                     \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawImageNine, Texture/Nearest/BACKEND,          \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkFilterMode::kNearest, false)                      \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawImageNine, Upload/Nearest/BACKEND,           \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkFilterMode::kNearest, true)                       \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawImageNine, Texture/Linear/BACKEND,           \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkFilterMode::kLinear, false)                       \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawImageNine, Upload/Linear/BACKEND,            \
                    BackendType::k##BACKEND##_Backend,                  \
                    SkFilterMode::kLinear, true)                        \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawTextBlob                                                      \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawTextBlob, BACKEND,                           \
                    BackendType::k##BACKEND##_Backend)                  \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 256)                                                   \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  /*                                                                    \
   *  DrawShadow                                                        \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawShadow, Lines/Transparent/BACKEND,           \
                    BackendType::k##BACKEND##_Backend, true,            \
                    SkPath::Verb::kLine_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Quads/Transparent/BACKEND,           \
                    BackendType::k##BACKEND##_Backend, true,            \
                    SkPath::Verb::kQuad_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Conics/Transparent/BACKEND,          \
                    BackendType::k##BACKEND##_Backend, true,            \
                    SkPath::Verb::kConic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Cubics/Transparent/BACKEND,          \
                    BackendType::k##BACKEND##_Backend, true,            \
                    SkPath::Verb::kCubic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Lines/Opaque/BACKEND,                \
                    BackendType::k##BACKEND##_Backend, false,           \
                    SkPath::Verb::kLine_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Quads/Opaque/BACKEND,                \
                    BackendType::k##BACKEND##_Backend, false,           \
                    SkPath::Verb::kQuad_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Conics/Opaque/BACKEND,               \
                    BackendType::k##BACKEND##_Backend, false,           \
                    SkPath::Verb::kConic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Cubics/Opaque/BACKEND,               \
                    BackendType::k##BACKEND##_Backend, false,           \
                    SkPath::Verb::kCubic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);

// clang-format on

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_H_
