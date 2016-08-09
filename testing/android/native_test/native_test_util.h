// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TESTING_ANDROID_NATIVE_TEST_UTIL_
#define TESTING_ANDROID_NATIVE_TEST_UTIL_

#include <stdio.h>
#include <string>
#include <vector>

// Helper methods for setting up environment for running gtest tests
// inside an APK.
namespace testing {
namespace android {

class ScopedMainEntryLogger {
 public:
  ScopedMainEntryLogger() {
    printf(">>ScopedMainEntryLogger\n");
  }

  ~ScopedMainEntryLogger() {
    printf("<<ScopedMainEntryLogger\n");
    fflush(stdout);
    fflush(stderr);
  }
};

void ParseArgsFromString(
    const std::string& command_line, std::vector<std::string>* args);
void ParseArgsFromCommandLineFile(
    const char* path, std::vector<std::string>* args);
int ArgsToArgv(const std::vector<std::string>& args, std::vector<char*>* argv);

}  // namespace android
}  // namespace testing

#endif  // TESTING_ANDROID_NATIVE_TEST_UTIL_
