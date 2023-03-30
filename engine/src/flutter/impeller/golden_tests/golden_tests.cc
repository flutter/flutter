// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <sstream>

#include "impeller/aiks/canvas.h"
#include "impeller/entity/contents/conical_gradient_contents.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/golden_tests/golden_digest.h"
#include "impeller/golden_tests/metal_screenshot.h"
#include "impeller/golden_tests/metal_screenshoter.h"
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
  GoldenTests() : screenshoter_(new MetalScreenshoter()) {}

  MetalScreenshoter& Screenshoter() { return *screenshoter_; }

 private:
  std::unique_ptr<MetalScreenshoter> screenshoter_;
};

TEST_F(GoldenTests, ConicalGradient) {
  Canvas canvas;
  Paint paint;
  paint.color_source_type = Paint::ColorSourceType::kConicalGradient;
  paint.color_source = []() {
    auto result = std::make_shared<ConicalGradientContents>();
    result->SetCenterAndRadius(Point(125, 125), 125);
    result->SetColors({Color(1.0, 0.0, 0.0, 1.0), Color(0.0, 0.0, 1.0, 1.0)});
    result->SetStops({0, 1});
    result->SetFocus(Point(180, 180), 0);
    result->SetTileMode(Entity::TileMode::kClamp);
    return result;
  };
  paint.stroke_width = 0.0;
  paint.style = Paint::Style::kFill;
  canvas.DrawRect(Rect(10, 10, 250, 250), paint);
  Picture picture = canvas.EndRecordingAsPicture();
  auto screenshot = Screenshoter().MakeScreenshot(picture);
  ASSERT_TRUE(SaveScreenshot(std::move(screenshot)));
}
}  // namespace testing
}  // namespace impeller
