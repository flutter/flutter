// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_TEST_SUPPORT_TEST_UTILS_H_
#define MOJO_PUBLIC_CPP_TEST_SUPPORT_TEST_UTILS_H_

#include <string>

#include "mojo/public/cpp/system/core.h"

namespace mojo {
namespace test {

// Writes a message to |handle| with message data |text|. Returns true on
// success.
bool WriteTextMessage(const MessagePipeHandle& handle, const std::string& text);

// Reads a message from |handle|, putting its contents into |*text|. Returns
// true on success. (This blocks if necessary and will call |MojoReadMessage()|
// multiple times, e.g., to query the size of the message.)
bool ReadTextMessage(const MessagePipeHandle& handle, std::string* text);

// Discards a message from |handle|. Returns true on success. (This does not
// block. It will fail if no message is available to discard.)
bool DiscardMessage(const MessagePipeHandle& handle);

// Run |single_iteration| an appropriate number of times and report its
// performance appropriately. (This actually runs |single_iteration| for a fixed
// amount of time and reports the number of iterations per unit time.)
typedef void (*PerfTestSingleIteration)(void* closure);
void IterateAndReportPerf(const char* test_name,
                          const char* sub_test_name,
                          PerfTestSingleIteration single_iteration,
                          void* closure);

}  // namespace test
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_TEST_SUPPORT_TEST_UTILS_H_
