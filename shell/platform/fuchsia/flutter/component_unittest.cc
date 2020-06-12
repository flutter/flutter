// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/fuchsia/flutter/component.h"

#include <gtest/gtest.h>

namespace flutter_runner {
namespace {

TEST(Component, ParseProgramMetadata) {
  std::string data_path;
  std::string assets_path;

  // The ProgramMetadata field may be null. We should parse this as if no
  // fields were specified.
  Application::ParseProgramMetadata(nullptr, &data_path, &assets_path);

  EXPECT_EQ(data_path, "");
  EXPECT_EQ(assets_path, "");

  // The ProgramMetadata field may be empty. Treat this the same as null.
  fidl::VectorPtr<fuchsia::sys::ProgramMetadata> program_metadata(size_t{0});

  Application::ParseProgramMetadata(program_metadata, &data_path, &assets_path);

  EXPECT_EQ(data_path, "");
  EXPECT_EQ(assets_path, "");

  // The assets_path defaults to the "data" value if unspecified
  program_metadata = {{"data", "foobar"}};

  Application::ParseProgramMetadata(program_metadata, &data_path, &assets_path);

  EXPECT_EQ(data_path, "pkg/foobar");
  EXPECT_EQ(assets_path, "pkg/foobar");

  data_path = "";
  assets_path = "";

  program_metadata = {{"not_data", "foo"}, {"data", "bar"}, {"assets", "baz"}};

  Application::ParseProgramMetadata(program_metadata, &data_path, &assets_path);

  EXPECT_EQ(data_path, "pkg/bar");
  EXPECT_EQ(assets_path, "pkg/baz");
}

}  // anonymous namespace
}  // namespace flutter_runner
