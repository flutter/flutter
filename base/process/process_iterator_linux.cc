// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_iterator.h"

#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/process/internal_linux.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "base/threading/thread_restrictions.h"

namespace base {

namespace {

// Reads the |field_num|th field from |proc_stats|.
// Returns an empty string on failure.
// This version only handles VM_COMM and VM_STATE, which are the only fields
// that are strings.
std::string GetProcStatsFieldAsString(
    const std::vector<std::string>& proc_stats,
    internal::ProcStatsFields field_num) {
  if (field_num < internal::VM_COMM || field_num > internal::VM_STATE) {
    NOTREACHED();
    return std::string();
  }

  if (proc_stats.size() > static_cast<size_t>(field_num))
    return proc_stats[field_num];

  NOTREACHED();
  return 0;
}

// Reads /proc/<pid>/cmdline and populates |proc_cmd_line_args| with the command
// line arguments. Returns true if successful.
// Note: /proc/<pid>/cmdline contains command line arguments separated by single
// null characters. We tokenize it into a vector of strings using '\0' as a
// delimiter.
bool GetProcCmdline(pid_t pid, std::vector<std::string>* proc_cmd_line_args) {
  // Synchronously reading files in /proc is safe.
  ThreadRestrictions::ScopedAllowIO allow_io;

  FilePath cmd_line_file = internal::GetProcPidDir(pid).Append("cmdline");
  std::string cmd_line;
  if (!ReadFileToString(cmd_line_file, &cmd_line))
    return false;
  std::string delimiters;
  delimiters.push_back('\0');
  *proc_cmd_line_args = SplitString(cmd_line, delimiters, KEEP_WHITESPACE,
                                    SPLIT_WANT_NONEMPTY);
  return true;
}

}  // namespace

ProcessIterator::ProcessIterator(const ProcessFilter* filter)
    : filter_(filter) {
  procfs_dir_ = opendir(internal::kProcDir);
}

ProcessIterator::~ProcessIterator() {
  if (procfs_dir_) {
    closedir(procfs_dir_);
    procfs_dir_ = NULL;
  }
}

bool ProcessIterator::CheckForNextProcess() {
  // TODO(port): skip processes owned by different UID

  pid_t pid = kNullProcessId;
  std::vector<std::string> cmd_line_args;
  std::string stats_data;
  std::vector<std::string> proc_stats;

  // Arbitrarily guess that there will never be more than 200 non-process
  // files in /proc.  Hardy has 53 and Lucid has 61.
  int skipped = 0;
  const int kSkipLimit = 200;
  while (skipped < kSkipLimit) {
    dirent* slot = readdir(procfs_dir_);
    // all done looking through /proc?
    if (!slot)
      return false;

    // If not a process, keep looking for one.
    pid = internal::ProcDirSlotToPid(slot->d_name);
    if (!pid) {
      skipped++;
      continue;
    }

    if (!GetProcCmdline(pid, &cmd_line_args))
      continue;

    if (!internal::ReadProcStats(pid, &stats_data))
      continue;
    if (!internal::ParseProcStats(stats_data, &proc_stats))
      continue;

    std::string runstate =
        GetProcStatsFieldAsString(proc_stats, internal::VM_STATE);
    if (runstate.size() != 1) {
      NOTREACHED();
      continue;
    }

    // Is the process in 'Zombie' state, i.e. dead but waiting to be reaped?
    // Allowed values: D R S T Z
    if (runstate[0] != 'Z')
      break;

    // Nope, it's a zombie; somebody isn't cleaning up after their children.
    // (e.g. WaitForProcessesToExit doesn't clean up after dead children yet.)
    // There could be a lot of zombies, can't really decrement i here.
  }
  if (skipped >= kSkipLimit) {
    NOTREACHED();
    return false;
  }

  entry_.pid_ = pid;
  entry_.ppid_ = GetProcStatsFieldAsInt64(proc_stats, internal::VM_PPID);
  entry_.gid_ = GetProcStatsFieldAsInt64(proc_stats, internal::VM_PGRP);
  entry_.cmd_line_args_.assign(cmd_line_args.begin(), cmd_line_args.end());
  entry_.exe_file_ = GetProcessExecutablePath(pid).BaseName().value();
  return true;
}

bool NamedProcessIterator::IncludeEntry() {
  if (executable_name_ != entry().exe_file())
    return false;
  return ProcessIterator::IncludeEntry();
}

}  // namespace base
