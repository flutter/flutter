// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_DART_HEAP_PROFILER_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_DART_HEAP_PROFILER_INTERNAL_H_

#include <elf.h>
#include <link.h>
#include <stdlib.h>
#include <time.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <cstddef>
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

#include "flutter/fml/macros.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/process.h"
#include "flutter/third_party/dart/third_party/perfetto/protos/perfetto/trace/interned_data/interned_data.pbzero.h"
#include "flutter/third_party/dart/third_party/perfetto/protos/perfetto/trace/profiling/profile_common.pbzero.h"
#include "flutter/third_party/dart/third_party/perfetto/protos/perfetto/trace/trace_packet.pbzero.h"
#include "perfetto/base/time.h"
#include "perfetto/protozero/message.h"
#include "perfetto/protozero/packed_repeated_fields.h"
#include "perfetto/protozero/proto_decoder.h"
#include "perfetto/protozero/scattered_heap_buffer.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_set.h"
#include "third_party/abseil-cpp/absl/hash/hash.h"
#include "third_party/abseil-cpp/absl/types/span.h"

namespace flutter::android_heap_profile_internal {

inline constexpr std::string_view kHeapprofdDataSourceName =
    "android.heapprofd";
inline constexpr std::string_view kJavaHprofDataSourceName =
    "android.java_hprof";
inline constexpr std::string_view kJavaHprofOomDataSourceName =
    "android.java_hprof.oom";
inline constexpr std::string_view kArtOutOfMemoryTriggerName =
    "com.android.telemetry.art-outofmemory";
inline constexpr std::string_view kDartHeapName = "com.google.dart";
inline constexpr std::string_view kDartHeapGraphRootType =
    "com.google.dart.Heap";
inline constexpr std::string_view kDartHeapGraphSampleField =
    "com.google.dart.Heap.sample";
inline constexpr intptr_t kDefaultSamplingInterval = 512 * 1024;
inline constexpr size_t kMaxStackFrames = 256;
inline constexpr size_t kSamplesPerPacketBatch = 128;

inline std::string_view View(protozero::ConstChars c) {
  return {c.data, c.size};
}

/// Captures synchronous native/Dart AOT stack frames in-process using Bionic's
/// `<execinfo.h>` `backtrace()` (available on Android 13+ / API 33+).
inline size_t CaptureStackFrames(std::span<uintptr_t> out_pcs) {
  using BacktraceFn = int (*)(void**, int);
  static const std::optional<BacktraceFn> kBacktrace = [] {
    auto lib = fml::NativeLibrary::CreateForCurrentProcess();
    return lib ? lib->ResolveFunction<BacktraceFn>("backtrace") : std::nullopt;
  }();
  if (!kBacktrace.has_value() || out_pcs.empty()) {
    return 0;
  }
  constexpr size_t kSkip = 2;
  std::array<void*, kMaxStackFrames + kSkip> raw;
  const int n = (*kBacktrace)(
      raw.data(),
      static_cast<int>(std::min(raw.size(), out_pcs.size() + kSkip)));
  if (n <= static_cast<int>(kSkip)) {
    return 0;
  }
  const size_t count = static_cast<size_t>(n) - kSkip;
  for (size_t i = 0; i < count; ++i) {
    out_pcs[i] = reinterpret_cast<uintptr_t>(raw[i + kSkip]);
  }
  return count;
}

/// Non-owning lookup view for heterogeneous `absl::flat_hash_set` queries.
struct SampleKeyView {
  uintptr_t group_key = 0;
  std::string_view class_name;
  std::span<const uintptr_t> pcs;
};

/// Thread-safe callsite entry tracking cumulative allocations and GC
/// deallocations for a unique `(isolate_group, class_name, pcs)` tuple.
struct AggregatedSample {
  static uint64_t NextStableId() {
    static std::atomic<uint64_t> next_id{1};
    return next_id.fetch_add(1, std::memory_order_relaxed);
  }

  AggregatedSample(uintptr_t group,
                   std::string_view cls,
                   std::span<const uintptr_t> frames)
      : stable_id(NextStableId()),
        group_key(group),
        num_frames(frames.size()),
        pcs_storage(std::make_unique<uintptr_t[]>(frames.size())),
        class_name(cls) {
    std::copy_n(frames.data(), frames.size(), pcs_storage.get());
  }

  std::span<const uintptr_t> pcs() const {
    return {pcs_storage.get(), num_frames};
  }
  SampleKeyView key() const { return {group_key, class_name, pcs()}; }

  void ResetSessionCounters() {
    self_allocated.store(0, std::memory_order_relaxed);
    self_freed.store(0, std::memory_order_relaxed);
    alloc_count.store(0, std::memory_order_relaxed);
    free_count.store(0, std::memory_order_relaxed);
  }

  uint64_t stable_id = 0;
  uintptr_t group_key = 0;
  size_t num_frames = 0;
  std::unique_ptr<uintptr_t[]> pcs_storage;
  std::string class_name;
  std::atomic<size_t> live_handles{0};
  std::atomic<uint64_t> self_allocated{0};
  std::atomic<uint64_t> self_freed{0};
  std::atomic<uint64_t> alloc_count{0};
  std::atomic<uint64_t> free_count{0};

  FML_DISALLOW_COPY_AND_ASSIGN(AggregatedSample);
};

/// Point-in-time cumulative counters for a sampled callsite.
struct SampleSnapshot {
  std::shared_ptr<AggregatedSample> sample;
  uint64_t self_allocated = 0;
  uint64_t self_freed = 0;
  uint64_t alloc_count = 0;
  uint64_t free_count = 0;
};

/// Surviving sampled Dart allocation reported via
/// `Dart_ReportSurvivingAllocations` for `"android.java_hprof"` dumps.
struct SurvivingObjectSample {
  std::string class_name;
  uint64_t size = 0;
};

/// Aggregates sampled Dart allocations by callstack and class name, supporting
/// idle background pruning, surviving-allocation session seeding, and
/// incremental flushes.
class HeapSampleAggregator {
 public:
  struct SeededBatch {
    HeapSampleAggregator* aggregator = nullptr;
    std::vector<std::shared_ptr<AggregatedSample>> samples;
  };

  HeapSampleAggregator() = default;
  ~HeapSampleAggregator() = default;

  void BeginSession() {
    std::scoped_lock lock(mutex_);
    session_seq_.store(++next_session_seq_, std::memory_order_release);
    session_active_.store(true, std::memory_order_release);
    has_unreported_activity_.store(false, std::memory_order_release);
    for (const auto& entry : entries_) {
      entry->ResetSessionCounters();
    }
  }

  void EndSession() {
    std::scoped_lock lock(mutex_);
    session_active_.store(false, std::memory_order_release);
    session_seq_.store(0, std::memory_order_release);
    has_unreported_activity_.store(false, std::memory_order_release);
    absl::erase_if(entries_, [](const std::shared_ptr<AggregatedSample>& e) {
      return e->live_handles.load(std::memory_order_acquire) == 0;
    });
  }

  size_t TrackedCallsiteCount() {
    std::scoped_lock lock(mutex_);
    return entries_.size();
  }

  void* RecordCurrentThreadAlloc(uintptr_t isolate_group_id,
                                 std::string_view class_name,
                                 size_t size) {
    if (size == 0) {
      return nullptr;
    }
    std::array<uintptr_t, kMaxStackFrames> pcs;
    const size_t count = CaptureStackFrames(pcs);
    return RecordAllocWithPcs(isolate_group_id, class_name, size,
                              std::span<const uintptr_t>(pcs.data(), count));
  }

  void* RecordAllocWithPcs(uintptr_t isolate_group_id,
                           std::string_view class_name,
                           size_t size,
                           std::span<const uintptr_t> pcs) {
    if (size == 0 || pcs.empty() || pcs.size() > kMaxStackFrames) {
      return nullptr;
    }
    const std::string_view safe_cls =
        !class_name.empty() ? class_name : std::string_view("Unknown");
    const SampleKeyView key{isolate_group_id, safe_cls, pcs};
    const auto byte_size = static_cast<uint64_t>(size);

    std::shared_ptr<AggregatedSample> entry;
    uint64_t claimed_seq = 0;
    {
      std::scoped_lock lock(mutex_);
      if (auto it = entries_.find(key); it != entries_.end()) {
        entry = *it;
      } else {
        entry =
            std::make_shared<AggregatedSample>(isolate_group_id, safe_cls, pcs);
        entries_.insert(entry);
      }
      entry->live_handles.fetch_add(1, std::memory_order_relaxed);
      if (session_active_.load(std::memory_order_relaxed)) {
        claimed_seq = session_seq_.load(std::memory_order_relaxed);
        entry->self_allocated.fetch_add(byte_size, std::memory_order_relaxed);
        entry->alloc_count.fetch_add(1, std::memory_order_relaxed);
        has_unreported_activity_.store(true, std::memory_order_release);
      }
    }
    return new SampledAllocationHandle{this, std::move(entry), byte_size,
                                       claimed_seq};
  }

  static void RecordFree(void* data) {
    if (data == nullptr) {
      return;
    }
    std::unique_ptr<SampledAllocationHandle> handle(
        static_cast<SampledAllocationHandle*>(data));
    HeapSampleAggregator* owner = handle->owner;
    const uint64_t claimed =
        handle->claimed_session_seq.load(std::memory_order_acquire);
    if (claimed != 0 &&
        claimed == owner->session_seq_.load(std::memory_order_acquire)) {
      handle->sample->self_freed.fetch_add(handle->size,
                                           std::memory_order_relaxed);
      handle->sample->free_count.fetch_add(1, std::memory_order_relaxed);
      owner->has_unreported_activity_.store(true, std::memory_order_release);
    }
    if (handle->sample->live_handles.fetch_sub(1, std::memory_order_acq_rel) ==
            1 &&
        !owner->session_active_.load(std::memory_order_acquire)) {
      std::scoped_lock lock(owner->mutex_);
      if (!owner->session_active_.load(std::memory_order_relaxed) &&
          handle->sample->live_handles.load(std::memory_order_acquire) == 0) {
        owner->entries_.erase(handle->sample);
      }
    }
  }

  /// Lock-free callback for `Dart_ReportSurvivingAllocations` that claims
  /// surviving pre-session samples into the active `"android.heapprofd"`
  /// session. Follow with `FinalizeSeededBatch()`.
  static void SeedSurvivingSampleCallback(void* context, void* data) {
    if (context == nullptr || data == nullptr) {
      return;
    }
    auto* batch = static_cast<SeededBatch*>(context);
    auto* handle = static_cast<SampledAllocationHandle*>(data);
    if (handle->owner != batch->aggregator) {
      return;
    }
    const uint64_t active_seq =
        batch->aggregator->session_seq_.load(std::memory_order_acquire);
    if (active_seq == 0) {
      return;
    }
    uint64_t prev = handle->claimed_session_seq.load(std::memory_order_relaxed);
    while (prev != active_seq) {
      if (handle->claimed_session_seq.compare_exchange_weak(
              prev, active_seq, std::memory_order_acq_rel,
              std::memory_order_relaxed)) {
        handle->sample->self_allocated.fetch_add(handle->size,
                                                 std::memory_order_relaxed);
        handle->sample->alloc_count.fetch_add(1, std::memory_order_relaxed);
        batch->samples.push_back(handle->sample);
        return;
      }
    }
  }

  void FinalizeSeededBatch(const SeededBatch& batch) {
    if (batch.samples.empty()) {
      return;
    }
    std::scoped_lock lock(mutex_);
    if (!session_active_.load(std::memory_order_relaxed)) {
      return;
    }
    for (const auto& sample : batch.samples) {
      entries_.insert(sample);
    }
    has_unreported_activity_.store(true, std::memory_order_release);
  }

  /// Callback for `Dart_ReportSurvivingAllocations` collecting surviving
  /// sampled Dart allocations for `"android.java_hprof"` dumps.
  static void CollectSurvivingSampleCallback(void* context, void* data) {
    if (context == nullptr || data == nullptr) {
      return;
    }
    auto* out = static_cast<std::vector<SurvivingObjectSample>*>(context);
    const auto* handle = static_cast<const SampledAllocationHandle*>(data);
    out->push_back(SurvivingObjectSample{
        .class_name = handle->sample->class_name,
        .size = handle->size,
    });
  }

  std::vector<SampleSnapshot> TakeSnapshot() {
    if (!has_unreported_activity_.exchange(false, std::memory_order_acq_rel)) {
      return {};
    }
    std::scoped_lock lock(mutex_);
    std::vector<SampleSnapshot> snapshots;
    snapshots.reserve(entries_.size());
    for (const auto& entry : entries_) {
      const SampleSnapshot snap{
          .sample = entry,
          .self_allocated =
              entry->self_allocated.load(std::memory_order_relaxed),
          .self_freed = entry->self_freed.load(std::memory_order_relaxed),
          .alloc_count = entry->alloc_count.load(std::memory_order_relaxed),
          .free_count = entry->free_count.load(std::memory_order_relaxed),
      };
      if (snap.alloc_count != 0 || snap.free_count != 0) {
        snapshots.push_back(snap);
      }
    }
    return snapshots;
  }

 private:
  struct SampledAllocationHandle {
    HeapSampleAggregator* owner = nullptr;
    std::shared_ptr<AggregatedSample> sample;
    uint64_t size = 0;
    std::atomic<uint64_t> claimed_session_seq{0};

    SampledAllocationHandle(HeapSampleAggregator* o,
                            std::shared_ptr<AggregatedSample> s,
                            uint64_t sz,
                            uint64_t seq)
        : owner(o), sample(std::move(s)), size(sz), claimed_session_seq(seq) {}
  };

  struct SampleHash {
    using is_transparent = void;
    size_t operator()(const SampleKeyView& k) const {
      return absl::HashOf(k.group_key, k.class_name,
                          absl::MakeConstSpan(k.pcs.data(), k.pcs.size()));
    }
    size_t operator()(const std::shared_ptr<AggregatedSample>& s) const {
      return (*this)(s->key());
    }
  };

  struct SampleEq {
    using is_transparent = void;
    static bool Equals(const SampleKeyView& a, const SampleKeyView& b) {
      return a.group_key == b.group_key && a.class_name == b.class_name &&
             std::equal(a.pcs.begin(), a.pcs.end(), b.pcs.begin(), b.pcs.end());
    }
    bool operator()(const SampleKeyView& a, const SampleKeyView& b) const {
      return Equals(a, b);
    }
    bool operator()(const std::shared_ptr<AggregatedSample>& a,
                    const SampleKeyView& b) const {
      return Equals(a->key(), b);
    }
    bool operator()(const SampleKeyView& a,
                    const std::shared_ptr<AggregatedSample>& b) const {
      return Equals(a, b->key());
    }
    bool operator()(const std::shared_ptr<AggregatedSample>& a,
                    const std::shared_ptr<AggregatedSample>& b) const {
      return a == b || Equals(a->key(), b->key());
    }
  };

  std::mutex mutex_;
  uint64_t next_session_seq_ = 1;
  std::atomic<uint64_t> session_seq_{1};
  std::atomic<bool> session_active_{true};
  std::atomic<bool> has_unreported_activity_{false};
  absl::flat_hash_set<std::shared_ptr<AggregatedSample>, SampleHash, SampleEq>
      entries_;

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

/// Enumerates loaded executable `PT_LOAD` segments and `NT_GNU_BUILD_ID` notes
/// for cloud symbolication in Firebase Crashlytics and Datadog, and registers
/// dynamic DWARF FDEs for 64-bit Dart AOT snapshots lacking `PT_GNU_EH_FRAME`.
class ElfModuleScanner {
 public:
#if defined(__aarch64__) || defined(__x86_64__) || \
    (defined(__riscv) && (__riscv_xlen == 64))
#if defined(__aarch64__)
  static constexpr uint8_t kDwarfFpReg = 29;  // x29 (FP)
  static constexpr uint8_t kDwarfRaReg = 30;  // x30 (LR)
  static constexpr uint8_t kCfaFromFp = 16;   // [FP] = prev_fp, [FP+8] = lr
#elif defined(__x86_64__)
  static constexpr uint8_t kDwarfFpReg = 6;   // rbp
  static constexpr uint8_t kDwarfRaReg = 16;  // rip
  static constexpr uint8_t kCfaFromFp = 16;   // [rbp] = prev_rbp, [rbp+8] = rip
#elif defined(__riscv) && (__riscv_xlen == 64)
  static constexpr uint8_t kDwarfFpReg = 8;  // s0/fp
  static constexpr uint8_t kDwarfRaReg = 1;  // ra
  static constexpr uint8_t kCfaFromFp = 0;   // [fp-16] = prev_fp, [fp-8] = ra
#endif

  /// Minimal DWARF `.eh_frame` CIE + FDE matching Dart's
  /// `Dwarf::WriteCallFrameInformationRecords` (`CFA = FP + kCfaFromFp`,
  /// `caller_FP = [CFA - 16]`, `caller_RA = [CFA - 8]`) encoded with 64-bit
  /// `DW_EH_PE_absptr` (`0x00`) addresses so heap distance never overflows.
  struct alignas(8) SyntheticDartEhFrame {
    uint32_t cie_length = 20;
    uint32_t cie_id = 0;
    uint8_t cie_version = 1;
    std::array<char, 3> augmentation = {'z', 'R', '\0'};
    uint8_t code_align = 1;     // ULEB128(1)
    uint8_t data_align = 0x78;  // SLEB128(-8)
    uint8_t ra_reg = kDwarfRaReg;
    uint8_t aug_data_len = 1;     // ULEB128(1)
    uint8_t fde_encoding = 0x00;  // DW_EH_PE_absptr
    std::array<uint8_t, 7> cie_instrs = {
        0x0c, kDwarfFpReg, kCfaFromFp,        // DW_CFA_def_cfa(FP, kCfaFromFp)
        0x00, 0x00,        0x00,       0x00,  // DW_CFA_nop padding
    };

    uint32_t fde_length = 28;
    uint32_t cie_pointer = 28;  // &cie_pointer (28) - &cie_length (0)
    uintptr_t pc_begin = 0;
    uintptr_t pc_range = 0;
    uint8_t fde_aug_data_len = 0;
    std::array<uint8_t, 7> fde_instrs = {
        static_cast<uint8_t>(0x80u | kDwarfFpReg),
        2,  // FP = [CFA - 16]
        static_cast<uint8_t>(0x80u | kDwarfRaReg),
        1,  // RA = [CFA - 8]
        0x00,
        0x00,
        0x00,  // DW_CFA_nop padding
    };
    uint32_t terminator = 0;
  };
  static_assert(offsetof(SyntheticDartEhFrame, fde_length) == 24);
  static_assert(offsetof(SyntheticDartEhFrame, cie_pointer) == 28);
  static_assert(offsetof(SyntheticDartEhFrame, pc_begin) == 32);
  static_assert(offsetof(SyntheticDartEhFrame, terminator) == 56);
  static_assert(sizeof(SyntheticDartEhFrame) == 64);
#endif

  static std::vector<ElfSegment> ScanLoadedExecutableSegments() {
    std::vector<ElfSegment> segments;
    segments.reserve(32);
    ::dl_iterate_phdr(&OnPhdr, &segments);
    return segments;
  }

  static bool IsDartSnapshotWithoutEhFrameHdr(const dl_phdr_info* info) {
    const ElfW(Dyn)* dynamic = nullptr;
    for (size_t i = 0; i < info->dlpi_phnum; ++i) {
      const auto& ph = info->dlpi_phdr[i];
      if (ph.p_type == PT_GNU_EH_FRAME && ph.p_memsz > 0) {
        return false;
      }
      if (ph.p_type == PT_DYNAMIC && ph.p_memsz >= sizeof(ElfW(Dyn))) {
        const auto dyn_addr =
            static_cast<uintptr_t>(info->dlpi_addr + ph.p_vaddr);
        if (IsAddrRangeMappedInPhdrs(info, dyn_addr, ph.p_memsz)) {
          dynamic = reinterpret_cast<const ElfW(Dyn)*>(dyn_addr);
        }
      }
    }
    if (dynamic == nullptr) {
      return false;
    }
    std::optional<uintptr_t> strtab_raw;
    size_t strsz = 0;
    for (const ElfW(Dyn)* d = dynamic; d->d_tag != DT_NULL; ++d) {
      if (d->d_tag == DT_STRTAB) {
        strtab_raw = static_cast<uintptr_t>(d->d_un.d_ptr);
      } else if (d->d_tag == DT_STRSZ) {
        strsz = static_cast<size_t>(d->d_un.d_val);
      }
    }
    if (!strtab_raw.has_value() || strsz == 0) {
      return false;
    }
    const auto base = static_cast<uintptr_t>(info->dlpi_addr);
    const uintptr_t strtab_addr =
        *strtab_raw < base ? base + *strtab_raw : *strtab_raw;
    if (!IsAddrRangeMappedInPhdrs(info, strtab_addr, strsz)) {
      return false;
    }
    const std::string_view dynstr(reinterpret_cast<const char*>(strtab_addr),
                                  strsz);
    return dynstr.find("_kDart") != std::string_view::npos;
  }

  static void RegisterMissingDartEhFrames() {
#if defined(__aarch64__) || defined(__x86_64__) || \
    (defined(__riscv) && (__riscv_xlen == 64))
    using RegisterFrameFn = void (*)(const void*);
    static const std::optional<RegisterFrameFn> kRegisterFrame = [] {
      auto lib = fml::NativeLibrary::CreateForCurrentProcess();
      return lib ? lib->ResolveFunction<RegisterFrameFn>("__register_frame")
                 : std::nullopt;
    }();
    if (!kRegisterFrame.has_value()) {
      return;
    }

    std::vector<std::pair<uintptr_t, uintptr_t>> candidates;
    ::dl_iterate_phdr(
        [](struct dl_phdr_info* info, size_t /*size*/, void* data) -> int {
          if (!IsDartSnapshotWithoutEhFrameHdr(info)) {
            return 0;
          }
          auto* out =
              static_cast<std::vector<std::pair<uintptr_t, uintptr_t>>*>(data);
          for (size_t i = 0; i < info->dlpi_phnum; ++i) {
            const auto& ph = info->dlpi_phdr[i];
            if (ph.p_type == PT_LOAD && (ph.p_flags & PF_X) != 0 &&
                ph.p_memsz > 0) {
              out->emplace_back(
                  static_cast<uintptr_t>(info->dlpi_addr + ph.p_vaddr),
                  static_cast<uintptr_t>(ph.p_memsz));
            }
          }
          return 0;
        },
        &candidates);

    static auto* state = new RegisteredEhFrames();
    std::scoped_lock lock(state->mutex);
    for (const auto& [start, len] : candidates) {
      if (std::find(state->registered_starts.begin(),
                    state->registered_starts.end(),
                    start) == state->registered_starts.end()) {
        state->registered_starts.push_back(start);
        auto frame = std::make_unique<SyntheticDartEhFrame>();
        frame->pc_begin = start;
        frame->pc_range = len;
        // Bionic's LLVM libunwind __register_frame expects a single FDE.
        (*kRegisterFrame)(&frame->fde_length);
        state->frames.push_back(std::move(frame));
      }
    }
#endif
  }

 private:
#if defined(__aarch64__) || defined(__x86_64__) || \
    (defined(__riscv) && (__riscv_xlen == 64))
  struct RegisteredEhFrames {
    std::mutex mutex;
    std::vector<uintptr_t> registered_starts;
    std::vector<std::unique_ptr<SyntheticDartEhFrame>> frames;
  };
#endif

  static bool IsAddrRangeMappedInPhdrs(const dl_phdr_info* info,
                                       uintptr_t addr,
                                       size_t size) {
    if (size == 0 || addr > std::numeric_limits<uintptr_t>::max() - size) {
      return false;
    }
    const uintptr_t end = addr + size;
    for (size_t i = 0; i < info->dlpi_phnum; ++i) {
      const auto& ph = info->dlpi_phdr[i];
      if (ph.p_type != PT_LOAD || ph.p_memsz == 0) {
        continue;
      }
      const auto seg_start =
          static_cast<uintptr_t>(info->dlpi_addr + ph.p_vaddr);
      const auto seg_end = seg_start + static_cast<uintptr_t>(ph.p_memsz);
      if (addr >= seg_start && end <= seg_end) {
        return true;
      }
    }
    return false;
  }

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

inline std::string_view NormalizeProcessCmdline(std::string_view raw) {
  const size_t nul = raw.find('\0');
  if (nul != std::string_view::npos) {
    raw = raw.substr(0, nul);
  }
  const size_t at = raw.find('@');
  if (at != std::string_view::npos) {
    raw = raw.substr(0, at);
  }
  const size_t slash = raw.rfind('/');
  if (slash != std::string_view::npos) {
    raw = raw.substr(slash + 1);
  }
  return raw;
}

inline bool MatchesCmdlineGlob(std::string_view pattern,
                               std::string_view target) {
  const std::string_view norm_pat = NormalizeProcessCmdline(pattern);
  const std::string_view norm_tgt = NormalizeProcessCmdline(target);
  if (norm_pat.empty() || norm_tgt.empty()) {
    return false;
  }
  const size_t star = norm_pat.find('*');
  if (star == std::string_view::npos) {
    return norm_pat == norm_tgt;
  }
  const std::string_view prefix = norm_pat.substr(0, star);
  const std::string_view suffix = norm_pat.substr(star + 1);
  return norm_tgt.size() >= prefix.size() + suffix.size() &&
         norm_tgt.starts_with(prefix) && norm_tgt.ends_with(suffix);
}

/// Kind of Perfetto profiling data source session.
enum class SessionKind : uint8_t {
  kNone,
  kHeapprofd,
  kJavaHprof,
};

/// Unified parsed configuration for `"android.heapprofd"`,
/// `"android.java_hprof"`, and `"android.java_hprof.oom"` sessions.
struct ParsedSessionConfig {
  SessionKind kind = SessionKind::kNone;
  bool matched = false;
  uint32_t target_buffer = 0;
  intptr_t sampling_interval = kDefaultSamplingInterval;
  uint32_t dump_phase_ms = 0;
  uint32_t dump_interval_ms = 0;
  bool no_startup = false;
};

/// Evaluates `DataSourceConfig` (and nested `HeapprofdConfig` or
/// `JavaHprofConfig`) against `self_pid` and `self_progname`.
inline ParsedSessionConfig ParseDataSourceConfigForProcess(
    std::span<const uint8_t> config_bytes,
    uint64_t self_pid,
    std::string_view self_progname) {
  ParsedSessionConfig res;
  // DataSourceConfig: name=1, target_buffer=2, heapprofd=105, java_hprof=110.
  protozero::TypedProtoDecoder<110, false> dsc(config_bytes.data(),
                                               config_bytes.size());
  res.target_buffer = dsc.at<2>().as_uint32();
  const std::string_view ds_name = View(dsc.at<1>().as_string());

  if (ds_name == kJavaHprofDataSourceName ||
      ds_name == kJavaHprofOomDataSourceName) {
    res.kind = SessionKind::kJavaHprof;
    const auto raw = dsc.at<110>().as_bytes();
    if (raw.data == nullptr) {
      res.matched = true;
      return res;
    }
    // JavaHprofConfig: process_cmdline=1, pid=2.
    protozero::TypedProtoDecoder<2, true> jhc(raw.data, raw.size);
    bool has_target = false;
    bool target_matched = false;
    for (auto it = jhc.GetRepeated<protozero::ConstChars>(1); it; ++it) {
      has_target = true;
      target_matched |= MatchesCmdlineGlob(View(*it), self_progname);
    }
    for (auto it = jhc.GetRepeated<uint64_t>(2); it; ++it) {
      has_target = true;
      target_matched |= (*it == self_pid);
    }
    res.matched = !has_target || target_matched;
    return res;
  }

  if (ds_name != kHeapprofdDataSourceName) {
    return res;
  }
  res.kind = SessionKind::kHeapprofd;
  const auto raw = dsc.at<105>().as_bytes();
  if (raw.data == nullptr) {
    res.matched = true;
    return res;
  }

  // HeapprofdConfig: interval=1, cmdline=2, pid=4, all=5, cdc=6, no_startup=10.
  protozero::TypedProtoDecoder<10, true> hc(raw.data, raw.size);
  if (const uint64_t iv = hc.at<1>().as_uint64(); iv > 0) {
    constexpr auto kMaxIntptr =
        static_cast<uint64_t>(std::numeric_limits<intptr_t>::max());
    res.sampling_interval = static_cast<intptr_t>(std::min(iv, kMaxIntptr));
  }
  res.no_startup = hc.at<10>().as_bool();
  if (const auto cdc_raw = hc.at<6>().as_bytes(); cdc_raw.data != nullptr) {
    // ContinuousDumpConfig: dump_phase_ms=5, dump_interval_ms=6.
    protozero::TypedProtoDecoder<6, false> cdc(cdc_raw.data, cdc_raw.size);
    res.dump_phase_ms = cdc.at<5>().as_uint32();
    res.dump_interval_ms = cdc.at<6>().as_uint32();
  }

  const std::string_view norm_self = NormalizeProcessCmdline(self_progname);
  bool has_target = false;
  bool target_matched = false;
  for (auto it = hc.GetRepeated<protozero::ConstChars>(2); it; ++it) {
    has_target = true;
    target_matched |=
        (!norm_self.empty() && NormalizeProcessCmdline(View(*it)) == norm_self);
  }
  for (auto it = hc.GetRepeated<uint64_t>(4); it; ++it) {
    has_target = true;
    target_matched |= (*it == self_pid);
  }
  res.matched = hc.at<5>().as_bool() || !has_target || target_matched;
  return res;
}

inline ParsedSessionConfig ParseDataSourceConfig(
    std::span<const uint8_t> config_bytes) {
  const char* prog = ::getprogname();
  return ParseDataSourceConfigForProcess(
      config_bytes, static_cast<uint64_t>(fml::GetCurrentProcId()),
      prog != nullptr ? std::string_view(prog) : std::string_view());
}

/// Stateful serializer for a single `"android.heapprofd"` dump across one or
/// more continued `TracePacket` batches.
class ProfileDumpSerializer {
 public:
  using TracePacket = perfetto::protos::pbzero::TracePacket;
  using InternedData = perfetto::protos::pbzero::InternedData;
  using InternedString = perfetto::protos::pbzero::InternedString;

  ProfileDumpSerializer(std::span<ElfSegment> segments,
                        intptr_t sampling_interval,
                        bool from_startup,
                        uint64_t boot_ns,
                        uint64_t mono_ns,
                        bool* first_packet_on_sequence,
                        uint64_t* packet_index)
      : segments_(segments),
        sampling_interval_(sampling_interval),
        from_startup_(from_startup),
        boot_ns_(boot_ns),
        mono_ns_(mono_ns),
        pid_(static_cast<uint64_t>(fml::GetCurrentProcId())),
        first_packet_on_sequence_(first_packet_on_sequence),
        packet_index_(packet_index) {}

  void WriteBatch(std::span<const SampleSnapshot> batch,
                  bool is_first_batch,
                  bool continued,
                  TracePacket* packet) {
    const uint32_t seq_flags =
        is_first_batch ? (TracePacket::SEQ_INCREMENTAL_STATE_CLEARED |
                          TracePacket::SEQ_NEEDS_INCREMENTAL_STATE)
                       : TracePacket::SEQ_NEEDS_INCREMENTAL_STATE;
    if (*first_packet_on_sequence_) {
      packet->AppendVarInt(/*first_packet_on_sequence=*/87, 1u);
      *first_packet_on_sequence_ = false;
    }
    packet->set_timestamp(boot_ns_);
    packet->set_sequence_flags(seq_flags);

    std::array<uint64_t, kSamplesPerPacketBatch> callstack_iids = {};
    {
      InternedData* interned = packet->set_interned_data();
      if (is_first_batch) {
        SetInternedStr(interned->add_build_ids(), 0, "");
        SetInternedStr(interned->add_mapping_paths(), 0, "");
        SetInternedStr(interned->add_function_names(), 0, "");
      }
      for (size_t i = 0; i < batch.size(); ++i) {
        callstack_iids[i] = InternSampleCallstack(interned, *batch[i].sample);
      }
    }
    WriteProcessDump(packet, batch, callstack_iids, continued);
  }

 private:
  static uint64_t SetInternedBytes(InternedString* entry,
                                   uint64_t iid,
                                   std::span<const uint8_t> bytes) {
    entry->set_iid(iid);
    entry->set_str(bytes.data(), bytes.size());
    return iid;
  }

  static uint64_t SetInternedStr(InternedString* entry,
                                 uint64_t iid,
                                 std::string_view str) {
    return SetInternedBytes(
        entry, iid, {reinterpret_cast<const uint8_t*>(str.data()), str.size()});
  }

  uint64_t InternSegmentMapping(InternedData* interned, ElfSegment& seg) {
    if (seg.mapping_iid != 0) {
      return seg.mapping_iid;
    }
    const uint64_t build_id_iid =
        seg.build_id_len > 0
            ? SetInternedBytes(interned->add_build_ids(), next_str_iid_++,
                               {seg.build_id.data(), seg.build_id_len})
            : 0;
    const std::string_view rel_path = seg.path.starts_with('/')
                                          ? std::string_view(seg.path).substr(1)
                                          : std::string_view(seg.path);
    const uint64_t path_iid = SetInternedStr(interned->add_mapping_paths(),
                                             next_str_iid_++, rel_path);

    seg.mapping_iid = next_map_iid_++;
    auto* mp = interned->add_mappings();
    mp->set_iid(seg.mapping_iid);
    mp->set_build_id(build_id_iid);
    mp->AppendVarInt(/*exact_offset=*/8, seg.exact_offset);
    mp->set_start(seg.start);
    mp->set_end(seg.end);
    mp->AppendVarInt(/*load_bias=*/6, seg.load_bias);
    mp->add_path_string_ids(path_iid);
    return seg.mapping_iid;
  }

  uint64_t InternSyntheticMapping(InternedData* interned) {
    if (synthetic_map_iid_ != 0) {
      return synthetic_map_iid_;
    }
    const uint64_t path_iid = SetInternedStr(interned->add_mapping_paths(),
                                             next_str_iid_++, kDartHeapName);
    synthetic_map_iid_ = next_map_iid_++;
    auto* mp = interned->add_mappings();
    mp->set_iid(synthetic_map_iid_);
    mp->set_build_id(0);
    mp->set_start(0);
    mp->set_end(0);
    mp->add_path_string_ids(path_iid);
    return synthetic_map_iid_;
  }

  uint64_t InternAddressFrame(InternedData* interned, uintptr_t pc) {
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
      map_iid = InternSyntheticMapping(interned);
    }
    const uint64_t frame_iid = next_frame_iid_++;
    auto* fr = interned->add_frames();
    fr->set_iid(frame_iid);
    fr->set_mapping_id(map_iid);
    fr->set_rel_pc(rel_pc);
    return frame_iid;
  }

  uint64_t InternClassLeafFrame(InternedData* interned,
                                std::string_view cls_name) {
    const uint64_t map_iid = InternSyntheticMapping(interned);
    const uint64_t fn_iid = SetInternedStr(interned->add_function_names(),
                                           next_str_iid_++, cls_name);
    const uint64_t frame_iid = next_frame_iid_++;
    auto* fr = interned->add_frames();
    fr->set_iid(frame_iid);
    fr->set_function_name_id(fn_iid);
    fr->set_mapping_id(map_iid);
    return frame_iid;
  }

  uint64_t InternSampleCallstack(InternedData* interned,
                                 const AggregatedSample& sample) {
    std::array<uint64_t, kMaxStackFrames + 1> frame_iids = {};
    size_t frame_count = 0;
    const auto pcs = sample.pcs();
    // Perfetto Callstack frame_ids are ordered root-first.
    for (size_t k = pcs.size(); k > 0; --k) {
      frame_iids[frame_count++] = InternAddressFrame(interned, pcs[k - 1]);
    }
    frame_iids[frame_count++] =
        InternClassLeafFrame(interned, sample.class_name);

    auto* cs = interned->add_callstacks();
    cs->set_iid(sample.stable_id);
    for (size_t i = 0; i < frame_count; ++i) {
      cs->add_frame_ids(frame_iids[i]);
    }
    return sample.stable_id;
  }

  void WriteProcessDump(
      TracePacket* packet,
      std::span<const SampleSnapshot> batch,
      const std::array<uint64_t, kSamplesPerPacketBatch>& callstack_iids,
      bool continued) {
    auto* prof =
        packet->BeginNestedMessage<protozero::Message>(/*profile_packet=*/37);
    prof->AppendVarInt(/*continued=*/6, continued ? 1u : 0u);
    prof->AppendVarInt(/*index=*/7, (*packet_index_)++);

    auto* dump =
        prof->BeginNestedMessage<protozero::Message>(/*process_dumps=*/5);
    dump->AppendVarInt(/*pid=*/1, pid_);
    if (from_startup_) {
      dump->AppendVarInt(/*from_startup=*/3, 1u);
    }
    dump->AppendVarInt(/*timestamp=*/9, mono_ns_);
    dump->AppendBytes(/*heap_name=*/11, kDartHeapName.data(),
                      kDartHeapName.size());
    const auto interval = static_cast<uint64_t>(sampling_interval_);
    dump->AppendVarInt(/*sampling_interval_bytes=*/12, interval);
    dump->AppendVarInt(/*orig_sampling_interval_bytes=*/13, interval);

    for (size_t i = 0; i < batch.size(); ++i) {
      const SampleSnapshot& s = batch[i];
      auto* hs = dump->BeginNestedMessage<protozero::Message>(/*samples=*/2);
      hs->AppendVarInt(/*callstack_id=*/1, callstack_iids[i]);
      hs->AppendVarInt(/*self_allocated=*/2, s.self_allocated);
      hs->AppendVarInt(/*self_freed=*/3, s.self_freed);
      hs->AppendVarInt(/*alloc_count=*/5, s.alloc_count);
      hs->AppendVarInt(/*free_count=*/6, s.free_count);
    }
  }

  std::span<ElfSegment> segments_;
  intptr_t sampling_interval_;
  bool from_startup_;
  uint64_t boot_ns_;
  uint64_t mono_ns_;
  uint64_t pid_;
  bool* first_packet_on_sequence_;
  uint64_t* packet_index_;

  uint64_t next_str_iid_ = 1;
  uint64_t next_map_iid_ = 1;
  uint64_t next_frame_iid_ = 1;
  uint64_t synthetic_map_iid_ = 0;
};

/// Snapshots sampled heap allocations and emits them across one or more
/// `TracePacket` batches.
template <typename EmitPacketFn>
void WriteHeapProfilePackets(HeapSampleAggregator& aggregator,
                             intptr_t sampling_interval,
                             bool from_startup,
                             bool* first_packet_on_sequence,
                             uint64_t* packet_index,
                             EmitPacketFn&& emit_packet) {
  const std::vector<SampleSnapshot> snapshots = aggregator.TakeSnapshot();
  if (snapshots.empty()) {
    return;
  }

  std::vector<ElfSegment> segments =
      ElfModuleScanner::ScanLoadedExecutableSegments();
  const auto boot_ns =
      static_cast<uint64_t>(perfetto::base::GetBootTimeNs().count());
  const auto mono_ns = static_cast<uint64_t>(
      perfetto::base::GetTimeInternalNs(CLOCK_MONOTONIC_COARSE).count());

  ProfileDumpSerializer serializer(segments, sampling_interval, from_startup,
                                   boot_ns, mono_ns, first_packet_on_sequence,
                                   packet_index);
  const std::span<const SampleSnapshot> all_snaps(snapshots);
  for (size_t offset = 0; offset < all_snaps.size();
       offset += kSamplesPerPacketBatch) {
    const size_t count =
        std::min(kSamplesPerPacketBatch, all_snaps.size() - offset);
    const bool continued = (offset + count) < all_snaps.size();
    emit_packet([&](perfetto::protos::pbzero::TracePacket* packet) {
      serializer.WriteBatch(all_snaps.subspan(offset, count),
                            /*is_first_batch=*/offset == 0, continued, packet);
    });
  }
}

/// Serializes surviving sampled Dart allocations collected via
/// `Dart_ReportSurvivingAllocations` into `perfetto.protos.HeapGraph` packets
/// for `"android.java_hprof"` and `"android.java_hprof.oom"` sessions.
template <typename EmitPacketFn>
void WriteDartHeapGraphPackets(
    std::span<const SurvivingObjectSample> raw_samples,
    bool* first_packet_on_sequence,
    uint64_t* packet_index,
    EmitPacketFn&& emit_packet) {
  constexpr uint64_t kRootTypeId = 1;
  constexpr uint64_t kLocationIid = 1;
  constexpr uint64_t kSampleFieldIid = 1;

  std::vector<const SurvivingObjectSample*> valid;
  std::vector<std::string_view> types;
  valid.reserve(raw_samples.size());
  types.reserve(raw_samples.size());
  for (const SurvivingObjectSample& s : raw_samples) {
    if (s.size == 0) {
      continue;
    }
    valid.push_back(&s);
    types.push_back(!s.class_name.empty() ? std::string_view(s.class_name)
                                          : "Unknown");
  }
  std::sort(types.begin(), types.end());
  types.erase(std::unique(types.begin(), types.end()), types.end());

  const auto boot_ns =
      static_cast<uint64_t>(perfetto::base::GetBootTimeNs().count());
  const auto pid = static_cast<int32_t>(fml::GetCurrentProcId());
  uint64_t next_obj_id = 1;
  uint64_t graph_index = 0;

  const size_t total = valid.size();
  const size_t num_batches = total == 0 ? 1
                                        : (total + kSamplesPerPacketBatch - 1) /
                                              kSamplesPerPacketBatch;

  auto add_interned_str = [](protozero::Message* parent, uint32_t field_id,
                             uint64_t iid, std::string_view s) {
    auto* entry =
        parent->BeginNestedMessage<perfetto::protos::pbzero::InternedString>(
            field_id);
    entry->set_iid(iid);
    entry->set_str(reinterpret_cast<const uint8_t*>(s.data()), s.size());
  };
  auto add_type = [](protozero::Message* hg, uint64_t id, std::string_view cls,
                     uint32_t kind) {
    auto* tp = hg->BeginNestedMessage<protozero::Message>(/*types=*/9);
    tp->AppendVarInt(/*id=*/1, id);
    tp->AppendVarInt(/*location_id=*/2, kLocationIid);
    tp->AppendBytes(/*class_name=*/3, cls.data(), cls.size());
    tp->AppendVarInt(/*object_size=*/4, 0u);
    tp->AppendVarInt(/*kind=*/7, kind);
  };

  for (size_t b = 0; b < num_batches; ++b) {
    const size_t offset = b * kSamplesPerPacketBatch;
    const size_t count =
        total == 0 ? 0 : std::min(kSamplesPerPacketBatch, total - offset);
    const bool is_last = (b + 1 == num_batches);

    emit_packet([&](perfetto::protos::pbzero::TracePacket* packet) {
      if (*first_packet_on_sequence) {
        packet->AppendVarInt(/*first_packet_on_sequence=*/87, 1u);
        *first_packet_on_sequence = false;
      }
      packet->set_timestamp(boot_ns);
      if (packet_index != nullptr) {
        ++(*packet_index);
      }

      auto* hg = packet->BeginNestedMessage<protozero::Message>(
          /*heap_graph=*/56);
      hg->AppendVarInt(/*pid=*/1, pid);

      const uint64_t container_id = next_obj_id++;
      {
        auto* root = hg->BeginNestedMessage<protozero::Message>(/*roots=*/7);
        protozero::PackedVarInt root_ids;
        root_ids.Append(container_id);
        root->AppendBytes(/*object_ids=*/1, root_ids.data(), root_ids.size());
        root->AppendVarInt(/*root_type=*/2, /*ROOT_VM_INTERNAL=*/13u);
      }

      const uint64_t first_child_id = next_obj_id;
      next_obj_id += count;
      {
        auto* container =
            hg->BeginNestedMessage<protozero::Message>(/*objects=*/2);
        container->AppendVarInt(/*id=*/1, container_id);
        container->AppendVarInt(/*type_id=*/2, kRootTypeId);
        container->AppendVarInt(/*self_size=*/3, 0u);
        if (count > 0) {
          protozero::PackedVarInt field_ids;
          protozero::PackedVarInt obj_ids;
          for (size_t i = 0; i < count; ++i) {
            field_ids.Append(kSampleFieldIid);
            obj_ids.Append(first_child_id + i);
          }
          container->AppendBytes(/*reference_field_id=*/4, field_ids.data(),
                                 field_ids.size());
          container->AppendBytes(/*reference_object_id=*/5, obj_ids.data(),
                                 obj_ids.size());
        }
      }

      for (size_t i = 0; i < count; ++i) {
        const SurvivingObjectSample& s = *valid[offset + i];
        const std::string_view cls =
            !s.class_name.empty() ? std::string_view(s.class_name) : "Unknown";
        const auto it = std::lower_bound(types.begin(), types.end(), cls);
        auto* obj = hg->BeginNestedMessage<protozero::Message>(/*objects=*/2);
        obj->AppendVarInt(/*id=*/1, first_child_id + i);
        obj->AppendVarInt(
            /*type_id=*/2,
            2u + static_cast<uint64_t>(std::distance(types.begin(), it)));
        obj->AppendVarInt(/*self_size=*/3, s.size);
      }

      if (is_last) {
        add_interned_str(hg, /*location_names=*/8, kLocationIid, kDartHeapName);
        if (total > 0) {
          add_interned_str(hg, /*field_names=*/4, kSampleFieldIid,
                           kDartHeapGraphSampleField);
        }
        add_type(hg, kRootTypeId, kDartHeapGraphRootType,
                 total > 0 ? /*KIND_NORMAL=*/1u : /*KIND_NOREFERENCES=*/2u);
        for (size_t i = 0; i < types.size(); ++i) {
          add_type(hg, 2u + i, types[i], /*KIND_NOREFERENCES=*/2u);
        }
      }

      hg->AppendVarInt(/*continued=*/5, is_last ? 0u : 1u);
      hg->AppendVarInt(/*index=*/6, graph_index++);
    });
  }
}

}  // namespace flutter::android_heap_profile_internal

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_DART_HEAP_PROFILER_INTERNAL_H_
