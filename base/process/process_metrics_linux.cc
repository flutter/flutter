// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_metrics.h"

#include <dirent.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/process/internal_linux.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/strings/string_tokenizer.h"
#include "base/strings/string_util.h"
#include "base/sys_info.h"
#include "base/threading/thread_restrictions.h"

namespace base {

namespace {

void TrimKeyValuePairs(StringPairs* pairs) {
  DCHECK(pairs);
  StringPairs& p_ref = *pairs;
  for (size_t i = 0; i < p_ref.size(); ++i) {
    TrimWhitespaceASCII(p_ref[i].first, TRIM_ALL, &p_ref[i].first);
    TrimWhitespaceASCII(p_ref[i].second, TRIM_ALL, &p_ref[i].second);
  }
}

#if defined(OS_CHROMEOS)
// Read a file with a single number string and return the number as a uint64.
static uint64 ReadFileToUint64(const FilePath file) {
  std::string file_as_string;
  if (!ReadFileToString(file, &file_as_string))
    return 0;
  TrimWhitespaceASCII(file_as_string, TRIM_ALL, &file_as_string);
  uint64 file_as_uint64 = 0;
  if (!StringToUint64(file_as_string, &file_as_uint64))
    return 0;
  return file_as_uint64;
}
#endif

// Read /proc/<pid>/status and return the value for |field|, or 0 on failure.
// Only works for fields in the form of "Field: value kB".
size_t ReadProcStatusAndGetFieldAsSizeT(pid_t pid, const std::string& field) {
  std::string status;
  {
    // Synchronously reading files in /proc does not hit the disk.
    ThreadRestrictions::ScopedAllowIO allow_io;
    FilePath stat_file = internal::GetProcPidDir(pid).Append("status");
    if (!ReadFileToString(stat_file, &status))
      return 0;
  }

  StringPairs pairs;
  SplitStringIntoKeyValuePairs(status, ':', '\n', &pairs);
  TrimKeyValuePairs(&pairs);
  for (size_t i = 0; i < pairs.size(); ++i) {
    const std::string& key = pairs[i].first;
    const std::string& value_str = pairs[i].second;
    if (key == field) {
      std::vector<std::string> split_value_str;
      SplitString(value_str, ' ', &split_value_str);
      if (split_value_str.size() != 2 || split_value_str[1] != "kB") {
        NOTREACHED();
        return 0;
      }
      size_t value;
      if (!StringToSizeT(split_value_str[0], &value)) {
        NOTREACHED();
        return 0;
      }
      return value;
    }
  }
  NOTREACHED();
  return 0;
}

#if defined(OS_LINUX)
// Read /proc/<pid>/sched and look for |field|. On succes, return true and
// write the value for |field| into |result|.
// Only works for fields in the form of "field    :     uint_value"
bool ReadProcSchedAndGetFieldAsUint64(pid_t pid,
                                      const std::string& field,
                                      uint64* result) {
  std::string sched_data;
  {
    // Synchronously reading files in /proc does not hit the disk.
    ThreadRestrictions::ScopedAllowIO allow_io;
    FilePath sched_file = internal::GetProcPidDir(pid).Append("sched");
    if (!ReadFileToString(sched_file, &sched_data))
      return false;
  }

  StringPairs pairs;
  SplitStringIntoKeyValuePairs(sched_data, ':', '\n', &pairs);
  TrimKeyValuePairs(&pairs);
  for (size_t i = 0; i < pairs.size(); ++i) {
    const std::string& key = pairs[i].first;
    const std::string& value_str = pairs[i].second;
    if (key == field) {
      uint64 value;
      if (!StringToUint64(value_str, &value))
        return false;
      *result = value;
      return true;
    }
  }
  return false;
}
#endif  // defined(OS_LINUX)

// Get the total CPU of a single process.  Return value is number of jiffies
// on success or -1 on error.
int GetProcessCPU(pid_t pid) {
  // Use /proc/<pid>/task to find all threads and parse their /stat file.
  FilePath task_path = internal::GetProcPidDir(pid).Append("task");

  DIR* dir = opendir(task_path.value().c_str());
  if (!dir) {
    DPLOG(ERROR) << "opendir(" << task_path.value() << ")";
    return -1;
  }

  int total_cpu = 0;
  while (struct dirent* ent = readdir(dir)) {
    pid_t tid = internal::ProcDirSlotToPid(ent->d_name);
    if (!tid)
      continue;

    // Synchronously reading files in /proc does not hit the disk.
    ThreadRestrictions::ScopedAllowIO allow_io;

    std::string stat;
    FilePath stat_path =
        task_path.Append(ent->d_name).Append(internal::kStatFile);
    if (ReadFileToString(stat_path, &stat)) {
      int cpu = ParseProcStatCPU(stat);
      if (cpu > 0)
        total_cpu += cpu;
    }
  }
  closedir(dir);

  return total_cpu;
}

}  // namespace

// static
ProcessMetrics* ProcessMetrics::CreateProcessMetrics(ProcessHandle process) {
  return new ProcessMetrics(process);
}

// On linux, we return vsize.
size_t ProcessMetrics::GetPagefileUsage() const {
  return internal::ReadProcStatsAndGetFieldAsSizeT(process_,
                                                   internal::VM_VSIZE);
}

// On linux, we return the high water mark of vsize.
size_t ProcessMetrics::GetPeakPagefileUsage() const {
  return ReadProcStatusAndGetFieldAsSizeT(process_, "VmPeak") * 1024;
}

// On linux, we return RSS.
size_t ProcessMetrics::GetWorkingSetSize() const {
  return internal::ReadProcStatsAndGetFieldAsSizeT(process_, internal::VM_RSS) *
      getpagesize();
}

// On linux, we return the high water mark of RSS.
size_t ProcessMetrics::GetPeakWorkingSetSize() const {
  return ReadProcStatusAndGetFieldAsSizeT(process_, "VmHWM") * 1024;
}

bool ProcessMetrics::GetMemoryBytes(size_t* private_bytes,
                                    size_t* shared_bytes) {
  WorkingSetKBytes ws_usage;
  if (!GetWorkingSetKBytes(&ws_usage))
    return false;

  if (private_bytes)
    *private_bytes = ws_usage.priv * 1024;

  if (shared_bytes)
    *shared_bytes = ws_usage.shared * 1024;

  return true;
}

bool ProcessMetrics::GetWorkingSetKBytes(WorkingSetKBytes* ws_usage) const {
#if defined(OS_CHROMEOS)
  if (GetWorkingSetKBytesTotmaps(ws_usage))
    return true;
#endif
  return GetWorkingSetKBytesStatm(ws_usage);
}

double ProcessMetrics::GetCPUUsage() {
  TimeTicks time = TimeTicks::Now();

  if (last_cpu_ == 0) {
    // First call, just set the last values.
    last_cpu_time_ = time;
    last_cpu_ = GetProcessCPU(process_);
    return 0;
  }

  int64 time_delta = (time - last_cpu_time_).InMicroseconds();
  DCHECK_NE(time_delta, 0);
  if (time_delta == 0)
    return 0;

  int cpu = GetProcessCPU(process_);

  // We have the number of jiffies in the time period.  Convert to percentage.
  // Note this means we will go *over* 100 in the case where multiple threads
  // are together adding to more than one CPU's worth.
  TimeDelta cpu_time = internal::ClockTicksToTimeDelta(cpu);
  TimeDelta last_cpu_time = internal::ClockTicksToTimeDelta(last_cpu_);
  double percentage = 100.0 * (cpu_time - last_cpu_time).InSecondsF() /
      TimeDelta::FromMicroseconds(time_delta).InSecondsF();

  last_cpu_time_ = time;
  last_cpu_ = cpu;

  return percentage;
}

// To have /proc/self/io file you must enable CONFIG_TASK_IO_ACCOUNTING
// in your kernel configuration.
bool ProcessMetrics::GetIOCounters(IoCounters* io_counters) const {
  // Synchronously reading files in /proc does not hit the disk.
  ThreadRestrictions::ScopedAllowIO allow_io;

  std::string proc_io_contents;
  FilePath io_file = internal::GetProcPidDir(process_).Append("io");
  if (!ReadFileToString(io_file, &proc_io_contents))
    return false;

  io_counters->OtherOperationCount = 0;
  io_counters->OtherTransferCount = 0;

  StringPairs pairs;
  SplitStringIntoKeyValuePairs(proc_io_contents, ':', '\n', &pairs);
  TrimKeyValuePairs(&pairs);
  for (size_t i = 0; i < pairs.size(); ++i) {
    const std::string& key = pairs[i].first;
    const std::string& value_str = pairs[i].second;
    uint64* target_counter = NULL;
    if (key == "syscr")
      target_counter = &io_counters->ReadOperationCount;
    else if (key == "syscw")
      target_counter = &io_counters->WriteOperationCount;
    else if (key == "rchar")
      target_counter = &io_counters->ReadTransferCount;
    else if (key == "wchar")
      target_counter = &io_counters->WriteTransferCount;
    if (!target_counter)
      continue;
    bool converted = StringToUint64(value_str, target_counter);
    DCHECK(converted);
  }
  return true;
}

ProcessMetrics::ProcessMetrics(ProcessHandle process)
    : process_(process),
      last_system_time_(0),
#if defined(OS_LINUX)
      last_absolute_idle_wakeups_(0),
#endif
      last_cpu_(0) {
  processor_count_ = SysInfo::NumberOfProcessors();
}

#if defined(OS_CHROMEOS)
// Private, Shared and Proportional working set sizes are obtained from
// /proc/<pid>/totmaps
bool ProcessMetrics::GetWorkingSetKBytesTotmaps(WorkingSetKBytes *ws_usage)
  const {
  // The format of /proc/<pid>/totmaps is:
  //
  // Rss:                6120 kB
  // Pss:                3335 kB
  // Shared_Clean:       1008 kB
  // Shared_Dirty:       4012 kB
  // Private_Clean:         4 kB
  // Private_Dirty:      1096 kB
  // Referenced:          XXX kB
  // Anonymous:           XXX kB
  // AnonHugePages:       XXX kB
  // Swap:                XXX kB
  // Locked:              XXX kB
  const size_t kPssIndex = (1 * 3) + 1;
  const size_t kPrivate_CleanIndex = (4 * 3) + 1;
  const size_t kPrivate_DirtyIndex = (5 * 3) + 1;
  const size_t kSwapIndex = (9 * 3) + 1;

  std::string totmaps_data;
  {
    FilePath totmaps_file = internal::GetProcPidDir(process_).Append("totmaps");
    ThreadRestrictions::ScopedAllowIO allow_io;
    bool ret = ReadFileToString(totmaps_file, &totmaps_data);
    if (!ret || totmaps_data.length() == 0)
      return false;
  }

  std::vector<std::string> totmaps_fields;
  SplitStringAlongWhitespace(totmaps_data, &totmaps_fields);

  DCHECK_EQ("Pss:", totmaps_fields[kPssIndex-1]);
  DCHECK_EQ("Private_Clean:", totmaps_fields[kPrivate_CleanIndex - 1]);
  DCHECK_EQ("Private_Dirty:", totmaps_fields[kPrivate_DirtyIndex - 1]);
  DCHECK_EQ("Swap:", totmaps_fields[kSwapIndex-1]);

  int pss = 0;
  int private_clean = 0;
  int private_dirty = 0;
  int swap = 0;
  bool ret = true;
  ret &= StringToInt(totmaps_fields[kPssIndex], &pss);
  ret &= StringToInt(totmaps_fields[kPrivate_CleanIndex], &private_clean);
  ret &= StringToInt(totmaps_fields[kPrivate_DirtyIndex], &private_dirty);
  ret &= StringToInt(totmaps_fields[kSwapIndex], &swap);

  // On ChromeOS swap is to zram. We count this as private / shared, as
  // increased swap decreases available RAM to user processes, which would
  // otherwise create surprising results.
  ws_usage->priv = private_clean + private_dirty + swap;
  ws_usage->shared = pss + swap;
  ws_usage->shareable = 0;
  ws_usage->swapped = swap;
  return ret;
}
#endif

// Private and Shared working set sizes are obtained from /proc/<pid>/statm.
bool ProcessMetrics::GetWorkingSetKBytesStatm(WorkingSetKBytes* ws_usage)
    const {
  // Use statm instead of smaps because smaps is:
  // a) Large and slow to parse.
  // b) Unavailable in the SUID sandbox.

  // First we need to get the page size, since everything is measured in pages.
  // For details, see: man 5 proc.
  const int page_size_kb = getpagesize() / 1024;
  if (page_size_kb <= 0)
    return false;

  std::string statm;
  {
    FilePath statm_file = internal::GetProcPidDir(process_).Append("statm");
    // Synchronously reading files in /proc does not hit the disk.
    ThreadRestrictions::ScopedAllowIO allow_io;
    bool ret = ReadFileToString(statm_file, &statm);
    if (!ret || statm.length() == 0)
      return false;
  }

  std::vector<std::string> statm_vec;
  SplitString(statm, ' ', &statm_vec);
  if (statm_vec.size() != 7)
    return false;  // Not the format we expect.

  int statm_rss, statm_shared;
  bool ret = true;
  ret &= StringToInt(statm_vec[1], &statm_rss);
  ret &= StringToInt(statm_vec[2], &statm_shared);

  ws_usage->priv = (statm_rss - statm_shared) * page_size_kb;
  ws_usage->shared = statm_shared * page_size_kb;

  // Sharable is not calculated, as it does not provide interesting data.
  ws_usage->shareable = 0;

#if defined(OS_CHROMEOS)
  // Can't get swapped memory from statm.
  ws_usage->swapped = 0;
#endif

  return ret;
}

size_t GetSystemCommitCharge() {
  SystemMemoryInfoKB meminfo;
  if (!GetSystemMemoryInfo(&meminfo))
    return 0;
  return meminfo.total - meminfo.free - meminfo.buffers - meminfo.cached;
}

int ParseProcStatCPU(const std::string& input) {
  // |input| may be empty if the process disappeared somehow.
  // e.g. http://crbug.com/145811.
  if (input.empty())
    return -1;

  size_t start = input.find_last_of(')');
  if (start == input.npos)
    return -1;

  // Number of spaces remaining until reaching utime's index starting after the
  // last ')'.
  int num_spaces_remaining = internal::VM_UTIME - 1;

  size_t i = start;
  while ((i = input.find(' ', i + 1)) != input.npos) {
    // Validate the assumption that there aren't any contiguous spaces
    // in |input| before utime.
    DCHECK_NE(input[i - 1], ' ');
    if (--num_spaces_remaining == 0) {
      int utime = 0;
      int stime = 0;
      if (sscanf(&input.data()[i], "%d %d", &utime, &stime) != 2)
        return -1;

      return utime + stime;
    }
  }

  return -1;
}

const char kProcSelfExe[] = "/proc/self/exe";

int GetNumberOfThreads(ProcessHandle process) {
  return internal::ReadProcStatsAndGetFieldAsInt64(process,
                                                   internal::VM_NUMTHREADS);
}

namespace {

// The format of /proc/diskstats is:
//  Device major number
//  Device minor number
//  Device name
//  Field  1 -- # of reads completed
//      This is the total number of reads completed successfully.
//  Field  2 -- # of reads merged, field 6 -- # of writes merged
//      Reads and writes which are adjacent to each other may be merged for
//      efficiency.  Thus two 4K reads may become one 8K read before it is
//      ultimately handed to the disk, and so it will be counted (and queued)
//      as only one I/O.  This field lets you know how often this was done.
//  Field  3 -- # of sectors read
//      This is the total number of sectors read successfully.
//  Field  4 -- # of milliseconds spent reading
//      This is the total number of milliseconds spent by all reads (as
//      measured from __make_request() to end_that_request_last()).
//  Field  5 -- # of writes completed
//      This is the total number of writes completed successfully.
//  Field  6 -- # of writes merged
//      See the description of field 2.
//  Field  7 -- # of sectors written
//      This is the total number of sectors written successfully.
//  Field  8 -- # of milliseconds spent writing
//      This is the total number of milliseconds spent by all writes (as
//      measured from __make_request() to end_that_request_last()).
//  Field  9 -- # of I/Os currently in progress
//      The only field that should go to zero. Incremented as requests are
//      given to appropriate struct request_queue and decremented as they
//      finish.
//  Field 10 -- # of milliseconds spent doing I/Os
//      This field increases so long as field 9 is nonzero.
//  Field 11 -- weighted # of milliseconds spent doing I/Os
//      This field is incremented at each I/O start, I/O completion, I/O
//      merge, or read of these stats by the number of I/Os in progress
//      (field 9) times the number of milliseconds spent doing I/O since the
//      last update of this field.  This can provide an easy measure of both
//      I/O completion time and the backlog that may be accumulating.

const size_t kDiskDriveName = 2;
const size_t kDiskReads = 3;
const size_t kDiskReadsMerged = 4;
const size_t kDiskSectorsRead = 5;
const size_t kDiskReadTime = 6;
const size_t kDiskWrites = 7;
const size_t kDiskWritesMerged = 8;
const size_t kDiskSectorsWritten = 9;
const size_t kDiskWriteTime = 10;
const size_t kDiskIO = 11;
const size_t kDiskIOTime = 12;
const size_t kDiskWeightedIOTime = 13;

}  // namespace

SystemMemoryInfoKB::SystemMemoryInfoKB() {
  total = 0;
  free = 0;
  buffers = 0;
  cached = 0;
  active_anon = 0;
  inactive_anon = 0;
  active_file = 0;
  inactive_file = 0;
  swap_total = 0;
  swap_free = 0;
  dirty = 0;

  pswpin = 0;
  pswpout = 0;
  pgmajfault = 0;

#ifdef OS_CHROMEOS
  shmem = 0;
  slab = 0;
  gem_objects = -1;
  gem_size = -1;
#endif
}

scoped_ptr<Value> SystemMemoryInfoKB::ToValue() const {
  scoped_ptr<DictionaryValue> res(new DictionaryValue());

  res->SetInteger("total", total);
  res->SetInteger("free", free);
  res->SetInteger("buffers", buffers);
  res->SetInteger("cached", cached);
  res->SetInteger("active_anon", active_anon);
  res->SetInteger("inactive_anon", inactive_anon);
  res->SetInteger("active_file", active_file);
  res->SetInteger("inactive_file", inactive_file);
  res->SetInteger("swap_total", swap_total);
  res->SetInteger("swap_free", swap_free);
  res->SetInteger("swap_used", swap_total - swap_free);
  res->SetInteger("dirty", dirty);
  res->SetInteger("pswpin", pswpin);
  res->SetInteger("pswpout", pswpout);
  res->SetInteger("pgmajfault", pgmajfault);
#ifdef OS_CHROMEOS
  res->SetInteger("shmem", shmem);
  res->SetInteger("slab", slab);
  res->SetInteger("gem_objects", gem_objects);
  res->SetInteger("gem_size", gem_size);
#endif

  return res.Pass();
}

// exposed for testing
bool ParseProcMeminfo(const std::string& meminfo_data,
                      SystemMemoryInfoKB* meminfo) {
  // The format of /proc/meminfo is:
  //
  // MemTotal:      8235324 kB
  // MemFree:       1628304 kB
  // Buffers:        429596 kB
  // Cached:        4728232 kB
  // ...
  // There is no guarantee on the ordering or position
  // though it doesn't appear to change very often

  // As a basic sanity check, let's make sure we at least get non-zero
  // MemTotal value
  meminfo->total = 0;

  for (const StringPiece& line : SplitStringPiece(
           meminfo_data, "\n", KEEP_WHITESPACE, SPLIT_WANT_NONEMPTY)) {
    std::vector<StringPiece> tokens = SplitStringPiece(
        line, kWhitespaceASCII, TRIM_WHITESPACE, SPLIT_WANT_NONEMPTY);
    // HugePages_* only has a number and no suffix so we can't rely on
    // there being exactly 3 tokens.
    if (tokens.size() <= 1) {
      DLOG(WARNING) << "meminfo: tokens: " << tokens.size()
                    << " malformed line: " << line.as_string();
      continue;
    }

    int* target = NULL;
    if (tokens[0] == "MemTotal:")
      target = &meminfo->total;
    else if (tokens[0] == "MemFree:")
      target = &meminfo->free;
    else if (tokens[0] == "Buffers:")
      target = &meminfo->buffers;
    else if (tokens[0] == "Cached:")
      target = &meminfo->cached;
    else if (tokens[0] == "Active(anon):")
      target = &meminfo->active_anon;
    else if (tokens[0] == "Inactive(anon):")
      target = &meminfo->inactive_anon;
    else if (tokens[0] == "Active(file):")
      target = &meminfo->active_file;
    else if (tokens[0] == "Inactive(file):")
      target = &meminfo->inactive_file;
    else if (tokens[0] == "SwapTotal:")
      target = &meminfo->swap_total;
    else if (tokens[0] == "SwapFree:")
      target = &meminfo->swap_free;
    else if (tokens[0] == "Dirty:")
      target = &meminfo->dirty;
#if defined(OS_CHROMEOS)
    // Chrome OS has a tweaked kernel that allows us to query Shmem, which is
    // usually video memory otherwise invisible to the OS.
    else if (tokens[0] == "Shmem:")
      target = &meminfo->shmem;
    else if (tokens[0] == "Slab:")
      target = &meminfo->slab;
#endif
    if (target)
      StringToInt(tokens[1], target);
  }

  // Make sure we got a valid MemTotal.
  return meminfo->total > 0;
}

// exposed for testing
bool ParseProcVmstat(const std::string& vmstat_data,
                     SystemMemoryInfoKB* meminfo) {
  // The format of /proc/vmstat is:
  //
  // nr_free_pages 299878
  // nr_inactive_anon 239863
  // nr_active_anon 1318966
  // nr_inactive_file 2015629
  // ...
  //
  // We iterate through the whole file because the position of the
  // fields are dependent on the kernel version and configuration.

  for (const StringPiece& line : SplitStringPiece(
           vmstat_data, "\n", KEEP_WHITESPACE, SPLIT_WANT_NONEMPTY)) {
    std::vector<StringPiece> tokens = SplitStringPiece(
        line, " ", KEEP_WHITESPACE, SPLIT_WANT_NONEMPTY);
    if (tokens.size() != 2)
      continue;

    if (tokens[0] == "pswpin") {
      StringToInt(tokens[1], &meminfo->pswpin);
    } else if (tokens[0] == "pswpout") {
      StringToInt(tokens[1], &meminfo->pswpout);
    } else if (tokens[0] == "pgmajfault") {
      StringToInt(tokens[1], &meminfo->pgmajfault);
    }
  }

  return true;
}

bool GetSystemMemoryInfo(SystemMemoryInfoKB* meminfo) {
  // Synchronously reading files in /proc and /sys are safe.
  ThreadRestrictions::ScopedAllowIO allow_io;

  // Used memory is: total - free - buffers - caches
  FilePath meminfo_file("/proc/meminfo");
  std::string meminfo_data;
  if (!ReadFileToString(meminfo_file, &meminfo_data)) {
    DLOG(WARNING) << "Failed to open " << meminfo_file.value();
    return false;
  }

  if (!ParseProcMeminfo(meminfo_data, meminfo)) {
    DLOG(WARNING) << "Failed to parse " << meminfo_file.value();
    return false;
  }

#if defined(OS_CHROMEOS)
  // Report on Chrome OS GEM object graphics memory. /run/debugfs_gpu is a
  // bind mount into /sys/kernel/debug and synchronously reading the in-memory
  // files in /sys is fast.
#if defined(ARCH_CPU_ARM_FAMILY)
  FilePath geminfo_file("/run/debugfs_gpu/exynos_gem_objects");
#else
  FilePath geminfo_file("/run/debugfs_gpu/i915_gem_objects");
#endif
  std::string geminfo_data;
  meminfo->gem_objects = -1;
  meminfo->gem_size = -1;
  if (ReadFileToString(geminfo_file, &geminfo_data)) {
    int gem_objects = -1;
    long long gem_size = -1;
    int num_res = sscanf(geminfo_data.c_str(),
                         "%d objects, %lld bytes",
                         &gem_objects, &gem_size);
    if (num_res == 2) {
      meminfo->gem_objects = gem_objects;
      meminfo->gem_size = gem_size;
    }
  }

#if defined(ARCH_CPU_ARM_FAMILY)
  // Incorporate Mali graphics memory if present.
  FilePath mali_memory_file("/sys/class/misc/mali0/device/memory");
  std::string mali_memory_data;
  if (ReadFileToString(mali_memory_file, &mali_memory_data)) {
    long long mali_size = -1;
    int num_res = sscanf(mali_memory_data.c_str(), "%lld bytes", &mali_size);
    if (num_res == 1)
      meminfo->gem_size += mali_size;
  }
#endif  // defined(ARCH_CPU_ARM_FAMILY)
#endif  // defined(OS_CHROMEOS)

  FilePath vmstat_file("/proc/vmstat");
  std::string vmstat_data;
  if (!ReadFileToString(vmstat_file, &vmstat_data)) {
    DLOG(WARNING) << "Failed to open " << vmstat_file.value();
    return false;
  }
  if (!ParseProcVmstat(vmstat_data, meminfo)) {
    DLOG(WARNING) << "Failed to parse " << vmstat_file.value();
    return false;
  }

  return true;
}

SystemDiskInfo::SystemDiskInfo() {
  reads = 0;
  reads_merged = 0;
  sectors_read = 0;
  read_time = 0;
  writes = 0;
  writes_merged = 0;
  sectors_written = 0;
  write_time = 0;
  io = 0;
  io_time = 0;
  weighted_io_time = 0;
}

scoped_ptr<Value> SystemDiskInfo::ToValue() const {
  scoped_ptr<DictionaryValue> res(new DictionaryValue());

  // Write out uint64 variables as doubles.
  // Note: this may discard some precision, but for JS there's no other option.
  res->SetDouble("reads", static_cast<double>(reads));
  res->SetDouble("reads_merged", static_cast<double>(reads_merged));
  res->SetDouble("sectors_read", static_cast<double>(sectors_read));
  res->SetDouble("read_time", static_cast<double>(read_time));
  res->SetDouble("writes", static_cast<double>(writes));
  res->SetDouble("writes_merged", static_cast<double>(writes_merged));
  res->SetDouble("sectors_written", static_cast<double>(sectors_written));
  res->SetDouble("write_time", static_cast<double>(write_time));
  res->SetDouble("io", static_cast<double>(io));
  res->SetDouble("io_time", static_cast<double>(io_time));
  res->SetDouble("weighted_io_time", static_cast<double>(weighted_io_time));

  return res.Pass();
}

bool IsValidDiskName(const std::string& candidate) {
  if (candidate.length() < 3)
    return false;
  if (candidate[1] == 'd' &&
      (candidate[0] == 'h' || candidate[0] == 's' || candidate[0] == 'v')) {
    // [hsv]d[a-z]+ case
    for (size_t i = 2; i < candidate.length(); ++i) {
      if (!islower(candidate[i]))
        return false;
    }
    return true;
  }

  const char kMMCName[] = "mmcblk";
  const size_t kMMCNameLen = strlen(kMMCName);
  if (candidate.length() < kMMCNameLen + 1)
    return false;
  if (candidate.compare(0, kMMCNameLen, kMMCName) != 0)
    return false;

  // mmcblk[0-9]+ case
  for (size_t i = kMMCNameLen; i < candidate.length(); ++i) {
    if (!isdigit(candidate[i]))
      return false;
  }
  return true;
}

bool GetSystemDiskInfo(SystemDiskInfo* diskinfo) {
  // Synchronously reading files in /proc does not hit the disk.
  ThreadRestrictions::ScopedAllowIO allow_io;

  FilePath diskinfo_file("/proc/diskstats");
  std::string diskinfo_data;
  if (!ReadFileToString(diskinfo_file, &diskinfo_data)) {
    DLOG(WARNING) << "Failed to open " << diskinfo_file.value();
    return false;
  }

  std::vector<StringPiece> diskinfo_lines = SplitStringPiece(
      diskinfo_data, "\n", KEEP_WHITESPACE, SPLIT_WANT_NONEMPTY);
  if (diskinfo_lines.size() == 0) {
    DLOG(WARNING) << "No lines found";
    return false;
  }

  diskinfo->reads = 0;
  diskinfo->reads_merged = 0;
  diskinfo->sectors_read = 0;
  diskinfo->read_time = 0;
  diskinfo->writes = 0;
  diskinfo->writes_merged = 0;
  diskinfo->sectors_written = 0;
  diskinfo->write_time = 0;
  diskinfo->io = 0;
  diskinfo->io_time = 0;
  diskinfo->weighted_io_time = 0;

  uint64 reads = 0;
  uint64 reads_merged = 0;
  uint64 sectors_read = 0;
  uint64 read_time = 0;
  uint64 writes = 0;
  uint64 writes_merged = 0;
  uint64 sectors_written = 0;
  uint64 write_time = 0;
  uint64 io = 0;
  uint64 io_time = 0;
  uint64 weighted_io_time = 0;

  for (const StringPiece& line : diskinfo_lines) {
    std::vector<StringPiece> disk_fields = SplitStringPiece(
        line, kWhitespaceASCII, TRIM_WHITESPACE, SPLIT_WANT_NONEMPTY);

    // Fields may have overflowed and reset to zero.
    if (IsValidDiskName(disk_fields[kDiskDriveName].as_string())) {
      StringToUint64(disk_fields[kDiskReads], &reads);
      StringToUint64(disk_fields[kDiskReadsMerged], &reads_merged);
      StringToUint64(disk_fields[kDiskSectorsRead], &sectors_read);
      StringToUint64(disk_fields[kDiskReadTime], &read_time);
      StringToUint64(disk_fields[kDiskWrites], &writes);
      StringToUint64(disk_fields[kDiskWritesMerged], &writes_merged);
      StringToUint64(disk_fields[kDiskSectorsWritten], &sectors_written);
      StringToUint64(disk_fields[kDiskWriteTime], &write_time);
      StringToUint64(disk_fields[kDiskIO], &io);
      StringToUint64(disk_fields[kDiskIOTime], &io_time);
      StringToUint64(disk_fields[kDiskWeightedIOTime], &weighted_io_time);

      diskinfo->reads += reads;
      diskinfo->reads_merged += reads_merged;
      diskinfo->sectors_read += sectors_read;
      diskinfo->read_time += read_time;
      diskinfo->writes += writes;
      diskinfo->writes_merged += writes_merged;
      diskinfo->sectors_written += sectors_written;
      diskinfo->write_time += write_time;
      diskinfo->io += io;
      diskinfo->io_time += io_time;
      diskinfo->weighted_io_time += weighted_io_time;
    }
  }

  return true;
}

#if defined(OS_CHROMEOS)
scoped_ptr<Value> SwapInfo::ToValue() const {
  scoped_ptr<DictionaryValue> res(new DictionaryValue());

  // Write out uint64 variables as doubles.
  // Note: this may discard some precision, but for JS there's no other option.
  res->SetDouble("num_reads", static_cast<double>(num_reads));
  res->SetDouble("num_writes", static_cast<double>(num_writes));
  res->SetDouble("orig_data_size", static_cast<double>(orig_data_size));
  res->SetDouble("compr_data_size", static_cast<double>(compr_data_size));
  res->SetDouble("mem_used_total", static_cast<double>(mem_used_total));
  if (compr_data_size > 0)
    res->SetDouble("compression_ratio", static_cast<double>(orig_data_size) /
                                        static_cast<double>(compr_data_size));
  else
    res->SetDouble("compression_ratio", 0);

  return res.Pass();
}

void GetSwapInfo(SwapInfo* swap_info) {
  // Synchronously reading files in /sys/block/zram0 does not hit the disk.
  ThreadRestrictions::ScopedAllowIO allow_io;

  FilePath zram_path("/sys/block/zram0");
  uint64 orig_data_size = ReadFileToUint64(zram_path.Append("orig_data_size"));
  if (orig_data_size <= 4096) {
    // A single page is compressed at startup, and has a high compression
    // ratio. We ignore this as it doesn't indicate any real swapping.
    swap_info->orig_data_size = 0;
    swap_info->num_reads = 0;
    swap_info->num_writes = 0;
    swap_info->compr_data_size = 0;
    swap_info->mem_used_total = 0;
    return;
  }
  swap_info->orig_data_size = orig_data_size;
  swap_info->num_reads = ReadFileToUint64(zram_path.Append("num_reads"));
  swap_info->num_writes = ReadFileToUint64(zram_path.Append("num_writes"));
  swap_info->compr_data_size =
      ReadFileToUint64(zram_path.Append("compr_data_size"));
  swap_info->mem_used_total =
      ReadFileToUint64(zram_path.Append("mem_used_total"));
}
#endif  // defined(OS_CHROMEOS)

#if defined(OS_LINUX)
int ProcessMetrics::GetIdleWakeupsPerSecond() {
  uint64 wake_ups;
  const char kWakeupStat[] = "se.statistics.nr_wakeups";
  return ReadProcSchedAndGetFieldAsUint64(process_, kWakeupStat, &wake_ups) ?
      CalculateIdleWakeupsPerSecond(wake_ups) : 0;
}
#endif  // defined(OS_LINUX)

}  // namespace base
