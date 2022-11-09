// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/testing/testing.h"
#include "impeller/compiler/switches.h"
#include "impeller/compiler/utilities.h"

namespace impeller {
namespace compiler {
namespace testing {

TEST(SwitchesTest, DoesntMangleUnicodeIncludes) {
  const char* directory_name = "test_shader_include_Ã�";
  fml::CreateDirectory(flutter::testing::OpenFixturesDirectory(),
                       {directory_name}, fml::FilePermission::kRead);

  auto include_path =
      std::string(flutter::testing::GetFixturesPath()) + "/" + directory_name;
  auto include_option = "--include=" + include_path;

  const auto cl = fml::CommandLineFromInitializerList(
      {"impellerc", "--opengl-desktop", "--input=input.vert",
       "--sl=output.vert", "--spirv=output.spirv", include_option.c_str()});
  Switches switches(cl);
  ASSERT_TRUE(switches.AreValid(std::cout));
  ASSERT_EQ(switches.include_directories.size(), 1u);
  ASSERT_NE(switches.include_directories[0].dir, nullptr);
  ASSERT_EQ(switches.include_directories[0].name, include_path);
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
