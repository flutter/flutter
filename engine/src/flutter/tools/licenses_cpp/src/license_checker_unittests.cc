// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <filesystem>
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"
#include "flutter/tools/licenses_cpp/src/license_checker.h"
#include "gtest/gtest.h"

namespace fs = std::filesystem;

class LicenseCheckerTest : public testing::Test {
 public:
  void SetUp() override {
    std::error_code err;
    temp_dir_base_ = fs::temp_directory_path(err);
    ASSERT_FALSE(err);
  }

  void TearDown() override {
    if (should_delete_temp_dir_) {
      fs::remove_all(temp_dir_);
    }
  }

  absl::StatusOr<fs::path> MakeTempDir() {
    static std::atomic<int32_t> count = 0;
    std::stringstream ss;
    ss << "LicenseCheckerTest_" << std::time(nullptr) << "_"
       << count.fetch_add(1);
    temp_dir_ = temp_dir_base_ / ss.str();
    std::error_code err;
    fs::create_directory(temp_dir_, err);
    if (!err) {
      should_delete_temp_dir_ = true;
    } else {
      return absl::InternalError("can't make temp dir");
    }

    return temp_dir_;
  }

 private:
  fs::path temp_dir_base_;
  fs::path temp_dir_;
  bool should_delete_temp_dir_;
};

namespace {
absl::StatusOr<Data> MakeTestData() {
  std::stringstream include;
  include << ".*\\.cc" << std::endl;
  absl::StatusOr<Filter> include_filter = Filter::Open(include);
  if (!include_filter.ok()) {
    return include_filter.status();
  }
  std::stringstream exclude;
  exclude << ".*/ignore/.*" << std::endl;
  absl::StatusOr<Filter> exclude_filter = Filter::Open(exclude);
  if (!exclude_filter.ok()) {
    return exclude_filter.status();
  }
  return Data{
      .include_filter = std::move(*include_filter),
      .exclude_filter = std::move(*exclude_filter),
  };
}
}  // namespace

TEST_F(LicenseCheckerTest, Simple) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("git init"), 0);
  ASSERT_EQ(std::system("echo \"Hello world!\" > main.cc"), 0);
  ASSERT_EQ(std::system("git add main.cc"), 0);
  ASSERT_EQ(std::system("git commit -m \"test\""), 0);

  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), *data);
  for (const auto& error : errors) {
    std::cout << error << std::endl;
  }
  ASSERT_EQ(errors.size(), 2u);
}
