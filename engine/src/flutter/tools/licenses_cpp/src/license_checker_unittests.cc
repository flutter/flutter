// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <filesystem>
#include <fstream>
#include "flutter/third_party/re2/re2/re2.h"
#include "flutter/tools/licenses_cpp/src/license_checker.h"
#include "gtest/gtest.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"
#include "third_party/abseil-cpp/absl/strings/str_cat.h"

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

    fs::path engine_path = temp_dir_ / "engine";
    fs::create_directory(engine_path, err);
    if (err) {
      return absl::InternalError("can't make temp engine dir");
    }

    return engine_path;
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

const char* kUnknownHeader = R"header(
// Unknown Copyright

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

const char* kLicense = R"lic(Test License
v2.0
)lic";

const char* kUnknownLicense = R"lic(Unknown License
2025
v2.0
)lic";

absl::StatusOr<Data> MakeTestData(
    std::optional<std::string_view> include_filter_text = std::nullopt) {
  std::stringstream include;
  if (include_filter_text.has_value()) {
    include << include_filter_text.value() << std::endl;
  } else {
    include << ".*\\.cc" << std::endl;
  }
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

  absl::StatusOr<Catalog> catalog =
      Catalog::Make({{"test", "Test License", R"lic(Test License
v\d\.\d)lic"},
                     {"header", "Copyright Test", "(?:C )?Copyright Test"}});
  if (!catalog.ok()) {
    return catalog.status();
  }

  return Data{
      .include_filter = std::move(*include_filter),
      .exclude_filter = std::move(*exclude_filter),
      .catalog = std::move(catalog.value()),
      .secondary_dir = fs::path(),
  };
}

absl::Status WriteFile(std::string_view data, const fs::path& path) {
  std::ofstream of;
  of.open(path.string(), std::ios::binary);
  if (!of.good()) {
    return absl::InternalError("can't open file");
  }
  of.write(data.data(), data.length());
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

class Repo {
 public:
  void Add(const std::string& file) { files_.emplace_back(std::string(file)); }

  absl::Status Commit() {
    if (std::system("git init") != 0) {
      return absl::InternalError("git init failed");
    }
    for (const std::string& file : files_) {
      if (std::system(("git add " + file).c_str()) != 0) {
        return absl::InternalError("git add failed: " + file);
      }
    }
    if (std::system("git commit -m \"test\"") != 0) {
      return absl::InternalError("git commit failed");
    }
    return absl::OkStatus();
  }

 private:
  std::vector<std::string> files_;
};

}  // namespace

TEST_F(LicenseCheckerTest, SimplePass) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  repo.Add(*temp_path / "LICENSE");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];
}

TEST_F(LicenseCheckerTest, UnknownFileLicense) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kUnknownHeader, *temp_path / "main.cc").ok());
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 1u);
  EXPECT_TRUE(FindError(errors, absl::StatusCode::kNotFound,
                        "Expected copyright in.*main.cc"))
      << (errors.size() > 0 ? absl::StrCat(errors[0]) : "")
      << (errors.size() > 1 ? absl::StrCat("\n", errors[1]) : "");
}

TEST_F(LicenseCheckerTest, UnknownLicense) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  // Make sure the error is only reported once.
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "foo.cc").ok());
  ASSERT_TRUE(WriteFile(kUnknownLicense, *temp_path / "LICENSE").ok());
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  repo.Add(*temp_path / "foo.cc");
  repo.Add(*temp_path / "LICENSE");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 1u);
  ASSERT_TRUE(!errors.empty());
  EXPECT_TRUE(FindError(errors, absl::StatusCode::kNotFound,
                        "Unknown license in.*LICENSE"))
      << errors[0];
}

TEST_F(LicenseCheckerTest, SimpleMissingFileLicense) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("echo \"Hello world!\" > main.cc"), 0);
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 1u);
  EXPECT_TRUE(FindError(errors, absl::StatusCode::kNotFound,
                        "Expected copyright in.*main.cc"))
      << (errors.size() > 0 ? absl::StrCat(errors[0]) : "");
}

TEST_F(LicenseCheckerTest, SimpleIgnoreFile) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  std::stringstream exclude;
  exclude << R"regex(^main\.cc)regex" << std::endl;
  absl::StatusOr<Filter> exclude_filter = Filter::Open(exclude);
  ASSERT_TRUE(exclude_filter.ok());
  data->exclude_filter = std::move(exclude_filter.value());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kUnknownHeader, *temp_path / "main.cc").ok());
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);
}

TEST_F(LicenseCheckerTest, CanIgnoreLicenseFiles) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  std::stringstream exclude;
  exclude << "^LICENSE" << std::endl;
  absl::StatusOr<Filter> exclude_filter = Filter::Open(exclude);
  ASSERT_TRUE(exclude_filter.ok());
  data->exclude_filter = std::move(exclude_filter.value());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  repo.Add(*temp_path / "LICENSE");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"output(engine

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, SimpleWritesFileLicensesFile) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"output(engine

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, SimpleWritesTwoFileLicensesFiles) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  ASSERT_TRUE(WriteFile(kCHeader, *temp_path / "cmain.cc").ok());
  Repo repo;
  repo.Add("main.cc");
  repo.Add("cmain.cc");
  ASSERT_TRUE(repo.Commit().ok());

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

TEST_F(LicenseCheckerTest, SimpleWritesDuplicateFileLicensesFiles) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "a.cc").ok());
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "b.cc").ok());
  Repo repo;
  repo.Add("a.cc");
  repo.Add("b.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);

  EXPECT_EQ(ss.str(), R"output(engine

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, FileLicenseMultiplePackages) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("mkdir -p third_party/foobar"), 0);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "a.cc").ok());
  ASSERT_TRUE(
      WriteFile(kHeader, *temp_path / "third_party" / "foobar" / "b.cc").ok());
  Repo repo;
  repo.Add("a.cc");
  repo.Add("third_party/foobar/b.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);

  EXPECT_EQ(ss.str(), R"output(engine
foobar

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, SimpleDirectoryLicense) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  Repo repo;
  repo.Add("main.cc");
  repo.Add("LICENSE");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);

  EXPECT_EQ(ss.str(), R"output(engine

Copyright Test
--------------------------------------------------------------------------------
engine

Test License
v2.0
)output");
}

TEST_F(LicenseCheckerTest, RootDirectoryIsStrict) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("echo \"Hello world!\" > main.cc"), 0);
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  Repo repo;
  repo.Add("main.cc");
  repo.Add("LICENSE");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 1u);

  EXPECT_TRUE(FindError(errors, absl::StatusCode::kNotFound,
                        "Expected root copyright in.*main.cc"))
      << (errors.size() > 0 ? absl::StrCat(errors[0]) : "");
}

TEST_F(LicenseCheckerTest, ThirdPartyDirectoryLicense) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("mkdir -p third_party/foobar"), 0);
  ASSERT_EQ(std::system("echo \"Hello world!\" > third_party/foobar/foo.cc"),
            0);
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  ASSERT_TRUE(
      WriteFile(kLicense, *temp_path / "third_party" / "foobar" / "LICENSE")
          .ok());
  Repo repo;
  repo.Add("LICENSE");
  repo.Add("third_party/foobar/foo.cc");
  repo.Add("third_party/foobar/LICENSE");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u);

  EXPECT_EQ(ss.str(), R"output(foobar

Test License
v2.0
)output");
}

TEST_F(LicenseCheckerTest, OnlyPrintMatch) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  ASSERT_TRUE(WriteFile(absl::StrCat(kLicense, "\n----------------------\n"),
                        *temp_path / "LICENSE")
                  .ok());
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  repo.Add(*temp_path / "LICENSE");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"output(engine

Copyright Test
--------------------------------------------------------------------------------
engine

Test License
v2.0
)output");
}

TEST_F(LicenseCheckerTest, OnlyPrintMatchHeader) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(R"header(
// Extra text.
// Copyright Test
//
// Extra text.

void main() {
}
)header",
                        *temp_path / "main.cc")
                  .ok());
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"output(engine

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, UnmatchedCommentsAsErrors) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_EQ(std::system("mkdir -p third_party/foobar"), 0);
  ASSERT_TRUE(
      WriteFile(kUnknownHeader, *temp_path / "third_party/foobar/foo.cc").ok());
  ASSERT_TRUE(
      WriteFile(kLicense, *temp_path / "third_party" / "foobar" / "LICENSE")
          .ok());
  Repo repo;
  repo.Add("third_party/foobar/foo.cc");
  repo.Add("third_party/foobar/LICENSE");
  ASSERT_TRUE(repo.Commit().ok());

  LicenseChecker::Flags flags = {.treat_unmatched_comments_as_errors = true};
  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data, flags);

  EXPECT_EQ(errors.size(), 1u);
  EXPECT_TRUE(
      FindError(errors, absl::StatusCode::kNotFound,
                "(?s).*foo.cc.*Selector didn't match.*Unknown Copyright"))
      << (errors.size() > 0 ? absl::StrCat(errors[0]) : "");
}

TEST_F(LicenseCheckerTest, NoticesFile) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData(/*include_filter_text=*/"NOTICES");
  ASSERT_TRUE(data.ok());

  std::string notices = R"notices(engine
foobar

Copyright Test
--------------------------------------------------------------------------------
engine

Test License
v2.0
)notices";

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(notices, "NOTICES").ok());
  Repo repo;
  repo.Add("NOTICES");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), notices);
}

TEST_F(LicenseCheckerTest, NoticesFileUnknownLicense) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData(/*include_filter_text=*/"NOTICES");
  ASSERT_TRUE(data.ok());

  std::string notices = R"notices(engine
foobar

Copyright Test
--------------------------------------------------------------------------------
engine

Unknown license
)notices";

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(notices, "NOTICES").ok());
  Repo repo;
  repo.Add("NOTICES");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  LicenseChecker::Flags flags = {.treat_unmatched_comments_as_errors = true};
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data, flags);
  EXPECT_EQ(errors.size(), 1u);
  ASSERT_TRUE(!errors.empty());
  EXPECT_TRUE(FindError(errors, absl::StatusCode::kNotFound, "NOTICES"))
      << errors[0];
}

TEST_F(LicenseCheckerTest, CipdDependencyParentDir) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);

  const char* deps_file = R"deps(
deps = {
  'child/third_party/foobar': {
    'dep_type': 'cipd',
    'packages': [{'package': 'flutter/testing/foobar', 'version': '1.0.0'}],
  },
}
)deps";
  ASSERT_TRUE(WriteFile(deps_file, "DEPS").ok());

  fs::create_directories("child/third_party/foobar");
  ASSERT_TRUE(WriteFile(kHeader, "child/third_party/foobar/foobar.cc").ok());

  Repo repo;
  repo.Add("DEPS");
  ASSERT_TRUE(repo.Commit().ok());

  fs::current_path(*temp_path / "child");
  std::stringstream ss;
  std::vector<absl::Status> errors = LicenseChecker::Run(".", ss, *data);
  EXPECT_EQ(errors.size(), 0u) << (errors.empty() ? "" : errors[0].message());

  EXPECT_EQ(ss.str(), R"output(foobar

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, CipdDependency) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);

  const char* deps_file = R"deps(
deps = {
  'third_party/foobar': {
    'dep_type': 'cipd',
    'packages': [{'package': 'flutter/testing/foobar', 'version': '1.0.0'}],
  },
}
)deps";
  ASSERT_TRUE(WriteFile(deps_file, "DEPS").ok());

  fs::create_directories("third_party/foobar");
  ASSERT_TRUE(WriteFile(kHeader, "third_party/foobar/foobar.cc").ok());

  Repo repo;
  repo.Add("DEPS");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << (errors.empty() ? "" : errors[0].message());

  EXPECT_EQ(ss.str(), R"output(foobar

Copyright Test
)output");
}

TEST_F(LicenseCheckerTest, Secondary) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  fs::create_directories("engine/third_party/foobar");
  fs::create_directories("secondary/third_party/foobar");
  ASSERT_TRUE(WriteFile(kHeader, "engine/third_party/foobar/foobar.cc").ok());
  ASSERT_TRUE(
      WriteFile(kLicense, "secondary/third_party/foobar/license.txt").ok());

  data->secondary_dir = *temp_path / "secondary";

  fs::current_path(*temp_path / "engine");
  Repo repo;
  repo.Add("third_party/foobar/foobar.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run((*temp_path / "engine").string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"notices(foobar

Copyright Test
--------------------------------------------------------------------------------
foobar

Test License
v2.0

)notices");
}

TEST_F(LicenseCheckerTest, WorkingDirectoryTrailingSlash) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  ASSERT_TRUE(WriteFile(kLicense, *temp_path / "LICENSE").ok());
  Repo repo;
  repo.Add("main.cc");
  repo.Add("LICENSE");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::string working_dir = temp_path->string() + "/";
  std::vector<absl::Status> errors =
      LicenseChecker::Run(working_dir, ss, *data);
  EXPECT_EQ(errors.size(), 0u) << (errors.empty() ? "" : errors[0].message());

  EXPECT_EQ(ss.str(), R"output(engine

Copyright Test
--------------------------------------------------------------------------------
engine

Test License
v2.0
)output");
}

TEST_F(LicenseCheckerTest, HandlesTxtFiles) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData(/*include_filter_text=*/".*txt");
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);

  ASSERT_TRUE(WriteFile(R"lic(Test License
v2.0
)lic",
                        *temp_path / "foobar.txt")
                  .ok());
  Repo repo;
  repo.Add("foobar.txt");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"output(engine

Test License
v2.0
)output");
}

TEST_F(LicenseCheckerTest, IgnoredDir) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  fs::create_directories("third_party/vulkan-deps");
  fs::create_directories("third_party/vulkan-deps/foobar");

  ASSERT_TRUE(
      WriteFile(kLicense, *temp_path / "third_party/vulkan-deps/foobar/LICENSE")
          .ok());
  ASSERT_TRUE(WriteFile(kHeader,
                        *temp_path / "third_party/vulkan-deps/foobar/foobar.cc")
                  .ok());

  Repo repo;
  repo.Add(*temp_path / "third_party/vulkan-deps/foobar/LICENSE");
  repo.Add(*temp_path / "third_party/vulkan-deps/foobar/foobar.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"output(foobar

Copyright Test
--------------------------------------------------------------------------------
foobar

Test License
v2.0
)output");
}

TEST_F(LicenseCheckerTest, IgnoredDirHasContent) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  fs::create_directories("third_party/vulkan-deps");
  fs::create_directories("third_party/vulkan-deps/foobar");

  ASSERT_TRUE(
      WriteFile(kLicense, *temp_path / "third_party/vulkan-deps/LICENSE").ok());
  ASSERT_TRUE(
      WriteFile(kHeader, *temp_path / "third_party/vulkan-deps/foobar.cc")
          .ok());

  Repo repo;
  repo.Add(*temp_path / "third_party/vulkan-deps/LICENSE");
  repo.Add(*temp_path / "third_party/vulkan-deps/foobar.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"output(vulkan-deps

Copyright Test
--------------------------------------------------------------------------------
vulkan-deps

Test License
v2.0
)output");
}

TEST_F(LicenseCheckerTest, DoubleLicenseFiles) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data =
      MakeTestData(/*include_filter_text=*/".*/COPYING|.*cc");
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  fs::create_directories("third_party/foobar");

  ASSERT_TRUE(WriteFile(R"lic(Test License
v2.0
)lic",
                        *temp_path / "third_party/foobar/LICENSE")
                  .ok());
  ASSERT_TRUE(WriteFile(R"lic(Test License
v3.0
)lic",
                        *temp_path / "third_party/foobar/COPYING")
                  .ok());
  ASSERT_TRUE(WriteFile(kHeader, "third_party/foobar/foobar.cc").ok());
  Repo repo;
  repo.Add("third_party/foobar/COPYING");
  repo.Add("third_party/foobar/LICENSE");
  repo.Add("third_party/foobar/foobar.cc");
  ASSERT_TRUE(repo.Commit().ok());

  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"output(foobar

Copyright Test
--------------------------------------------------------------------------------
foobar

Test License
v2.0
--------------------------------------------------------------------------------
foobar

Test License
v3.0
)output");
}

TEST_F(LicenseCheckerTest, OverrideRootPackageName) {
  absl::StatusOr<fs::path> temp_path = MakeTempDir();
  ASSERT_TRUE(temp_path.ok());

  absl::StatusOr<Data> data = MakeTestData();
  ASSERT_TRUE(data.ok());

  fs::current_path(*temp_path);
  ASSERT_TRUE(WriteFile(kHeader, *temp_path / "main.cc").ok());
  Repo repo;
  repo.Add(*temp_path / "main.cc");
  ASSERT_TRUE(repo.Commit().ok());

  LicenseChecker::Flags flags = {.root_package_name = "testroot"};
  std::stringstream ss;
  std::vector<absl::Status> errors =
      LicenseChecker::Run(temp_path->string(), ss, *data, flags);
  EXPECT_EQ(errors.size(), 0u) << errors[0];

  EXPECT_EQ(ss.str(), R"output(testroot

Copyright Test
)output");
}
