// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <sstream>

#include "flutter/fml/platform/darwin/scoped_nsautorelease_pool.h"
#include "impeller/aiks/aiks_context.h"
#include "impeller/aiks/canvas.h"
#include "impeller/entity/contents/conical_gradient_contents.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/golden_tests/golden_digest.h"
#include "impeller/golden_tests/metal_screenshot.h"
#include "impeller/golden_tests/metal_screenshotter.h"
#include "impeller/golden_tests/working_directory.h"

namespace impeller {
namespace testing {

namespace {
std::string GetTestName() {
  std::string suite_name =
      ::testing::UnitTest::GetInstance()->current_test_suite()->name();
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  std::stringstream ss;
  ss << "impeller_" << suite_name << "_" << test_name;
  return ss.str();
}

std::string GetGoldenFilename() {
  return GetTestName() + ".png";
}

bool SaveScreenshot(std::unique_ptr<MetalScreenshot> screenshot) {
  if (!screenshot || !screenshot->GetBytes()) {
    return false;
  }
  std::string test_name = GetTestName();
  std::string filename = GetGoldenFilename();
  GoldenDigest::Instance()->AddImage(
      test_name, filename, screenshot->GetWidth(), screenshot->GetHeight());
  return screenshot->WriteToPNG(
      WorkingDirectory::Instance()->GetFilenamePath(filename));
}

}  // namespace

class GoldenTests : public ::testing::Test {
 public:
  GoldenTests() : screenshotter_(new MetalScreenshotter()) {}

  MetalScreenshotter& Screenshotter() { return *screenshotter_; }

  void SetUp() override {
    testing::GoldenDigest::Instance()->AddDimension(
        "gpu_string",
        Screenshotter().GetPlayground().GetContext()->DescribeGpuModel());
  }

 private:
  // This must be placed before any other members that may use the
  // autorelease pool.
  fml::ScopedNSAutoreleasePool autorelease_pool_;

  std::unique_ptr<MetalScreenshotter> screenshotter_;
};

TEST_F(GoldenTests, ConicalGradient) {
  Canvas canvas;
  Paint paint;

  paint.color_source = ColorSource::MakeConicalGradient(
      {125, 125}, 125, {Color(1.0, 0.0, 0.0, 1.0), Color(0.0, 0.0, 1.0, 1.0)},
      {0, 1}, {180, 180}, 0, Entity::TileMode::kClamp, {});

  paint.stroke_width = 0.0;
  paint.style = Paint::Style::kFill;
  canvas.DrawRect(Rect::MakeXYWH(10, 10, 250, 250), paint);
  Picture picture = canvas.EndRecordingAsPicture();

  auto aiks_context =
      AiksContext(Screenshotter().GetPlayground().GetContext(), nullptr);
  auto screenshot = Screenshotter().MakeScreenshot(aiks_context, picture);
  ASSERT_TRUE(SaveScreenshot(std::move(screenshot)));
}
}  // namespace testing
}  // namespace impeller
