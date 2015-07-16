// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "debug.h"

#include <sstream>
#include "testing/gtest/include/gtest/gtest.h"

namespace relocation_packer {

TEST(Debug, Log) {
  Logger::Reset();
  std::ostringstream info;
  std::ostringstream error;
  Logger::SetStreams(&info, &error);

  LOG(INFO) << "INFO log message";
  LOG(WARNING) << "WARNING log message";
  LOG(ERROR) << "ERROR log message";

  EXPECT_EQ("INFO: INFO log message\n", info.str());
  EXPECT_EQ("WARNING: WARNING log message\n"
            "ERROR: ERROR log message\n", error.str());
  Logger::Reset();
}

TEST(Debug, LogIf) {
  Logger::Reset();
  std::ostringstream info;
  std::ostringstream error;
  Logger::SetStreams(&info, &error);

  LOG_IF(INFO, true) << "INFO log message";
  LOG_IF(INFO, false) << "INFO log message, SHOULD NOT PRINT";
  LOG_IF(WARNING, true) << "WARNING log message";
  LOG_IF(WARNING, false) << "WARNING log message, SHOULD NOT PRINT";
  LOG_IF(ERROR, true) << "ERROR log message";
  LOG_IF(ERROR, false) << "ERROR log message, SHOULD NOT PRINT";
  LOG_IF(FATAL, false) << "FATAL log message, SHOULD NOT PRINT";

  EXPECT_EQ("INFO: INFO log message\n", info.str());
  EXPECT_EQ("WARNING: WARNING log message\n"
            "ERROR: ERROR log message\n", error.str());
  Logger::Reset();
}

TEST(Debug, Vlog) {
  Logger::Reset();
  std::ostringstream info;
  std::ostringstream error;
  Logger::SetStreams(&info, &error);

  VLOG(0) << "VLOG 0 INFO log message, SHOULD NOT PRINT";
  VLOG(1) << "VLOG 1 INFO log message, SHOULD NOT PRINT";
  VLOG(2) << "VLOG 2 INFO log message, SHOULD NOT PRINT";

  EXPECT_EQ("", info.str());
  EXPECT_EQ("", error.str());

  Logger::SetVerbose(1);

  VLOG(0) << "VLOG 0 INFO log message";
  VLOG(1) << "VLOG 1 INFO log message";
  VLOG(2) << "VLOG 2 INFO log message, SHOULD NOT PRINT";

  EXPECT_EQ("INFO: VLOG 0 INFO log message\n"
            "INFO: VLOG 1 INFO log message\n", info.str());
  EXPECT_EQ("", error.str());
  Logger::Reset();
}

TEST(Debug, VlogIf) {
  Logger::Reset();
  std::ostringstream info;
  std::ostringstream error;
  Logger::SetStreams(&info, &error);

  VLOG_IF(0, true) << "VLOG 0 INFO log message, SHOULD NOT PRINT";
  VLOG_IF(1, true) << "VLOG 1 INFO log message, SHOULD NOT PRINT";
  VLOG_IF(2, true) << "VLOG 2 INFO log message, SHOULD NOT PRINT";

  EXPECT_EQ("", info.str());
  EXPECT_EQ("", error.str());

  Logger::SetVerbose(1);

  VLOG_IF(0, true) << "VLOG 0 INFO log message";
  VLOG_IF(0, false) << "VLOG 0 INFO log message, SHOULD NOT PRINT";
  VLOG_IF(1, true) << "VLOG 1 INFO log message";
  VLOG_IF(1, false) << "VLOG 1 INFO log message, SHOULD NOT PRINT";
  VLOG_IF(2, true) << "VLOG 2 INFO log message, SHOULD NOT PRINT";
  VLOG_IF(2, false) << "VLOG 2 INFO log message, SHOULD NOT PRINT";

  EXPECT_EQ("INFO: VLOG 0 INFO log message\n"
            "INFO: VLOG 1 INFO log message\n", info.str());
  EXPECT_EQ("", error.str());
  Logger::Reset();
}

TEST(DebugDeathTest, Fatal) {
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  Logger::Reset();
  EXPECT_DEATH(LOG(FATAL) << "FATAL log message", "FATAL: FATAL log message");
  EXPECT_DEATH(
      LOG_IF(FATAL, true) << "FATAL log message", "FATAL: FATAL log message");
}

TEST(DebugDeathTest, Check) {
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  Logger::Reset();
  CHECK(0 == 0);
  EXPECT_DEATH(CHECK(0 == 1), "FATAL: .*:.*: .*: CHECK '0 == 1' failed");
}

TEST(DebugDeathTest, NotReached) {
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  Logger::Reset();
  EXPECT_DEATH(NOTREACHED(), "FATAL: .*:.*: .*: NOTREACHED\\(\\) hit");
}

}  // namespace relocation_packer
