// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path.h"
#include "base/path_service.h"
#include "gin/modules/console.h"
#include "gin/modules/module_registry.h"
#include "gin/test/file_runner.h"
#include "gin/test/gtest.h"
#include "mojo/edk/js/core.h"
#include "mojo/edk/js/support.h"
#include "mojo/public/cpp/environment/environment.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace js {
namespace {

class TestRunnerDelegate : public gin::FileRunnerDelegate {
 public:
  TestRunnerDelegate() {
    AddBuiltinModule(gin::Console::kModuleName, gin::Console::GetModule);
    AddBuiltinModule(Core::kModuleName, Core::GetModule);
    AddBuiltinModule(Support::kModuleName, Support::GetModule);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TestRunnerDelegate);
};

void RunTest(std::string test, bool run_until_idle) {
  base::FilePath path;
  PathService::Get(base::DIR_SOURCE_ROOT, &path);
  path = path.AppendASCII("mojo")
             .AppendASCII("public")
             .AppendASCII("js")
             .AppendASCII(test);
  TestRunnerDelegate delegate;
  gin::RunTestFromFile(path, &delegate, run_until_idle);
}

// TODO(abarth): Should we autogenerate these stubs from GYP?
TEST(JSTest, core) {
  RunTest("core_unittests.js", true);
}

TEST(JSTest, codec) {
  RunTest("codec_unittests.js", true);
}

TEST(JSTest, struct) {
  RunTest("struct_unittests.js", true);
}

TEST(JSTest, union) {
  RunTest("union_unittests.js", true);
}

TEST(JSTest, validation) {
  RunTest("validation_unittests.js", true);
}

}  // namespace
}  // namespace js
}  // namespace mojo
