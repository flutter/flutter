// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_RUNTIME_TEST_H_
#define FLUTTER_RUNTIME_RUNTIME_TEST_H_

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/thread_test.h"

namespace blink {
namespace testing {

class RuntimeTest : public ::testing::ThreadTest {
 public:
  RuntimeTest();

  ~RuntimeTest();

  void SetSnapshotsAndAssets(Settings& settings);

 protected:
  // |testing::ThreadTest|
  void SetUp() override;

  // |testing::ThreadTest|
  void TearDown() override;

 private:
  fml::UniqueFD assets_dir_;
};

}  // namespace testing
}  // namespace blink

#endif  // FLUTTER_RUNTIME_RUNTIME_TEST_H_
