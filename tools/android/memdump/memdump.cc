// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fcntl.h>
#include <signal.h>
#include <sys/types.h>
#include <unistd.h>

#include <algorithm>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <string>
#include <utility>
#include <vector>

#include "base/base64.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/callback_helpers.h"
#include "base/containers/hash_tables.h"
#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#include "base/format_macros.h"
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/strings/stringprintf.h"

const unsigned int kPageSize = getpagesize();

namespace {

class BitSet {
 public:
  void resize(size_t nbits) {
    data_.resize((nbits + 7) / 8);
  }

  void set(uint32 bit) {
    const uint32 byte_idx = bit / 8;
    CHECK(byte_idx < data_.size());
    data_[byte_idx] |= (1 << (bit & 7));
  }

  std::string AsB64String() const {
    // Simple optimization: strip trailing zero bytes from the bitmap.
    // For instance, if a region has 32 pages but only the first 9 are resident,
    // The full bitmap would be 0xff 0x01 0x00 0x00, the stripped one 0xff 0x01.
    // It can save up to some seconds when printing large mmaps, in particular
    // in presence of large virtual address space reservations (where none of
    // the pages are resident).
    size_t end = data_.size();
    while (end > 0 && data_[end - 1] == '\0')
      --end;
    std::string bits(&data_[0], end);
    std::string b64_string;
    base::Base64Encode(bits, &b64_string);
    return b64_string;
  }

 private:
  std::vector<char> data_;
};

// An entry in /proc/<pid>/pagemap.
struct PageMapEntry {
  uint64 page_frame_number : 55;
  uint unused : 8;
  uint present : 1;
};

// Describes a memory page.
struct PageInfo {
  int64 page_frame_number; // Physical page id, also known as PFN.
  int64 flags;
  int32 times_mapped;
};

struct PageCount {
  PageCount() : total_count(0), unevictable_count(0) {}

  int total_count;
  int unevictable_count;
};

struct MemoryMap {
  std::string name;
  std::string flags;
  uint64 start_address;
  uint64 end_address;
  uint64 offset;
  PageCount private_pages;
  // app_shared_pages[i] contains the number of pages mapped in i+2 processes
  // (only among the processes that are being analyzed).
  std::vector<PageCount> app_shared_pages;
  PageCount other_shared_pages;
  std::vector<PageInfo> committed_pages;
  // committed_pages_bits is a bitset reflecting the present bit for all the
  // virtual pages of the mapping.
  BitSet committed_pages_bits;
};

struct ProcessMemory {
  pid_t pid;
  std::vector<MemoryMap> memory_maps;
};

bool PageIsUnevictable(const PageInfo& page_info) {
  // These constants are taken from kernel-page-flags.h.
  const int KPF_DIRTY = 4; // Note that only file-mapped pages can be DIRTY.
  const int KPF_ANON = 12; // Anonymous pages are dirty per definition.
  const int KPF_UNEVICTABLE = 18;
  const int KPF_MLOCKED = 33;

  return (page_info.flags & ((1ll << KPF_DIRTY) |
                             (1ll << KPF_ANON) |
                             (1ll << KPF_UNEVICTABLE) |
                             (1ll << KPF_MLOCKED))) ?
                             true : false;
}

// Number of times a physical page is mapped in a process.
typedef base::hash_map<uint64, int> PFNMap;

// Parses lines from /proc/<PID>/maps, e.g.:
// 401e7000-401f5000 r-xp 00000000 103:02 158       /system/bin/linker
bool ParseMemoryMapLine(const std::string& line,
                        std::vector<std::string>* tokens,
                        MemoryMap* memory_map) {
  tokens->clear();
  base::SplitString(line, ' ', tokens);
  if (tokens->size() < 2)
    return false;
  const std::string& addr_range = tokens->at(0);
  std::vector<std::string> range_tokens;
  base::SplitString(addr_range, '-', &range_tokens);
  const std::string& start_address_token = range_tokens.at(0);
  if (!base::HexStringToUInt64(start_address_token,
                               &memory_map->start_address)) {
    return false;
  }
  const std::string& end_address_token = range_tokens.at(1);
  if (!base::HexStringToUInt64(end_address_token, &memory_map->end_address)) {
    return false;
  }
  if (tokens->at(1).size() != strlen("rwxp"))
    return false;
  memory_map->flags.swap(tokens->at(1));
  if (!base::HexStringToUInt64(tokens->at(2), &memory_map->offset))
    return false;
  memory_map->committed_pages_bits.resize(
      (memory_map->end_address - memory_map->start_address) / kPageSize);
  const int map_name_index = 5;
  if (tokens->size() >= map_name_index + 1) {
    for (std::vector<std::string>::const_iterator it =
             tokens->begin() + map_name_index; it != tokens->end(); ++it) {
      if (!it->empty()) {
        if (!memory_map->name.empty())
          memory_map->name.append(" ");
        memory_map->name.append(*it);
      }
    }
  }
  return true;
}

// Reads sizeof(T) bytes from file |fd| at |offset|.
template <typename T>
bool ReadFromFileAtOffset(int fd, off_t offset, T* value) {
  if (lseek64(fd, offset * sizeof(*value), SEEK_SET) < 0) {
    PLOG(ERROR) << "lseek";
    return false;
  }
  ssize_t bytes = read(fd, value, sizeof(*value));
  if (bytes != sizeof(*value) && bytes != 0) {
    PLOG(ERROR) << "read";
    return false;
  }
  return true;
}

// Fills |process_maps| in with the process memory maps identified by |pid|.
bool GetProcessMaps(pid_t pid, std::vector<MemoryMap>* process_maps) {
  std::ifstream maps_file(base::StringPrintf("/proc/%d/maps", pid).c_str());
  if (!maps_file.good()) {
    PLOG(ERROR) << "open";
    return false;
  }
  std::string line;
  std::vector<std::string> tokens;
  while (std::getline(maps_file, line) && !line.empty()) {
    MemoryMap memory_map = {};
    if (!ParseMemoryMapLine(line, &tokens, &memory_map)) {
      LOG(ERROR) << "Could not parse line: " << line;
      return false;
    }
    process_maps->push_back(memory_map);
  }
  return true;
}

// Fills |committed_pages| in with the set of committed pages contained in the
// provided memory map.
bool GetPagesForMemoryMap(int pagemap_fd,
                          const MemoryMap& memory_map,
                          std::vector<PageInfo>* committed_pages,
                          BitSet* committed_pages_bits) {
  const off64_t offset = memory_map.start_address / kPageSize;
  if (lseek64(pagemap_fd, offset * sizeof(PageMapEntry), SEEK_SET) < 0) {
    PLOG(ERROR) << "lseek";
    return false;
  }
  for (uint64 addr = memory_map.start_address, page_index = 0;
       addr < memory_map.end_address;
       addr += kPageSize, ++page_index) {
    DCHECK_EQ(0, addr % kPageSize);
    PageMapEntry page_map_entry = {};
    static_assert(sizeof(PageMapEntry) == sizeof(uint64), "unexpected size");
    ssize_t bytes = read(pagemap_fd, &page_map_entry, sizeof(page_map_entry));
    if (bytes != sizeof(PageMapEntry) && bytes != 0) {
      PLOG(ERROR) << "read";
      return false;
    }
    if (page_map_entry.present) {  // Ignore non-committed pages.
      if (page_map_entry.page_frame_number == 0)
        continue;
      PageInfo page_info = {};
      page_info.page_frame_number = page_map_entry.page_frame_number;
      committed_pages->push_back(page_info);
      committed_pages_bits->set(page_index);
    }
  }
  return true;
}

// Fills |committed_pages| with mapping count and flags information gathered
// looking-up /proc/kpagecount and /proc/kpageflags.
bool SetPagesInfo(int pagecount_fd,
                  int pageflags_fd,
                  std::vector<PageInfo>* pages) {
  for (std::vector<PageInfo>::iterator it = pages->begin();
       it != pages->end(); ++it) {
    PageInfo* const page_info = &*it;
    int64 times_mapped;
    if (!ReadFromFileAtOffset(
            pagecount_fd, page_info->page_frame_number, &times_mapped)) {
      return false;
    }
    DCHECK(times_mapped <= std::numeric_limits<int32_t>::max());
    page_info->times_mapped = static_cast<int32>(times_mapped);

    int64 page_flags;
    if (!ReadFromFileAtOffset(
            pageflags_fd, page_info->page_frame_number, &page_flags)) {
      return false;
    }
    page_info->flags = page_flags;
  }
  return true;
}

// Fills in the provided vector of Page Frame Number maps. This lets
// ClassifyPages() know how many times each page is mapped in the processes.
void FillPFNMaps(const std::vector<ProcessMemory>& processes_memory,
                 std::vector<PFNMap>* pfn_maps) {
  int current_process_index = 0;
  for (std::vector<ProcessMemory>::const_iterator it = processes_memory.begin();
       it != processes_memory.end(); ++it, ++current_process_index) {
    const std::vector<MemoryMap>& memory_maps = it->memory_maps;
    for (std::vector<MemoryMap>::const_iterator it = memory_maps.begin();
         it != memory_maps.end(); ++it) {
      const std::vector<PageInfo>& pages = it->committed_pages;
      for (std::vector<PageInfo>::const_iterator it = pages.begin();
           it != pages.end(); ++it) {
        const PageInfo& page_info = *it;
        PFNMap* const pfn_map = &(*pfn_maps)[current_process_index];
        const std::pair<PFNMap::iterator, bool> result = pfn_map->insert(
            std::make_pair(page_info.page_frame_number, 0));
        ++result.first->second;
      }
    }
  }
}

// Sets the private_count/app_shared_pages/other_shared_count fields of the
// provided memory maps for each process.
void ClassifyPages(std::vector<ProcessMemory>* processes_memory) {
  std::vector<PFNMap> pfn_maps(processes_memory->size());
  FillPFNMaps(*processes_memory, &pfn_maps);
  // Hash set keeping track of the physical pages mapped in a single process so
  // that they can be counted only once.
  base::hash_set<uint64> physical_pages_mapped_in_process;

  for (std::vector<ProcessMemory>::iterator it = processes_memory->begin();
       it != processes_memory->end(); ++it) {
    std::vector<MemoryMap>* const memory_maps = &it->memory_maps;
    physical_pages_mapped_in_process.clear();
    for (std::vector<MemoryMap>::iterator it = memory_maps->begin();
         it != memory_maps->end(); ++it) {
      MemoryMap* const memory_map = &*it;
      const size_t processes_count = processes_memory->size();
      memory_map->app_shared_pages.resize(processes_count - 1);
      const std::vector<PageInfo>& pages = memory_map->committed_pages;
      for (std::vector<PageInfo>::const_iterator it = pages.begin();
           it != pages.end(); ++it) {
        const PageInfo& page_info = *it;
        if (page_info.times_mapped == 1) {
          ++memory_map->private_pages.total_count;
          if (PageIsUnevictable(page_info))
            ++memory_map->private_pages.unevictable_count;
          continue;
        }
        const uint64 page_frame_number = page_info.page_frame_number;
        const std::pair<base::hash_set<uint64>::iterator, bool> result =
            physical_pages_mapped_in_process.insert(page_frame_number);
        const bool did_insert = result.second;
        if (!did_insert) {
          // This physical page (mapped multiple times in the same process) was
          // already counted.
          continue;
        }
        // See if the current physical page is also mapped in the other
        // processes that are being analyzed.
        int times_mapped = 0;
        int mapped_in_processes_count = 0;
        for (std::vector<PFNMap>::const_iterator it = pfn_maps.begin();
             it != pfn_maps.end(); ++it) {
          const PFNMap& pfn_map = *it;
          const PFNMap::const_iterator found_it = pfn_map.find(
              page_frame_number);
          if (found_it == pfn_map.end())
            continue;
          ++mapped_in_processes_count;
          times_mapped += found_it->second;
        }
        PageCount* page_count_to_update = NULL;
        if (times_mapped == page_info.times_mapped) {
          // The physical page is only mapped in the processes that are being
          // analyzed.
          if (mapped_in_processes_count > 1) {
            // The physical page is mapped in multiple processes.
            page_count_to_update =
                &memory_map->app_shared_pages[mapped_in_processes_count - 2];
          } else {
            // The physical page is mapped multiple times in the same process.
            page_count_to_update = &memory_map->private_pages;
          }
        } else {
          page_count_to_update = &memory_map->other_shared_pages;
        }
        ++page_count_to_update->total_count;
        if (PageIsUnevictable(page_info))
          ++page_count_to_update->unevictable_count;
      }
    }
  }
}

void AppendAppSharedField(const std::vector<PageCount>& app_shared_pages,
                          std::string* out) {
  out->append("[");
  for (std::vector<PageCount>::const_iterator it = app_shared_pages.begin();
       it != app_shared_pages.end(); ++it) {
    out->append(base::IntToString(it->total_count * kPageSize));
    out->append(":");
    out->append(base::IntToString(it->unevictable_count * kPageSize));
    if (it + 1 != app_shared_pages.end())
      out->append(",");
  }
  out->append("]");
}

void DumpProcessesMemoryMapsInShortFormat(
    const std::vector<ProcessMemory>& processes_memory) {
  const int KB_PER_PAGE = kPageSize >> 10;
  std::vector<int> totals_app_shared(processes_memory.size());
  std::string buf;
  std::cout << "pid\tprivate\t\tshared_app\tshared_other (KB)\n";
  for (std::vector<ProcessMemory>::const_iterator it = processes_memory.begin();
       it != processes_memory.end(); ++it) {
    const ProcessMemory& process_memory = *it;
    std::fill(totals_app_shared.begin(), totals_app_shared.end(), 0);
    int total_private = 0, total_other_shared = 0;
    const std::vector<MemoryMap>& memory_maps = process_memory.memory_maps;
    for (std::vector<MemoryMap>::const_iterator it = memory_maps.begin();
         it != memory_maps.end(); ++it) {
      const MemoryMap& memory_map = *it;
      total_private += memory_map.private_pages.total_count;
      for (size_t i = 0; i < memory_map.app_shared_pages.size(); ++i)
        totals_app_shared[i] += memory_map.app_shared_pages[i].total_count;
      total_other_shared += memory_map.other_shared_pages.total_count;
    }
    double total_app_shared = 0;
    for (size_t i = 0; i < totals_app_shared.size(); ++i)
      total_app_shared += static_cast<double>(totals_app_shared[i]) / (i + 2);
    base::SStringPrintf(
        &buf, "%d\t%d\t\t%d\t\t%d\n",
        process_memory.pid,
        total_private * KB_PER_PAGE,
        static_cast<int>(total_app_shared) * KB_PER_PAGE,
        total_other_shared * KB_PER_PAGE);
    std::cout << buf;
  }
}

void DumpProcessesMemoryMapsInExtendedFormat(
    const std::vector<ProcessMemory>& processes_memory) {
  std::string buf;
  std::string app_shared_buf;
  for (std::vector<ProcessMemory>::const_iterator it = processes_memory.begin();
       it != processes_memory.end(); ++it) {
    const ProcessMemory& process_memory = *it;
    std::cout << "[ PID=" << process_memory.pid << "]" << '\n';
    const std::vector<MemoryMap>& memory_maps = process_memory.memory_maps;
    for (std::vector<MemoryMap>::const_iterator it = memory_maps.begin();
         it != memory_maps.end(); ++it) {
      const MemoryMap& memory_map = *it;
      app_shared_buf.clear();
      AppendAppSharedField(memory_map.app_shared_pages, &app_shared_buf);
      base::SStringPrintf(
          &buf,
          "%"PRIx64"-%"PRIx64" %s %"PRIx64" private_unevictable=%d private=%d "
          "shared_app=%s shared_other_unevictable=%d shared_other=%d "
          "\"%s\" [%s]\n",
          memory_map.start_address,
          memory_map.end_address,
          memory_map.flags.c_str(),
          memory_map.offset,
          memory_map.private_pages.unevictable_count * kPageSize,
          memory_map.private_pages.total_count * kPageSize,
          app_shared_buf.c_str(),
          memory_map.other_shared_pages.unevictable_count * kPageSize,
          memory_map.other_shared_pages.total_count * kPageSize,
          memory_map.name.c_str(),
          memory_map.committed_pages_bits.AsB64String().c_str());
      std::cout << buf;
    }
  }
}

bool CollectProcessMemoryInformation(int page_count_fd,
                                     int page_flags_fd,
                                     ProcessMemory* process_memory) {
  const pid_t pid = process_memory->pid;
  base::ScopedFD pagemap_fd(HANDLE_EINTR(open(
      base::StringPrintf("/proc/%d/pagemap", pid).c_str(), O_RDONLY)));
  if (!pagemap_fd.is_valid()) {
    PLOG(ERROR) << "open";
    return false;
  }
  std::vector<MemoryMap>* const process_maps = &process_memory->memory_maps;
  if (!GetProcessMaps(pid, process_maps))
    return false;
  for (std::vector<MemoryMap>::iterator it = process_maps->begin();
       it != process_maps->end(); ++it) {
    std::vector<PageInfo>* const committed_pages = &it->committed_pages;
    BitSet* const pages_bits = &it->committed_pages_bits;
    GetPagesForMemoryMap(pagemap_fd.get(), *it, committed_pages, pages_bits);
    SetPagesInfo(page_count_fd, page_flags_fd, committed_pages);
  }
  return true;
}

void KillAll(const std::vector<pid_t>& pids, int signal_number) {
  for (std::vector<pid_t>::const_iterator it = pids.begin(); it != pids.end();
       ++it) {
    kill(*it, signal_number);
  }
}

void ExitWithUsage() {
  LOG(ERROR) << "Usage: memdump [-a] <PID1>... <PIDN>";
  exit(EXIT_FAILURE);
}

}  // namespace

int main(int argc, char** argv) {
  if (argc == 1)
    ExitWithUsage();
  const bool short_output = !strncmp(argv[1], "-a", 2);
  if (short_output) {
    if (argc == 2)
      ExitWithUsage();
    ++argv;
  }
  std::vector<pid_t> pids;
  for (const char* const* ptr = argv + 1; *ptr; ++ptr) {
    pid_t pid;
    if (!base::StringToInt(*ptr, &pid))
      return EXIT_FAILURE;
    pids.push_back(pid);
  }

  std::vector<ProcessMemory> processes_memory(pids.size());
  {
    base::ScopedFD page_count_fd(
        HANDLE_EINTR(open("/proc/kpagecount", O_RDONLY)));
    if (!page_count_fd.is_valid()) {
      PLOG(ERROR) << "open /proc/kpagecount";
      return EXIT_FAILURE;
    }

    base::ScopedFD page_flags_fd(open("/proc/kpageflags", O_RDONLY));
    if (!page_flags_fd.is_valid()) {
      PLOG(ERROR) << "open /proc/kpageflags";
      return EXIT_FAILURE;
    }

    base::ScopedClosureRunner auto_resume_processes(
        base::Bind(&KillAll, pids, SIGCONT));
    KillAll(pids, SIGSTOP);
    for (std::vector<pid_t>::const_iterator it = pids.begin(); it != pids.end();
         ++it) {
      ProcessMemory* const process_memory =
          &processes_memory[it - pids.begin()];
      process_memory->pid = *it;
      if (!CollectProcessMemoryInformation(
              page_count_fd.get(), page_flags_fd.get(), process_memory)) {
        return EXIT_FAILURE;
      }
    }
  }

  ClassifyPages(&processes_memory);
  if (short_output)
    DumpProcessesMemoryMapsInShortFormat(processes_memory);
  else
    DumpProcessesMemoryMapsInExtendedFormat(processes_memory);
  return EXIT_SUCCESS;
}
