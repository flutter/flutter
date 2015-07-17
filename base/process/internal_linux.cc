// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/internal_linux.h"

#include <unistd.h>

#include <map>
#include <string>
#include <vector>

#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "base/threading/thread_restrictions.h"
#include "base/time/time.h"

namespace base {
namespace internal {

const char kProcDir[] = "/proc";

const char kStatFile[] = "stat";

FilePath GetProcPidDir(pid_t pid) {
  return FilePath(kProcDir).Append(IntToString(pid));
}

pid_t ProcDirSlotToPid(const char* d_name) {
  int i;
  for (i = 0; i < NAME_MAX && d_name[i]; ++i) {
    if (!IsAsciiDigit(d_name[i])) {
      return 0;
    }
  }
  if (i == NAME_MAX)
    return 0;

  // Read the process's command line.
  pid_t pid;
  std::string pid_string(d_name);
  if (!StringToInt(pid_string, &pid)) {
    NOTREACHED();
    return 0;
  }
  return pid;
}

bool ReadProcFile(const FilePath& file, std::string* buffer) {
  buffer->clear();
  // Synchronously reading files in /proc is safe.
  ThreadRestrictions::ScopedAllowIO allow_io;

  if (!ReadFileToString(file, buffer)) {
    DLOG(WARNING) << "Failed to read " << file.MaybeAsASCII();
    return false;
  }
  return !buffer->empty();
}

bool ReadProcStats(pid_t pid, std::string* buffer) {
  FilePath stat_file = internal::GetProcPidDir(pid).Append(kStatFile);
  return ReadProcFile(stat_file, buffer);
}

bool ParseProcStats(const std::string& stats_data,
                    std::vector<std::string>* proc_stats) {
  // |stats_data| may be empty if the process disappeared somehow.
  // e.g. http://crbug.com/145811
  if (stats_data.empty())
    return false;

  // The stat file is formatted as:
  // pid (process name) data1 data2 .... dataN
  // Look for the closing paren by scanning backwards, to avoid being fooled by
  // processes with ')' in the name.
  size_t open_parens_idx = stats_data.find(" (");
  size_t close_parens_idx = stats_data.rfind(") ");
  if (open_parens_idx == std::string::npos ||
      close_parens_idx == std::string::npos ||
      open_parens_idx > close_parens_idx) {
    DLOG(WARNING) << "Failed to find matched parens in '" << stats_data << "'";
    NOTREACHED();
    return false;
  }
  open_parens_idx++;

  proc_stats->clear();
  // PID.
  proc_stats->push_back(stats_data.substr(0, open_parens_idx));
  // Process name without parentheses.
  proc_stats->push_back(
      stats_data.substr(open_parens_idx + 1,
                        close_parens_idx - (open_parens_idx + 1)));

  // Split the rest.
  std::vector<std::string> other_stats;
  SplitString(stats_data.substr(close_parens_idx + 2), ' ', &other_stats);
  for (size_t i = 0; i < other_stats.size(); ++i)
    proc_stats->push_back(other_stats[i]);
  return true;
}

typedef std::map<std::string, std::string> ProcStatMap;
void ParseProcStat(const std::string& contents, ProcStatMap* output) {
  StringPairs key_value_pairs;
  SplitStringIntoKeyValuePairs(contents, ' ', '\n', &key_value_pairs);
  for (size_t i = 0; i < key_value_pairs.size(); ++i) {
    output->insert(key_value_pairs[i]);
  }
}

int64 GetProcStatsFieldAsInt64(const std::vector<std::string>& proc_stats,
                               ProcStatsFields field_num) {
  DCHECK_GE(field_num, VM_PPID);
  CHECK_LT(static_cast<size_t>(field_num), proc_stats.size());

  int64 value;
  return StringToInt64(proc_stats[field_num], &value) ? value : 0;
}

size_t GetProcStatsFieldAsSizeT(const std::vector<std::string>& proc_stats,
                                ProcStatsFields field_num) {
  DCHECK_GE(field_num, VM_PPID);
  CHECK_LT(static_cast<size_t>(field_num), proc_stats.size());

  size_t value;
  return StringToSizeT(proc_stats[field_num], &value) ? value : 0;
}

int64 ReadProcStatsAndGetFieldAsInt64(pid_t pid, ProcStatsFields field_num) {
  std::string stats_data;
  if (!ReadProcStats(pid, &stats_data))
    return 0;
  std::vector<std::string> proc_stats;
  if (!ParseProcStats(stats_data, &proc_stats))
    return 0;
  return GetProcStatsFieldAsInt64(proc_stats, field_num);
}

size_t ReadProcStatsAndGetFieldAsSizeT(pid_t pid,
                                       ProcStatsFields field_num) {
  std::string stats_data;
  if (!ReadProcStats(pid, &stats_data))
    return 0;
  std::vector<std::string> proc_stats;
  if (!ParseProcStats(stats_data, &proc_stats))
    return 0;
  return GetProcStatsFieldAsSizeT(proc_stats, field_num);
}

Time GetBootTime() {
  FilePath path("/proc/stat");
  std::string contents;
  if (!ReadProcFile(path, &contents))
    return Time();
  ProcStatMap proc_stat;
  ParseProcStat(contents, &proc_stat);
  ProcStatMap::const_iterator btime_it = proc_stat.find("btime");
  if (btime_it == proc_stat.end())
    return Time();
  int btime;
  if (!StringToInt(btime_it->second, &btime))
    return Time();
  return Time::FromTimeT(btime);
}

TimeDelta ClockTicksToTimeDelta(int clock_ticks) {
  // This queries the /proc-specific scaling factor which is
  // conceptually the system hertz.  To dump this value on another
  // system, try
  //   od -t dL /proc/self/auxv
  // and look for the number after 17 in the output; mine is
  //   0000040          17         100           3   134512692
  // which means the answer is 100.
  // It may be the case that this value is always 100.
  static const int kHertz = sysconf(_SC_CLK_TCK);

  return TimeDelta::FromMicroseconds(
      Time::kMicrosecondsPerSecond * clock_ticks / kHertz);
}

}  // namespace internal
}  // namespace base
