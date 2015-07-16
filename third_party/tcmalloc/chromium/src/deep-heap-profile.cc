// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ---
// Author: Sainbayar Sukhbaatar
//         Dai Mikurube
//

#include "deep-heap-profile.h"

#ifdef USE_DEEP_HEAP_PROFILE
#include <algorithm>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>  // for getpagesize and getpid
#endif  // HAVE_UNISTD_H

#if defined(__linux__)
#include <endian.h>
#if !defined(__LITTLE_ENDIAN__) and !defined(__BIG_ENDIAN__)
#if __BYTE_ORDER == __BIG_ENDIAN
#define __BIG_ENDIAN__
#endif  // __BYTE_ORDER == __BIG_ENDIAN
#endif  // !defined(__LITTLE_ENDIAN__) and !defined(__BIG_ENDIAN__)
#if defined(__BIG_ENDIAN__)
#include <byteswap.h>
#endif  // defined(__BIG_ENDIAN__)
#endif  // defined(__linux__)
#if defined(COMPILER_MSVC)
#include <Winsock2.h>  // for gethostname
#endif  // defined(COMPILER_MSVC)

#include "base/cycleclock.h"
#include "base/sysinfo.h"
#include "internal_logging.h"  // for ASSERT, etc

static const int kProfilerBufferSize = 1 << 20;
static const int kHashTableSize = 179999;  // Same as heap-profile-table.cc.

static const int PAGEMAP_BYTES = 8;
static const int KPAGECOUNT_BYTES = 8;
static const uint64 MAX_ADDRESS = kuint64max;

// Tag strings in heap profile dumps.
static const char kProfileHeader[] = "heap profile: ";
static const char kProfileVersion[] = "DUMP_DEEP_6";
static const char kMetaInformationHeader[] = "META:\n";
static const char kMMapListHeader[] = "MMAP_LIST:\n";
static const char kGlobalStatsHeader[] = "GLOBAL_STATS:\n";
static const char kStacktraceHeader[] = "STACKTRACES:\n";
static const char kProcSelfMapsHeader[] = "\nMAPPED_LIBRARIES:\n";

static const char kVirtualLabel[] = "virtual";
static const char kCommittedLabel[] = "committed";

#if defined(__linux__)
#define OS_NAME "linux"
#elif defined(_WIN32) || defined(_WIN64)
#define OS_NAME "windows"
#else
#define OS_NAME "unknown-os"
#endif

bool DeepHeapProfile::AppendCommandLine(TextBuffer* buffer) {
#if defined(__linux__)
  RawFD fd;
  char filename[100];
  char cmdline[4096];
  snprintf(filename, sizeof(filename), "/proc/%d/cmdline",
           static_cast<int>(getpid()));
  fd = open(filename, O_RDONLY);
  if (fd == kIllegalRawFD) {
    RAW_VLOG(0, "Failed to open /proc/self/cmdline");
    return false;
  }

  size_t length = read(fd, cmdline, sizeof(cmdline) - 1);
  close(fd);

  for (int i = 0; i < length; ++i)
    if (cmdline[i] == '\0')
      cmdline[i] = ' ';
  cmdline[length] = '\0';

  buffer->AppendString("CommandLine: ", 0);
  buffer->AppendString(cmdline, 0);
  buffer->AppendChar('\n');

  return true;
#else
  return false;
#endif
}

#if defined(_WIN32) || defined(_WIN64)

// TODO(peria): Implement this function.
void DeepHeapProfile::MemoryInfoGetterWindows::Initialize() {
}

// TODO(peria): Implement this function.
size_t DeepHeapProfile::MemoryInfoGetterWindows::CommittedSize(
    uint64 first_address,
    uint64 last_address,
    TextBuffer* buffer) const {
  return 0;
}

// TODO(peria): Implement this function.
bool DeepHeapProfile::MemoryInfoGetterWindows::IsPageCountAvailable() const {
  return false;
}

#endif  // defined(_WIN32) || defined(_WIN64)

#if defined(__linux__)

void DeepHeapProfile::MemoryInfoGetterLinux::Initialize() {
  char filename[100];
  snprintf(filename, sizeof(filename), "/proc/%d/pagemap",
           static_cast<int>(getpid()));
  pagemap_fd_ = open(filename, O_RDONLY);
  RAW_CHECK(pagemap_fd_ != -1, "Failed to open /proc/self/pagemap");

  if (pageframe_type_ == DUMP_PAGECOUNT) {
    snprintf(filename, sizeof(filename), "/proc/kpagecount");
    kpagecount_fd_ = open(filename, O_RDONLY);
    if (kpagecount_fd_ == -1)
      RAW_VLOG(0, "Failed to open /proc/kpagecount");
  }
}

size_t DeepHeapProfile::MemoryInfoGetterLinux::CommittedSize(
    uint64 first_address,
    uint64 last_address,
    DeepHeapProfile::TextBuffer* buffer) const {
  int page_size = getpagesize();
  uint64 page_address = (first_address / page_size) * page_size;
  size_t committed_size = 0;
  size_t pageframe_list_length = 0;

  Seek(first_address);

  // Check every page on which the allocation resides.
  while (page_address <= last_address) {
    // Read corresponding physical page.
    State state;
    // TODO(dmikurube): Read pagemap in bulk for speed.
    // TODO(dmikurube): Consider using mincore(2).
    if (Read(&state, pageframe_type_ != DUMP_NO_PAGEFRAME) == false) {
      // We can't read the last region (e.g vsyscall).
#ifndef NDEBUG
      RAW_VLOG(0, "pagemap read failed @ %#llx %" PRId64 " bytes",
              first_address, last_address - first_address + 1);
#endif
      return 0;
    }

    // Dump pageframes of resident pages.  Non-resident pages are just skipped.
    if (pageframe_type_ != DUMP_NO_PAGEFRAME &&
        buffer != NULL && state.pfn != 0) {
      if (pageframe_list_length == 0) {
        buffer->AppendString("  PF:", 0);
        pageframe_list_length = 5;
      }
      buffer->AppendChar(' ');
      if (page_address < first_address)
        buffer->AppendChar('<');
      buffer->AppendBase64(state.pfn, 4);
      pageframe_list_length += 5;
      if (pageframe_type_ == DUMP_PAGECOUNT && IsPageCountAvailable()) {
        uint64 pagecount = ReadPageCount(state.pfn);
        // Assume pagecount == 63 if the pageframe is mapped more than 63 times.
        if (pagecount > 63)
          pagecount = 63;
        buffer->AppendChar('#');
        buffer->AppendBase64(pagecount, 1);
        pageframe_list_length += 2;
      }
      if (last_address < page_address - 1 + page_size)
        buffer->AppendChar('>');
      // Begins a new line every 94 characters.
      if (pageframe_list_length > 94) {
        buffer->AppendChar('\n');
        pageframe_list_length = 0;
      }
    }

    if (state.is_committed) {
      // Calculate the size of the allocation part in this page.
      size_t bytes = page_size;

      // If looking at the last page in a given region.
      if (last_address <= page_address - 1 + page_size) {
        bytes = last_address - page_address + 1;
      }

      // If looking at the first page in a given region.
      if (page_address < first_address) {
        bytes -= first_address - page_address;
      }

      committed_size += bytes;
    }
    if (page_address > MAX_ADDRESS - page_size) {
      break;
    }
    page_address += page_size;
  }

  if (pageframe_type_ != DUMP_NO_PAGEFRAME &&
      buffer != NULL && pageframe_list_length != 0) {
    buffer->AppendChar('\n');
  }

  return committed_size;
}

uint64 DeepHeapProfile::MemoryInfoGetterLinux::ReadPageCount(uint64 pfn) const {
  int64 index = pfn * KPAGECOUNT_BYTES;
  int64 offset = lseek64(kpagecount_fd_, index, SEEK_SET);
  RAW_DCHECK(offset == index, "Failed in seeking in kpagecount.");

  uint64 kpagecount_value;
  int result = read(kpagecount_fd_, &kpagecount_value, KPAGECOUNT_BYTES);
  if (result != KPAGECOUNT_BYTES)
    return 0;

  return kpagecount_value;
}

bool DeepHeapProfile::MemoryInfoGetterLinux::Seek(uint64 address) const {
  int64 index = (address / getpagesize()) * PAGEMAP_BYTES;
  RAW_DCHECK(pagemap_fd_ != -1, "Failed to seek in /proc/self/pagemap");
  int64 offset = lseek64(pagemap_fd_, index, SEEK_SET);
  RAW_DCHECK(offset == index, "Failed in seeking.");
  return offset >= 0;
}

bool DeepHeapProfile::MemoryInfoGetterLinux::Read(
    State* state, bool get_pfn) const {
  static const uint64 U64_1 = 1;
  static const uint64 PFN_FILTER = (U64_1 << 55) - U64_1;
  static const uint64 PAGE_PRESENT = U64_1 << 63;
  static const uint64 PAGE_SWAP = U64_1 << 62;
  static const uint64 PAGE_RESERVED = U64_1 << 61;
  static const uint64 FLAG_NOPAGE = U64_1 << 20;
  static const uint64 FLAG_KSM = U64_1 << 21;
  static const uint64 FLAG_MMAP = U64_1 << 11;

  uint64 pagemap_value;
  RAW_DCHECK(pagemap_fd_ != -1, "Failed to read from /proc/self/pagemap");
  int result = read(pagemap_fd_, &pagemap_value, PAGEMAP_BYTES);
  if (result != PAGEMAP_BYTES) {
    return false;
  }

  // Check if the page is committed.
  state->is_committed = (pagemap_value & (PAGE_PRESENT | PAGE_SWAP));

  state->is_present = (pagemap_value & PAGE_PRESENT);
  state->is_swapped = (pagemap_value & PAGE_SWAP);
  state->is_shared = false;

  if (get_pfn && state->is_present && !state->is_swapped)
    state->pfn = (pagemap_value & PFN_FILTER);
  else
    state->pfn = 0;

  return true;
}

bool DeepHeapProfile::MemoryInfoGetterLinux::IsPageCountAvailable() const {
  return kpagecount_fd_ != -1;
}

#endif  // defined(__linux__)

DeepHeapProfile::MemoryResidenceInfoGetterInterface::
    MemoryResidenceInfoGetterInterface() {}

DeepHeapProfile::MemoryResidenceInfoGetterInterface::
    ~MemoryResidenceInfoGetterInterface() {}

DeepHeapProfile::MemoryResidenceInfoGetterInterface*
    DeepHeapProfile::MemoryResidenceInfoGetterInterface::Create(
        PageFrameType pageframe_type) {
#if defined(_WIN32) || defined(_WIN64)
  return new MemoryInfoGetterWindows(pageframe_type);
#elif defined(__linux__)
  return new MemoryInfoGetterLinux(pageframe_type);
#else
  return NULL;
#endif
}

DeepHeapProfile::DeepHeapProfile(HeapProfileTable* heap_profile,
                                 const char* prefix,
                                 enum PageFrameType pageframe_type)
    : memory_residence_info_getter_(
          MemoryResidenceInfoGetterInterface::Create(pageframe_type)),
      most_recent_pid_(-1),
      stats_(),
      dump_count_(0),
      filename_prefix_(NULL),
      deep_table_(kHashTableSize, heap_profile->alloc_, heap_profile->dealloc_),
      pageframe_type_(pageframe_type),
      heap_profile_(heap_profile) {
  // Copy filename prefix.
  const int prefix_length = strlen(prefix);
  filename_prefix_ =
      reinterpret_cast<char*>(heap_profile_->alloc_(prefix_length + 1));
  memcpy(filename_prefix_, prefix, prefix_length);
  filename_prefix_[prefix_length] = '\0';

  strncpy(run_id_, "undetermined-run-id", sizeof(run_id_));
}

DeepHeapProfile::~DeepHeapProfile() {
  heap_profile_->dealloc_(filename_prefix_);
  delete memory_residence_info_getter_;
}

// Global malloc() should not be used in this function.
// Use LowLevelAlloc if required.
void DeepHeapProfile::DumpOrderedProfile(const char* reason,
                                         char raw_buffer[],
                                         int buffer_size,
                                         RawFD fd) {
  TextBuffer buffer(raw_buffer, buffer_size, fd);

#ifndef NDEBUG
  int64 starting_cycles = CycleClock::Now();
#endif

  // Get the time before starting snapshot.
  // TODO(dmikurube): Consider gettimeofday if available.
  time_t time_value = time(NULL);

  ++dump_count_;

  // Re-open files in /proc/pid/ if the process is newly forked one.
  if (most_recent_pid_ != getpid()) {
    char hostname[64];
    if (0 == gethostname(hostname, sizeof(hostname))) {
      char* dot = strchr(hostname, '.');
      if (dot != NULL)
        *dot = '\0';
    } else {
      strcpy(hostname, "unknown");
    }

    most_recent_pid_ = getpid();

    snprintf(run_id_, sizeof(run_id_), "%s-" OS_NAME "-%d-%lu",
             hostname, most_recent_pid_, time(NULL));

    if (memory_residence_info_getter_)
      memory_residence_info_getter_->Initialize();
    deep_table_.ResetIsLogged();

    // Write maps into "|filename_prefix_|.<pid>.maps".
    WriteProcMaps(filename_prefix_, raw_buffer, buffer_size);
  }

  // Reset committed sizes of buckets.
  deep_table_.ResetCommittedSize();

  // Record committed sizes.
  stats_.SnapshotAllocations(this);

  // TODO(dmikurube): Eliminate dynamic memory allocation caused by snprintf.
  // glibc's snprintf internally allocates memory by alloca normally, but it
  // allocates memory by malloc if large memory is required.

  buffer.AppendString(kProfileHeader, 0);
  buffer.AppendString(kProfileVersion, 0);
  buffer.AppendString("\n", 0);

  // Fill buffer with meta information.
  buffer.AppendString(kMetaInformationHeader, 0);

  buffer.AppendString("Time: ", 0);
  buffer.AppendUnsignedLong(time_value, 0);
  buffer.AppendChar('\n');

  if (reason != NULL) {
    buffer.AppendString("Reason: ", 0);
    buffer.AppendString(reason, 0);
    buffer.AppendChar('\n');
  }

  AppendCommandLine(&buffer);

  buffer.AppendString("RunID: ", 0);
  buffer.AppendString(run_id_, 0);
  buffer.AppendChar('\n');

  buffer.AppendString("PageSize: ", 0);
  buffer.AppendInt(getpagesize(), 0, 0);
  buffer.AppendChar('\n');

  // Assumes the physical memory <= 64GB (PFN < 2^24).
  if (pageframe_type_ == DUMP_PAGECOUNT && memory_residence_info_getter_ &&
      memory_residence_info_getter_->IsPageCountAvailable()) {
    buffer.AppendString("PageFrame: 24,Base64,PageCount", 0);
    buffer.AppendChar('\n');
  } else if (pageframe_type_ != DUMP_NO_PAGEFRAME) {
    buffer.AppendString("PageFrame: 24,Base64", 0);
    buffer.AppendChar('\n');
  }

  // Fill buffer with the global stats.
  buffer.AppendString(kMMapListHeader, 0);

  stats_.SnapshotMaps(memory_residence_info_getter_, this, &buffer);

  // Fill buffer with the global stats.
  buffer.AppendString(kGlobalStatsHeader, 0);

  stats_.Unparse(&buffer);

  buffer.AppendString(kStacktraceHeader, 0);
  buffer.AppendString(kVirtualLabel, 10);
  buffer.AppendChar(' ');
  buffer.AppendString(kCommittedLabel, 10);
  buffer.AppendString("\n", 0);

  // Fill buffer.
  deep_table_.UnparseForStats(&buffer);

  buffer.Flush();

  // Write the bucket listing into a .bucket file.
  deep_table_.WriteForBucketFile(
      filename_prefix_, dump_count_, raw_buffer, buffer_size);

#ifndef NDEBUG
  int64 elapsed_cycles = CycleClock::Now() - starting_cycles;
  double elapsed_seconds = elapsed_cycles / CyclesPerSecond();
  RAW_VLOG(0, "Time spent on DeepProfiler: %.3f sec\n", elapsed_seconds);
#endif
}

int DeepHeapProfile::TextBuffer::Size() {
  return size_;
}

int DeepHeapProfile::TextBuffer::FilledBytes() {
  return cursor_;
}

void DeepHeapProfile::TextBuffer::Clear() {
  cursor_ = 0;
}

void DeepHeapProfile::TextBuffer::Flush() {
  RawWrite(fd_, buffer_, cursor_);
  cursor_ = 0;
}

// TODO(dmikurube): These Append* functions should not use snprintf.
bool DeepHeapProfile::TextBuffer::AppendChar(char value) {
  return ForwardCursor(snprintf(buffer_ + cursor_, size_ - cursor_,
                                "%c", value));
}

bool DeepHeapProfile::TextBuffer::AppendString(const char* value, int width) {
  char* position = buffer_ + cursor_;
  int available = size_ - cursor_;
  int appended;
  if (width == 0)
    appended = snprintf(position, available, "%s", value);
  else
    appended = snprintf(position, available, "%*s",
                        width, value);
  return ForwardCursor(appended);
}

bool DeepHeapProfile::TextBuffer::AppendInt(int value, int width,
                                            bool leading_zero) {
  char* position = buffer_ + cursor_;
  int available = size_ - cursor_;
  int appended;
  if (width == 0)
    appended = snprintf(position, available, "%d", value);
  else if (leading_zero)
    appended = snprintf(position, available, "%0*d", width, value);
  else
    appended = snprintf(position, available, "%*d", width, value);
  return ForwardCursor(appended);
}

bool DeepHeapProfile::TextBuffer::AppendLong(long value, int width) {
  char* position = buffer_ + cursor_;
  int available = size_ - cursor_;
  int appended;
  if (width == 0)
    appended = snprintf(position, available, "%ld", value);
  else
    appended = snprintf(position, available, "%*ld", width, value);
  return ForwardCursor(appended);
}

bool DeepHeapProfile::TextBuffer::AppendUnsignedLong(unsigned long value,
                                                     int width) {
  char* position = buffer_ + cursor_;
  int available = size_ - cursor_;
  int appended;
  if (width == 0)
    appended = snprintf(position, available, "%lu", value);
  else
    appended = snprintf(position, available, "%*lu", width, value);
  return ForwardCursor(appended);
}

bool DeepHeapProfile::TextBuffer::AppendInt64(int64 value, int width) {
  char* position = buffer_ + cursor_;
  int available = size_ - cursor_;
  int appended;
  if (width == 0)
    appended = snprintf(position, available, "%" PRId64, value);
  else
    appended = snprintf(position, available, "%*" PRId64, width, value);
  return ForwardCursor(appended);
}

bool DeepHeapProfile::TextBuffer::AppendPtr(uint64 value, int width) {
  char* position = buffer_ + cursor_;
  int available = size_ - cursor_;
  int appended;
  if (width == 0)
    appended = snprintf(position, available, "%" PRIx64, value);
  else
    appended = snprintf(position, available, "%0*" PRIx64, width, value);
  return ForwardCursor(appended);
}

bool DeepHeapProfile::TextBuffer::AppendBase64(uint64 value, int width) {
  static const char base64[65] =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
#if defined(__BIG_ENDIAN__)
  value = bswap_64(value);
#endif
  for (int shift = (width - 1) * 6; shift >= 0; shift -= 6) {
    if (!AppendChar(base64[(value >> shift) & 0x3f]))
      return false;
  }
  return true;
}

bool DeepHeapProfile::TextBuffer::ForwardCursor(int appended) {
  if (appended < 0 || appended >= size_ - cursor_)
    return false;
  cursor_ += appended;
  if (cursor_ > size_ * 4 / 5)
    Flush();
  return true;
}

void DeepHeapProfile::DeepBucket::UnparseForStats(TextBuffer* buffer) {
  buffer->AppendInt64(bucket->alloc_size - bucket->free_size, 10);
  buffer->AppendChar(' ');
  buffer->AppendInt64(committed_size, 10);
  buffer->AppendChar(' ');
  buffer->AppendInt(bucket->allocs, 6, false);
  buffer->AppendChar(' ');
  buffer->AppendInt(bucket->frees, 6, false);
  buffer->AppendString(" @ ", 0);
  buffer->AppendInt(id, 0, false);
  buffer->AppendString("\n", 0);
}

void DeepHeapProfile::DeepBucket::UnparseForBucketFile(TextBuffer* buffer) {
  buffer->AppendInt(id, 0, false);
  buffer->AppendChar(' ');
  buffer->AppendString(is_mmap ? "mmap" : "malloc", 0);

#if defined(TYPE_PROFILING)
  buffer->AppendString(" t0x", 0);
  buffer->AppendPtr(reinterpret_cast<uintptr_t>(type), 0);
  if (type == NULL) {
    buffer->AppendString(" nno_typeinfo", 0);
  } else {
    buffer->AppendString(" n", 0);
    buffer->AppendString(type->name(), 0);
  }
#endif

  for (int depth = 0; depth < bucket->depth; depth++) {
    buffer->AppendString(" 0x", 0);
    buffer->AppendPtr(reinterpret_cast<uintptr_t>(bucket->stack[depth]), 8);
  }
  buffer->AppendString("\n", 0);
}

DeepHeapProfile::DeepBucketTable::DeepBucketTable(
    int table_size,
    HeapProfileTable::Allocator alloc,
    HeapProfileTable::DeAllocator dealloc)
    : table_(NULL),
      table_size_(table_size),
      alloc_(alloc),
      dealloc_(dealloc),
      bucket_id_(0) {
  const int bytes = table_size * sizeof(DeepBucket*);
  table_ = reinterpret_cast<DeepBucket**>(alloc(bytes));
  memset(table_, 0, bytes);
}

DeepHeapProfile::DeepBucketTable::~DeepBucketTable() {
  ASSERT(table_ != NULL);
  for (int db = 0; db < table_size_; db++) {
    for (DeepBucket* x = table_[db]; x != 0; /**/) {
      DeepBucket* db = x;
      x = x->next;
      dealloc_(db);
    }
  }
  dealloc_(table_);
}

DeepHeapProfile::DeepBucket* DeepHeapProfile::DeepBucketTable::Lookup(
    Bucket* bucket,
#if defined(TYPE_PROFILING)
    const std::type_info* type,
#endif
    bool is_mmap) {
  // Make hash-value
  uintptr_t h = 0;

  AddToHashValue(reinterpret_cast<uintptr_t>(bucket), &h);
  if (is_mmap) {
    AddToHashValue(1, &h);
  } else {
    AddToHashValue(0, &h);
  }

#if defined(TYPE_PROFILING)
  if (type == NULL) {
    AddToHashValue(0, &h);
  } else {
    AddToHashValue(reinterpret_cast<uintptr_t>(type->name()), &h);
  }
#endif

  FinishHashValue(&h);

  // Lookup stack trace in table
  unsigned int buck = ((unsigned int) h) % table_size_;
  for (DeepBucket* db = table_[buck]; db != 0; db = db->next) {
    if (db->bucket == bucket) {
      return db;
    }
  }

  // Create a new bucket
  DeepBucket* db = reinterpret_cast<DeepBucket*>(alloc_(sizeof(DeepBucket)));
  memset(db, 0, sizeof(*db));
  db->bucket         = bucket;
#if defined(TYPE_PROFILING)
  db->type           = type;
#endif
  db->committed_size = 0;
  db->is_mmap        = is_mmap;
  db->id             = (bucket_id_++);
  db->is_logged      = false;
  db->next           = table_[buck];
  table_[buck] = db;
  return db;
}

// TODO(dmikurube): Eliminate dynamic memory allocation caused by snprintf.
void DeepHeapProfile::DeepBucketTable::UnparseForStats(TextBuffer* buffer) {
  for (int i = 0; i < table_size_; i++) {
    for (DeepBucket* deep_bucket = table_[i];
         deep_bucket != NULL;
         deep_bucket = deep_bucket->next) {
      Bucket* bucket = deep_bucket->bucket;
      if (bucket->alloc_size - bucket->free_size == 0) {
        continue;  // Skip empty buckets.
      }
      deep_bucket->UnparseForStats(buffer);
    }
  }
}

void DeepHeapProfile::DeepBucketTable::WriteForBucketFile(
    const char* prefix, int dump_count, char raw_buffer[], int buffer_size) {
  char filename[100];
  snprintf(filename, sizeof(filename),
           "%s.%05d.%04d.buckets", prefix, getpid(), dump_count);
  RawFD fd = RawOpenForWriting(filename);
  RAW_DCHECK(fd != kIllegalRawFD, "");

  TextBuffer buffer(raw_buffer, buffer_size, fd);

  for (int i = 0; i < table_size_; i++) {
    for (DeepBucket* deep_bucket = table_[i];
         deep_bucket != NULL;
         deep_bucket = deep_bucket->next) {
      Bucket* bucket = deep_bucket->bucket;
      if (deep_bucket->is_logged) {
        continue;  // Skip the bucket if it is already logged.
      }
      if (!deep_bucket->is_mmap &&
          bucket->alloc_size - bucket->free_size <= 64) {
        continue;  // Skip small malloc buckets.
      }

      deep_bucket->UnparseForBucketFile(&buffer);
      deep_bucket->is_logged = true;
    }
  }

  buffer.Flush();
  RawClose(fd);
}

void DeepHeapProfile::DeepBucketTable::ResetCommittedSize() {
  for (int i = 0; i < table_size_; i++) {
    for (DeepBucket* deep_bucket = table_[i];
         deep_bucket != NULL;
         deep_bucket = deep_bucket->next) {
      deep_bucket->committed_size = 0;
    }
  }
}

void DeepHeapProfile::DeepBucketTable::ResetIsLogged() {
  for (int i = 0; i < table_size_; i++) {
    for (DeepBucket* deep_bucket = table_[i];
         deep_bucket != NULL;
         deep_bucket = deep_bucket->next) {
      deep_bucket->is_logged = false;
    }
  }
}

// This hash function is from HeapProfileTable::GetBucket.
// static
void DeepHeapProfile::DeepBucketTable::AddToHashValue(
    uintptr_t add, uintptr_t* hash_value) {
  *hash_value += add;
  *hash_value += *hash_value << 10;
  *hash_value ^= *hash_value >> 6;
}

// This hash function is from HeapProfileTable::GetBucket.
// static
void DeepHeapProfile::DeepBucketTable::FinishHashValue(uintptr_t* hash_value) {
  *hash_value += *hash_value << 3;
  *hash_value ^= *hash_value >> 11;
}

void DeepHeapProfile::RegionStats::Initialize() {
  virtual_bytes_ = 0;
  committed_bytes_ = 0;
}

uint64 DeepHeapProfile::RegionStats::Record(
    const MemoryResidenceInfoGetterInterface* memory_residence_info_getter,
    uint64 first_address,
    uint64 last_address,
    TextBuffer* buffer) {
  uint64 committed = 0;
  virtual_bytes_ += static_cast<size_t>(last_address - first_address + 1);
  if (memory_residence_info_getter)
    committed = memory_residence_info_getter->CommittedSize(first_address,
                                                            last_address,
                                                            buffer);
  committed_bytes_ += committed;
  return committed;
}

void DeepHeapProfile::RegionStats::Unparse(const char* name,
                                           TextBuffer* buffer) {
  buffer->AppendString(name, 25);
  buffer->AppendChar(' ');
  buffer->AppendLong(virtual_bytes_, 12);
  buffer->AppendChar(' ');
  buffer->AppendLong(committed_bytes_, 12);
  buffer->AppendString("\n", 0);
}

// Snapshots all virtual memory mapping stats by merging mmap(2) records from
// MemoryRegionMap and /proc/maps, the OS-level memory mapping information.
// Memory regions described in /proc/maps, but which are not created by mmap,
// are accounted as "unhooked" memory regions.
//
// This function assumes that every memory region created by mmap is covered
// by VMA(s) described in /proc/maps except for http://crbug.com/189114.
// Note that memory regions created with mmap don't align with borders of VMAs
// in /proc/maps.  In other words, a memory region by mmap can cut across many
// VMAs.  Also, of course a VMA can include many memory regions by mmap.
// It means that the following situation happens:
//
// => Virtual address
// <----- VMA #1 -----><----- VMA #2 ----->...<----- VMA #3 -----><- VMA #4 ->
// ..< mmap #1 >.<- mmap #2 -><- mmap #3 ->...<- mmap #4 ->..<-- mmap #5 -->..
//
// It can happen easily as permission can be changed by mprotect(2) for a part
// of a memory region.  A change in permission splits VMA(s).
//
// To deal with the situation, this function iterates over MemoryRegionMap and
// /proc/maps independently.  The iterator for MemoryRegionMap is initialized
// at the top outside the loop for /proc/maps, and it goes forward inside the
// loop while comparing their addresses.
//
// TODO(dmikurube): Eliminate dynamic memory allocation caused by snprintf.
void DeepHeapProfile::GlobalStats::SnapshotMaps(
    const MemoryResidenceInfoGetterInterface* memory_residence_info_getter,
    DeepHeapProfile* deep_profile,
    TextBuffer* mmap_dump_buffer) {
  MemoryRegionMap::LockHolder lock_holder;
  ProcMapsIterator::Buffer procmaps_iter_buffer;
  ProcMapsIterator procmaps_iter(0, &procmaps_iter_buffer);
  uint64 vma_start_addr, vma_last_addr, offset;
  int64 inode;
  char* flags;
  char* filename;
  enum MapsRegionType type;

  for (int i = 0; i < NUMBER_OF_MAPS_REGION_TYPES; ++i) {
    all_[i].Initialize();
    unhooked_[i].Initialize();
  }
  profiled_mmap_.Initialize();

  MemoryRegionMap::RegionIterator mmap_iter =
      MemoryRegionMap::BeginRegionLocked();
  DeepBucket* deep_bucket = NULL;
  if (mmap_iter != MemoryRegionMap::EndRegionLocked()) {
    deep_bucket = GetInformationOfMemoryRegion(
        mmap_iter, memory_residence_info_getter, deep_profile);
  }

  while (procmaps_iter.Next(&vma_start_addr, &vma_last_addr,
                            &flags, &offset, &inode, &filename)) {
    if (mmap_dump_buffer) {
      char buffer[1024];
      int written = procmaps_iter.FormatLine(buffer, sizeof(buffer),
                                             vma_start_addr, vma_last_addr,
                                             flags, offset, inode, filename, 0);
      mmap_dump_buffer->AppendString(buffer, 0);
    }

    // 'vma_last_addr' should be the last inclusive address of the region.
    vma_last_addr -= 1;
    if (strcmp("[vsyscall]", filename) == 0) {
      continue;  // Reading pagemap will fail in [vsyscall].
    }

    // TODO(dmikurube): |type| will be deprecated in the dump.
    // See http://crbug.com/245603.
    type = ABSENT;
    if (filename[0] == '/') {
      if (flags[2] == 'x')
        type = FILE_EXEC;
      else
        type = FILE_NONEXEC;
    } else if (filename[0] == '\0' || filename[0] == '\n') {
      type = ANONYMOUS;
    } else if (strcmp(filename, "[stack]") == 0) {
      type = STACK;
    } else {
      type = OTHER;
    }
    // TODO(dmikurube): This |all_| count should be removed in future soon.
    // See http://crbug.com/245603.
    uint64 vma_total = all_[type].Record(
        memory_residence_info_getter, vma_start_addr, vma_last_addr, NULL);
    uint64 vma_subtotal = 0;

    // TODO(dmikurube): Stop double-counting pagemap.
    // It will be fixed when http://crbug.com/245603 finishes.
    if (MemoryRegionMap::IsRecordingLocked()) {
      uint64 cursor = vma_start_addr;
      bool first = true;

      // Iterates over MemoryRegionMap until the iterator moves out of the VMA.
      do {
        if (!first) {
          cursor = mmap_iter->end_addr;
          ++mmap_iter;
          // Don't break here even if mmap_iter == EndRegionLocked().

          if (mmap_iter != MemoryRegionMap::EndRegionLocked()) {
            deep_bucket = GetInformationOfMemoryRegion(
                mmap_iter, memory_residence_info_getter, deep_profile);
          }
        }
        first = false;

        uint64 last_address_of_unhooked;
        // If the next mmap entry is away from the current VMA.
        if (mmap_iter == MemoryRegionMap::EndRegionLocked() ||
            mmap_iter->start_addr > vma_last_addr) {
          last_address_of_unhooked = vma_last_addr;
        } else {
          last_address_of_unhooked = mmap_iter->start_addr - 1;
        }

        if (last_address_of_unhooked + 1 > cursor) {
          RAW_CHECK(cursor >= vma_start_addr,
                    "Wrong calculation for unhooked");
          RAW_CHECK(last_address_of_unhooked <= vma_last_addr,
                    "Wrong calculation for unhooked");
          uint64 committed_size = unhooked_[type].Record(
              memory_residence_info_getter,
              cursor,
              last_address_of_unhooked,
              mmap_dump_buffer);
          vma_subtotal += committed_size;
          if (mmap_dump_buffer) {
            mmap_dump_buffer->AppendString("  ", 0);
            mmap_dump_buffer->AppendPtr(cursor, 0);
            mmap_dump_buffer->AppendString(" - ", 0);
            mmap_dump_buffer->AppendPtr(last_address_of_unhooked + 1, 0);
            mmap_dump_buffer->AppendString("  unhooked ", 0);
            mmap_dump_buffer->AppendInt64(committed_size, 0);
            mmap_dump_buffer->AppendString(" / ", 0);
            mmap_dump_buffer->AppendInt64(
                last_address_of_unhooked - cursor + 1, 0);
            mmap_dump_buffer->AppendString("\n", 0);
          }
          cursor = last_address_of_unhooked + 1;
        }

        if (mmap_iter != MemoryRegionMap::EndRegionLocked() &&
            mmap_iter->start_addr <= vma_last_addr &&
            mmap_dump_buffer) {
          bool trailing = mmap_iter->start_addr < vma_start_addr;
          bool continued = mmap_iter->end_addr - 1 > vma_last_addr;
          uint64 partial_first_address, partial_last_address;
          if (trailing)
            partial_first_address = vma_start_addr;
          else
            partial_first_address = mmap_iter->start_addr;
          if (continued)
            partial_last_address = vma_last_addr;
          else
            partial_last_address = mmap_iter->end_addr - 1;
          uint64 committed_size = 0;
          if (memory_residence_info_getter)
            committed_size = memory_residence_info_getter->CommittedSize(
                partial_first_address, partial_last_address, mmap_dump_buffer);
          vma_subtotal += committed_size;
          mmap_dump_buffer->AppendString(trailing ? " (" : "  ", 0);
          mmap_dump_buffer->AppendPtr(mmap_iter->start_addr, 0);
          mmap_dump_buffer->AppendString(trailing ? ")" : " ", 0);
          mmap_dump_buffer->AppendString("-", 0);
          mmap_dump_buffer->AppendString(continued ? "(" : " ", 0);
          mmap_dump_buffer->AppendPtr(mmap_iter->end_addr, 0);
          mmap_dump_buffer->AppendString(continued ? ")" : " ", 0);
          mmap_dump_buffer->AppendString(" hooked ", 0);
          mmap_dump_buffer->AppendInt64(committed_size, 0);
          mmap_dump_buffer->AppendString(" / ", 0);
          mmap_dump_buffer->AppendInt64(
              partial_last_address - partial_first_address + 1, 0);
          mmap_dump_buffer->AppendString(" @ ", 0);
          if (deep_bucket != NULL) {
            mmap_dump_buffer->AppendInt(deep_bucket->id, 0, false);
          } else {
            mmap_dump_buffer->AppendInt(0, 0, false);
          }
          mmap_dump_buffer->AppendString("\n", 0);
        }
      } while (mmap_iter != MemoryRegionMap::EndRegionLocked() &&
               mmap_iter->end_addr - 1 <= vma_last_addr);
    }

    if (vma_total != vma_subtotal) {
      char buffer[1024];
      int written = procmaps_iter.FormatLine(buffer, sizeof(buffer),
                                             vma_start_addr, vma_last_addr,
                                             flags, offset, inode, filename, 0);
      RAW_VLOG(0, "[%d] Mismatched total in VMA %" PRId64 ":"
              "%" PRId64 " (%" PRId64 ")",
              getpid(), vma_total, vma_subtotal, vma_total - vma_subtotal);
      RAW_VLOG(0, "[%d]   in %s", getpid(), buffer);
    }
  }

  // TODO(dmikurube): Investigate and fix http://crbug.com/189114.
  //
  // The total committed memory usage in all_ (from /proc/<pid>/maps) is
  // sometimes smaller than the sum of the committed mmap'ed addresses and
  // unhooked regions.  Within our observation, the difference was only 4KB
  // in committed usage, zero in reserved virtual addresses
  //
  // A guess is that an uncommitted (but reserved) page may become committed
  // during counting memory usage in the loop above.
  //
  // The difference is accounted as "ABSENT" to investigate such cases.
  //
  // It will be fixed when http://crbug.com/245603 finishes (no double count).

  RegionStats all_total;
  RegionStats unhooked_total;
  for (int i = 0; i < NUMBER_OF_MAPS_REGION_TYPES; ++i) {
    all_total.AddAnotherRegionStat(all_[i]);
    unhooked_total.AddAnotherRegionStat(unhooked_[i]);
  }

  size_t absent_virtual = profiled_mmap_.virtual_bytes() +
                          unhooked_total.virtual_bytes() -
                          all_total.virtual_bytes();
  if (absent_virtual > 0)
    all_[ABSENT].AddToVirtualBytes(absent_virtual);

  size_t absent_committed = profiled_mmap_.committed_bytes() +
                            unhooked_total.committed_bytes() -
                            all_total.committed_bytes();
  if (absent_committed > 0)
    all_[ABSENT].AddToCommittedBytes(absent_committed);
}

void DeepHeapProfile::GlobalStats::SnapshotAllocations(
    DeepHeapProfile* deep_profile) {
  profiled_malloc_.Initialize();

  deep_profile->heap_profile_->address_map_->Iterate(RecordAlloc, deep_profile);
}

void DeepHeapProfile::GlobalStats::Unparse(TextBuffer* buffer) {
  RegionStats all_total;
  RegionStats unhooked_total;
  for (int i = 0; i < NUMBER_OF_MAPS_REGION_TYPES; ++i) {
    all_total.AddAnotherRegionStat(all_[i]);
    unhooked_total.AddAnotherRegionStat(unhooked_[i]);
  }

  // "# total (%lu) %c= profiled-mmap (%lu) + nonprofiled-* (%lu)\n"
  buffer->AppendString("# total (", 0);
  buffer->AppendUnsignedLong(all_total.committed_bytes(), 0);
  buffer->AppendString(") ", 0);
  buffer->AppendChar(all_total.committed_bytes() ==
                     profiled_mmap_.committed_bytes() +
                     unhooked_total.committed_bytes() ? '=' : '!');
  buffer->AppendString("= profiled-mmap (", 0);
  buffer->AppendUnsignedLong(profiled_mmap_.committed_bytes(), 0);
  buffer->AppendString(") + nonprofiled-* (", 0);
  buffer->AppendUnsignedLong(unhooked_total.committed_bytes(), 0);
  buffer->AppendString(")\n", 0);

  // "                               virtual    committed"
  buffer->AppendString("", 26);
  buffer->AppendString(kVirtualLabel, 12);
  buffer->AppendChar(' ');
  buffer->AppendString(kCommittedLabel, 12);
  buffer->AppendString("\n", 0);

  all_total.Unparse("total", buffer);
  all_[ABSENT].Unparse("absent", buffer);
  all_[FILE_EXEC].Unparse("file-exec", buffer);
  all_[FILE_NONEXEC].Unparse("file-nonexec", buffer);
  all_[ANONYMOUS].Unparse("anonymous", buffer);
  all_[STACK].Unparse("stack", buffer);
  all_[OTHER].Unparse("other", buffer);
  unhooked_total.Unparse("nonprofiled-total", buffer);
  unhooked_[ABSENT].Unparse("nonprofiled-absent", buffer);
  unhooked_[ANONYMOUS].Unparse("nonprofiled-anonymous", buffer);
  unhooked_[FILE_EXEC].Unparse("nonprofiled-file-exec", buffer);
  unhooked_[FILE_NONEXEC].Unparse("nonprofiled-file-nonexec", buffer);
  unhooked_[STACK].Unparse("nonprofiled-stack", buffer);
  unhooked_[OTHER].Unparse("nonprofiled-other", buffer);
  profiled_mmap_.Unparse("profiled-mmap", buffer);
  profiled_malloc_.Unparse("profiled-malloc", buffer);
}

// static
void DeepHeapProfile::GlobalStats::RecordAlloc(const void* pointer,
                                               AllocValue* alloc_value,
                                               DeepHeapProfile* deep_profile) {
  uint64 address = reinterpret_cast<uintptr_t>(pointer);
  size_t committed = deep_profile->memory_residence_info_getter_->CommittedSize(
      address, address + alloc_value->bytes - 1, NULL);

  DeepBucket* deep_bucket = deep_profile->deep_table_.Lookup(
      alloc_value->bucket(),
#if defined(TYPE_PROFILING)
      LookupType(pointer),
#endif
      /* is_mmap */ false);
  deep_bucket->committed_size += committed;
  deep_profile->stats_.profiled_malloc_.AddToVirtualBytes(alloc_value->bytes);
  deep_profile->stats_.profiled_malloc_.AddToCommittedBytes(committed);
}

DeepHeapProfile::DeepBucket*
    DeepHeapProfile::GlobalStats::GetInformationOfMemoryRegion(
        const MemoryRegionMap::RegionIterator& mmap_iter,
        const MemoryResidenceInfoGetterInterface* memory_residence_info_getter,
        DeepHeapProfile* deep_profile) {
  size_t committed = deep_profile->memory_residence_info_getter_->
      CommittedSize(mmap_iter->start_addr, mmap_iter->end_addr - 1, NULL);

  // TODO(dmikurube): Store a reference to the bucket in region.
  Bucket* bucket = MemoryRegionMap::GetBucket(
      mmap_iter->call_stack_depth, mmap_iter->call_stack);
  DeepBucket* deep_bucket = NULL;
  if (bucket != NULL) {
    deep_bucket = deep_profile->deep_table_.Lookup(
        bucket,
#if defined(TYPE_PROFILING)
        NULL,  // No type information for memory regions by mmap.
#endif
        /* is_mmap */ true);
    if (deep_bucket != NULL)
      deep_bucket->committed_size += committed;
  }

  profiled_mmap_.AddToVirtualBytes(
      mmap_iter->end_addr - mmap_iter->start_addr);
  profiled_mmap_.AddToCommittedBytes(committed);

  return deep_bucket;
}

// static
void DeepHeapProfile::WriteProcMaps(const char* prefix,
                                    char raw_buffer[],
                                    int buffer_size) {
  char filename[100];
  snprintf(filename, sizeof(filename),
           "%s.%05d.maps", prefix, static_cast<int>(getpid()));

  RawFD fd = RawOpenForWriting(filename);
  RAW_DCHECK(fd != kIllegalRawFD, "");

  int length;
  bool wrote_all;
  length = tcmalloc::FillProcSelfMaps(raw_buffer, buffer_size, &wrote_all);
  RAW_DCHECK(wrote_all, "");
  RAW_DCHECK(length <= buffer_size, "");
  RawWrite(fd, raw_buffer, length);
  RawClose(fd);
}
#else  // USE_DEEP_HEAP_PROFILE

DeepHeapProfile::DeepHeapProfile(HeapProfileTable* heap_profile,
                                 const char* prefix,
                                 enum PageFrameType pageframe_type)
    : heap_profile_(heap_profile) {
}

DeepHeapProfile::~DeepHeapProfile() {
}

void DeepHeapProfile::DumpOrderedProfile(const char* reason,
                                         char raw_buffer[],
                                         int buffer_size,
                                         RawFD fd) {
}

#endif  // USE_DEEP_HEAP_PROFILE
