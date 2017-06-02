/*
 * Copyright 2017 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "render_test.h"
#include "third_party/skia/include/core/SkImageEncoder.h"
#include "third_party/skia/include/core/SkStream.h"

RenderTest::RenderTest() : snapshots_(0) {}

RenderTest::~RenderTest() {}

SkCanvas* RenderTest::GetCanvas() {
  return canvas_ == nullptr ? nullptr : canvas_.get();
}

std::string RenderTest::GetNextSnapshotName() {
  const auto& test_info =
      ::testing::UnitTest::GetInstance()->current_test_info();

  std::stringstream stream;
  stream << test_info->test_case_name() << "_" << test_info->name();
  stream << "_" << ++snapshots_ << ".png";

  return stream.str();
}

bool RenderTest::Snapshot() {
  if (!canvas_ || !bitmap_) {
    return false;
  }
  auto file_name = GetNextSnapshotName();
  SkFILEWStream file(file_name.c_str());
  return SkEncodeImage(&file, *bitmap_, SkEncodedImageFormat::kPNG, 100);
}

size_t RenderTest::GetTestCanvasWidth() const {
  return 800;
}

size_t RenderTest::GetTestCanvasHeight() const {
  return 600;
}

void RenderTest::SetUp() {
  bitmap_ = std::make_unique<SkBitmap>();
  bitmap_->allocN32Pixels(GetTestCanvasWidth(), GetTestCanvasHeight());
  canvas_ = std::make_unique<SkCanvas>(*bitmap_);
  canvas_->clear(SK_ColorTRANSPARENT);
}

void RenderTest::TearDown() {
  canvas_ = nullptr;
  bitmap_ = nullptr;
}
