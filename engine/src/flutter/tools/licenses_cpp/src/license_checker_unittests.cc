// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <filesystem>
#include <fstream>
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"
#include "flutter/third_party/re2/re2/re2.h"
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

const char* kHeader = R"header(
// Copyright Test

void main() {
}
)header";

const char* kCHeader = R"header(
/*
C Copyright Test
*/

void main() {
}
)header";

const char* kLicense = R"lic(
Test License
v2.0
)lic";

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

absl::Status WriteFile(const char* data, const fs::path& path) {
  std::ofstream of;
  of.open(path.string(), std::ios::binary);
  if (!of.good()) {
    return absl::InternalError("can't open file");
  }
  of.write(data, std::strlen(data));
  of.close();
  return absl::OkStatus();
}

bool FindError(const std::vector<absl::Status>& errors,
               absl::StatusCode code,
               std::string_view regex) {
  return std::find_if(errors.begin(), errors.end(),
                      [code, regex](const absl::Status& status) {
                        return status.code() == code &&
                               RE2::PartialMatch(status.message(), regex);
                      }) != errors.end();
}
}  // namespace

TEST_F(LicenseCheckerTest, SimplePass) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("git init"), 0);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  ASSERT_EQ(std::system("git add main.cc"), 0);
  ASSERT_EQ(std::system("git add LICENSE"), 0);
  ASSERT_EQ(std::system("git commit -m \"test\""), 0);

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);
}

TEST_F(LicenseCheckerTest, SimpleMissingLicense) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("git init"), 0);
  ASSERT_EQ(std::system("echo \"Hello world!\" > main.cc"), 0);
  ASSERT_EQ(std::system("git add main.cc"), 0);
  ASSERT_EQ(std::system("git commit -m \"test\""), 0);

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 2u);
  EXPECT_TRUE(
      FindError(errors, absl::StatusCode::kNotFound, "Expected LICENSE at"));
  EXPECT_TRUE(FindError(errors, absl::StatusCode::kNotFound,
                        "Expected copyright in.*main.cc"));
}

TEST_F(LicenseCheckerTest, SimpleWritesLicensesFile) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("git init"), 0);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  ASSERT_EQ(std::system("git add main.cc"), 0);
  ASSERT_EQ(std::system("git add LICENSE"), 0);
  ASSERT_EQ(std::system("git commit -m \"test\""), 0);

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);

  EXPECT_EQ(ss.str(), R"output(engine

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, SimpleWritesTwoLicensesFiles) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("git init"), 0);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  ASSERT_TRUE(WriteFile(kCHeader, *temp_path / "cmain.cc").ok());
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  ASSERT_EQ(std::system("git add main.cc"), 0);
  ASSERT_EQ(std::system("git add cmain.cc"), 0);
  ASSERT_EQ(std::system("git add LICENSE"), 0);
  ASSERT_EQ(std::system("git commit -m \"test\""), 0);

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);

  EXPECT_EQ(ss.str(), R"output(engine

C Copyright Test

--------------------------------------------------------------------------------
engine

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, SimpleWritesDuplicateLicensesFiles) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("git init"), 0);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "a.cc").ok());
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "b.cc").ok());
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  ASSERT_EQ(std::system("git add a.cc"), 0);
  ASSERT_EQ(std::system("git add b.cc"), 0);
  ASSERT_EQ(std::system("git add LICENSE"), 0);
  ASSERT_EQ(std::system("git commit -m \"test\""), 0);

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);

  EXPECT_EQ(ss.str(), R"output(engine

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, MultiplePackages) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("mkdir -p third_party/foobar"), 0);
  ASSERT_EQ(std::system("git init"), 0);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "a.cc").ok());
  ASSERT_TRUE(
      WriteFile(kHeader, *temp_path / "third_party" / "foobar" / "b.cc").ok());
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  ASSERT_TRUE(
      WriteFile(kLicense, *temp_path / "third_party" / "foobar" / "LICENSE")
          .ok());
  ASSERT_EQ(std::system("git add a.cc"), 0);
  ASSERT_EQ(std::system("git add third_party/foobar/b.cc"), 0);
  ASSERT_EQ(std::system("git add third_party/foobar/LICENSE"), 0);
  ASSERT_EQ(std::system("git add LICENSE"), 0);
  ASSERT_EQ(std::system("git commit -m \"test\""), 0);

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);

  EXPECT_EQ(ss.str(), R"output(engine
foobar

Copyright Test
)output");
}
