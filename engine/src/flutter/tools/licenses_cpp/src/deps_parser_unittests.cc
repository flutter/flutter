// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/deps_parser.h"
#include "gtest/gtest.h"

TEST(DepsParserTest, Trivial) {
  DepsParser parser;
  ASSERT_TRUE(true);
}

TEST(DepsParserTest, ParseDepsWithWhitespace) {
  DepsParser parser;
  std::string input = R"(# Yadda yadda
foo = {}
deps =   {
  'engine/src/flutter/third_party/harfbuzz':
   Var('flutter_git') + '/third_party/harfbuzz' + '@' + 'ea6a172f84f2cbcfed803b5ae71064c7afb6b5c2',
  'engine/src/flutter/third_party/dart/tools/sdks/dart-sdk':
   {'dep_type': 'cipd', 'packages': [{'package': 'dart/dart-sdk/${{platform}}', 'version': 'git_revision:4bb26ad346b166d759773e01ffc8247893b9681e'}]},
  'third_party/doof':
   {'packages': [{'package': 'doof', 'version': '1.0'}], 'dep_type': 'cipd'},
}
)";
  std::vector<std::string> expected = {
      "engine/src/flutter/third_party/dart/tools/sdks/dart-sdk",
      "third_party/doof"};

  std::vector<std::string> actual = parser.Parse(input);

  ASSERT_EQ(actual.size(), expected.size());
  EXPECT_EQ(actual[0], expected[0]);
  EXPECT_EQ(actual[1], expected[1]);
}
