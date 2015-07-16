// Copyright (c) 2006, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Sanjay Ghemawat
//         Maxim Lifantsev (refactoring)
//

#include <config.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>   // for write()
#endif
#include <fcntl.h>    // for open()
#ifdef HAVE_GLOB_H
#include <glob.h>
#ifndef GLOB_NOMATCH  // true on some old cygwins
# define GLOB_NOMATCH 0
#endif
#endif
#ifdef HAVE_INTTYPES_H
#include <inttypes.h> // for PRIxPTR
#endif
#ifdef HAVE_POLL_H
#include <poll.h>
#endif
#include <errno.h>
#include <stdarg.h>
#include <string>
#include <map>
#include <algorithm>  // for sort(), equal(), and copy()

#include "heap-profile-table.h"

#include "base/logging.h"
#include "raw_printer.h"
#include "symbolize.h"
#include <gperftools/stacktrace.h>
#include <gperftools/malloc_hook.h>
#include "memory_region_map.h"
#include "base/commandlineflags.h"
#include "base/logging.h"    // for the RawFD I/O commands
#include "base/sysinfo.h"

using std::sort;
using std::equal;
using std::copy;
using std::string;
using std::map;

using tcmalloc::FillProcSelfMaps;   // from sysinfo.h
using tcmalloc::DumpProcSelfMaps;   // from sysinfo.h

//----------------------------------------------------------------------

DEFINE_bool(cleanup_old_heap_profiles,
            EnvToBool("HEAP_PROFILE_CLEANUP", true),
            "At initialization time, delete old heap profiles.");

DEFINE_int32(heap_check_max_leaks,
             EnvToInt("HEAP_CHECK_MAX_LEAKS", 20),
             "The maximum number of leak reports to print.");

//----------------------------------------------------------------------

// header of the dumped heap profile
static const char kProfileHeader[] = "heap profile: ";
static const char kProcSelfMapsHeader[] = "\nMAPPED_LIBRARIES:\n";
#if defined(TYPE_PROFILING)
static const char kTypeProfileStatsHeader[] = "type statistics:\n";
#endif  // defined(TYPE_PROFILING)

//----------------------------------------------------------------------

const char HeapProfileTable::kFileExt[] = ".heap";

//----------------------------------------------------------------------

static const int kHashTableSize = 179999;   // Size for bucket_table_.
// GCC requires this declaration, but MSVC does not allow it.
#if !defined(COMPILER_MSVC)
/*static*/ const int HeapProfileTable::kMaxStackDepth;
#endif

//----------------------------------------------------------------------

// We strip out different number of stack frames in debug mode
// because less inlining happens in that case
#ifdef NDEBUG
static const int kStripFrames = 2;
#else
static const int kStripFrames = 3;
#endif

// For sorting Stats or Buckets by in-use space
static bool ByAllocatedSpace(HeapProfileTable::Stats* a,
                             HeapProfileTable::Stats* b) {
  // Return true iff "a" has more allocated space than "b"
  return (a->alloc_size - a->free_size) > (b->alloc_size - b->free_size);
}

//----------------------------------------------------------------------

HeapProfileTable::HeapProfileTable(Allocator alloc,
                                   DeAllocator dealloc,
                                   bool profile_mmap)
    : alloc_(alloc),
      dealloc_(dealloc),
      bucket_table_(NULL),
      profile_mmap_(profile_mmap),
      num_buckets_(0),
      address_map_(NULL) {
  // Make a hash table for buckets.
  const int table_bytes = kHashTableSize * sizeof(*bucket_table_);
  bucket_table_ = static_cast<Bucket**>(alloc_(table_bytes));
  memset(bucket_table_, 0, table_bytes);

  // Make an allocation map.
  address_map_ =
      new(alloc_(sizeof(AllocationMap))) AllocationMap(alloc_, dealloc_);

  // Initialize.
  memset(&total_, 0, sizeof(total_));
  num_buckets_ = 0;
}

HeapProfileTable::~HeapProfileTable() {
  // Free the allocation map.
  address_map_->~AllocationMap();
  dealloc_(address_map_);
  address_map_ = NULL;

  // Free the hash table.
  for (int i = 0; i < kHashTableSize; i++) {
    for (Bucket* curr = bucket_table_[i]; curr != 0; /**/) {
      Bucket* bucket = curr;
      curr = curr->next;
      dealloc_(bucket->stack);
      dealloc_(bucket);
    }
  }
  dealloc_(bucket_table_);
  bucket_table_ = NULL;
}

HeapProfileTable::Bucket* HeapProfileTable::GetBucket(int depth,
                                                      const void* const key[]) {
  // Make hash-value
  uintptr_t h = 0;
  for (int i = 0; i < depth; i++) {
    h += reinterpret_cast<uintptr_t>(key[i]);
    h += h << 10;
    h ^= h >> 6;
  }
  h += h << 3;
  h ^= h >> 11;

  // Lookup stack trace in table
  unsigned int buck = ((unsigned int) h) % kHashTableSize;
  for (Bucket* b = bucket_table_[buck]; b != 0; b = b->next) {
    if ((b->hash == h) &&
        (b->depth == depth) &&
        equal(key, key + depth, b->stack)) {
      return b;
    }
  }

  // Create new bucket
  const size_t key_size = sizeof(key[0]) * depth;
  const void** kcopy = reinterpret_cast<const void**>(alloc_(key_size));
  copy(key, key + depth, kcopy);
  Bucket* b = reinterpret_cast<Bucket*>(alloc_(sizeof(Bucket)));
  memset(b, 0, sizeof(*b));
  b->hash  = h;
  b->depth = depth;
  b->stack = kcopy;
  b->next  = bucket_table_[buck];
  bucket_table_[buck] = b;
  num_buckets_++;
  return b;
}

int HeapProfileTable::GetCallerStackTrace(
    int skip_count, void* stack[kMaxStackDepth]) {
  return MallocHook::GetCallerStackTrace(
      stack, kMaxStackDepth, kStripFrames + skip_count + 1);
}

void HeapProfileTable::RecordAlloc(
    const void* ptr, size_t bytes, int stack_depth,
    const void* const call_stack[]) {
  Bucket* b = GetBucket(stack_depth, call_stack);
  b->allocs++;
  b->alloc_size += bytes;
  total_.allocs++;
  total_.alloc_size += bytes;

  AllocValue v;
  v.set_bucket(b);  // also did set_live(false); set_ignore(false)
  v.bytes = bytes;
  address_map_->Insert(ptr, v);
}

void HeapProfileTable::RecordFree(const void* ptr) {
  AllocValue v;
  if (address_map_->FindAndRemove(ptr, &v)) {
    Bucket* b = v.bucket();
    b->frees++;
    b->free_size += v.bytes;
    total_.frees++;
    total_.free_size += v.bytes;
  }
}

bool HeapProfileTable::FindAlloc(const void* ptr, size_t* object_size) const {
  const AllocValue* alloc_value = address_map_->Find(ptr);
  if (alloc_value != NULL) *object_size = alloc_value->bytes;
  return alloc_value != NULL;
}

bool HeapProfileTable::FindAllocDetails(const void* ptr,
                                        AllocInfo* info) const {
  const AllocValue* alloc_value = address_map_->Find(ptr);
  if (alloc_value != NULL) {
    info->object_size = alloc_value->bytes;
    info->call_stack = alloc_value->bucket()->stack;
    info->stack_depth = alloc_value->bucket()->depth;
  }
  return alloc_value != NULL;
}

bool HeapProfileTable::FindInsideAlloc(const void* ptr,
                                       size_t max_size,
                                       const void** object_ptr,
                                       size_t* object_size) const {
  const AllocValue* alloc_value =
    address_map_->FindInside(&AllocValueSize, max_size, ptr, object_ptr);
  if (alloc_value != NULL) *object_size = alloc_value->bytes;
  return alloc_value != NULL;
}

bool HeapProfileTable::MarkAsLive(const void* ptr) {
  AllocValue* alloc = address_map_->FindMutable(ptr);
  if (alloc && !alloc->live()) {
    alloc->set_live(true);
    return true;
  }
  return false;
}

void HeapProfileTable::MarkAsIgnored(const void* ptr) {
  AllocValue* alloc = address_map_->FindMutable(ptr);
  if (alloc) {
    alloc->set_ignore(true);
  }
}

void HeapProfileTable::IterateAllocationAddresses(AddressIterator f,
                                                  void* data) {
  const AllocationAddressIteratorArgs args(f, data);
  address_map_->Iterate<const AllocationAddressIteratorArgs&>(
      AllocationAddressesIterator, args);
}

void HeapProfileTable::MarkCurrentAllocations(AllocationMark mark) {
  const MarkArgs args(mark, true);
  address_map_->Iterate<const MarkArgs&>(MarkIterator, args);
}

void HeapProfileTable::MarkUnmarkedAllocations(AllocationMark mark) {
  const MarkArgs args(mark, false);
  address_map_->Iterate<const MarkArgs&>(MarkIterator, args);
}

// We'd be happier using snprintfer, but we don't to reduce dependencies.
int HeapProfileTable::UnparseBucket(const Bucket& b,
                                    char* buf, int buflen, int bufsize,
                                    const char* extra,
                                    Stats* profile_stats) {
  if (profile_stats != NULL) {
    profile_stats->allocs += b.allocs;
    profile_stats->alloc_size += b.alloc_size;
    profile_stats->frees += b.frees;
    profile_stats->free_size += b.free_size;
  }
  int printed =
    snprintf(buf + buflen, bufsize - buflen,
             "%6d: %8" PRId64 " [%6d: %8" PRId64 "] @%s",
             b.allocs - b.frees,
             b.alloc_size - b.free_size,
             b.allocs,
             b.alloc_size,
             extra);
  // If it looks like the snprintf failed, ignore the fact we printed anything
  if (printed < 0 || printed >= bufsize - buflen) return buflen;
  buflen += printed;
  for (int d = 0; d < b.depth; d++) {
    printed = snprintf(buf + buflen, bufsize - buflen, " 0x%08" PRIxPTR,
                       reinterpret_cast<uintptr_t>(b.stack[d]));
    if (printed < 0 || printed >= bufsize - buflen) return buflen;
    buflen += printed;
  }
  printed = snprintf(buf + buflen, bufsize - buflen, "\n");
  if (printed < 0 || printed >= bufsize - buflen) return buflen;
  buflen += printed;
  return buflen;
}

HeapProfileTable::Bucket**
HeapProfileTable::MakeSortedBucketList() const {
  Bucket** list = static_cast<Bucket**>(alloc_(sizeof(Bucket) * num_buckets_));

  int bucket_count = 0;
  for (int i = 0; i < kHashTableSize; i++) {
    for (Bucket* curr = bucket_table_[i]; curr != 0; curr = curr->next) {
      list[bucket_count++] = curr;
    }
  }
  RAW_DCHECK(bucket_count == num_buckets_, "");

  sort(list, list + num_buckets_, ByAllocatedSpace);

  return list;
}

void HeapProfileTable::DumpMarkedObjects(AllocationMark mark,
                                         const char* file_name) {
  RawFD fd = RawOpenForWriting(file_name);
  if (fd == kIllegalRawFD) {
    RAW_LOG(ERROR, "Failed dumping live objects to %s", file_name);
    return;
  }
  const DumpMarkedArgs args(fd, mark);
  address_map_->Iterate<const DumpMarkedArgs&>(DumpMarkedIterator, args);
  RawClose(fd);
}

#if defined(TYPE_PROFILING)
void HeapProfileTable::DumpTypeStatistics(const char* file_name) const {
  RawFD fd = RawOpenForWriting(file_name);
  if (fd == kIllegalRawFD) {
    RAW_LOG(ERROR, "Failed dumping type statistics to %s", file_name);
    return;
  }

  AddressMap<TypeCount>* type_size_map;
  type_size_map = new(alloc_(sizeof(AddressMap<TypeCount>)))
      AddressMap<TypeCount>(alloc_, dealloc_);
  address_map_->Iterate(TallyTypesItererator, type_size_map);

  RawWrite(fd, kTypeProfileStatsHeader, strlen(kTypeProfileStatsHeader));
  const DumpArgs args(fd, NULL);
  type_size_map->Iterate<const DumpArgs&>(DumpTypesIterator, args);
  RawClose(fd);

  type_size_map->~AddressMap<TypeCount>();
  dealloc_(type_size_map);
}
#endif  // defined(TYPE_PROFILING)

void HeapProfileTable::IterateOrderedAllocContexts(
    AllocContextIterator callback) const {
  Bucket** list = MakeSortedBucketList();
  AllocContextInfo info;
  for (int i = 0; i < num_buckets_; ++i) {
    *static_cast<Stats*>(&info) = *static_cast<Stats*>(list[i]);
    info.stack_depth = list[i]->depth;
    info.call_stack = list[i]->stack;
    callback(info);
  }
  dealloc_(list);
}

int HeapProfileTable::FillOrderedProfile(char buf[], int size) const {
  Bucket** list = MakeSortedBucketList();

  // Our file format is "bucket, bucket, ..., bucket, proc_self_maps_info".
  // In the cases buf is too small, we'd rather leave out the last
  // buckets than leave out the /proc/self/maps info.  To ensure that,
  // we actually print the /proc/self/maps info first, then move it to
  // the end of the buffer, then write the bucket info into whatever
  // is remaining, and then move the maps info one last time to close
  // any gaps.  Whew!
  int map_length = snprintf(buf, size, "%s", kProcSelfMapsHeader);
  if (map_length < 0 || map_length >= size) return 0;
  bool dummy;   // "wrote_all" -- did /proc/self/maps fit in its entirety?
  map_length += FillProcSelfMaps(buf + map_length, size - map_length, &dummy);
  RAW_DCHECK(map_length <= size, "");
  char* const map_start = buf + size - map_length;      // move to end
  memmove(map_start, buf, map_length);
  size -= map_length;

  Stats stats;
  memset(&stats, 0, sizeof(stats));
  int bucket_length = snprintf(buf, size, "%s", kProfileHeader);
  if (bucket_length < 0 || bucket_length >= size) return 0;
  bucket_length = UnparseBucket(total_, buf, bucket_length, size,
                                " heapprofile", &stats);

  // Dump the mmap list first.
  if (profile_mmap_) {
    BufferArgs buffer(buf, bucket_length, size);
    MemoryRegionMap::IterateBuckets<BufferArgs*>(DumpBucketIterator, &buffer);
    bucket_length = buffer.buflen;
  }

  for (int i = 0; i < num_buckets_; i++) {
    bucket_length = UnparseBucket(*list[i], buf, bucket_length, size, "",
                                  &stats);
  }
  RAW_DCHECK(bucket_length < size, "");

  dealloc_(list);

  RAW_DCHECK(buf + bucket_length <= map_start, "");
  memmove(buf + bucket_length, map_start, map_length);  // close the gap

  return bucket_length + map_length;
}

// static
void HeapProfileTable::DumpBucketIterator(const Bucket* bucket,
                                          BufferArgs* args) {
  args->buflen = UnparseBucket(*bucket, args->buf, args->buflen, args->bufsize,
                               "", NULL);
}

#if defined(TYPE_PROFILING)
// static
void HeapProfileTable::TallyTypesItererator(
    const void* ptr,
    AllocValue* value,
    AddressMap<TypeCount>* type_size_map) {
  const std::type_info* type = LookupType(ptr);

  const void* key = NULL;
  if (type)
    key = type->name();

  TypeCount* count = type_size_map->FindMutable(key);
  if (count) {
    count->bytes += value->bytes;
    ++count->objects;
  } else {
    type_size_map->Insert(key, TypeCount(value->bytes, 1));
  }
}

// static
void HeapProfileTable::DumpTypesIterator(const void* ptr,
                                         TypeCount* count,
                                         const DumpArgs& args) {
  char buf[1024];
  int len;
  const char* mangled_type_name = static_cast<const char*>(ptr);
  len = snprintf(buf, sizeof(buf), "%6d: %8" PRId64 " @ %s\n",
                 count->objects, count->bytes,
                 mangled_type_name ? mangled_type_name : "(no_typeinfo)");
  RawWrite(args.fd, buf, len);
}
#endif  // defined(TYPE_PROFILING)

inline
void HeapProfileTable::DumpNonLiveIterator(const void* ptr, AllocValue* v,
                                           const DumpArgs& args) {
  if (v->live()) {
    v->set_live(false);
    return;
  }
  if (v->ignore()) {
    return;
  }
  Bucket b;
  memset(&b, 0, sizeof(b));
  b.allocs = 1;
  b.alloc_size = v->bytes;
  b.depth = v->bucket()->depth;
  b.stack = v->bucket()->stack;
  char buf[1024];
  int len = UnparseBucket(b, buf, 0, sizeof(buf), "", args.profile_stats);
  RawWrite(args.fd, buf, len);
}

inline
void HeapProfileTable::DumpMarkedIterator(const void* ptr, AllocValue* v,
                                          const DumpMarkedArgs& args) {
  if (v->mark() != args.mark)
    return;
  Bucket b;
  memset(&b, 0, sizeof(b));
  b.allocs = 1;
  b.alloc_size = v->bytes;
  b.depth = v->bucket()->depth;
  b.stack = v->bucket()->stack;
  char addr[16];
  snprintf(addr, 16, "0x%08" PRIxPTR, ptr);
  char buf[1024];
  int len = UnparseBucket(b, buf, 0, sizeof(buf), addr, NULL);
  RawWrite(args.fd, buf, len);
}

inline
void HeapProfileTable::AllocationAddressesIterator(
    const void* ptr,
    AllocValue* v,
    const AllocationAddressIteratorArgs& args) {
  args.callback(args.data, ptr);
}

inline
void HeapProfileTable::MarkIterator(const void* ptr, AllocValue* v,
                                    const MarkArgs& args) {
  if (!args.mark_all && v->mark() != UNMARKED)
    return;
  v->set_mark(args.mark);
}

// Callback from NonLiveSnapshot; adds entry to arg->dest
// if not the entry is not live and is not present in arg->base.
void HeapProfileTable::AddIfNonLive(const void* ptr, AllocValue* v,
                                    AddNonLiveArgs* arg) {
  if (v->live()) {
    v->set_live(false);
  } else {
    if (arg->base != NULL && arg->base->map_.Find(ptr) != NULL) {
      // Present in arg->base, so do not save
    } else {
      arg->dest->Add(ptr, *v);
    }
  }
}

bool HeapProfileTable::WriteProfile(const char* file_name,
                                    const Bucket& total,
                                    AllocationMap* allocations) {
  RAW_VLOG(1, "Dumping non-live heap profile to %s", file_name);
  RawFD fd = RawOpenForWriting(file_name);
  if (fd == kIllegalRawFD) {
    RAW_LOG(ERROR, "Failed dumping filtered heap profile to %s", file_name);
    return false;
  }
  RawWrite(fd, kProfileHeader, strlen(kProfileHeader));
  char buf[512];
  int len = UnparseBucket(total, buf, 0, sizeof(buf), " heapprofile",
                          NULL);
  RawWrite(fd, buf, len);
  const DumpArgs args(fd, NULL);
  allocations->Iterate<const DumpArgs&>(DumpNonLiveIterator, args);
  RawWrite(fd, kProcSelfMapsHeader, strlen(kProcSelfMapsHeader));
  DumpProcSelfMaps(fd);
  RawClose(fd);
  return true;
}

void HeapProfileTable::CleanupOldProfiles(const char* prefix) {
  if (!FLAGS_cleanup_old_heap_profiles)
    return;
  char buf[1000];
  snprintf(buf, 1000,"%s.%05d.", prefix, getpid());
  string pattern = string(buf) + ".*" + kFileExt;

#if defined(HAVE_GLOB_H)
  glob_t g;
  const int r = glob(pattern.c_str(), GLOB_ERR, NULL, &g);
  if (r == 0 || r == GLOB_NOMATCH) {
    const int prefix_length = strlen(prefix);
    for (int i = 0; i < g.gl_pathc; i++) {
      const char* fname = g.gl_pathv[i];
      if ((strlen(fname) >= prefix_length) &&
          (memcmp(fname, prefix, prefix_length) == 0)) {
        RAW_VLOG(1, "Removing old heap profile %s", fname);
        unlink(fname);
      }
    }
  }
  globfree(&g);
#else   /* HAVE_GLOB_H */
  RAW_LOG(WARNING, "Unable to remove old heap profiles (can't run glob())");
#endif
}

HeapProfileTable::Snapshot* HeapProfileTable::TakeSnapshot() {
  Snapshot* s = new (alloc_(sizeof(Snapshot))) Snapshot(alloc_, dealloc_);
  address_map_->Iterate(AddToSnapshot, s);
  return s;
}

void HeapProfileTable::ReleaseSnapshot(Snapshot* s) {
  s->~Snapshot();
  dealloc_(s);
}

// Callback from TakeSnapshot; adds a single entry to snapshot
void HeapProfileTable::AddToSnapshot(const void* ptr, AllocValue* v,
                                     Snapshot* snapshot) {
  snapshot->Add(ptr, *v);
}

HeapProfileTable::Snapshot* HeapProfileTable::NonLiveSnapshot(
    Snapshot* base) {
  RAW_VLOG(2, "NonLiveSnapshot input: %d %d\n",
           int(total_.allocs - total_.frees),
           int(total_.alloc_size - total_.free_size));

  Snapshot* s = new (alloc_(sizeof(Snapshot))) Snapshot(alloc_, dealloc_);
  AddNonLiveArgs args;
  args.dest = s;
  args.base = base;
  address_map_->Iterate<AddNonLiveArgs*>(AddIfNonLive, &args);
  RAW_VLOG(2, "NonLiveSnapshot output: %d %d\n",
           int(s->total_.allocs - s->total_.frees),
           int(s->total_.alloc_size - s->total_.free_size));
  return s;
}

// Information kept per unique bucket seen
struct HeapProfileTable::Snapshot::Entry {
  int count;
  int bytes;
  Bucket* bucket;
  Entry() : count(0), bytes(0) { }

  // Order by decreasing bytes
  bool operator<(const Entry& x) const {
    return this->bytes > x.bytes;
  }
};

// State used to generate leak report.  We keep a mapping from Bucket pointer
// the collected stats for that bucket.
struct HeapProfileTable::Snapshot::ReportState {
  map<Bucket*, Entry> buckets_;
};

// Callback from ReportLeaks; updates ReportState.
void HeapProfileTable::Snapshot::ReportCallback(const void* ptr,
                                                AllocValue* v,
                                                ReportState* state) {
  Entry* e = &state->buckets_[v->bucket()]; // Creates empty Entry first time
  e->bucket = v->bucket();
  e->count++;
  e->bytes += v->bytes;
}

void HeapProfileTable::Snapshot::ReportLeaks(const char* checker_name,
                                             const char* filename,
                                             bool should_symbolize) {
  // This is only used by the heap leak checker, but is intimately
  // tied to the allocation map that belongs in this module and is
  // therefore placed here.
  RAW_LOG(ERROR, "Leak check %s detected leaks of %" PRIuS " bytes "
          "in %" PRIuS " objects",
          checker_name,
          size_t(total_.alloc_size),
          size_t(total_.allocs));

  // Group objects by Bucket
  ReportState state;
  map_.Iterate(&ReportCallback, &state);

  // Sort buckets by decreasing leaked size
  const int n = state.buckets_.size();
  Entry* entries = new Entry[n];
  int dst = 0;
  for (map<Bucket*,Entry>::const_iterator iter = state.buckets_.begin();
       iter != state.buckets_.end();
       ++iter) {
    entries[dst++] = iter->second;
  }
  sort(entries, entries + n);

  // Report a bounded number of leaks to keep the leak report from
  // growing too long.
  const int to_report =
      (FLAGS_heap_check_max_leaks > 0 &&
       n > FLAGS_heap_check_max_leaks) ? FLAGS_heap_check_max_leaks : n;
  RAW_LOG(ERROR, "The %d largest leaks:", to_report);

  // Print
  SymbolTable symbolization_table;
  for (int i = 0; i < to_report; i++) {
    const Entry& e = entries[i];
    for (int j = 0; j < e.bucket->depth; j++) {
      symbolization_table.Add(e.bucket->stack[j]);
    }
  }
  static const int kBufSize = 2<<10;
  char buffer[kBufSize];
  if (should_symbolize)
    symbolization_table.Symbolize();
  for (int i = 0; i < to_report; i++) {
    const Entry& e = entries[i];
    base::RawPrinter printer(buffer, kBufSize);
    printer.Printf("Leak of %d bytes in %d objects allocated from:\n",
                   e.bytes, e.count);
    for (int j = 0; j < e.bucket->depth; j++) {
      const void* pc = e.bucket->stack[j];
      printer.Printf("\t@ %" PRIxPTR " %s\n",
          reinterpret_cast<uintptr_t>(pc), symbolization_table.GetSymbol(pc));
    }
    RAW_LOG(ERROR, "%s", buffer);
  }

  if (to_report < n) {
    RAW_LOG(ERROR, "Skipping leaks numbered %d..%d",
            to_report, n-1);
  }
  delete[] entries;

  // TODO: Dump the sorted Entry list instead of dumping raw data?
  // (should be much shorter)
  if (!HeapProfileTable::WriteProfile(filename, total_, &map_)) {
    RAW_LOG(ERROR, "Could not write pprof profile to %s", filename);
  }
}

void HeapProfileTable::Snapshot::ReportObject(const void* ptr,
                                              AllocValue* v,
                                              char* unused) {
  // Perhaps also log the allocation stack trace (unsymbolized)
  // on this line in case somebody finds it useful.
  RAW_LOG(ERROR, "leaked %" PRIuS " byte object %p", v->bytes, ptr);
}

void HeapProfileTable::Snapshot::ReportIndividualObjects() {
  char unused;
  map_.Iterate(ReportObject, &unused);
}
