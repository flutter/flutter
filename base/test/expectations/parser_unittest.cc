// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/expectations/parser.h"

#include <string>
#include <vector>

#include "base/compiler_specific.h"
#include "testing/gtest/include/gtest/gtest.h"

using test_expectations::Parser;

class TestExpectationParserTest : public testing::Test,
                                  public Parser::Delegate {
 public:
  void EmitExpectation(
      const test_expectations::Expectation& expectation) override {
    expectations_.push_back(expectation);
  }

  void OnSyntaxError(const std::string& message) override {
    syntax_error_ = message;
  }

  void OnDataError(const std::string& error) override {
    data_errors_.push_back(error);
  }

 protected:
  std::vector<test_expectations::Expectation> expectations_;
  std::string syntax_error_;
  std::vector<std::string> data_errors_;
};

TEST_F(TestExpectationParserTest, Basic) {
  Parser(this,
      "http://crbug.com/1234 [ Win-8 ] DouglasTest.PoopsOk = Timeout").
          Parse();
  EXPECT_TRUE(syntax_error_.empty());
  EXPECT_EQ(0u, data_errors_.size());

  ASSERT_EQ(1u, expectations_.size());
  EXPECT_EQ("DouglasTest.PoopsOk", expectations_[0].test_name);
  EXPECT_EQ(test_expectations::RESULT_TIMEOUT, expectations_[0].result);
  EXPECT_EQ(test_expectations::CONFIGURATION_UNSPECIFIED,
            expectations_[0].configuration);

  ASSERT_EQ(1u, expectations_[0].platforms.size());
  EXPECT_EQ("Win", expectations_[0].platforms[0].name);
  EXPECT_EQ("8", expectations_[0].platforms[0].variant);
}

TEST_F(TestExpectationParserTest, MultiModifier) {
  Parser(this, "BUG [ Win-XP Mac ] OhMy.MeOhMy = Failure").Parse();
  EXPECT_TRUE(syntax_error_.empty());
  EXPECT_EQ(0u, data_errors_.size());

  ASSERT_EQ(1u, expectations_.size());
  EXPECT_EQ("OhMy.MeOhMy", expectations_[0].test_name);
  EXPECT_EQ(test_expectations::RESULT_FAILURE,
            expectations_[0].result);
  EXPECT_EQ(test_expectations::CONFIGURATION_UNSPECIFIED,
            expectations_[0].configuration);

  ASSERT_EQ(2u, expectations_[0].platforms.size());

  EXPECT_EQ("Win", expectations_[0].platforms[0].name);
  EXPECT_EQ("XP", expectations_[0].platforms[0].variant);

  EXPECT_EQ("Mac", expectations_[0].platforms[1].name);
  EXPECT_EQ("", expectations_[0].platforms[1].variant);
}

TEST_F(TestExpectationParserTest, EmptyModifier) {
  Parser(this,
      "BUG [] First.Test = Failure\n"
      "BUG2 [   ] Second.Test = Crash").Parse();
  EXPECT_EQ(0u, data_errors_.size());

  ASSERT_EQ(2u, expectations_.size());

  EXPECT_EQ("First.Test", expectations_[0].test_name);
  EXPECT_EQ(test_expectations::RESULT_FAILURE,
            expectations_[0].result);
  EXPECT_EQ(test_expectations::CONFIGURATION_UNSPECIFIED,
            expectations_[0].configuration);
  EXPECT_EQ(0u, expectations_[0].platforms.size());

  EXPECT_EQ("Second.Test", expectations_[1].test_name);
  EXPECT_EQ(test_expectations::RESULT_CRASH,
            expectations_[1].result);
  EXPECT_EQ(test_expectations::CONFIGURATION_UNSPECIFIED,
            expectations_[1].configuration);
  EXPECT_EQ(0u, expectations_[1].platforms.size());
}

TEST_F(TestExpectationParserTest, MultiLine) {
  Parser(this,
      "BUG [ Linux ] Line.First = Failure\n"
      "\n"
      "# A test comment.\n"
      "BUG2 [ Release ] Line.Second = Skip").Parse();
  EXPECT_TRUE(syntax_error_.empty());
  EXPECT_EQ(0u, data_errors_.size());

  ASSERT_EQ(2u, expectations_.size());
  EXPECT_EQ("Line.First", expectations_[0].test_name);
  EXPECT_EQ(test_expectations::RESULT_FAILURE, expectations_[0].result);
  EXPECT_EQ(test_expectations::CONFIGURATION_UNSPECIFIED,
            expectations_[0].configuration);

  ASSERT_EQ(1u, expectations_[0].platforms.size());
  EXPECT_EQ("Linux", expectations_[0].platforms[0].name);
  EXPECT_EQ("", expectations_[0].platforms[0].variant);

  EXPECT_EQ("Line.Second", expectations_[1].test_name);
  EXPECT_EQ(test_expectations::RESULT_SKIP, expectations_[1].result);
  EXPECT_EQ(test_expectations::CONFIGURATION_RELEASE,
            expectations_[1].configuration);
  EXPECT_EQ(0u, expectations_[1].platforms.size());
}

TEST_F(TestExpectationParserTest, MultiLineWithComments) {
  Parser(this,
      "  # Comment for your thoughts\n"
      "  \t \n"
      "BUG [ Mac-10.8 Debug] Foo=Bar =Skip   # Why not another comment?\n"
      "BUG2 [Win-XP\tWin-Vista ] Cow.GoesMoo   =\tTimeout\n\n").Parse();
  EXPECT_TRUE(syntax_error_.empty()) << syntax_error_;
  EXPECT_EQ(0u, data_errors_.size());

  ASSERT_EQ(2u, expectations_.size());
  EXPECT_EQ("Foo=Bar", expectations_[0].test_name);
  EXPECT_EQ(test_expectations::RESULT_SKIP, expectations_[0].result);
  EXPECT_EQ(test_expectations::CONFIGURATION_DEBUG,
            expectations_[0].configuration);

  ASSERT_EQ(1u, expectations_[0].platforms.size());
  EXPECT_EQ("Mac", expectations_[0].platforms[0].name);
  EXPECT_EQ("10.8", expectations_[0].platforms[0].variant);

  EXPECT_EQ("Cow.GoesMoo", expectations_[1].test_name);
  EXPECT_EQ(test_expectations::RESULT_TIMEOUT, expectations_[1].result);
  EXPECT_EQ(test_expectations::CONFIGURATION_UNSPECIFIED,
            expectations_[1].configuration);

  ASSERT_EQ(2u, expectations_[1].platforms.size());
  EXPECT_EQ("Win", expectations_[1].platforms[0].name);
  EXPECT_EQ("XP", expectations_[1].platforms[0].variant);
  EXPECT_EQ("Win", expectations_[1].platforms[0].name);
  EXPECT_EQ("Vista", expectations_[1].platforms[1].variant);
}

TEST_F(TestExpectationParserTest, WeirdSpaces) {
  Parser(this, "   BUG       [Linux]        Weird  = Skip    ").Parse();
  EXPECT_EQ(1u, expectations_.size());
  EXPECT_TRUE(syntax_error_.empty());
  EXPECT_EQ(0u, data_errors_.size());
}

TEST_F(TestExpectationParserTest, SyntaxErrors) {
  const char* const kErrors[] = {
    "Foo [ dfasd",
    "Foo [Linux] # This is an illegal comment",
    "Foo [Linux] Bar # Another illegal comment.",
    "Foo [Linux] Bar = # Another illegal comment.",
    "Foo[Linux]Bar=Failure",
    "Foo\n[Linux] Bar = Failure",
    "Foo [\nLinux] Bar = Failure",
    "Foo [Linux\n] Bar = Failure",
    "Foo [ Linux ] \n Bar = Failure",
    "Foo [ Linux ] Bar =\nFailure",
    "Foo [ Linux \n ] Bar =\nFailure",
  };

  for (size_t i = 0; i < arraysize(kErrors); ++i) {
    Parser(this, kErrors[i]).Parse();
    EXPECT_FALSE(syntax_error_.empty())
        << "Should have error for #" << i << ": " << kErrors[i];
    syntax_error_.clear();
  }
}

TEST_F(TestExpectationParserTest, DataErrors) {
  const char* const kOneError[] = {
    "http://crbug.com/1234 [MagicBrowzR] BadModifier = Timeout",
    "________ [Linux] BadResult = WhatNow",
    "http://wkb.ug/1234 [Debug Release Win-7] MultipleConfigs = Skip",
  };

  for (size_t i = 0; i < arraysize(kOneError); ++i) {
    Parser(this, kOneError[i]).Parse();
    EXPECT_EQ(1u, data_errors_.size()) << kOneError[i];
    data_errors_.clear();
  }

  const char* const kTwoErrors[] = {
    ". [Mac-TurningIntoiOS] BadModifierVariant.BadResult = Foobar",
    "1234 [ Debug Release OS/2 ] MultipleConfigs.BadModifier = Pass",
  };

  for (size_t i = 0; i < arraysize(kTwoErrors); ++i) {
    Parser(this, kTwoErrors[i]).Parse();
    EXPECT_EQ(2u, data_errors_.size()) << kTwoErrors[i];
    data_errors_.clear();
  }
}
