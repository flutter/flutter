// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_iterator.h"

#include <errno.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/logging.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"

namespace base {

ProcessIterator::ProcessIterator(const ProcessFilter* filter)
    : index_of_kinfo_proc_(0),
      filter_(filter) {
  // Get a snapshot of all of my processes (yes, as we loop it can go stale, but
  // but trying to find where we were in a constantly changing list is basically
  // impossible.

  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_UID, geteuid() };

  // Since more processes could start between when we get the size and when
  // we get the list, we do a loop to keep trying until we get it.
  bool done = false;
  int try_num = 1;
  const int max_tries = 10;
  do {
    // Get the size of the buffer
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
      // Load the list of processes
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
    if ((kinfo.kp_proc.p_pid > 0) && (kinfo.kp_proc.p_stat == SZOMB))
      continue;

    int mib[] = { CTL_KERN, KERN_PROCARGS, kinfo.kp_proc.p_pid };

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
    entry_.cmd_line_args_ = SplitString(data, delimiters,
                                        KEEP_WHITESPACE, SPLIT_WANT_NONEMPTY);

    // |data| starts with the full executable path followed by a null character.
    // We search for the first instance of '\0' and extract everything before it
    // to populate |entry_.exe_file_|.
    size_t exec_name_end = data.find('\0');
    if (exec_name_end == std::string::npos) {
      DLOG(ERROR) << "command line data didn't match expected format";
      continue;
    }

    entry_.pid_ = kinfo.kp_proc.p_pid;
    entry_.ppid_ = kinfo.kp_eproc.e_ppid;
    entry_.gid_ = kinfo.kp_eproc.e_pgid;
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
