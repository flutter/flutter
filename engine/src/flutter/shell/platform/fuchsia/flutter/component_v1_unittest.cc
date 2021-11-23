// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "component_v1.h"

#include <gtest/gtest.h>
#include <optional>

namespace flutter_runner {
namespace {

TEST(ComponentV1, ParseProgramMetadata) {
  // The ProgramMetadata field may be null. We should parse this as if no
  // fields were specified.
  ProgramMetadata result = ComponentV1::ParseProgramMetadata(nullptr);

  EXPECT_EQ(result.data_path, "");
  EXPECT_EQ(result.assets_path, "");
  EXPECT_EQ(result.old_gen_heap_size, std::nullopt);

  // The ProgramMetadata field may be empty. Treat this the same as null.
  fidl::VectorPtr<fuchsia::sys::ProgramMetadata> program_metadata(size_t{0});
  result = ComponentV1::ParseProgramMetadata(program_metadata);

  EXPECT_EQ(result.data_path, "");
  EXPECT_EQ(result.assets_path, "");
  EXPECT_EQ(result.old_gen_heap_size, std::nullopt);

  // The assets_path defaults to the "data" value if unspecified.
  program_metadata = {{"data", "foobar"}};
  result = ComponentV1::ParseProgramMetadata(program_metadata);

  EXPECT_EQ(result.data_path, "pkg/foobar");
  EXPECT_EQ(result.assets_path, "pkg/foobar");
  EXPECT_EQ(result.old_gen_heap_size, std::nullopt);

  // Invalid keys are ignored.
  program_metadata = {{"not_data", "foo"}, {"data", "bar"}, {"assets", "baz"}};
  result = ComponentV1::ParseProgramMetadata(program_metadata);

  EXPECT_EQ(result.data_path, "pkg/bar");
  EXPECT_EQ(result.assets_path, "pkg/baz");
  EXPECT_EQ(result.old_gen_heap_size, std::nullopt);

  // The old_gen_heap_size can be specified.
  program_metadata = {{"old_gen_heap_size", "100"}};
  result = ComponentV1::ParseProgramMetadata(program_metadata);

  EXPECT_EQ(result.data_path, "");
  EXPECT_EQ(result.assets_path, "");
  EXPECT_EQ(result.old_gen_heap_size, 100);

  // Invalid old_gen_heap_sizes should be ignored.
  program_metadata = {{"old_gen_heap_size", "asdf100"}};
  result = ComponentV1::ParseProgramMetadata(program_metadata);

  EXPECT_EQ(result.data_path, "");
  EXPECT_EQ(result.assets_path, "");
  EXPECT_EQ(result.old_gen_heap_size, std::nullopt);
}

}  // anonymous namespace
}  // namespace flutter_runner
