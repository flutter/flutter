// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_H_
#define FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_H_

#include "flutter/fml/mapping.h"
#include "flutter/testing/testing.h"

#include "third_party/benchmark/include/benchmark/benchmark.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkVertices.h"

namespace flutter {

namespace testing {

class CanvasProvider {
 public:
  virtual ~CanvasProvider() = default;
  virtual const std::string BackendName() = 0;
  virtual void InitializeSurface(const size_t width, const size_t height) = 0;
  virtual sk_sp<SkSurface> GetSurface() = 0;
  virtual sk_sp<SkSurface> MakeOffscreenSurface(const size_t width,
                                                const size_t height) = 0;

  virtual bool Snapshot(std::string filename) {
    auto image = GetSurface()->makeImageSnapshot();
    if (!image) {
      return false;
    }
    auto raster = image->makeRasterImage();
    if (!raster) {
      return false;
    }
    auto data = raster->encodeToData();
    if (!data) {
      return false;
    }
    fml::NonOwnedMapping mapping(static_cast<const uint8_t*>(data->data()),
                                 data->size());
    return WriteAtomically(OpenFixturesDirectory(), filename.c_str(), mapping);
  }
};

// Benchmarks

void BM_DrawLine(benchmark::State& state,
                 std::unique_ptr<CanvasProvider> canvas_provider);
void BM_DrawRect(benchmark::State& state,
                 std::unique_ptr<CanvasProvider> canvas_provider);
void BM_DrawCircle(benchmark::State& state,
                   std::unique_ptr<CanvasProvider> canvas_provider);
void BM_DrawOval(benchmark::State& state,
                 std::unique_ptr<CanvasProvider> canvas_provider);
void BM_DrawArc(benchmark::State& state,
                std::unique_ptr<CanvasProvider> canvas_provider);
void BM_DrawRRect(benchmark::State& state,
                  std::unique_ptr<CanvasProvider> canvas_provider,
                  SkRRect::Type type);
void BM_DrawPath(benchmark::State& state,
                 std::unique_ptr<CanvasProvider> canvas_provider,
                 SkPath::Verb type);
void BM_DrawPoints(benchmark::State& state,
                   std::unique_ptr<CanvasProvider> canvas_provider,
                   SkCanvas::PointMode mode);
void BM_DrawVertices(benchmark::State& state,
                     std::unique_ptr<CanvasProvider> canvas_provider,
                     SkVertices::VertexMode mode);
void BM_DrawImage(benchmark::State& state,
                  std::unique_ptr<CanvasProvider> canvas_provider,
                  const SkSamplingOptions& options,
                  bool upload_bitmap);
void BM_DrawImageRect(benchmark::State& state,
                      std::unique_ptr<CanvasProvider> canvas_provider,
                      const SkSamplingOptions& options,
                      SkCanvas::SrcRectConstraint constraint,
                      bool upload_bitmap);
void BM_DrawImageNine(benchmark::State& state,
                      std::unique_ptr<CanvasProvider> canvas_provider,
                      const SkFilterMode filter,
                      bool upload_bitmap);
void BM_DrawTextBlob(benchmark::State& state,
                     std::unique_ptr<CanvasProvider> canvas_provider);
void BM_DrawShadow(benchmark::State& state,
                   std::unique_ptr<CanvasProvider> canvas_provider,
                   bool transparent_occluder,
                   SkPath::Verb type);

// clang-format off

#define RUN_DISPLAYLIST_BENCHMARKS(BACKEND)                             \
                                                                        \
  /*                                                                    \
   *  DrawLine                                                          \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawLine, BACKEND,                               \
                    std::make_unique<BACKEND##CanvasProvider>())        \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawRect                                                          \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawRect, BACKEND,                               \
                    std::make_unique<BACKEND##CanvasProvider>())        \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawOval                                                          \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawOval, BACKEND,                               \
                    std::make_unique<BACKEND##CanvasProvider>())        \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawCircle                                                        \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawCircle, BACKEND,                             \
                    std::make_unique<BACKEND##CanvasProvider>())        \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawArc                                                           \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawArc, BACKEND,                                \
                    std::make_unique<BACKEND##CanvasProvider>())        \
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
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkPath::Verb::kLine_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(8, 1024)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPath,                                        \
                    Quads/BACKEND,                                      \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkPath::Verb::kQuad_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(8, 1024)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPath,                                        \
                    Conics/BACKEND,                                     \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkPath::Verb::kConic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(8, 1024)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPath,                                        \
                    Cubics/BACKEND,                                     \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkPath::Verb::kCubic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(8, 1024)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  /*                                                                    \
   *  DrawPoints                                                        \
   */                                                                   \
  BENCHMARK_CAPTURE(BM_DrawPoints, Points/BACKEND,                      \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkCanvas::kPoints_PointMode)                        \
      ->RangeMultiplier(2)                                              \
      ->Range(1024, 32768)                                              \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPoints, Lines/BACKEND,                       \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkCanvas::kLines_PointMode)                         \
      ->RangeMultiplier(2)                                              \
      ->Range(1024, 32768)                                              \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawPoints, Polygon/BACKEND,                     \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
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
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkVertices::VertexMode::kTriangleStrip_VertexMode)  \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawVertices,                                    \
                    TriangleFan/BACKEND,                                \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkVertices::VertexMode::kTriangleFan_VertexMode)    \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond)                                   \
      ->Complexity();                                                   \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawVertices,                                    \
                    Triangles/BACKEND,                                  \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
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
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkRRect::Type::kSimple_Type)                        \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawRRect, NinePatch/BACKEND,                    \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkRRect::Type::kNinePatch_Type)                     \
      ->RangeMultiplier(2)                                              \
      ->Range(16, 2048)                                                 \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawRRect, Complex/BACKEND,                      \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
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
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkSamplingOptions(), false)                         \
      ->RangeMultiplier(2)                                              \
      ->Range(128, 1024)                                                \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawImage, Upload/BACKEND,                       \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkSamplingOptions(), true)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(128, 1024)                                                \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  /*                                                                    \
   *  DrawImageRect                                                     \
   */                                                                   \
  BENCHMARK_CAPTURE(                                                    \
      BM_DrawImageRect, Texture/Strict/BACKEND,                         \
      std::make_unique<BACKEND##CanvasProvider>(), SkSamplingOptions(), \
      SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint, false)    \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(                                                    \
      BM_DrawImageRect, Texture/Fast/BACKEND,                           \
      std::make_unique<BACKEND##CanvasProvider>(), SkSamplingOptions(), \
      SkCanvas::SrcRectConstraint::kFast_SrcRectConstraint, false)      \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(                                                    \
      BM_DrawImageRect, Upload/Strict/BACKEND,                          \
      std::make_unique<BACKEND##CanvasProvider>(), SkSamplingOptions(), \
      SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint, true)     \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(                                                    \
      BM_DrawImageRect, Upload/Fast/BACKEND,                            \
      std::make_unique<BACKEND##CanvasProvider>(), SkSamplingOptions(), \
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
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkFilterMode::kNearest, false)                      \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawImageNine, Upload/Nearest/BACKEND,           \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkFilterMode::kNearest, true)                       \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawImageNine, Texture/Linear/BACKEND,           \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
                    SkFilterMode::kLinear, false)                       \
      ->RangeMultiplier(2)                                              \
      ->Range(32, 256)                                                  \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawImageNine, Upload/Linear/BACKEND,            \
                    std::make_unique<BACKEND##CanvasProvider>(),        \
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
                    std::make_unique<BACKEND##CanvasProvider>())        \
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
                    std::make_unique<BACKEND##CanvasProvider>(), true,  \
                    SkPath::Verb::kLine_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Quads/Transparent/BACKEND,           \
                    std::make_unique<BACKEND##CanvasProvider>(), true,  \
                    SkPath::Verb::kQuad_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Conics/Transparent/BACKEND,          \
                    std::make_unique<BACKEND##CanvasProvider>(), true,  \
                    SkPath::Verb::kConic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Cubics/Transparent/BACKEND,          \
                    std::make_unique<BACKEND##CanvasProvider>(), true,  \
                    SkPath::Verb::kCubic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Lines/Opaque/BACKEND,                \
                    std::make_unique<BACKEND##CanvasProvider>(), false, \
                    SkPath::Verb::kLine_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Quads/Opaque/BACKEND,                \
                    std::make_unique<BACKEND##CanvasProvider>(), false, \
                    SkPath::Verb::kQuad_Verb)                           \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Conics/Opaque/BACKEND,               \
                    std::make_unique<BACKEND##CanvasProvider>(), false, \
                    SkPath::Verb::kConic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);                                  \
                                                                        \
  BENCHMARK_CAPTURE(BM_DrawShadow, Cubics/Opaque/BACKEND,               \
                    std::make_unique<BACKEND##CanvasProvider>(), false, \
                    SkPath::Verb::kCubic_Verb)                          \
      ->RangeMultiplier(2)                                              \
      ->Range(1, 32)                                                    \
      ->UseRealTime()                                                   \
      ->Unit(benchmark::kMillisecond);

// clang-format on

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_H_
