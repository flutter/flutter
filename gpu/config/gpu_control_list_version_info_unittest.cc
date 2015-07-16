// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_control_list.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class VersionInfoTest : public testing::Test {
 public:
  VersionInfoTest() { }
  ~VersionInfoTest() override {}

  typedef GpuControlList::VersionInfo VersionInfo;
};

TEST_F(VersionInfoTest, ValidVersionInfo) {
  const std::string op[] = {
    "=",
    "<",
    "<=",
    ">",
    ">=",
    "any",
    "between"
  };
  for (size_t i = 0; i < arraysize(op); ++i) {
    std::string string1;
    std::string string2;
    if (op[i] != "any")
      string1 = "8.9";
    if (op[i] == "between")
      string2 = "9.0";
    VersionInfo info(op[i], std::string(), string1, string2);
    EXPECT_TRUE(info.IsValid());
  }

  const std::string style[] = {
    "lexical",
    "numerical",
    ""  // Default, same as "numerical"
  };
  for (size_t i =0; i < arraysize(style); ++i) {
    VersionInfo info("=", style[i], "8.9", std::string());
    EXPECT_TRUE(info.IsValid());
    if (style[i] == "lexical")
      EXPECT_TRUE(info.IsLexical());
    else
      EXPECT_FALSE(info.IsLexical());
  }

  const std::string number[] = {
    "10",
    "10.9",
    "10.0",
    "10.0.9",
    "0.8",
    // Leading 0s are valid.
    "10.09",
    // Whitespaces are ignored.
    " 10.9",
    "10.9 ",
    "10 .9",
    "10. 9",
  };
  for (size_t i =0; i < arraysize(number); ++i) {
    VersionInfo info("=", std::string(), number[i], std::string());
    EXPECT_TRUE(info.IsValid());
  }
}

TEST_F(VersionInfoTest, InvalidVersionInfo) {
  const std::string op[] = {
    "=",
    "<",
    "<=",
    ">",
    ">=",
    "any",
    "between"
  };
  for (size_t i = 0; i < arraysize(op); ++i) {
    {
      VersionInfo info(op[i], std::string(), "8.9", std::string());
      if (op[i] == "between")
        EXPECT_FALSE(info.IsValid());
      else
        EXPECT_TRUE(info.IsValid());
    }
    {
      VersionInfo info(op[i], std::string(), std::string(), std::string());
      if (op[i] == "any")
        EXPECT_TRUE(info.IsValid());
      else
        EXPECT_FALSE(info.IsValid());
    }
    {
      VersionInfo info(op[i], std::string(), "8.9", "9.0");
      EXPECT_TRUE(info.IsValid());
    }
  }

  const std::string number[] = {
    "8.E",
    "8-9",
  };
  for (size_t i = 0; i < arraysize(number); ++i) {
    VersionInfo info("=", std::string(), number[i], std::string());
    EXPECT_FALSE(info.IsValid());
  }
}

TEST_F(VersionInfoTest, VersionComparison) {
  {
    VersionInfo info("any", std::string(), std::string(), std::string());
    EXPECT_TRUE(info.Contains("0"));
    EXPECT_TRUE(info.Contains("8.9"));
    EXPECT_TRUE(info.Contains("100"));
  }
  {
    VersionInfo info(">", std::string(), "8.9", std::string());
    EXPECT_FALSE(info.Contains("7"));
    EXPECT_FALSE(info.Contains("8.9"));
    EXPECT_FALSE(info.Contains("8.9.1"));
    EXPECT_TRUE(info.Contains("9"));
  }
  {
    VersionInfo info(">=", std::string(), "8.9", std::string());
    EXPECT_FALSE(info.Contains("7"));
    EXPECT_TRUE(info.Contains("8.9"));
    EXPECT_TRUE(info.Contains("8.9.1"));
    EXPECT_TRUE(info.Contains("9"));
  }
  {
    VersionInfo info("=", std::string(), "8.9", std::string());
    EXPECT_FALSE(info.Contains("7"));
    EXPECT_TRUE(info.Contains("8"));
    EXPECT_TRUE(info.Contains("8.9"));
    EXPECT_TRUE(info.Contains("8.9.1"));
    EXPECT_FALSE(info.Contains("9"));
  }
  {
    VersionInfo info("<", std::string(), "8.9", std::string());
    EXPECT_TRUE(info.Contains("7"));
    EXPECT_TRUE(info.Contains("8.8"));
    EXPECT_FALSE(info.Contains("8"));
    EXPECT_FALSE(info.Contains("8.9"));
    EXPECT_FALSE(info.Contains("8.9.1"));
    EXPECT_FALSE(info.Contains("9"));
  }
  {
    VersionInfo info("<=", std::string(), "8.9", std::string());
    EXPECT_TRUE(info.Contains("7"));
    EXPECT_TRUE(info.Contains("8.8"));
    EXPECT_TRUE(info.Contains("8"));
    EXPECT_TRUE(info.Contains("8.9"));
    EXPECT_TRUE(info.Contains("8.9.1"));
    EXPECT_FALSE(info.Contains("9"));
  }
  {
    VersionInfo info("between", std::string(), "8.9", "9.1");
    EXPECT_FALSE(info.Contains("7"));
    EXPECT_FALSE(info.Contains("8.8"));
    EXPECT_TRUE(info.Contains("8"));
    EXPECT_TRUE(info.Contains("8.9"));
    EXPECT_TRUE(info.Contains("8.9.1"));
    EXPECT_TRUE(info.Contains("9"));
    EXPECT_TRUE(info.Contains("9.1"));
    EXPECT_TRUE(info.Contains("9.1.9"));
    EXPECT_FALSE(info.Contains("9.2"));
    EXPECT_FALSE(info.Contains("10"));
  }
}

TEST_F(VersionInfoTest, DateComparison) {
  // When we use '-' as splitter, we assume a format of mm-dd-yyyy
  // or mm-yyyy, i.e., a date.
  {
    VersionInfo info("=", std::string(), "1976.3.21", std::string());
    EXPECT_TRUE(info.Contains("3-21-1976", '-'));
    EXPECT_TRUE(info.Contains("3-1976", '-'));
    EXPECT_TRUE(info.Contains("03-1976", '-'));
    EXPECT_FALSE(info.Contains("21-3-1976", '-'));
  }
  {
    VersionInfo info(">", std::string(), "1976.3.21", std::string());
    EXPECT_TRUE(info.Contains("3-22-1976", '-'));
    EXPECT_TRUE(info.Contains("4-1976", '-'));
    EXPECT_TRUE(info.Contains("04-1976", '-'));
    EXPECT_FALSE(info.Contains("3-1976", '-'));
    EXPECT_FALSE(info.Contains("2-1976", '-'));
  }
  {
    VersionInfo info("between", std::string(), "1976.3.21", "2012.12.25");
    EXPECT_FALSE(info.Contains("3-20-1976", '-'));
    EXPECT_TRUE(info.Contains("3-21-1976", '-'));
    EXPECT_TRUE(info.Contains("3-22-1976", '-'));
    EXPECT_TRUE(info.Contains("3-1976", '-'));
    EXPECT_TRUE(info.Contains("4-1976", '-'));
    EXPECT_TRUE(info.Contains("1-1-2000", '-'));
    EXPECT_TRUE(info.Contains("1-2000", '-'));
    EXPECT_TRUE(info.Contains("2000", '-'));
    EXPECT_TRUE(info.Contains("11-2012", '-'));
    EXPECT_TRUE(info.Contains("12-2012", '-'));
    EXPECT_TRUE(info.Contains("12-24-2012", '-'));
    EXPECT_TRUE(info.Contains("12-25-2012", '-'));
    EXPECT_FALSE(info.Contains("12-26-2012", '-'));
    EXPECT_FALSE(info.Contains("1-2013", '-'));
    EXPECT_FALSE(info.Contains("2013", '-'));
  }
}

TEST_F(VersionInfoTest, LexicalComparison) {
  // When we use lexical style, we assume a format major.minor.*.
  // We apply numerical comparison to major, lexical comparison to others.
  {
    VersionInfo info("<", "lexical", "8.201", std::string());
    EXPECT_TRUE(info.Contains("8.001.100"));
    EXPECT_TRUE(info.Contains("8.109"));
    EXPECT_TRUE(info.Contains("8.10900"));
    EXPECT_TRUE(info.Contains("8.109.100"));
    EXPECT_TRUE(info.Contains("8.2"));
    EXPECT_TRUE(info.Contains("8.20"));
    EXPECT_TRUE(info.Contains("8.200"));
    EXPECT_TRUE(info.Contains("8.20.100"));
    EXPECT_FALSE(info.Contains("8.201"));
    EXPECT_FALSE(info.Contains("8.2010"));
    EXPECT_FALSE(info.Contains("8.21"));
    EXPECT_FALSE(info.Contains("8.21.100"));
    EXPECT_FALSE(info.Contains("9.002"));
    EXPECT_FALSE(info.Contains("9.201"));
    EXPECT_FALSE(info.Contains("12"));
    EXPECT_FALSE(info.Contains("12.201"));
  }
  {
    VersionInfo info("<", "lexical", "9.002", std::string());
    EXPECT_TRUE(info.Contains("8.001.100"));
    EXPECT_TRUE(info.Contains("8.109"));
    EXPECT_TRUE(info.Contains("8.10900"));
    EXPECT_TRUE(info.Contains("8.109.100"));
    EXPECT_TRUE(info.Contains("8.2"));
    EXPECT_TRUE(info.Contains("8.20"));
    EXPECT_TRUE(info.Contains("8.200"));
    EXPECT_TRUE(info.Contains("8.20.100"));
    EXPECT_TRUE(info.Contains("8.201"));
    EXPECT_TRUE(info.Contains("8.2010"));
    EXPECT_TRUE(info.Contains("8.21"));
    EXPECT_TRUE(info.Contains("8.21.100"));
    EXPECT_FALSE(info.Contains("9.002"));
    EXPECT_FALSE(info.Contains("9.201"));
    EXPECT_FALSE(info.Contains("12"));
    EXPECT_FALSE(info.Contains("12.201"));
  }
}

}  // namespace gpu

