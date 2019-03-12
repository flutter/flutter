// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/flow_test_utils.h"
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

// Relative to the flutter/src/engine/flutter directory
const char* kGoldenFileName = "performance_overlay_gold.png";

// Relative to the flutter/src/engine/flutter directory
const char* kNewGoldenFileName = "performance_overlay_gold_new.png";

TEST(PerformanceOverlayLayer, Gold) {
  const std::string& golden_dir = flow::GetGoldenDir();
  // This unit test should only be run on Linux (not even on Mac since it's a
  // golden test). Hence we don't have to worry about the "/" vs. "\".
  std::string golden_file_path = golden_dir + "/" + kGoldenFileName;
  std::string new_golden_file_path = golden_dir + "/" + kNewGoldenFileName;

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

  // Specify font file to ensure the same font across different operation
  // systems.
  flow::PerformanceOverlayLayer layer(flow::kDisplayRasterizerStatistics |
                                          flow::kVisualizeRasterizerStatistics |
                                          flow::kDisplayEngineStatistics |
                                          flow::kVisualizeEngineStatistics,
                                      flow::GetFontFile().c_str());
  layer.set_paint_bounds(SkRect::MakeWH(1000, 400));
  surface->getCanvas()->clear(SK_ColorTRANSPARENT);
  layer.Paint(paintContext);

  sk_sp<SkImage> snapshot = surface->makeImageSnapshot();
  sk_sp<SkData> snapshot_data = snapshot->encodeToData();

  sk_sp<SkData> golden_data =
      SkData::MakeFromFileName(golden_file_path.c_str());
  EXPECT_TRUE(golden_data != nullptr)
      << "Golden file not found: " << golden_file_path << ".\n"
      << "Please either set --golden-dir, or make sure that the unit test is "
      << "run from the right directory (e.g., flutter/engine/src).";

  const bool golden_data_matches = golden_data->equals(snapshot_data.get());
  if (!golden_data_matches) {
    SkFILEWStream wstream(new_golden_file_path.c_str());
    wstream.write(snapshot_data->data(), snapshot_data->size());
    wstream.flush();

    size_t b64_size =
        SkBase64::Encode(snapshot_data->data(), snapshot_data->size(), nullptr);
    sk_sp<SkData> b64_data = SkData::MakeUninitialized(b64_size + 1);
    char* b64_char = static_cast<char*>(b64_data->writable_data());
    SkBase64::Encode(snapshot_data->data(), snapshot_data->size(), b64_char);
    b64_char[b64_size] = 0;  // make it null terminated for printing

    EXPECT_TRUE(golden_data_matches)
        << "Golden file mismatch. Please check "
        << "the difference between " << kGoldenFileName << " and "
        << kNewGoldenFileName << ", and  replace the former "
        << "with the latter if the difference looks good.\n\n"
        << "See also the base64 encoded " << kNewGoldenFileName << ":\n"
        << b64_char;
  }
}
