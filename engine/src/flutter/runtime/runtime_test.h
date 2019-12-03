// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_RUNTIME_TEST_H_
#define FLUTTER_RUNTIME_RUNTIME_TEST_H_

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/test_dart_native_resolver.h"
#include "flutter/testing/thread_test.h"

namespace flutter {
namespace testing {

class RuntimeTest : public ThreadTest {
 public:
  RuntimeTest();

  ~RuntimeTest();

  Settings CreateSettingsForFixture();

  void AddNativeCallback(std::string name, Dart_NativeFunction callback);

 protected:
  // |testing::ThreadTest|
  void SetUp() override;

  // |testing::ThreadTest|
  void TearDown() override;

 private:
  fml::UniqueFD assets_dir_;
  std::shared_ptr<TestDartNativeResolver> native_resolver_;

  void SetSnapshotsAndAssets(Settings& settings);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_RUNTIME_RUNTIME_TEST_H_
