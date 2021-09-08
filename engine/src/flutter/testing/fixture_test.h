// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_FIXTURE_TEST_H_
#define FLUTTER_TESTING_FIXTURE_TEST_H_

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/testing/elf_loader.h"
#include "flutter/testing/test_dart_native_resolver.h"
#include "flutter/testing/testing.h"
#include "flutter/testing/thread_test.h"

namespace flutter {
namespace testing {

class FixtureTest : public ThreadTest {
 public:
  // Uses the default filenames from the fixtures generator.
  FixtureTest();

  // Allows to customize the kernel, ELF and split ELF filenames.
  FixtureTest(std::string kernel_filename,
              std::string elf_filename,
              std::string elf_split_filename);

  virtual Settings CreateSettingsForFixture();

  void AddNativeCallback(std::string name, Dart_NativeFunction callback);

 protected:
  void SetSnapshotsAndAssets(Settings& settings);

  std::shared_ptr<TestDartNativeResolver> native_resolver_;

  ELFAOTSymbols split_aot_symbols_;

 private:
  std::string kernel_filename_;
  std::string elf_filename_;
  fml::UniqueFD assets_dir_;
  ELFAOTSymbols aot_symbols_;

  FML_DISALLOW_COPY_AND_ASSIGN(FixtureTest);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_TESTING_FIXTURE_TEST_H_
