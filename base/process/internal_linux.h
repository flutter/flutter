// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains internal routines that are called by other files in
// base/process/.

#ifndef BASE_PROCESS_INTERNAL_LINUX_H_
#define BASE_PROCESS_INTERNAL_LINUX_H_

#include <unistd.h>

#include "base/files/file_path.h"

namespace base {

class Time;
class TimeDelta;

namespace internal {

// "/proc"
extern const char kProcDir[];

// "stat"
extern const char kStatFile[];

// Returns a FilePath to "/proc/pid".
base::FilePath GetProcPidDir(pid_t pid);

// Take a /proc directory entry named |d_name|, and if it is the directory for
// a process, convert it to a pid_t.
// Returns 0 on failure.
// e.g. /proc/self/ will return 0, whereas /proc/1234 will return 1234.
pid_t ProcDirSlotToPid(const char* d_name);

// Reads /proc/<pid>/stat into |buffer|. Returns true if the file can be read
// and is non-empty.
bool ReadProcStats(pid_t pid, std::string* buffer);

// Takes |stats_data| and populates |proc_stats| with the values split by
// spaces. Taking into account the 2nd field may, in itself, contain spaces.
// Returns true if successful.
bool ParseProcStats(const std::string& stats_data,
                    std::vector<std::string>* proc_stats);

// Fields from /proc/<pid>/stat, 0-based. See man 5 proc.
// If the ordering ever changes, carefully review functions that use these
// values.
enum ProcStatsFields {
  VM_COMM           = 1,   // Filename of executable, without parentheses.
  VM_STATE          = 2,   // Letter indicating the state of the process.
  VM_PPID           = 3,   // PID of the parent.
  VM_PGRP           = 4,   // Process group id.
  VM_UTIME          = 13,  // Time scheduled in user mode in clock ticks.
  VM_STIME          = 14,  // Time scheduled in kernel mode in clock ticks.
  VM_NUMTHREADS     = 19,  // Number of threads.
  VM_STARTTIME      = 21,  // The time the process started in clock ticks.
  VM_VSIZE          = 22,  // Virtual memory size in bytes.
  VM_RSS            = 23,  // Resident Set Size in pages.
};

// Reads the |field_num|th field from |proc_stats|. Returns 0 on failure.
// This version does not handle the first 3 values, since the first value is
// simply |pid|, and the next two values are strings.
int64 GetProcStatsFieldAsInt64(const std::vector<std::string>& proc_stats,
                               ProcStatsFields field_num);

// Same as GetProcStatsFieldAsInt64(), but for size_t values.
size_t GetProcStatsFieldAsSizeT(const std::vector<std::string>& proc_stats,
                                ProcStatsFields field_num);

// Convenience wrapper around GetProcStatsFieldAsInt64(), ParseProcStats() and
// ReadProcStats(). See GetProcStatsFieldAsInt64() for details.
int64 ReadProcStatsAndGetFieldAsInt64(pid_t pid, ProcStatsFields field_num);

// Same as ReadProcStatsAndGetFieldAsInt64() but for size_t values.
size_t ReadProcStatsAndGetFieldAsSizeT(pid_t pid,
                                       ProcStatsFields field_num);

// Returns the time that the OS started. Clock ticks are relative to this.
Time GetBootTime();

// Converts Linux clock ticks to a wall time delta.
TimeDelta ClockTicksToTimeDelta(int clock_ticks);

}  // namespace internal
}  // namespace base

#endif  // BASE_PROCESS_INTERNAL_LINUX_H_
