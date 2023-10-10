// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/golden_tests/golden_playground_test.h"

#include "impeller/aiks/picture.h"

namespace impeller {

GoldenPlaygroundTest::GoldenPlaygroundTest() = default;

GoldenPlaygroundTest::~GoldenPlaygroundTest() = default;

void GoldenPlaygroundTest::SetTypographerContext(
    std::shared_ptr<TypographerContext> typographer_context) {
  typographer_context_ = std::move(typographer_context);
};

void GoldenPlaygroundTest::TearDown() {}

void GoldenPlaygroundTest::SetUp() {
  GTEST_SKIP_("GoldenPlaygroundTest doesn't support this backend type.");
}

PlaygroundBackend GoldenPlaygroundTest::GetBackend() const {
  return GetParam();
}

bool GoldenPlaygroundTest::OpenPlaygroundHere(Picture picture) {
  return false;
}

bool GoldenPlaygroundTest::OpenPlaygroundHere(
    AiksPlaygroundCallback
        callback) {  // NOLINT(performance-unnecessary-value-param)
  return false;
}

std::shared_ptr<Texture> GoldenPlaygroundTest::CreateTextureForFixture(
    const char* fixture_name,
    bool enable_mipmapping) const {
  return nullptr;
}

std::shared_ptr<RuntimeStage> GoldenPlaygroundTest::OpenAssetAsRuntimeStage(
    const char* asset_name) const {
  return nullptr;
}

std::shared_ptr<Context> GoldenPlaygroundTest::GetContext() const {
  return nullptr;
}

Point GoldenPlaygroundTest::GetContentScale() const {
  return Point();
}

Scalar GoldenPlaygroundTest::GetSecondsElapsed() const {
  return Scalar();
}

ISize GoldenPlaygroundTest::GetWindowSize() const {
  return ISize();
}

void GoldenPlaygroundTest::SetWindowSize(ISize size) {}

}  // namespace impeller
