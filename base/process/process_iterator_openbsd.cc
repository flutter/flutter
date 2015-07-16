// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_iterator.h"

#include <errno.h>
#include <sys/sysctl.h>

#include "base/logging.h"
#include "base/strings/string_util.h"

namespace base {

ProcessIterator::ProcessIterator(const ProcessFilter* filter)
    : index_of_kinfo_proc_(),
      filter_(filter) {

  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_UID, getuid(),
                sizeof(struct kinfo_proc), 0 };

  bool done = false;
  int try_num = 1;
  const int max_tries = 10;

  do {
    size_t len = 0;
    if (sysctl(mib, arraysize(mib), NULL, &len, NULL, 0) < 0) {
      DLOG(ERROR) << "failed to get the size needed for the process list";
      kinfo_procs_.resize(0);
      done = true;
    } else {
      size_t num_of_kinfo_proc = len / sizeof(struct kinfo_proc);
      // Leave some spare room for process table growth (more could show up
      // between when we check and now)
      num_of_kinfo_proc += 16;
      kinfo_procs_.resize(num_of_kinfo_proc);
      len = num_of_kinfo_proc * sizeof(struct kinfo_proc);
      if (sysctl(mib, arraysize(mib), &kinfo_procs_[0], &len, NULL, 0) < 0) {
        // If we get a mem error, it just means we need a bigger buffer, so
        // loop around again.  Anything else is a real error and give up.
        if (errno != ENOMEM) {
          DLOG(ERROR) << "failed to get the process list";
          kinfo_procs_.resize(0);
          done = true;
        }
      } else {
        // Got the list, just make sure we're sized exactly right
        size_t num_of_kinfo_proc = len / sizeof(struct kinfo_proc);
        kinfo_procs_.resize(num_of_kinfo_proc);
        done = true;
      }
    }
  } while (!done && (try_num++ < max_tries));

  if (!done) {
    DLOG(ERROR) << "failed to collect the process list in a few tries";
    kinfo_procs_.resize(0);
  }
}

ProcessIterator::~ProcessIterator() {
}

bool ProcessIterator::CheckForNextProcess() {
  std::string data;
  for (; index_of_kinfo_proc_ < kinfo_procs_.size(); ++index_of_kinfo_proc_) {
    kinfo_proc& kinfo = kinfo_procs_[index_of_kinfo_proc_];

    // Skip processes just awaiting collection
    if ((kinfo.p_pid > 0) && (kinfo.p_stat == SZOMB))
      continue;

    int mib[] = { CTL_KERN, KERN_PROC_ARGS, kinfo.p_pid };

    // Find out what size buffer we need.
    size_t data_len = 0;
    if (sysctl(mib, arraysize(mib), NULL, &data_len, NULL, 0) < 0) {
      DVPLOG(1) << "failed to figure out the buffer size for a commandline";
      continue;
    }

    data.resize(data_len);
    if (sysctl(mib, arraysize(mib), &data[0], &data_len, NULL, 0) < 0) {
      DVPLOG(1) << "failed to fetch a commandline";
      continue;
    }

    // |data| contains all the command line parameters of the process, separated
    // by blocks of one or more null characters. We tokenize |data| into a
    // vector of strings using '\0' as a delimiter and populate
    // |entry_.cmd_line_args_|.
    std::string delimiters;
    delimiters.push_back('\0');
    Tokenize(data, delimiters, &entry_.cmd_line_args_);

    // |data| starts with the full executable path followed by a null character.
    // We search for the first instance of '\0' and extract everything before it
    // to populate |entry_.exe_file_|.
    size_t exec_name_end = data.find('\0');
    if (exec_name_end == std::string::npos) {
      DLOG(ERROR) << "command line data didn't match expected format";
      continue;
    }

    entry_.pid_ = kinfo.p_pid;
    entry_.ppid_ = kinfo.p_ppid;
    entry_.gid_ = kinfo.p__pgid;
    size_t last_slash = data.rfind('/', exec_name_end);
    if (last_slash == std::string::npos)
      entry_.exe_file_.assign(data, 0, exec_name_end);
    else
      entry_.exe_file_.assign(data, last_slash + 1,
                              exec_name_end - last_slash - 1);
    // Start w/ the next entry next time through
    ++index_of_kinfo_proc_;
    // Done
    return true;
  }
  return false;
}

bool NamedProcessIterator::IncludeEntry() {
  return (executable_name_ == entry().exe_file() &&
          ProcessIterator::IncludeEntry());
}

}  // namespace base
