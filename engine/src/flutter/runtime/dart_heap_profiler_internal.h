// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_HEAP_PROFILER_INTERNAL_H_
#define FLUTTER_RUNTIME_DART_HEAP_PROFILER_INTERNAL_H_

#include <elf.h>
#include <link.h>
#include <time.h>
#include <unwind.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <cstdint>
#include <limits>
#include <memory>
#include <mutex>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "flutter/fml/file.h"
#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/process.h"
#include "perfetto/protozero/message.h"
#include "perfetto/protozero/proto_decoder.h"
#include "perfetto/protozero/proto_utils.h"
#include "perfetto/protozero/scattered_heap_buffer.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter::heap_profile_internal {

inline constexpr std::string_view kHeapprofdDataSourceName =
    "android.heapprofd";
inline constexpr std::string_view kDartHeapName = "com.google.dart";
inline constexpr intptr_t kDefaultSamplingInterval = 512 * 1024;
inline constexpr size_t kMaxStackFrames = 64;
inline constexpr size_t kSamplesPerPacketBatch = 128;

// Perfetto TracePacket / InternedData / ProfilePacket protobuf field IDs.
namespace proto_fields {

inline constexpr uint32_t kTracePacketTimestamp = 8;
inline constexpr uint32_t kTracePacketTrustedSeqId = 10;
inline constexpr uint32_t kTracePacketInternedData = 12;
inline constexpr uint32_t kTracePacketSequenceFlags = 13;
inline constexpr uint32_t kTracePacketProfilePacket = 37;

inline constexpr uint32_t kSeqIncrementalStateCleared = 1u;
inline constexpr uint32_t kSeqNeedsIncrementalState = 2u;

inline constexpr uint32_t kInternedFunctionNames = 5;
inline constexpr uint32_t kInternedFrames = 6;
inline constexpr uint32_t kInternedCallstacks = 7;
inline constexpr uint32_t kInternedBuildIds = 16;
inline constexpr uint32_t kInternedMappingPaths = 17;
inline constexpr uint32_t kInternedMappings = 19;

inline constexpr uint32_t kInternedStringIid = 1;
inline constexpr uint32_t kInternedStringStr = 2;

inline constexpr uint32_t kMappingIid = 1;
inline constexpr uint32_t kMappingBuildId = 2;
inline constexpr uint32_t kMappingStart = 4;
inline constexpr uint32_t kMappingEnd = 5;
inline constexpr uint32_t kMappingLoadBias = 6;
inline constexpr uint32_t kMappingPathStringIds = 7;
inline constexpr uint32_t kMappingExactOffset = 8;

inline constexpr uint32_t kFrameIid = 1;
inline constexpr uint32_t kFrameFunctionNameId = 2;
inline constexpr uint32_t kFrameMappingId = 3;
inline constexpr uint32_t kFrameRelPc = 4;

inline constexpr uint32_t kCallstackIid = 1;
inline constexpr uint32_t kCallstackFrameIds = 2;

inline constexpr uint32_t kProfilePacketProcessDumps = 5;
inline constexpr uint32_t kProfilePacketContinued = 6;
inline constexpr uint32_t kProfilePacketIndex = 7;

inline constexpr uint32_t kProcessDumpPid = 1;
inline constexpr uint32_t kProcessDumpSamples = 2;
inline constexpr uint32_t kProcessDumpTimestamp = 9;
inline constexpr uint32_t kProcessDumpHeapName = 11;
inline constexpr uint32_t kProcessDumpSamplingInterval = 12;
inline constexpr uint32_t kProcessDumpOrigSamplingInterval = 13;
inline constexpr uint32_t kProcessDumpStartTimestamp = 15;

inline constexpr uint32_t kHeapSampleCallstackId = 1;
inline constexpr uint32_t kHeapSampleSelfAllocated = 2;
inline constexpr uint32_t kHeapSampleSelfFreed = 3;
inline constexpr uint32_t kHeapSampleAllocCount = 5;
inline constexpr uint32_t kHeapSampleFreeCount = 6;

}  // namespace proto_fields

/// Returns `CLOCK_BOOTTIME` in nanoseconds (Perfetto's default trace clock).
inline uint64_t GetBootTimeNs() {
  struct timespec ts = {};
  ::clock_gettime(CLOCK_BOOTTIME, &ts);
  return static_cast<uint64_t>(ts.tv_sec) * 1000000000ULL +
         static_cast<uint64_t>(ts.tv_nsec);
}

/// Returns `CLOCK_MONOTONIC_COARSE` in nanoseconds (heapprofd dump clock).
inline uint64_t GetMonotonicCoarseNs() {
  struct timespec ts = {};
  ::clock_gettime(CLOCK_MONOTONIC_COARSE, &ts);
  return static_cast<uint64_t>(ts.tv_sec) * 1000000000ULL +
         static_cast<uint64_t>(ts.tv_nsec);
}

/// Captures synchronous native/Dart AOT stack frames in-process using the
/// system `_Unwind_Backtrace` resolved via `fml::NativeLibrary`.
class StackUnwinder {
 public:
  static size_t Capture(std::span<uintptr_t> out_pcs) {
    const auto& symbols = GetSymbols();
    if (!symbols.backtrace.has_value() || !symbols.get_ip.has_value() ||
        out_pcs.empty()) {
      return 0;
    }
    WalkContext ctx = {
        .get_ip = *symbols.get_ip,
        .out = out_pcs,
        .count = 0,
        .frames_to_skip = 2,
    };
    (*symbols.backtrace)(&OnFrame, &ctx);
    return ctx.count;
  }

 private:
  using BacktraceFn = _Unwind_Reason_Code (*)(_Unwind_Trace_Fn, void*);
  using GetIpFn = _Unwind_Ptr (*)(struct _Unwind_Context*);

  struct Symbols {
    std::optional<BacktraceFn> backtrace;
    std::optional<GetIpFn> get_ip;
  };

  struct WalkContext {
    GetIpFn get_ip;
    std::span<uintptr_t> out;
    size_t count;
    size_t frames_to_skip;
  };

  static const Symbols& GetSymbols() {
    static const Symbols kSymbols = []() {
      Symbols resolved;
      auto process_lib = fml::NativeLibrary::CreateForCurrentProcess();
      if (process_lib) {
        resolved.backtrace =
            process_lib->ResolveFunction<BacktraceFn>("_Unwind_Backtrace");
        resolved.get_ip =
            process_lib->ResolveFunction<GetIpFn>("_Unwind_GetIP");
      }
      return resolved;
    }();
    return kSymbols;
  }

  static _Unwind_Reason_Code OnFrame(struct _Unwind_Context* context,
                                     void* arg) {
    auto* ctx = static_cast<WalkContext*>(arg);
    uintptr_t pc = static_cast<uintptr_t>(ctx->get_ip(context));
    if (pc == 0) {
      return _URC_END_OF_STACK;
    }
    if (ctx->frames_to_skip > 0) {
      ctx->frames_to_skip--;
      return _URC_NO_REASON;
    }
#if defined(__aarch64__)
    // xpaclri (HINT #7): strips PAC bits on ARMv8.3+, executes as NOP on v8.0.
    register uintptr_t x30 __asm__("x30") = pc;
    __asm__("hint #7" : "+r"(x30));
    pc = x30 > 4 ? x30 - 4 : x30;
#else
    if (pc > 1) {
      pc -= 1;
    }
#endif
    ctx->out[ctx->count++] = pc;
    return ctx->count >= ctx->out.size() ? _URC_END_OF_STACK : _URC_NO_REASON;
  }
};

/// Thread-safe reference-counted callsite entry tracking cumulative allocations
/// and GC deallocations for a unique `(isolate_group, class_name, pcs)` tuple.
class AggregatedSample : public fml::RefCountedThreadSafe<AggregatedSample> {
 public:
  size_t hash() const { return hash_; }
  uintptr_t group_key() const { return group_key_; }
  std::string_view class_name() const { return class_name_; }
  std::span<const uintptr_t> pcs() const { return {pcs_.get(), num_frames_}; }

  bool Matches(uintptr_t group_key,
               size_t hash,
               std::string_view class_name,
               std::span<const uintptr_t> pcs) const {
    return hash_ == hash && group_key_ == group_key &&
           class_name_ == class_name &&
           std::equal(pcs.begin(), pcs.end(), this->pcs().begin(),
                      this->pcs().end());
  }

  void RecordAlloc(uint64_t bytes) {
    self_allocated_.fetch_add(bytes, std::memory_order_relaxed);
    alloc_count_.fetch_add(1, std::memory_order_relaxed);
    dirty_.store(true, std::memory_order_release);
  }

  void RecordFree(uint64_t bytes) {
    self_freed_.fetch_add(bytes, std::memory_order_relaxed);
    free_count_.fetch_add(1, std::memory_order_relaxed);
    dirty_.store(true, std::memory_order_release);
  }

  bool TakeDirtyFlag() {
    return dirty_.exchange(false, std::memory_order_acq_rel);
  }

  void MarkDirty() { dirty_.store(true, std::memory_order_release); }

  uint64_t self_allocated() const {
    return self_allocated_.load(std::memory_order_relaxed);
  }
  uint64_t self_freed() const {
    return self_freed_.load(std::memory_order_relaxed);
  }
  uint64_t alloc_count() const {
    return alloc_count_.load(std::memory_order_relaxed);
  }
  uint64_t free_count() const {
    return free_count_.load(std::memory_order_relaxed);
  }

 private:
  AggregatedSample(uintptr_t group_key,
                   size_t hash,
                   std::string_view class_name,
                   std::span<const uintptr_t> pcs)
      : hash_(hash),
        group_key_(group_key),
        num_frames_(pcs.size()),
        pcs_(std::make_unique<uintptr_t[]>(pcs.size())),
        class_name_(class_name) {
    std::copy_n(pcs.data(), pcs.size(), pcs_.get());
  }

  ~AggregatedSample() = default;

  size_t hash_ = 0;
  uintptr_t group_key_ = 0;
  size_t num_frames_ = 0;
  std::unique_ptr<uintptr_t[]> pcs_;
  std::string class_name_;
  std::atomic<uint64_t> self_allocated_{0};
  std::atomic<uint64_t> self_freed_{0};
  std::atomic<uint64_t> alloc_count_{0};
  std::atomic<uint64_t> free_count_{0};
  std::atomic<bool> dirty_{false};

  FML_FRIEND_MAKE_REF_COUNTED(AggregatedSample);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(AggregatedSample);
  FML_DISALLOW_COPY_AND_ASSIGN(AggregatedSample);
};

/// Point-in-time cumulative counters for a modified callsite.
struct SampleSnapshot {
  fml::RefPtr<AggregatedSample> sample;
  uint64_t self_allocated = 0;
  uint64_t self_freed = 0;
  uint64_t alloc_count = 0;
  uint64_t free_count = 0;
};

/// Open-addressed hash table aggregating sampled Dart allocations by callstack
/// and class name without `std::unordered_map` node/bucket overhead.
class HeapSampleAggregator {
 public:
  HeapSampleAggregator() = default;
  ~HeapSampleAggregator() = default;

  /// Unwinds the current thread's stack and records a sampled allocation.
  void* RecordCurrentThreadAlloc(Dart_IsolateGroup group,
                                 const char* cls_name,
                                 intptr_t size) {
    if (size <= 0) {
      return nullptr;
    }
    std::array<uintptr_t, kMaxStackFrames> pcs;
    const size_t count = StackUnwinder::Capture(pcs);
    return RecordAllocWithPcs(group, cls_name, size,
                              std::span<const uintptr_t>(pcs.data(), count));
  }

  /// Records a sampled allocation for explicit `pcs` and returns an opaque
  /// handle owned by Dart's weak-table entry until `RecordFree` runs.
  void* RecordAllocWithPcs(Dart_IsolateGroup group,
                           const char* cls_name,
                           intptr_t size,
                           std::span<const uintptr_t> pcs) {
    if (size <= 0 || pcs.empty() || pcs.size() > kMaxStackFrames) {
      return nullptr;
    }
    const std::string_view safe_cls =
        (cls_name != nullptr && cls_name[0] != '\0')
            ? std::string_view(cls_name)
            : std::string_view("Unknown");
    const auto group_key = reinterpret_cast<uintptr_t>(group);
    const size_t hash = ComputeHash(group_key, safe_cls, pcs);

    fml::RefPtr<AggregatedSample> entry;
    {
      std::scoped_lock lock(mutex_);
      entry = LookupOrInsertLocked(group_key, hash, safe_cls, pcs);
    }
    const auto byte_size = static_cast<uint64_t>(size);
    entry->RecordAlloc(byte_size);
    return new SampledAllocationHandle{std::move(entry), byte_size};
  }

  /// Lock-free GC finalizer callback attributing freed bytes to the callsite.
  static void RecordFree(void* data) {
    if (data == nullptr) {
      return;
    }
    std::unique_ptr<SampledAllocationHandle> handle(
        static_cast<SampledAllocationHandle*>(data));
    handle->sample->RecordFree(handle->size);
  }

  /// Snapshots all entries modified since the previous snapshot.
  std::vector<SampleSnapshot> TakeSnapshot() {
    std::scoped_lock lock(mutex_);
    std::vector<SampleSnapshot> snapshots;
    if (count_ == 0) {
      return snapshots;
    }
    snapshots.reserve(count_);
    for (size_t i = 0; i < capacity_; ++i) {
      const fml::RefPtr<AggregatedSample>& entry = buckets_[i];
      if (!entry || !entry->TakeDirtyFlag()) {
        continue;
      }
      snapshots.push_back(SampleSnapshot{
          .sample = entry,
          .self_allocated = entry->self_allocated(),
          .self_freed = entry->self_freed(),
          .alloc_count = entry->alloc_count(),
          .free_count = entry->free_count(),
      });
    }
    return snapshots;
  }

  /// Marks all active entries dirty after an incremental state clear.
  void MarkAllDirty() {
    std::scoped_lock lock(mutex_);
    for (size_t i = 0; i < capacity_; ++i) {
      if (buckets_[i]) {
        buckets_[i]->MarkDirty();
      }
    }
  }

  /// Clears all map entries when a profiling session stops.
  void Clear() {
    std::scoped_lock lock(mutex_);
    for (size_t i = 0; i < capacity_; ++i) {
      buckets_[i] = nullptr;
    }
    count_ = 0;
  }

 private:
  struct SampledAllocationHandle {
    fml::RefPtr<AggregatedSample> sample;
    uint64_t size = 0;
  };

  static size_t ComputeHash(uintptr_t group_key,
                            std::string_view cls_name,
                            std::span<const uintptr_t> pcs) {
    size_t seed = fml::HashCombine(group_key, cls_name);
    for (uintptr_t pc : pcs) {
      fml::HashCombineSeed(seed, pc);
    }
    return seed;
  }

  fml::RefPtr<AggregatedSample> LookupOrInsertLocked(
      uintptr_t group_key,
      size_t hash,
      std::string_view cls_name,
      std::span<const uintptr_t> pcs) {
    if (capacity_ == 0 || (count_ + 1) * 10 >= capacity_ * 7) {
      GrowLocked();
    }
    const size_t mask = capacity_ - 1;
    size_t idx = hash & mask;
    while (buckets_[idx]) {
      if (buckets_[idx]->Matches(group_key, hash, cls_name, pcs)) {
        return buckets_[idx];
      }
      idx = (idx + 1) & mask;
    }
    auto created =
        fml::MakeRefCounted<AggregatedSample>(group_key, hash, cls_name, pcs);
    buckets_[idx] = created;
    count_++;
    return created;
  }

  void GrowLocked() {
    const size_t new_capacity = capacity_ == 0 ? 256 : capacity_ * 2;
    auto new_buckets =
        std::make_unique<fml::RefPtr<AggregatedSample>[]>(new_capacity);
    const size_t mask = new_capacity - 1;
    for (size_t i = 0; i < capacity_; ++i) {
      if (!buckets_[i]) {
        continue;
      }
      size_t idx = buckets_[i]->hash() & mask;
      while (new_buckets[idx]) {
        idx = (idx + 1) & mask;
      }
      new_buckets[idx] = std::move(buckets_[i]);
    }
    buckets_ = std::move(new_buckets);
    capacity_ = new_capacity;
  }

  std::mutex mutex_;
  std::unique_ptr<fml::RefPtr<AggregatedSample>[]> buckets_;
  size_t count_ = 0;
  size_t capacity_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(HeapSampleAggregator);
};

/// Executable ELF segment discovered in-process via `dl_iterate_phdr`.
struct ElfSegment {
  uintptr_t start = 0;
  uintptr_t end = 0;
  uint64_t exact_offset = 0;
  uint64_t load_bias = 0;
  std::string path;
  std::array<uint8_t, 32> build_id = {};
  uint8_t build_id_len = 0;
  uint64_t mapping_iid = 0;
};

/// Enumerates loaded executable `PT_LOAD` segments and `NT_GNU_BUILD_ID` notes.
class ElfModuleScanner {
 public:
  static std::vector<ElfSegment> ScanLoadedExecutableSegments() {
    std::vector<ElfSegment> segments;
    segments.reserve(32);
    ::dl_iterate_phdr(&OnPhdr, &segments);
    return segments;
  }

 private:
  static uint8_t ExtractGnuBuildId(const dl_phdr_info* info,
                                   std::array<uint8_t, 32>* out) {
    constexpr std::string_view kGnuNoteName("GNU\0", 4);
    constexpr uint32_t kNtGnuBuildId = 3;

    for (size_t i = 0; i < info->dlpi_phnum; ++i) {
      const auto& ph = info->dlpi_phdr[i];
      if (ph.p_type != PT_NOTE || ph.p_memsz == 0 ||
          (ph.p_vaddr % alignof(ElfW(Nhdr))) != 0) {
        continue;
      }
      const auto* ptr =
          reinterpret_cast<const uint8_t*>(info->dlpi_addr + ph.p_vaddr);
      const uint8_t* end = ptr + ph.p_memsz;
      while (ptr + sizeof(ElfW(Nhdr)) <= end) {
        const auto* nhdr = reinterpret_cast<const ElfW(Nhdr)*>(ptr);
        ptr += sizeof(ElfW(Nhdr));
        const size_t name_aligned = (nhdr->n_namesz + 3u) & ~3u;
        const size_t desc_aligned = (nhdr->n_descsz + 3u) & ~3u;
        if (ptr + name_aligned + desc_aligned > end) {
          break;
        }
        const std::string_view note_name(reinterpret_cast<const char*>(ptr),
                                         nhdr->n_namesz);
        if (nhdr->n_type == kNtGnuBuildId && note_name == kGnuNoteName &&
            nhdr->n_descsz <= out->size()) {
          std::copy_n(ptr + name_aligned, nhdr->n_descsz, out->begin());
          return static_cast<uint8_t>(nhdr->n_descsz);
        }
        ptr += name_aligned + desc_aligned;
      }
    }
    return 0;
  }

  static int OnPhdr(struct dl_phdr_info* info, size_t /*size*/, void* data) {
    auto* segments = static_cast<std::vector<ElfSegment>*>(data);
    std::array<uint8_t, 32> build_id = {};
    const uint8_t build_id_len = ExtractGnuBuildId(info, &build_id);
    const std::string_view raw_name =
        (info->dlpi_name != nullptr && info->dlpi_name[0] != '\0')
            ? std::string_view(info->dlpi_name)
            : std::string_view("[executable]");

    for (size_t i = 0; i < info->dlpi_phnum; ++i) {
      const auto& ph = info->dlpi_phdr[i];
      if (ph.p_type != PT_LOAD || (ph.p_flags & PF_X) == 0 || ph.p_memsz == 0) {
        continue;
      }
      const auto seg_start =
          static_cast<uintptr_t>(info->dlpi_addr + ph.p_vaddr);
      segments->push_back(ElfSegment{
          .start = seg_start,
          .end = seg_start + static_cast<uintptr_t>(ph.p_memsz),
          .exact_offset = ph.p_offset,
          .load_bias = ph.p_vaddr - ph.p_offset,
          .path = std::string(raw_name),
          .build_id = build_id,
          .build_id_len = build_id_len,
          .mapping_iid = 0,
      });
    }
    return 0;
  }
};

/// Parsed configuration for a matched `"android.heapprofd"` tracing session.
struct ParsedHeapprofdSession {
  bool matched = false;
  uint32_t target_buffer = 0;
  intptr_t sampling_interval = kDefaultSamplingInterval;
  uint32_t dump_phase_ms = 0;
  uint32_t dump_interval_ms = 0;
};

/// Matches `text` against a glob `pattern` supporting `*` wildcards.
inline bool MatchWildcard(std::string_view pattern, std::string_view text) {
  size_t p = 0;
  size_t t = 0;
  size_t star_p = std::string_view::npos;
  size_t star_t = 0;
  while (t < text.size()) {
    if (p < pattern.size() && pattern[p] == '*') {
      star_p = p++;
      star_t = t;
    } else if (p < pattern.size() && pattern[p] == text[t]) {
      p++;
      t++;
    } else if (star_p != std::string_view::npos) {
      p = star_p + 1;
      t = ++star_t;
    } else {
      return false;
    }
  }
  while (p < pattern.size() && pattern[p] == '*') {
    p++;
  }
  return p == pattern.size();
}

/// Strips NUL arguments, leading directory components, and trailing `@...`
/// suffixes per Perfetto's `HeapprofdConfig.process_cmdline` rules.
inline std::string_view NormalizeCmdline(std::string_view cmdline) {
  if (const size_t nul = cmdline.find('\0'); nul != std::string_view::npos) {
    cmdline = cmdline.substr(0, nul);
  }
  if (const size_t at = cmdline.find('@'); at != std::string_view::npos) {
    cmdline = cmdline.substr(0, at);
  }
  if (const size_t slash = cmdline.rfind('/');
      slash != std::string_view::npos) {
    cmdline = cmdline.substr(slash + 1);
  }
  return cmdline;
}

inline bool MatchesCmdlineEntry(std::string_view pattern,
                                std::string_view self_cmdline) {
  if (const size_t nul = self_cmdline.find('\0');
      nul != std::string_view::npos) {
    self_cmdline = self_cmdline.substr(0, nul);
  }
  if (pattern.find('*') != std::string_view::npos) {
    std::string_view target = self_cmdline;
    if (!pattern.starts_with('/')) {
      if (const size_t slash = target.rfind('/');
          slash != std::string_view::npos) {
        target = target.substr(slash + 1);
      }
    }
    return MatchWildcard(pattern, target);
  }
  return NormalizeCmdline(pattern) == NormalizeCmdline(self_cmdline);
}

inline intptr_t ClampSamplingInterval(uint64_t raw) {
  constexpr auto kMax =
      static_cast<uint64_t>(std::numeric_limits<intptr_t>::max());
  return static_cast<intptr_t>(std::min(raw, kMax));
}

/// Evaluates `DataSourceConfig` (and nested `HeapprofdConfig`) against
/// `self_pid` and `self_cmdline`.
inline ParsedHeapprofdSession ParseDataSourceConfigForProcess(
    std::span<const uint8_t> config_bytes,
    uint64_t self_pid,
    std::optional<std::string_view> self_cmdline) {
  ParsedHeapprofdSession res;
  protozero::ProtoDecoder dsc(config_bytes.data(), config_bytes.size());
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
  std::optional<size_t> dart_heap_index;
  std::array<uint64_t, 16> intervals = {};
  size_t interval_count = 0;

  protozero::ProtoDecoder hc(heapprofd_raw.data, heapprofd_raw.size);
  for (auto f = hc.ReadField(); f.valid(); f = hc.ReadField()) {
    const std::string_view str_val(reinterpret_cast<const char*>(f.data()),
                                   f.size());
    switch (f.id()) {
      case 1:  // sampling_interval_bytes
        if (f.as_uint64() > 0) {
          res.sampling_interval = ClampSamplingInterval(f.as_uint64());
        }
        break;
      case 2:  // process_cmdline
        has_pid_or_cmd = true;
        if (self_cmdline.has_value() && !pid_or_cmd_matched &&
            MatchesCmdlineEntry(str_val, *self_cmdline)) {
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
        if (str_val == kDartHeapName) {
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
          while (p < end_p && interval_count < intervals.size()) {
            uint64_t val = 0;
            const uint8_t* next =
                protozero::proto_utils::ParseVarInt(p, end_p, &val);
            if (next == p) {
              break;
            }
            intervals[interval_count++] = val;
            p = next;
          }
        } else if (interval_count < intervals.size()) {
          intervals[interval_count++] = f.as_uint64();
        }
        break;
      case 27:  // exclude_heaps
        if (str_val == kDartHeapName) {
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
  if (!all_heaps && !dart_heap_index.has_value()) {
    return res;
  }
  if (!all_procs && has_pid_or_cmd && !pid_or_cmd_matched) {
    return res;
  }
  if (dart_heap_index.has_value() && *dart_heap_index < interval_count &&
      intervals[*dart_heap_index] > 0) {
    res.sampling_interval = ClampSamplingInterval(intervals[*dart_heap_index]);
  }
  res.matched = true;
  return res;
}

/// Evaluates `DataSourceConfig` against the current OS process using `fml`.
inline ParsedHeapprofdSession ParseDataSourceConfig(
    std::span<const uint8_t> config_bytes) {
  const auto cmdline = fml::ReadFileToString("/proc/self/cmdline", 256);
  std::optional<std::string_view> cmdline_view;
  if (cmdline.has_value()) {
    cmdline_view = *cmdline;
  }
  return ParseDataSourceConfigForProcess(
      config_bytes, static_cast<uint64_t>(fml::GetCurrentProcId()),
      cmdline_view);
}

/// Stateful serializer for a single heap dump across one or more continued
/// `TracePacket` batches.
class ProfileDumpSerializer {
 public:
  ProfileDumpSerializer(std::span<ElfSegment> segments,
                        intptr_t sampling_interval,
                        uint64_t boot_ns,
                        uint64_t mono_ns,
                        uint64_t start_mono_ns,
                        uint64_t* packet_index)
      : segments_(segments),
        sampling_interval_(sampling_interval),
        boot_ns_(boot_ns),
        mono_ns_(mono_ns),
        start_mono_ns_(start_mono_ns),
        pid_(static_cast<uint64_t>(fml::GetCurrentProcId())),
        packet_index_(packet_index) {}

  void WriteBatch(std::span<const SampleSnapshot> batch,
                  bool is_first_batch,
                  bool continued,
                  protozero::Message* packet) {
    const uint32_t seq_flags =
        is_first_batch ? (proto_fields::kSeqIncrementalStateCleared |
                          proto_fields::kSeqNeedsIncrementalState)
                       : proto_fields::kSeqNeedsIncrementalState;
    packet->AppendVarInt(proto_fields::kTracePacketTimestamp, boot_ns_);
    packet->AppendVarInt(proto_fields::kTracePacketSequenceFlags, seq_flags);

    std::array<uint64_t, kSamplesPerPacketBatch> callstack_iids = {};
    {
      auto* interned = packet->BeginNestedMessage<protozero::Message>(
          proto_fields::kTracePacketInternedData);
      if (is_first_batch) {
        EmitEmptyDefaultInternings(interned);
      }
      for (size_t i = 0; i < batch.size(); ++i) {
        callstack_iids[i] = InternSampleCallstack(interned, *batch[i].sample);
      }
      interned->Finalize();
    }
    WriteProcessDump(packet, batch, callstack_iids, continued);
  }

 private:
  static uint64_t AppendInternedBytes(protozero::Message* interned,
                                      uint32_t field_id,
                                      uint64_t iid,
                                      std::span<const uint8_t> bytes) {
    auto* entry = interned->BeginNestedMessage<protozero::Message>(field_id);
    entry->AppendVarInt(proto_fields::kInternedStringIid, iid);
    entry->AppendBytes(proto_fields::kInternedStringStr, bytes.data(),
                       bytes.size());
    entry->Finalize();
    return iid;
  }

  static uint64_t AppendInternedString(protozero::Message* interned,
                                       uint32_t field_id,
                                       uint64_t iid,
                                       std::string_view str) {
    return AppendInternedBytes(
        interned, field_id, iid,
        std::span<const uint8_t>(reinterpret_cast<const uint8_t*>(str.data()),
                                 str.size()));
  }

  static void EmitEmptyDefaultInternings(protozero::Message* interned) {
    AppendInternedString(interned, proto_fields::kInternedBuildIds, 0, "");
    AppendInternedString(interned, proto_fields::kInternedMappingPaths, 0, "");
    AppendInternedString(interned, proto_fields::kInternedFunctionNames, 0, "");
  }

  uint64_t InternSegmentMapping(protozero::Message* interned, ElfSegment& seg) {
    if (seg.mapping_iid != 0) {
      return seg.mapping_iid;
    }
    const uint64_t build_id_iid =
        seg.build_id_len > 0
            ? AppendInternedBytes(interned, proto_fields::kInternedBuildIds,
                                  next_str_iid_++,
                                  std::span<const uint8_t>(seg.build_id.data(),
                                                           seg.build_id_len))
            : 0;
    const uint64_t path_iid =
        AppendInternedString(interned, proto_fields::kInternedMappingPaths,
                             next_str_iid_++, seg.path);

    seg.mapping_iid = next_map_iid_++;
    auto* mp = interned->BeginNestedMessage<protozero::Message>(
        proto_fields::kInternedMappings);
    mp->AppendVarInt(proto_fields::kMappingIid, seg.mapping_iid);
    mp->AppendVarInt(proto_fields::kMappingBuildId, build_id_iid);
    mp->AppendVarInt(proto_fields::kMappingExactOffset, seg.exact_offset);
    mp->AppendVarInt(proto_fields::kMappingStart, seg.start);
    mp->AppendVarInt(proto_fields::kMappingEnd, seg.end);
    mp->AppendVarInt(proto_fields::kMappingLoadBias, seg.load_bias);
    mp->AppendVarInt(proto_fields::kMappingPathStringIds, path_iid);
    mp->Finalize();
    return seg.mapping_iid;
  }

  uint64_t InternUnknownMapping(protozero::Message* interned) {
    if (unknown_map_iid_ != 0) {
      return unknown_map_iid_;
    }
    unknown_map_iid_ = next_map_iid_++;
    auto* mp = interned->BeginNestedMessage<protozero::Message>(
        proto_fields::kInternedMappings);
    mp->AppendVarInt(proto_fields::kMappingIid, unknown_map_iid_);
    mp->AppendVarInt(proto_fields::kMappingBuildId, 0);
    mp->AppendVarInt(proto_fields::kMappingStart, 0);
    mp->AppendVarInt(proto_fields::kMappingEnd,
                     std::numeric_limits<uint64_t>::max());
    mp->Finalize();
    return unknown_map_iid_;
  }

  uint64_t InternAddressFrame(protozero::Message* interned, uintptr_t pc) {
    uint64_t map_iid = 0;
    uint64_t rel_pc = pc;
    for (ElfSegment& seg : segments_) {
      if (pc >= seg.start && pc < seg.end) {
        map_iid = InternSegmentMapping(interned, seg);
        rel_pc = (pc - seg.start) + seg.exact_offset;
        break;
      }
    }
    if (map_iid == 0) {
      map_iid = InternUnknownMapping(interned);
    }
    const uint64_t frame_iid = next_frame_iid_++;
    auto* fr = interned->BeginNestedMessage<protozero::Message>(
        proto_fields::kInternedFrames);
    fr->AppendVarInt(proto_fields::kFrameIid, frame_iid);
    fr->AppendVarInt(proto_fields::kFrameMappingId, map_iid);
    fr->AppendVarInt(proto_fields::kFrameRelPc, rel_pc);
    fr->Finalize();
    return frame_iid;
  }

  uint64_t InternClassLeafFrame(protozero::Message* interned,
                                std::string_view cls_name) {
    const uint64_t fn_iid =
        AppendInternedString(interned, proto_fields::kInternedFunctionNames,
                             next_str_iid_++, cls_name);
    const uint64_t frame_iid = next_frame_iid_++;
    auto* fr = interned->BeginNestedMessage<protozero::Message>(
        proto_fields::kInternedFrames);
    fr->AppendVarInt(proto_fields::kFrameIid, frame_iid);
    fr->AppendVarInt(proto_fields::kFrameFunctionNameId, fn_iid);
    fr->Finalize();
    return frame_iid;
  }

  uint64_t InternSampleCallstack(protozero::Message* interned,
                                 const AggregatedSample& sample) {
    std::array<uint64_t, kMaxStackFrames + 1> frame_iids = {};
    size_t frame_count = 0;
    const auto pcs = sample.pcs();
    // Perfetto Callstack frame_ids are ordered root-first.
    for (size_t k = pcs.size(); k > 0; --k) {
      frame_iids[frame_count++] = InternAddressFrame(interned, pcs[k - 1]);
    }
    frame_iids[frame_count++] =
        InternClassLeafFrame(interned, sample.class_name());

    const uint64_t callstack_iid = next_callstack_iid_++;
    auto* cs = interned->BeginNestedMessage<protozero::Message>(
        proto_fields::kInternedCallstacks);
    cs->AppendVarInt(proto_fields::kCallstackIid, callstack_iid);
    for (size_t i = 0; i < frame_count; ++i) {
      cs->AppendVarInt(proto_fields::kCallstackFrameIds, frame_iids[i]);
    }
    cs->Finalize();
    return callstack_iid;
  }

  void WriteProcessDump(
      protozero::Message* packet,
      std::span<const SampleSnapshot> batch,
      const std::array<uint64_t, kSamplesPerPacketBatch>& callstack_iids,
      bool continued) {
    auto* prof = packet->BeginNestedMessage<protozero::Message>(
        proto_fields::kTracePacketProfilePacket);
    prof->AppendVarInt(proto_fields::kProfilePacketContinued,
                       continued ? 1u : 0u);
    prof->AppendVarInt(proto_fields::kProfilePacketIndex, (*packet_index_)++);

    auto* dump = prof->BeginNestedMessage<protozero::Message>(
        proto_fields::kProfilePacketProcessDumps);
    dump->AppendVarInt(proto_fields::kProcessDumpPid, pid_);
    dump->AppendVarInt(proto_fields::kProcessDumpTimestamp, mono_ns_);
    if (start_mono_ns_ != 0) {
      dump->AppendVarInt(proto_fields::kProcessDumpStartTimestamp,
                         start_mono_ns_);
    }
    dump->AppendBytes(proto_fields::kProcessDumpHeapName, kDartHeapName.data(),
                      kDartHeapName.size());
    dump->AppendVarInt(proto_fields::kProcessDumpSamplingInterval,
                       static_cast<uint64_t>(sampling_interval_));
    dump->AppendVarInt(proto_fields::kProcessDumpOrigSamplingInterval,
                       static_cast<uint64_t>(sampling_interval_));

    for (size_t i = 0; i < batch.size(); ++i) {
      const SampleSnapshot& s = batch[i];
      auto* hs = dump->BeginNestedMessage<protozero::Message>(
          proto_fields::kProcessDumpSamples);
      hs->AppendVarInt(proto_fields::kHeapSampleCallstackId, callstack_iids[i]);
      hs->AppendVarInt(proto_fields::kHeapSampleSelfAllocated,
                       s.self_allocated);
      hs->AppendVarInt(proto_fields::kHeapSampleSelfFreed, s.self_freed);
      hs->AppendVarInt(proto_fields::kHeapSampleAllocCount, s.alloc_count);
      hs->AppendVarInt(proto_fields::kHeapSampleFreeCount, s.free_count);
      hs->Finalize();
    }
    dump->Finalize();
    prof->Finalize();
  }

  std::span<ElfSegment> segments_;
  intptr_t sampling_interval_;
  uint64_t boot_ns_;
  uint64_t mono_ns_;
  uint64_t start_mono_ns_;
  uint64_t pid_;
  uint64_t* packet_index_;

  uint64_t next_str_iid_ = 1;
  uint64_t next_map_iid_ = 1;
  uint64_t next_frame_iid_ = 1;
  uint64_t next_callstack_iid_ = 1;
  uint64_t unknown_map_iid_ = 0;
};

/// Snapshots modified heap samples and emits them across one or more
/// `TracePacket` batches.
template <typename EmitPacketFn>
void WriteHeapProfilePackets(HeapSampleAggregator& aggregator,
                             intptr_t sampling_interval,
                             uint64_t* packet_index,
                             uint64_t* prev_dump_mono_ns,
                             EmitPacketFn&& emit_packet) {
  const std::vector<SampleSnapshot> snapshots = aggregator.TakeSnapshot();
  if (snapshots.empty()) {
    return;
  }

  std::vector<ElfSegment> segments =
      ElfModuleScanner::ScanLoadedExecutableSegments();
  const uint64_t boot_ns = GetBootTimeNs();
  const uint64_t mono_ns = GetMonotonicCoarseNs();
  const uint64_t start_mono_ns = *prev_dump_mono_ns;
  *prev_dump_mono_ns = mono_ns;

  ProfileDumpSerializer serializer(segments, sampling_interval, boot_ns,
                                   mono_ns, start_mono_ns, packet_index);
  const std::span<const SampleSnapshot> all_snaps(snapshots);
  for (size_t offset = 0; offset < all_snaps.size();
       offset += kSamplesPerPacketBatch) {
    const size_t count =
        std::min(kSamplesPerPacketBatch, all_snaps.size() - offset);
    const bool continued = (offset + count) < all_snaps.size();
    emit_packet([&](protozero::Message* packet) {
      serializer.WriteBatch(all_snaps.subspan(offset, count),
                            /*is_first_batch=*/offset == 0, continued, packet);
    });
  }
}

}  // namespace flutter::heap_profile_internal

#endif  // FLUTTER_RUNTIME_DART_HEAP_PROFILER_INTERNAL_H_
