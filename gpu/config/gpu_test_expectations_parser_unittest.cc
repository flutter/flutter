// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "gpu/config/gpu_test_expectations_parser.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class GPUTestExpectationsParserTest : public testing::Test {
 public:
  GPUTestExpectationsParserTest() { }

  ~GPUTestExpectationsParserTest() override {}

  const GPUTestBotConfig& bot_config() const {
    return bot_config_;
  }

 protected:
  void SetUp() override {
    bot_config_.set_os(GPUTestConfig::kOsWin7);
    bot_config_.set_build_type(GPUTestConfig::kBuildTypeRelease);
    bot_config_.AddGPUVendor(0x10de);
    bot_config_.set_gpu_device_id(0x0640);
    ASSERT_TRUE(bot_config_.IsValid());
  }

  void TearDown() override {}

 private:
  GPUTestBotConfig bot_config_;
};

TEST_F(GPUTestExpectationsParserTest, CommentOnly) {
  const std::string text =
      "  \n"
      "// This is just some comment\n"
      "";
  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestPass,
            parser.GetTestExpectation("some_test", bot_config()));
}

TEST_F(GPUTestExpectationsParserTest, ValidFullEntry) {
  const std::string text =
      "BUG12345 WIN7 RELEASE NVIDIA 0x0640 : MyTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestFail,
            parser.GetTestExpectation("MyTest", bot_config()));
}

TEST_F(GPUTestExpectationsParserTest, ValidPartialEntry) {
  const std::string text =
      "BUG12345 WIN NVIDIA : MyTest = TIMEOUT";

  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestTimeout,
            parser.GetTestExpectation("MyTest", bot_config()));
}

TEST_F(GPUTestExpectationsParserTest, ValidUnrelatedOsEntry) {
  const std::string text =
      "BUG12345 LEOPARD : MyTest = TIMEOUT";

  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestPass,
            parser.GetTestExpectation("MyTest", bot_config()));
}

TEST_F(GPUTestExpectationsParserTest, ValidUnrelatedTestEntry) {
  const std::string text =
      "BUG12345 WIN7 RELEASE NVIDIA 0x0640 : AnotherTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestPass,
            parser.GetTestExpectation("MyTest", bot_config()));
}

TEST_F(GPUTestExpectationsParserTest, AllModifiers) {
  const std::string text =
      "BUG12345 XP VISTA WIN7 WIN8 LEOPARD SNOWLEOPARD LION MOUNTAINLION "
      "MAVERICKS LINUX CHROMEOS ANDROID "
      "NVIDIA INTEL AMD VMWARE RELEASE DEBUG : MyTest = "
      "PASS FAIL FLAKY TIMEOUT SKIP";

  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestPass |
            GPUTestExpectationsParser::kGpuTestFail |
            GPUTestExpectationsParser::kGpuTestFlaky |
            GPUTestExpectationsParser::kGpuTestTimeout |
            GPUTestExpectationsParser::kGpuTestSkip,
            parser.GetTestExpectation("MyTest", bot_config()));
}

TEST_F(GPUTestExpectationsParserTest, DuplicateModifiers) {
  const std::string text =
      "BUG12345 WIN7 WIN7 RELEASE NVIDIA 0x0640 : MyTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_FALSE(parser.LoadTestExpectations(text));
  EXPECT_NE(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, AllModifiersLowerCase) {
  const std::string text =
      "BUG12345 xp vista win7 leopard snowleopard lion linux chromeos android "
      "nvidia intel amd vmware release debug : MyTest = "
      "pass fail flaky timeout skip";

  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestPass |
            GPUTestExpectationsParser::kGpuTestFail |
            GPUTestExpectationsParser::kGpuTestFlaky |
            GPUTestExpectationsParser::kGpuTestTimeout |
            GPUTestExpectationsParser::kGpuTestSkip,
            parser.GetTestExpectation("MyTest", bot_config()));
}

TEST_F(GPUTestExpectationsParserTest, MissingColon) {
  const std::string text =
      "BUG12345 XP MyTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_FALSE(parser.LoadTestExpectations(text));
  EXPECT_NE(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, MissingEqual) {
  const std::string text =
      "BUG12345 XP : MyTest FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_FALSE(parser.LoadTestExpectations(text));
  EXPECT_NE(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, IllegalModifier) {
  const std::string text =
      "BUG12345 XP XXX : MyTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_FALSE(parser.LoadTestExpectations(text));
  EXPECT_NE(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, OsConflicts) {
  const std::string text =
      "BUG12345 XP WIN : MyTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_FALSE(parser.LoadTestExpectations(text));
  EXPECT_NE(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, InvalidModifierCombination) {
  const std::string text =
      "BUG12345 XP NVIDIA INTEL 0x0640 : MyTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_FALSE(parser.LoadTestExpectations(text));
  EXPECT_NE(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, BadGpuDeviceID) {
  const std::string text =
      "BUG12345 XP NVIDIA 0xU07X : MyTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_FALSE(parser.LoadTestExpectations(text));
  EXPECT_NE(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, MoreThanOneGpuDeviceID) {
  const std::string text =
      "BUG12345 XP NVIDIA 0x0640 0x0641 : MyTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_FALSE(parser.LoadTestExpectations(text));
  EXPECT_NE(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, MultipleEntriesConflicts) {
  const std::string text =
      "BUG12345 WIN7 RELEASE NVIDIA 0x0640 : MyTest = FAIL\n"
      "BUG12345 WIN : MyTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_FALSE(parser.LoadTestExpectations(text));
  EXPECT_NE(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, MultipleTests) {
  const std::string text =
      "BUG12345 WIN7 RELEASE NVIDIA 0x0640 : MyTest = FAIL\n"
      "BUG12345 WIN : AnotherTest = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
}

TEST_F(GPUTestExpectationsParserTest, ValidMultipleEntries) {
  const std::string text =
      "BUG12345 WIN7 RELEASE NVIDIA 0x0640 : MyTest = FAIL\n"
      "BUG12345 LINUX : MyTest = TIMEOUT";

  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestFail,
            parser.GetTestExpectation("MyTest", bot_config()));
}

TEST_F(GPUTestExpectationsParserTest, StarMatching) {
  const std::string text =
      "BUG12345 WIN7 RELEASE NVIDIA 0x0640 : MyTest* = FAIL";

  GPUTestExpectationsParser parser;
  EXPECT_TRUE(parser.LoadTestExpectations(text));
  EXPECT_EQ(0u, parser.GetErrorMessages().size());
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestFail,
            parser.GetTestExpectation("MyTest0", bot_config()));
  EXPECT_EQ(GPUTestExpectationsParser::kGpuTestPass,
            parser.GetTestExpectation("OtherTest", bot_config()));
}

}  // namespace gpu

