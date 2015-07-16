// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/process_memory_maps_dump_provider.h"

#include <cctype>
#include <fstream>

#include "base/logging.h"
#include "base/process/process_metrics.h"
#include "base/trace_event/process_memory_dump.h"
#include "base/trace_event/process_memory_maps.h"

namespace base {
namespace trace_event {

#if defined(OS_LINUX) || defined(OS_ANDROID)
// static
std::istream* ProcessMemoryMapsDumpProvider::proc_smaps_for_testing = nullptr;

namespace {

const uint32 kMaxLineSize = 4096;

bool ParseSmapsHeader(std::istream* smaps,
                      ProcessMemoryMaps::VMRegion* region) {
  // e.g., "00400000-00421000 r-xp 00000000 fc:01 1234  /foo.so\n"
  bool res = true;  // Whether this region should be appended or skipped.
  uint64 end_addr;
  std::string protection_flags;
  std::string ignored;
  *smaps >> std::hex >> region->start_address;
  smaps->ignore(1);
  *smaps >> std::hex >> end_addr;
  if (end_addr > region->start_address) {
    region->size_in_bytes = end_addr - region->start_address;
  } else {
    // This is not just paranoia, it can actually happen (See crbug.com/461237).
    region->size_in_bytes = 0;
    res = false;
  }

  region->protection_flags = 0;
  *smaps >> protection_flags;
  CHECK_EQ(4UL, protection_flags.size());
  if (protection_flags[0] == 'r') {
    region->protection_flags |=
        ProcessMemoryMaps::VMRegion::kProtectionFlagsRead;
  }
  if (protection_flags[1] == 'w') {
    region->protection_flags |=
        ProcessMemoryMaps::VMRegion::kProtectionFlagsWrite;
  }
  if (protection_flags[2] == 'x') {
    region->protection_flags |=
        ProcessMemoryMaps::VMRegion::kProtectionFlagsExec;
  }
  *smaps >> ignored;  // Ignore mapped file offset.
  *smaps >> ignored;  // Ignore device maj-min (fc:01 in the example above).
  *smaps >> ignored;  // Ignore inode number (1234 in the example above).

  while (smaps->peek() == ' ')
    smaps->ignore(1);
  char mapped_file[kMaxLineSize];
  smaps->getline(mapped_file, sizeof(mapped_file));
  region->mapped_file = mapped_file;

  return res;
}

uint64 ReadCounterBytes(std::istream* smaps) {
  uint64 counter_value = 0;
  *smaps >> std::dec >> counter_value;
  return counter_value * 1024;
}

uint32 ParseSmapsCounter(std::istream* smaps,
                         ProcessMemoryMaps::VMRegion* region) {
  // A smaps counter lines looks as follows: "RSS:  0 Kb\n"
  uint32 res = 1;
  std::string counter_name;
  *smaps >> counter_name;

  // TODO(primiano): "Swap" should also be accounted as resident. Check
  // whether Rss isn't already counting swapped and fix below if that is
  // the case.
  if (counter_name == "Pss:") {
    region->byte_stats_proportional_resident = ReadCounterBytes(smaps);
  } else if (counter_name == "Private_Dirty:") {
    region->byte_stats_private_dirty_resident = ReadCounterBytes(smaps);
  } else if (counter_name == "Private_Clean:") {
    region->byte_stats_private_clean_resident = ReadCounterBytes(smaps);
  } else if (counter_name == "Shared_Dirty:") {
    region->byte_stats_shared_dirty_resident = ReadCounterBytes(smaps);
  } else if (counter_name == "Shared_Clean:") {
    region->byte_stats_shared_clean_resident = ReadCounterBytes(smaps);
  } else if (counter_name == "Swap:") {
    region->byte_stats_swapped = ReadCounterBytes(smaps);
  } else {
    res = 0;
  }

#ifndef NDEBUG
  // Paranoid check against changes of the Kernel /proc interface.
  if (res) {
    std::string unit;
    *smaps >> unit;
    DCHECK_EQ("kB", unit);
  }
#endif

  smaps->ignore(kMaxLineSize, '\n');

  return res;
}

uint32 ReadLinuxProcSmapsFile(std::istream* smaps, ProcessMemoryMaps* pmm) {
  if (!smaps->good())
    return 0;

  const uint32 kNumExpectedCountersPerRegion = 6;
  uint32 counters_parsed_for_current_region = 0;
  uint32 num_valid_regions = 0;
  ProcessMemoryMaps::VMRegion region;
  bool should_add_current_region = false;
  for (;;) {
    int next = smaps->peek();
    if (next == std::ifstream::traits_type::eof() || next == '\n')
      break;
    if (isxdigit(next) && !isupper(next)) {
      region = ProcessMemoryMaps::VMRegion();
      counters_parsed_for_current_region = 0;
      should_add_current_region = ParseSmapsHeader(smaps, &region);
    } else {
      counters_parsed_for_current_region += ParseSmapsCounter(smaps, &region);
      DCHECK_LE(counters_parsed_for_current_region,
                kNumExpectedCountersPerRegion);
      if (counters_parsed_for_current_region == kNumExpectedCountersPerRegion) {
        if (should_add_current_region) {
          pmm->AddVMRegion(region);
          ++num_valid_regions;
          should_add_current_region = false;
        }
      }
    }
  }
  return num_valid_regions;
}

}  // namespace
#endif  // defined(OS_LINUX) || defined(OS_ANDROID)

// static
ProcessMemoryMapsDumpProvider* ProcessMemoryMapsDumpProvider::GetInstance() {
  return Singleton<ProcessMemoryMapsDumpProvider,
                   LeakySingletonTraits<ProcessMemoryMapsDumpProvider>>::get();
}

ProcessMemoryMapsDumpProvider::ProcessMemoryMapsDumpProvider() {
}

ProcessMemoryMapsDumpProvider::~ProcessMemoryMapsDumpProvider() {
}

// Called at trace dump point time. Creates a snapshot the memory maps for the
// current process.
bool ProcessMemoryMapsDumpProvider::OnMemoryDump(ProcessMemoryDump* pmd) {
  uint32 res = 0;

#if defined(OS_LINUX) || defined(OS_ANDROID)
  if (UNLIKELY(proc_smaps_for_testing)) {
    res = ReadLinuxProcSmapsFile(proc_smaps_for_testing, pmd->process_mmaps());
  } else {
    std::ifstream proc_self_smaps("/proc/self/smaps");
    res = ReadLinuxProcSmapsFile(&proc_self_smaps, pmd->process_mmaps());
  }
#else
  LOG(ERROR) << "ProcessMemoryMaps dump provider is supported only on Linux";
#endif

  if (res > 0) {
    pmd->set_has_process_mmaps();
    return true;
  }

  return false;
}

}  // namespace trace_event
}  // namespace base
