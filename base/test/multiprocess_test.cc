// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/multiprocess_test.h"

#include "base/base_switches.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"

namespace base {

#if !defined(OS_ANDROID)
Process SpawnMultiProcessTestChild(
    const std::string& procname,
    const CommandLine& base_command_line,
    const LaunchOptions& options) {
  CommandLine command_line(base_command_line);
  // TODO(viettrungluu): See comment above |MakeCmdLine()| in the header file.
  // This is a temporary hack, since |MakeCmdLine()| has to provide a full
  // command line.
  if (!command_line.HasSwitch(switches::kTestChildProcess))
    command_line.AppendSwitchASCII(switches::kTestChildProcess, procname);

  return LaunchProcess(command_line, options);
}
#endif  // !defined(OS_ANDROID)

CommandLine GetMultiProcessTestChildBaseCommandLine() {
  CommandLine cmd_line = *CommandLine::ForCurrentProcess();
  cmd_line.SetProgram(MakeAbsoluteFilePath(cmd_line.GetProgram()));
  return cmd_line;
}

// MultiProcessTest ------------------------------------------------------------

MultiProcessTest::MultiProcessTest() {
}

Process MultiProcessTest::SpawnChild(const std::string& procname) {
  LaunchOptions options;
#if defined(OS_WIN)
  options.start_hidden = true;
#endif
  return SpawnChildWithOptions(procname, options);
}

Process MultiProcessTest::SpawnChildWithOptions(
    const std::string& procname,
    const LaunchOptions& options) {
  return SpawnMultiProcessTestChild(procname, MakeCmdLine(procname), options);
}

CommandLine MultiProcessTest::MakeCmdLine(const std::string& procname) {
  CommandLine command_line = GetMultiProcessTestChildBaseCommandLine();
  command_line.AppendSwitchASCII(switches::kTestChildProcess, procname);
  return command_line;
}

}  // namespace base
