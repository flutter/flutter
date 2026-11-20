// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_HEAP_PROFILER_INTERNAL_H_
#define FLUTTER_RUNTIME_DART_HEAP_PROFILER_INTERNAL_H_

#include <dlfcn.h>
#include <elf.h>
#include <fcntl.h>
#include <link.h>
#include <time.h>
#include <unistd.h>
#include <unwind.h>

#include <atomic>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <mutex>

#include "perfetto/protozero/message.h"
#include "perfetto/protozero/packed_repeated_fields.h"
#include "perfetto/protozero/proto_decoder.h"
#include "perfetto/protozero/scattered_heap_buffer.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter::heap_profile_internal {

constexpr char kHeapprofdDataSourceName[] = "android.heapprofd";
constexpr char kDartHeapName[] = "com.google.dart";
constexpr intptr_t kDefaultSamplingInterval = 512 * 1024;
constexpr size_t kMaxStackFrames = 64;
constexpr size_t kSamplesPerPacketBatch = 128;

// Perfetto TracePacket / InternedData / ProfilePacket protobuf field numbers.
constexpr uint32_t kTracePacketTimestampField = 8;
constexpr uint32_t kTracePacketTrustedSeqIdField = 10;
constexpr uint32_t kTracePacketInternedDataField = 12;
constexpr uint32_t kTracePacketSequenceFlagsField = 13;
constexpr uint32_t kTracePacketProfilePacketField = 37;

constexpr uint32_t kSeqIncrementalStateCleared = 1u;
constexpr uint32_t kSeqNeedsIncrementalState = 2u;

constexpr uint32_t kInternedFunctionNamesField = 5;
constexpr uint32_t kInternedFramesField = 6;
constexpr uint32_t kInternedCallstacksField = 7;
constexpr uint32_t kInternedBuildIdsField = 16;
constexpr uint32_t kInternedMappingPathsField = 17;
constexpr uint32_t kInternedMappingsField = 19;

constexpr uint32_t kMappingIidField = 1;
constexpr uint32_t kMappingBuildIdField = 2;
constexpr uint32_t kMappingStartField = 4;
constexpr uint32_t kMappingEndField = 5;
constexpr uint32_t kMappingLoadBiasField = 6;
constexpr uint32_t kMappingPathStringIdsField = 7;
constexpr uint32_t kMappingExactOffsetField = 8;

constexpr uint32_t kFrameIidField = 1;
constexpr uint32_t kFrameFunctionNameIdField = 2;
constexpr uint32_t kFrameMappingIdField = 3;
constexpr uint32_t kFrameRelPcField = 4;

constexpr uint32_t kCallstackIidField = 1;
constexpr uint32_t kCallstackFrameIdsField = 2;

constexpr uint32_t kProfilePacketProcessDumpsField = 5;
constexpr uint32_t kProfilePacketContinuedField = 6;
constexpr uint32_t kProfilePacketIndexField = 7;

constexpr uint32_t kProcessDumpPidField = 1;
constexpr uint32_t kProcessDumpSamplesField = 2;
constexpr uint32_t kProcessDumpTimestampField = 9;
constexpr uint32_t kProcessDumpHeapNameField = 11;
constexpr uint32_t kProcessDumpSamplingIntervalField = 12;
constexpr uint32_t kProcessDumpOrigSamplingIntervalField = 13;
constexpr uint32_t kProcessDumpStartTimestampField = 15;

constexpr uint32_t kHeapSampleCallstackIdField = 1;
constexpr uint32_t kHeapSampleSelfAllocatedField = 2;
constexpr uint32_t kHeapSampleSelfFreedField = 3;
constexpr uint32_t kHeapSampleAllocCountField = 5;
constexpr uint32_t kHeapSampleFreeCountField = 6;

/// Returns `CLOCK_BOOTTIME` in nanoseconds (Perfetto's default trace clock).
inline uint64_t GetBootTimeNs() {
  struct timespec ts{};
  clock_gettime(CLOCK_BOOTTIME, &ts);
  return static_cast<uint64_t>(ts.tv_sec) * 1000000000ULL +
         static_cast<uint64_t>(ts.tv_nsec);
}

/// Returns `CLOCK_MONOTONIC_COARSE` in nanoseconds (heapprofd dump clock).
inline uint64_t GetMonotonicCoarseNs() {
  struct timespec ts{};
  clock_gettime(CLOCK_MONOTONIC_COARSE, &ts);
  return static_cast<uint64_t>(ts.tv_sec) * 1000000000ULL +
         static_cast<uint64_t>(ts.tv_nsec);
}

/// Computes a non-zero 32-bit FNV-1a hash over `data[0..len)`.
inline uint32_t HashBytes(const void* data,
                          size_t len,
                          uint32_t seed = 2166136261u) {
  const auto* bytes = static_cast<const uint8_t*>(data);
  uint32_t h = seed;
  for (size_t i = 0; i < len; ++i) {
    h ^= bytes[i];
    h *= 16777619u;
  }
  return h == 0 ? 1u : h;
}

/// Resolves `_Unwind_Backtrace` and `_Unwind_GetIP` from the system C runtime
/// (`libc.so` on Android 11+ / API 30+) so unwinding adds zero binary size.
struct UnwindApi {
  using BacktraceFn = _Unwind_Reason_Code (*)(_Unwind_Trace_Fn, void*);
  using GetIpFn = _Unwind_Ptr (*)(struct _Unwind_Context*);

  BacktraceFn backtrace = nullptr;
  GetIpFn get_ip = nullptr;

  static const UnwindApi& Get() {
    static const UnwindApi api = []() {
      UnwindApi res;
      res.backtrace = reinterpret_cast<BacktraceFn>(
          dlsym(RTLD_DEFAULT, "_Unwind_Backtrace"));
      res.get_ip =
          reinterpret_cast<GetIpFn>(dlsym(RTLD_DEFAULT, "_Unwind_GetIP"));
      return res;
    }();
    return api;
  }
};

struct BacktraceState {
  UnwindApi::GetIpFn get_ip;
  uintptr_t* pcs;
  size_t count;
  size_t skip;
};

/// Unwind callback invoked for each frame on the allocating thread's stack.
inline _Unwind_Reason_Code UnwindStep(struct _Unwind_Context* ctx, void* arg) {
  auto* st = static_cast<BacktraceState*>(arg);
  uintptr_t pc = static_cast<uintptr_t>(st->get_ip(ctx));
  if (pc == 0) {
    return _URC_END_OF_STACK;
  }
  if (st->skip > 0) {
    st->skip--;
    return _URC_NO_REASON;
  }
#if defined(__aarch64__)
  // xpaclri (HINT #7): strips PAC bits on ARMv8.3+, executes as NOP on ARMv8.0.
  register uintptr_t x30 __asm__("x30") = pc;
  __asm__("hint #7" : "+r"(x30));
  pc = x30 > 4 ? x30 - 4 : x30;
#else
  if (pc > 1) {
    pc -= 1;
  }
#endif
  st->pcs[st->count++] = pc;
  return st->count >= kMaxStackFrames ? _URC_END_OF_STACK : _URC_NO_REASON;
}

/// Captures up to `kMaxStackFrames` instruction pointers from the current
/// stack.
inline size_t CollectStackPcs(uintptr_t (&pcs)[kMaxStackFrames]) {
  const UnwindApi& api = UnwindApi::Get();
  if (api.backtrace == nullptr || api.get_ip == nullptr) {
    return 0;
  }
  BacktraceState st{api.get_ip, pcs, 0, /*skip=*/2};
  api.backtrace(&UnwindStep, &st);
  return st.count;
}

/// Ref-counted callsite record laid out in a single `malloc` block alongside
/// its trailing `uintptr_t pcs[num_frames]` and NUL-terminated `cls_name`.
struct AggregatedEntry {
  uint32_t hash = 0;
  uint16_t num_frames = 0;
  uint16_t cls_len = 0;
  uintptr_t group_key = 0;
  std::atomic<uint64_t> self_allocated{0};
  std::atomic<uint64_t> self_freed{0};
  std::atomic<uint64_t> alloc_count{0};
  std::atomic<uint64_t> free_count{0};
  std::atomic<uint32_t> refs{1};
  std::atomic<bool> dirty{false};

  const uintptr_t* pcs() const {
    return reinterpret_cast<const uintptr_t*>(this + 1);
  }
  const char* cls_name() const {
    return reinterpret_cast<const char*>(pcs() + num_frames);
  }

  static AggregatedEntry* Create(uintptr_t group_key,
                                 uint32_t hash,
                                 const char* cls,
                                 size_t cls_len,
                                 const uintptr_t* pcs,
                                 size_t num_frames) {
    const size_t pcs_bytes = num_frames * sizeof(uintptr_t);
    auto* raw = static_cast<uint8_t*>(
        std::malloc(sizeof(AggregatedEntry) + pcs_bytes + cls_len + 1));
    if (raw == nullptr) {
      return nullptr;
    }
    auto* e = new (raw) AggregatedEntry();
    e->hash = hash;
    e->num_frames = static_cast<uint16_t>(num_frames);
    e->cls_len = static_cast<uint16_t>(cls_len);
    e->group_key = group_key;
    auto* dst_pcs = reinterpret_cast<uintptr_t*>(e + 1);
    std::memcpy(dst_pcs, pcs, pcs_bytes);
    auto* dst_cls = reinterpret_cast<char*>(dst_pcs + num_frames);
    if (cls_len > 0) {
      std::memcpy(dst_cls, cls, cls_len);
    }
    dst_cls[cls_len] = '\0';
    return e;
  }

  void Release() {
    if (refs.fetch_sub(1, std::memory_order_acq_rel) == 1) {
      std::free(this);
    }
  }
};

/// Handle stored in Dart's weak table for each live sampled object.
struct SampledRecord {
  AggregatedEntry* entry;
  uint64_t size;
};

/// Point-in-time cumulative counters for a modified callsite.
struct SampleSnapshot {
  AggregatedEntry* entry;
  uint64_t self_allocated;
  uint64_t self_freed;
  uint64_t alloc_count;
  uint64_t free_count;
};

/// Open-addressed hash table aggregating sampled Dart allocations by callstack
/// and class name without pulling in `std::unordered_map` template bloat.
class HeapSampleAggregator {
 public:
  ~HeapSampleAggregator() {
    Clear();
    std::free(buckets_);
  }

  /// Unwinds the current stack and records a sampled allocation.
  void* RecordCurrentThreadAlloc(Dart_IsolateGroup group,
                                 const char* cls_name,
                                 intptr_t size) {
    if (size <= 0) {
      return nullptr;
    }
    uintptr_t pcs[kMaxStackFrames];
    const size_t n = CollectStackPcs(pcs);
    return RecordAllocWithPcs(group, cls_name, size, pcs, n);
  }

  /// Records a sampled allocation for explicit `pcs[0..n)`.
  void* RecordAllocWithPcs(Dart_IsolateGroup group,
                           const char* cls_name,
                           intptr_t size,
                           const uintptr_t* pcs,
                           size_t n) {
    if (size <= 0 || n == 0 || n > kMaxStackFrames) {
      return nullptr;
    }
    const char* safe_cls = cls_name != nullptr ? cls_name : "Unknown";
    const size_t cls_len = std::strlen(safe_cls);
    const auto group_key = reinterpret_cast<uintptr_t>(group);
    uint32_t h = HashBytes(&group_key, sizeof(group_key));
    h = HashBytes(pcs, n * sizeof(uintptr_t), h);
    h = HashBytes(safe_cls, cls_len, h);

    auto* rec = static_cast<SampledRecord*>(std::malloc(sizeof(SampledRecord)));
    if (rec == nullptr) {
      return nullptr;
    }
    AggregatedEntry* entry = nullptr;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      entry = LookupOrInsertLocked(group_key, h, safe_cls, cls_len, pcs, n);
      if (entry != nullptr) {
        entry->refs.fetch_add(1, std::memory_order_relaxed);
      }
    }
    if (entry == nullptr) {
      std::free(rec);
      return nullptr;
    }
    const auto usize = static_cast<uint64_t>(size);
    entry->self_allocated.fetch_add(usize, std::memory_order_relaxed);
    entry->alloc_count.fetch_add(1, std::memory_order_relaxed);
    entry->dirty.store(true, std::memory_order_release);
    rec->entry = entry;
    rec->size = usize;
    return rec;
  }

  /// Lock-free GC finalizer callback attributing freed bytes to the callsite.
  static void RecordFree(void* data) {
    if (data == nullptr) {
      return;
    }
    auto* rec = static_cast<SampledRecord*>(data);
    AggregatedEntry* e = rec->entry;
    e->self_freed.fetch_add(rec->size, std::memory_order_relaxed);
    e->free_count.fetch_add(1, std::memory_order_relaxed);
    e->dirty.store(true, std::memory_order_release);
    e->Release();
    std::free(rec);
  }

  /// Snapshots all entries modified since the previous snapshot.
  size_t TakeSnapshot(SampleSnapshot** out_items) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (count_ == 0) {
      *out_items = nullptr;
      return 0;
    }
    auto* arr = static_cast<SampleSnapshot*>(
        std::malloc(count_ * sizeof(SampleSnapshot)));
    if (arr == nullptr) {
      *out_items = nullptr;
      return 0;
    }
    size_t out_n = 0;
    for (size_t i = 0; i < capacity_; ++i) {
      AggregatedEntry* e = buckets_[i];
      if (e == nullptr ||
          !e->dirty.exchange(false, std::memory_order_acq_rel)) {
        continue;
      }
      e->refs.fetch_add(1, std::memory_order_relaxed);
      arr[out_n++] = SampleSnapshot{
          e,
          e->self_allocated.load(std::memory_order_relaxed),
          e->self_freed.load(std::memory_order_relaxed),
          e->alloc_count.load(std::memory_order_relaxed),
          e->free_count.load(std::memory_order_relaxed),
      };
    }
    if (out_n == 0) {
      std::free(arr);
      *out_items = nullptr;
    } else {
      *out_items = arr;
    }
    return out_n;
  }

  /// Releases snapshot entry references acquired by `TakeSnapshot`.
  static void FreeSnapshot(SampleSnapshot* items, size_t n) {
    for (size_t i = 0; i < n; ++i) {
      items[i].entry->Release();
    }
    std::free(items);
  }

  /// Marks all active entries dirty after an incremental state clear.
  void MarkAllDirty() {
    std::lock_guard<std::mutex> lock(mutex_);
    for (size_t i = 0; i < capacity_; ++i) {
      if (buckets_[i] != nullptr) {
        buckets_[i]->dirty.store(true, std::memory_order_release);
      }
    }
  }

  /// Releases all map entries when a profiling session stops.
  void Clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    for (size_t i = 0; i < capacity_; ++i) {
      if (buckets_[i] != nullptr) {
        buckets_[i]->Release();
        buckets_[i] = nullptr;
      }
    }
    count_ = 0;
  }

 private:
  AggregatedEntry* LookupOrInsertLocked(uintptr_t group_key,
                                        uint32_t hash,
                                        const char* cls,
                                        size_t cls_len,
                                        const uintptr_t* pcs,
                                        size_t n) {
    if (capacity_ == 0 || (count_ + 1) * 10 >= capacity_ * 7) {
      if (!GrowLocked()) {
        return nullptr;
      }
    }
    const size_t mask = capacity_ - 1;
    size_t idx = hash & mask;
    while (buckets_[idx] != nullptr) {
      AggregatedEntry* e = buckets_[idx];
      if (e->hash == hash && e->group_key == group_key && e->num_frames == n &&
          e->cls_len == cls_len &&
          std::memcmp(e->pcs(), pcs, n * sizeof(uintptr_t)) == 0 &&
          std::memcmp(e->cls_name(), cls, cls_len) == 0) {
        return e;
      }
      idx = (idx + 1) & mask;
    }
    AggregatedEntry* created =
        AggregatedEntry::Create(group_key, hash, cls, cls_len, pcs, n);
    if (created != nullptr) {
      buckets_[idx] = created;
      count_++;
    }
    return created;
  }

  bool GrowLocked() {
    const size_t new_cap = capacity_ == 0 ? 256 : capacity_ * 2;
    auto** new_buckets = static_cast<AggregatedEntry**>(
        std::calloc(new_cap, sizeof(AggregatedEntry*)));
    if (new_buckets == nullptr) {
      return false;
    }
    const size_t mask = new_cap - 1;
    for (size_t i = 0; i < capacity_; ++i) {
      AggregatedEntry* e = buckets_[i];
      if (e == nullptr) {
        continue;
      }
      size_t idx = e->hash & mask;
      while (new_buckets[idx] != nullptr) {
        idx = (idx + 1) & mask;
      }
      new_buckets[idx] = e;
    }
    std::free(buckets_);
    buckets_ = new_buckets;
    capacity_ = new_cap;
    return true;
  }

  std::mutex mutex_;
  AggregatedEntry** buckets_ = nullptr;
  size_t count_ = 0;
  size_t capacity_ = 0;
};

/// Executable ELF segment discovered in-process via `dl_iterate_phdr`.
struct ElfSegment {
  uintptr_t start;
  uintptr_t end;
  uint64_t exact_offset;
  uint64_t load_bias;
  const char* path;
  uint8_t build_id[32];
  uint8_t build_id_len;
  uint64_t mapping_iid;
};

struct ElfScanContext {
  ElfSegment* segs;
  size_t count;
  size_t cap;
};

/// Extracts `NT_GNU_BUILD_ID` from a `PT_NOTE` program header if present.
inline uint8_t ExtractGnuBuildId(const dl_phdr_info* info, uint8_t (&out)[32]) {
  for (size_t i = 0; i < info->dlpi_phnum; ++i) {
    const auto& ph = info->dlpi_phdr[i];
    if (ph.p_type != PT_NOTE || ph.p_memsz == 0) {
      continue;
    }
    const auto* ptr =
        reinterpret_cast<const uint8_t*>(info->dlpi_addr + ph.p_vaddr);
    const uint8_t* end = ptr + ph.p_memsz;
    while (ptr + sizeof(ElfW(Nhdr)) <= end) {
      ElfW(Nhdr) nhdr{};
      std::memcpy(&nhdr, ptr, sizeof(nhdr));
      ptr += sizeof(nhdr);
      const size_t name_aligned = (nhdr.n_namesz + 3u) & ~3u;
      const size_t desc_aligned = (nhdr.n_descsz + 3u) & ~3u;
      if (ptr + name_aligned + desc_aligned > end) {
        break;
      }
      if (nhdr.n_type == 3 /* NT_GNU_BUILD_ID */ && nhdr.n_namesz == 4 &&
          std::memcmp(ptr, "GNU", 4) == 0 && nhdr.n_descsz <= sizeof(out)) {
        std::memcpy(out, ptr + name_aligned, nhdr.n_descsz);
        return static_cast<uint8_t>(nhdr.n_descsz);
      }
      ptr += name_aligned + desc_aligned;
    }
  }
  return 0;
}

/// `dl_iterate_phdr` visitor recording executable `PT_LOAD` segments.
inline int OnPhdr(struct dl_phdr_info* info, size_t /*size*/, void* data) {
  auto* ctx = static_cast<ElfScanContext*>(data);
  uint8_t build_id[32]{};
  const uint8_t build_id_len = ExtractGnuBuildId(info, build_id);
  const char* path = (info->dlpi_name != nullptr && info->dlpi_name[0] != '\0')
                         ? info->dlpi_name
                         : "[executable]";

  for (size_t i = 0; i < info->dlpi_phnum; ++i) {
    const auto& ph = info->dlpi_phdr[i];
    if (ph.p_type != PT_LOAD || (ph.p_flags & PF_X) == 0 || ph.p_memsz == 0) {
      continue;
    }
    if (ctx->count == ctx->cap) {
      const size_t new_cap = ctx->cap == 0 ? 32 : ctx->cap * 2;
      auto* next = static_cast<ElfSegment*>(
          std::realloc(ctx->segs, new_cap * sizeof(ElfSegment)));
      if (next == nullptr) {
        return 0;
      }
      ctx->segs = next;
      ctx->cap = new_cap;
    }
    ElfSegment& seg = ctx->segs[ctx->count++];
    seg.start = static_cast<uintptr_t>(info->dlpi_addr + ph.p_vaddr);
    seg.end = seg.start + static_cast<uintptr_t>(ph.p_memsz);
    seg.exact_offset = ph.p_offset;
    seg.load_bias = ph.p_vaddr - ph.p_offset;
    seg.path = path;
    std::memcpy(seg.build_id, build_id, sizeof(build_id));
    seg.build_id_len = build_id_len;
    seg.mapping_iid = 0;
  }
  return 0;
}

/// Parsed configuration for a matched `"android.heapprofd"` tracing session.
struct ParsedHeapprofdSession {
  bool matched = false;
  uint32_t target_buffer = 0;
  intptr_t sampling_interval = kDefaultSamplingInterval;
  uint32_t dump_phase_ms = 0;
  uint32_t dump_interval_ms = 0;
};

inline bool ReadSelfCmdline(char* buf, size_t cap) {
  const int fd = open("/proc/self/cmdline", O_RDONLY | O_CLOEXEC);
  if (fd < 0) {
    return false;
  }
  const ssize_t n = read(fd, buf, cap - 1);
  close(fd);
  if (n <= 0) {
    return false;
  }
  buf[n] = '\0';
  return true;
}

/// Matches `str` against a pattern containing `*` wildcards.
inline bool MatchWildcard(const char* pat, size_t pat_len, const char* str) {
  size_t p = 0;
  size_t s = 0;
  size_t star_p = static_cast<size_t>(-1);
  size_t star_s = 0;
  while (str[s] != '\0') {
    if (p < pat_len && pat[p] == '*') {
      star_p = p++;
      star_s = s;
    } else if (p < pat_len && pat[p] == str[s]) {
      p++;
      s++;
    } else if (star_p != static_cast<size_t>(-1)) {
      p = star_p + 1;
      s = ++star_s;
    } else {
      return false;
    }
  }
  while (p < pat_len && pat[p] == '*') {
    p++;
  }
  return p == pat_len;
}

/// Strips leading directory components and trailing `@...` suffix per Perfetto
/// `HeapprofdConfig.process_cmdline` normalization rules.
inline void NormalizeCmdline(const char* in,
                             size_t len,
                             char* out,
                             size_t cap) {
  size_t start = 0;
  size_t end = len;
  for (size_t i = 0; i < len; ++i) {
    if (in[i] == '\0') {
      end = i;
      break;
    }
  }
  for (size_t i = 0; i < end; ++i) {
    if (in[i] == '/') {
      start = i + 1;
    } else if (in[i] == '@') {
      end = i;
      break;
    }
  }
  size_t n = end > start ? end - start : 0;
  if (n >= cap) {
    n = cap - 1;
  }
  std::memcpy(out, in + start, n);
  out[n] = '\0';
}

/// Matches a single `HeapprofdConfig.process_cmdline` entry against `argv0`.
inline bool MatchesCmdlineEntry(const char* pat,
                                size_t pat_len,
                                const char* self_argv0) {
  if (std::memchr(pat, '*', pat_len) != nullptr) {
    const char* target = self_argv0;
    if (pat_len > 0 && pat[0] != '/') {
      const char* slash = std::strrchr(self_argv0, '/');
      if (slash != nullptr) {
        target = slash + 1;
      }
    }
    return MatchWildcard(pat, pat_len, target);
  }
  char norm_self[256]{};
  char norm_pat[256]{};
  NormalizeCmdline(self_argv0, std::strlen(self_argv0), norm_self,
                   sizeof(norm_self));
  NormalizeCmdline(pat, pat_len, norm_pat, sizeof(norm_pat));
  return std::strcmp(norm_pat, norm_self) == 0;
}

inline intptr_t ClampInterval(uint64_t raw) {
  constexpr auto kMax =
      static_cast<uint64_t>(std::numeric_limits<intptr_t>::max());
  return static_cast<intptr_t>(raw > kMax ? kMax : raw);
}

/// Evaluates `DataSourceConfig` (and nested `HeapprofdConfig`) against
/// `self_pid` and `self_argv0`.
inline ParsedHeapprofdSession ParseDataSourceConfigForProcess(
    const uint8_t* data,
    size_t len,
    uint64_t self_pid,
    const char* self_argv0) {
  ParsedHeapprofdSession res;
  protozero::ProtoDecoder dsc(data, len);
  protozero::ConstBytes heapprofd_raw{};
  for (auto f = dsc.ReadField(); f.valid(); f = dsc.ReadField()) {
    if (f.id() == 2) {  // DataSourceConfig.target_buffer
      res.target_buffer = f.as_uint32();
    } else if (f.id() == 105) {  // DataSourceConfig.heapprofd_config
      heapprofd_raw = f.as_bytes();
    }
  }
  if (heapprofd_raw.data == nullptr && heapprofd_raw.size == 0) {
    res.matched = true;
    return res;
  }

  bool all_procs = false;
  bool all_heaps = false;
  bool dart_heap_excluded = false;
  bool has_pid_or_cmd = false;
  bool pid_or_cmd_matched = false;
  size_t heap_idx = 0;
  size_t dart_heap_index = static_cast<size_t>(-1);
  uint64_t intervals[16]{};
  size_t interval_count = 0;

  protozero::ProtoDecoder hc(heapprofd_raw.data, heapprofd_raw.size);
  for (auto f = hc.ReadField(); f.valid(); f = hc.ReadField()) {
    switch (f.id()) {
      case 1:  // sampling_interval_bytes
        if (f.as_uint64() > 0) {
          res.sampling_interval = ClampInterval(f.as_uint64());
        }
        break;
      case 2:  // process_cmdline
        has_pid_or_cmd = true;
        if (self_argv0 != nullptr && !pid_or_cmd_matched &&
            MatchesCmdlineEntry(reinterpret_cast<const char*>(f.data()),
                                f.size(), self_argv0)) {
          pid_or_cmd_matched = true;
        }
        break;
      case 4:  // pid
        has_pid_or_cmd = true;
        if (f.as_uint64() == self_pid) {
          pid_or_cmd_matched = true;
        }
        break;
      case 5:  // all
        all_procs = f.as_bool();
        break;
      case 6: {  // continuous_dump_config
        protozero::ProtoDecoder cdc(f.data(), f.size());
        for (auto cf = cdc.ReadField(); cf.valid(); cf = cdc.ReadField()) {
          if (cf.id() == 5) {
            res.dump_phase_ms = cf.as_uint32();
          } else if (cf.id() == 6) {
            res.dump_interval_ms = cf.as_uint32();
          }
        }
        break;
      }
      case 20:  // heaps
        if (f.size() == sizeof(kDartHeapName) - 1 &&
            std::memcmp(f.data(), kDartHeapName, f.size()) == 0) {
          dart_heap_index = heap_idx;
        }
        heap_idx++;
        break;
      case 21:  // all_heaps
        all_heaps = f.as_bool();
        break;
      case 22:  // heap_sampling_intervals (varint or packed varint)
        if (f.type() ==
            protozero::proto_utils::ProtoWireType::kLengthDelimited) {
          const uint8_t* p = f.data();
          const uint8_t* end_p = p + f.size();
          while (p < end_p && interval_count < 16) {
            uint64_t v = 0;
            const uint8_t* next =
                protozero::proto_utils::ParseVarInt(p, end_p, &v);
            if (next == p) {
              break;
            }
            intervals[interval_count++] = v;
            p = next;
          }
        } else if (interval_count < 16) {
          intervals[interval_count++] = f.as_uint64();
        }
        break;
      case 27:  // exclude_heaps
        if (f.size() == sizeof(kDartHeapName) - 1 &&
            std::memcmp(f.data(), kDartHeapName, f.size()) == 0) {
          dart_heap_excluded = true;
        }
        break;
      default:
        break;
    }
  }

  if (dart_heap_excluded) {
    return res;
  }
  if (!all_heaps && dart_heap_index == static_cast<size_t>(-1)) {
    return res;
  }
  if (!all_procs && has_pid_or_cmd && !pid_or_cmd_matched) {
    return res;
  }
  if (dart_heap_index < interval_count && intervals[dart_heap_index] > 0) {
    res.sampling_interval = ClampInterval(intervals[dart_heap_index]);
  }
  res.matched = true;
  return res;
}

/// Evaluates `DataSourceConfig` against the current OS process.
inline ParsedHeapprofdSession ParseDataSourceConfig(const uint8_t* data,
                                                    size_t len) {
  char cmdline[256]{};
  const char* argv0 =
      ReadSelfCmdline(cmdline, sizeof(cmdline)) ? cmdline : nullptr;
  return ParseDataSourceConfigForProcess(
      data, len, static_cast<uint64_t>(getpid()), argv0);
}

inline uint64_t AppendInternedString(protozero::Message* interned,
                                     uint32_t field_id,
                                     uint64_t iid,
                                     const void* bytes,
                                     size_t len) {
  auto* s = interned->BeginNestedMessage<protozero::Message>(field_id);
  s->AppendVarInt(1, iid);
  s->AppendBytes(2, bytes, len);
  s->Finalize();
  return iid;
}

/// Serializes modified heap samples into one or more `TracePacket`s containing
/// `InternedData` and `ProfilePacket` messages.
template <typename EmitPacketFn>
void WriteHeapProfilePackets(HeapSampleAggregator& aggregator,
                             intptr_t sampling_interval,
                             uint64_t* packet_index,
                             uint64_t* prev_dump_mono_ns,
                             EmitPacketFn&& emit_packet) {
  SampleSnapshot* snaps = nullptr;
  const size_t num_snaps = aggregator.TakeSnapshot(&snaps);
  if (num_snaps == 0) {
    return;
  }

  ElfScanContext elf_ctx{nullptr, 0, 0};
  dl_iterate_phdr(&OnPhdr, &elf_ctx);

  const uint64_t boot_ns = GetBootTimeNs();
  const uint64_t mono_ns = GetMonotonicCoarseNs();
  const uint64_t start_mono_ns = *prev_dump_mono_ns;
  *prev_dump_mono_ns = mono_ns;
  const auto pid = static_cast<uint64_t>(getpid());

  // Interning IDs persist across continued batches of this dump; the first
  // batch clears incremental state so no cross-dump hash tables are needed.
  uint64_t next_str_iid = 1;
  uint64_t next_map_iid = 1;
  uint64_t next_frame_iid = 1;
  uint64_t next_cs_iid = 1;
  uint64_t unknown_map_iid = 0;

  for (size_t start = 0; start < num_snaps; start += kSamplesPerPacketBatch) {
    const size_t end = (start + kSamplesPerPacketBatch < num_snaps)
                           ? (start + kSamplesPerPacketBatch)
                           : num_snaps;
    const bool continued = end < num_snaps;
    const uint32_t seq_flags =
        (start == 0) ? (kSeqIncrementalStateCleared | kSeqNeedsIncrementalState)
                     : kSeqNeedsIncrementalState;

    emit_packet([&](protozero::Message* pkt) {
      pkt->AppendVarInt(kTracePacketTimestampField, boot_ns);
      pkt->AppendVarInt(kTracePacketSequenceFlagsField, seq_flags);

      uint64_t callstack_iids[kSamplesPerPacketBatch]{};
      {
        auto* interned = pkt->BeginNestedMessage<protozero::Message>(
            kTracePacketInternedDataField);

        if (start == 0) {
          // Perfetto's StackProfileSequenceState requires iid=0 empty entries
          // for unset build_id and function_name_id references.
          AppendInternedString(interned, kInternedBuildIdsField, 0, "", 0);
          AppendInternedString(interned, kInternedMappingPathsField, 0, "", 0);
          AppendInternedString(interned, kInternedFunctionNamesField, 0, "", 0);
        }

        for (size_t i = start; i < end; ++i) {
          AggregatedEntry* e = snaps[i].entry;
          uint64_t frame_iids[kMaxStackFrames + 1];
          size_t f_count = 0;

          // Perfetto Callstack frame_ids are ordered root-first.
          for (size_t k = e->num_frames; k > 0; --k) {
            const uintptr_t pc = e->pcs()[k - 1];
            uint64_t map_iid = 0;
            uint64_t rel_pc = pc;
            for (size_t m = 0; m < elf_ctx.count; ++m) {
              ElfSegment& seg = elf_ctx.segs[m];
              if (pc >= seg.start && pc < seg.end) {
                if (seg.mapping_iid == 0) {
                  const uint64_t bid_iid =
                      seg.build_id_len > 0
                          ? AppendInternedString(
                                interned, kInternedBuildIdsField,
                                next_str_iid++, seg.build_id, seg.build_id_len)
                          : 0;
                  const uint64_t path_iid = AppendInternedString(
                      interned, kInternedMappingPathsField, next_str_iid++,
                      seg.path, std::strlen(seg.path));
                  seg.mapping_iid = next_map_iid++;
                  auto* mp = interned->BeginNestedMessage<protozero::Message>(
                      kInternedMappingsField);
                  mp->AppendVarInt(kMappingIidField, seg.mapping_iid);
                  mp->AppendVarInt(kMappingBuildIdField, bid_iid);
                  mp->AppendVarInt(kMappingExactOffsetField, seg.exact_offset);
                  mp->AppendVarInt(kMappingStartField, seg.start);
                  mp->AppendVarInt(kMappingEndField, seg.end);
                  mp->AppendVarInt(kMappingLoadBiasField, seg.load_bias);
                  mp->AppendVarInt(kMappingPathStringIdsField, path_iid);
                  mp->Finalize();
                }
                map_iid = seg.mapping_iid;
                rel_pc = (pc - seg.start) + seg.exact_offset;
                break;
              }
            }
            if (map_iid == 0) {
              if (unknown_map_iid == 0) {
                unknown_map_iid = next_map_iid++;
                auto* mp = interned->BeginNestedMessage<protozero::Message>(
                    kInternedMappingsField);
                mp->AppendVarInt(kMappingIidField, unknown_map_iid);
                mp->AppendVarInt(kMappingBuildIdField, 0);
                mp->AppendVarInt(kMappingStartField, 0);
                mp->AppendVarInt(kMappingEndField, ~uint64_t{0});
                mp->Finalize();
              }
              map_iid = unknown_map_iid;
            }
            const uint64_t fid = next_frame_iid++;
            auto* fr = interned->BeginNestedMessage<protozero::Message>(
                kInternedFramesField);
            fr->AppendVarInt(kFrameIidField, fid);
            fr->AppendVarInt(kFrameMappingIdField, map_iid);
            fr->AppendVarInt(kFrameRelPcField, rel_pc);
            fr->Finalize();
            frame_iids[f_count++] = fid;
          }

          // Append synthetic leaf frame carrying the allocated Dart class name.
          const uint64_t fn_iid =
              AppendInternedString(interned, kInternedFunctionNamesField,
                                   next_str_iid++, e->cls_name(), e->cls_len);
          const uint64_t cls_fid = next_frame_iid++;
          {
            auto* fr = interned->BeginNestedMessage<protozero::Message>(
                kInternedFramesField);
            fr->AppendVarInt(kFrameIidField, cls_fid);
            fr->AppendVarInt(kFrameFunctionNameIdField, fn_iid);
            fr->Finalize();
          }
          frame_iids[f_count++] = cls_fid;

          const uint64_t cs_iid = next_cs_iid++;
          auto* cs = interned->BeginNestedMessage<protozero::Message>(
              kInternedCallstacksField);
          cs->AppendVarInt(kCallstackIidField, cs_iid);
          for (size_t f = 0; f < f_count; ++f) {
            cs->AppendVarInt(kCallstackFrameIdsField, frame_iids[f]);
          }
          cs->Finalize();
          callstack_iids[i - start] = cs_iid;
        }
        interned->Finalize();
      }

      auto* prof = pkt->BeginNestedMessage<protozero::Message>(
          kTracePacketProfilePacketField);
      prof->AppendVarInt(kProfilePacketContinuedField, continued ? 1u : 0u);
      prof->AppendVarInt(kProfilePacketIndexField, (*packet_index)++);
      auto* dump = prof->BeginNestedMessage<protozero::Message>(
          kProfilePacketProcessDumpsField);
      dump->AppendVarInt(kProcessDumpPidField, pid);
      dump->AppendVarInt(kProcessDumpTimestampField, mono_ns);
      if (start_mono_ns != 0) {
        dump->AppendVarInt(kProcessDumpStartTimestampField, start_mono_ns);
      }
      dump->AppendString(kProcessDumpHeapNameField, kDartHeapName);
      dump->AppendVarInt(kProcessDumpSamplingIntervalField,
                         static_cast<uint64_t>(sampling_interval));
      dump->AppendVarInt(kProcessDumpOrigSamplingIntervalField,
                         static_cast<uint64_t>(sampling_interval));

      for (size_t i = start; i < end; ++i) {
        const SampleSnapshot& s = snaps[i];
        auto* hs = dump->BeginNestedMessage<protozero::Message>(
            kProcessDumpSamplesField);
        hs->AppendVarInt(kHeapSampleCallstackIdField,
                         callstack_iids[i - start]);
        hs->AppendVarInt(kHeapSampleSelfAllocatedField, s.self_allocated);
        hs->AppendVarInt(kHeapSampleSelfFreedField, s.self_freed);
        hs->AppendVarInt(kHeapSampleAllocCountField, s.alloc_count);
        hs->AppendVarInt(kHeapSampleFreeCountField, s.free_count);
        hs->Finalize();
      }
      dump->Finalize();
      prof->Finalize();
    });
  }

  std::free(elf_ctx.segs);
  HeapSampleAggregator::FreeSnapshot(snaps, num_snaps);
}

}  // namespace flutter::heap_profile_internal

#endif  // FLUTTER_RUNTIME_DART_HEAP_PROFILER_INTERNAL_H_
