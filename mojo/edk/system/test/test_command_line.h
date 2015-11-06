// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Provides a command line singleton for tests. (This is mainly useful for
// multiprocess tests which start their own binary as a child process. Having
// the singleton makes the command line accessible without lots of plumbing.)

#ifndef MOJO_EDK_SYSTEM_TEST_TEST_COMMAND_LINE_H_
#define MOJO_EDK_SYSTEM_TEST_TEST_COMMAND_LINE_H_

namespace mojo {

namespace util {
class CommandLine;
}  // namespace util

namespace system {
namespace test {

// Initializes the command line singleton (made accessible via
// |GetTestCommandLine()| below. This should be called at most once (typically
// in |main()|).
void InitializeTestCommandLine(int argc, const char* const* argv);

// Gets the "command line" that the test binary was run with.
const util::CommandLine* GetTestCommandLine();

}  // namespace test
}  // namespace system

}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_TEST_COMMAND_LINE_H_
