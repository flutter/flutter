// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/multiprocess_test.h"

#include <unistd.h>

#include "base/base_switches.h"
#include "base/command_line.h"
#include "base/containers/hash_tables.h"
#include "base/logging.h"
#include "base/posix/global_descriptors.h"
#include "testing/multiprocess_func_list.h"

namespace base {

// A very basic implementation for Android. On Android tests can run in an APK
// and we don't have an executable to exec*. This implementation does the bare
// minimum to execute the method specified by procname (in the child process).
//  - All options except |fds_to_remap| are ignored.
Process SpawnMultiProcessTestChild(const std::string& procname,
                                   const CommandLine& base_command_line,
                                   const LaunchOptions& options) {
  // TODO(viettrungluu): The FD-remapping done below is wrong in the presence of
  // cycles (e.g., fd1 -> fd2, fd2 -> fd1). crbug.com/326576
  FileHandleMappingVector empty;
  const FileHandleMappingVector* fds_to_remap =
      options.fds_to_remap ? options.fds_to_remap : &empty;

  pid_t pid = fork();

  if (pid < 0) {
    PLOG(ERROR) << "fork";
    return Process();
  }
  if (pid > 0) {
    // Parent process.
    return Process(pid);
  }
  // Child process.
  base::hash_set<int> fds_to_keep_open;
  for (FileHandleMappingVector::const_iterator it = fds_to_remap->begin();
       it != fds_to_remap->end(); ++it) {
    fds_to_keep_open.insert(it->first);
  }
  // Keep standard FDs (stdin, stdout, stderr, etc.) open since this
  // is not meant to spawn a daemon.
  int base = GlobalDescriptors::kBaseDescriptor;
  for (int fd = base; fd < sysconf(_SC_OPEN_MAX); ++fd) {
    if (fds_to_keep_open.find(fd) == fds_to_keep_open.end()) {
      close(fd);
    }
  }
  for (FileHandleMappingVector::const_iterator it = fds_to_remap->begin();
       it != fds_to_remap->end(); ++it) {
    int old_fd = it->first;
    int new_fd = it->second;
    if (dup2(old_fd, new_fd) < 0) {
      PLOG(FATAL) << "dup2";
    }
    close(old_fd);
  }
  CommandLine::Reset();
  CommandLine::Init(0, nullptr);
  CommandLine* command_line = CommandLine::ForCurrentProcess();
  command_line->InitFromArgv(base_command_line.argv());
  if (!command_line->HasSwitch(switches::kTestChildProcess))
    command_line->AppendSwitchASCII(switches::kTestChildProcess, procname);

  _exit(multi_process_function_list::InvokeChildProcessTest(procname));
  return Process();
}

}  // namespace base
