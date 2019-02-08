// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/performance_overlay_layer.h"
#include "flutter/flow/raster_cache.h"

#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/utils/SkBase64.h"

#include "gtest/gtest.h"

// To get the size of kMockedTimes in compile time.
template <class T, std::size_t N>
constexpr int size(const T (&array)[N]) noexcept {
  return N;
}

constexpr int kMockedTimes[] = {17, 1,  4,  24, 4,  25, 30, 4,  13, 34,
                                14, 0,  18, 9,  32, 36, 26, 23, 5,  8,
                                32, 18, 29, 16, 29, 18, 0,  36, 33, 10};

const char* kGoldenFileName =
    "flutter/testing/resources/performance_overlay_gold.png";

const char* kNewGoldenFileName =
    "flutter/testing/resources/performance_overlay_gold_new.png";

// Ensure the same font across different operation systems.
const char* kFontFilePath =
    "flutter/third_party/txt/third_party/fonts/Roboto-Regular.ttf";

TEST(PerformanceOverlayLayer, Gold) {
  flow::Stopwatch mock_stopwatch;
  for (int i = 0; i < size(kMockedTimes); ++i) {
    mock_stopwatch.SetLapTime(
        fml::TimeDelta::FromMilliseconds(kMockedTimes[i]));
  }

  const SkImageInfo image_info = SkImageInfo::MakeN32Premul(1000, 1000);
  sk_sp<SkSurface> surface = SkSurface::MakeRaster(image_info);

  ASSERT_TRUE(surface != nullptr);

  flow::TextureRegistry unused_texture_registry;

  flow::Layer::PaintContext paintContext = {
      nullptr,        surface->getCanvas(),    nullptr, mock_stopwatch,
      mock_stopwatch, unused_texture_registry, nullptr, false};

  flow::PerformanceOverlayLayer layer(flow::kDisplayRasterizerStatistics |
                                          flow::kVisualizeRasterizerStatistics |
                                          flow::kDisplayEngineStatistics |
                                          flow::kVisualizeEngineStatistics,
                                      kFontFilePath);
  layer.set_paint_bounds(SkRect::MakeWH(1000, 400));
  surface->getCanvas()->clear(SK_ColorTRANSPARENT);
  layer.Paint(paintContext);

  sk_sp<SkImage> snapshot = surface->makeImageSnapshot();
  sk_sp<SkData> snapshot_data = snapshot->encodeToData();

  sk_sp<SkData> golden_data = SkData::MakeFromFileName(kGoldenFileName);
  EXPECT_TRUE(golden_data != nullptr)
      << "Golden file not found: " << kGoldenFileName << ".\n"
      << "Please make sure that the unit test is run from the right directory "
      << "(e.g., flutter/engine/src)";

  const bool golden_data_matches = golden_data->equals(snapshot_data.get());
  if (!golden_data_matches) {
    SkFILEWStream wstream(kNewGoldenFileName);
    wstream.write(snapshot_data->data(), snapshot_data->size());
    wstream.flush();

    size_t b64_size =
        SkBase64::Encode(snapshot_data->data(), snapshot_data->size(), nullptr);
    char* b64_data = new char[b64_size];
    SkBase64::Encode(snapshot_data->data(), snapshot_data->size(), b64_data);

    EXPECT_TRUE(golden_data_matches)
        << "Golden file mismatch. Please check "
        << "the difference between " << kGoldenFileName << " and "
        << kNewGoldenFileName << ", and  replace the former "
        << "with the latter if the difference looks good.\n\n"
        << "See also the base64 encoded " << kNewGoldenFileName << ":\n"
        << b64_data;

    delete[] b64_data;
  }
}
