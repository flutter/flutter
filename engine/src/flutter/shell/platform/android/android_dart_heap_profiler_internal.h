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
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/process.h"
#include "flutter/third_party/dart/third_party/perfetto/protos/perfetto/trace/interned_data/interned_data.pbzero.h"
#include "flutter/third_party/dart/third_party/perfetto/protos/perfetto/trace/profiling/profile_common.pbzero.h"
#include "flutter/third_party/dart/third_party/perfetto/protos/perfetto/trace/trace_packet.pbzero.h"
#include "perfetto/base/time.h"
#include "perfetto/protozero/message.h"
#include "perfetto/protozero/proto_decoder.h"
#include "perfetto/protozero/scattered_heap_buffer.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_set.h"
#include "third_party/abseil-cpp/absl/hash/hash.h"
#include "third_party/abseil-cpp/absl/types/span.h"

namespace flutter::android_heap_profile_internal {

inline constexpr std::string_view kHeapprofdDataSourceName =
    "android.heapprofd";
inline constexpr std::string_view kDartHeapName = "com.google.dart";
inline constexpr intptr_t kDefaultSamplingInterval = 512 * 1024;
inline constexpr size_t kMaxStackFrames = 64;
inline constexpr size_t kSamplesPerPacketBatch = 128;

// Field IDs omitted from Dart's trimmed `.pbzero.h` proto subset.
namespace proto_fields {

inline constexpr uint32_t kTracePacketProfilePacket = 37;
inline constexpr uint32_t kTracePacketFirstPacketOnSequence = 87;
inline constexpr uint32_t kMappingLoadBias = 6;
inline constexpr uint32_t kMappingExactOffset = 8;

inline constexpr uint32_t kProfilePacketProcessDumps = 5;
inline constexpr uint32_t kProfilePacketContinued = 6;
inline constexpr uint32_t kProfilePacketIndex = 7;

inline constexpr uint32_t kProcessDumpPid = 1;
inline constexpr uint32_t kProcessDumpSamples = 2;
inline constexpr uint32_t kProcessDumpTimestamp = 9;
inline constexpr uint32_t kProcessDumpHeapName = 11;
inline constexpr uint32_t kProcessDumpSamplingInterval = 12;
inline constexpr uint32_t kProcessDumpOrigSamplingInterval = 13;

inline constexpr uint32_t kHeapSampleCallstackId = 1;
inline constexpr uint32_t kHeapSampleSelfAllocated = 2;
inline constexpr uint32_t kHeapSampleSelfFreed = 3;
inline constexpr uint32_t kHeapSampleAllocCount = 5;
inline constexpr uint32_t kHeapSampleFreeCount = 6;

}  // namespace proto_fields

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

/// Thread-safe reference-counted callsite entry tracking cumulative allocations
/// and GC deallocations for a unique `(isolate_group, class_name, pcs)` tuple.
class AggregatedSample : public fml::RefCountedThreadSafe<AggregatedSample> {
 public:
  uintptr_t group_key() const { return group_key_; }
  std::string_view class_name() const { return class_name_; }
  std::span<const uintptr_t> pcs() const { return {pcs_.get(), num_frames_}; }
  SampleKeyView key() const { return {group_key_, class_name_, pcs()}; }

  void RecordAlloc(uint64_t bytes) {
    self_allocated_.fetch_add(bytes, std::memory_order_relaxed);
    alloc_count_.fetch_add(1, std::memory_order_relaxed);
  }

  void RecordFree(uint64_t bytes) {
    self_freed_.fetch_add(bytes, std::memory_order_relaxed);
    free_count_.fetch_add(1, std::memory_order_relaxed);
  }

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
                   std::string_view class_name,
                   std::span<const uintptr_t> pcs)
      : group_key_(group_key),
        num_frames_(pcs.size()),
        pcs_(std::make_unique<uintptr_t[]>(pcs.size())),
        class_name_(class_name) {
    std::copy_n(pcs.data(), pcs.size(), pcs_.get());
  }

  ~AggregatedSample() = default;

  uintptr_t group_key_ = 0;
  size_t num_frames_ = 0;
  std::unique_ptr<uintptr_t[]> pcs_;
  std::string class_name_;
  std::atomic<uint64_t> self_allocated_{0};
  std::atomic<uint64_t> self_freed_{0};
  std::atomic<uint64_t> alloc_count_{0};
  std::atomic<uint64_t> free_count_{0};

  FML_FRIEND_MAKE_REF_COUNTED(AggregatedSample);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(AggregatedSample);
  FML_DISALLOW_COPY_AND_ASSIGN(AggregatedSample);
};

/// Point-in-time cumulative counters for a sampled callsite.
struct SampleSnapshot {
  fml::RefPtr<AggregatedSample> sample;
  uint64_t self_allocated = 0;
  uint64_t self_freed = 0;
  uint64_t alloc_count = 0;
  uint64_t free_count = 0;
};

/// Aggregates sampled Dart allocations by callstack and class name using
/// `absl::flat_hash_set` and `absl::HashOf`.
class HeapSampleAggregator {
 public:
  HeapSampleAggregator() = default;
  ~HeapSampleAggregator() = default;

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

    fml::RefPtr<AggregatedSample> entry;
    {
      std::scoped_lock lock(mutex_);
      if (auto it = entries_.find(key); it != entries_.end()) {
        entry = *it;
      } else {
        entry = fml::MakeRefCounted<AggregatedSample>(isolate_group_id,
                                                      safe_cls, pcs);
        entries_.insert(entry);
      }
    }
    const auto byte_size = static_cast<uint64_t>(size);
    entry->RecordAlloc(byte_size);
    has_unreported_activity_.store(true, std::memory_order_release);
    return new SampledAllocationHandle{this, std::move(entry), byte_size};
  }

  static void RecordFree(void* data) {
    if (data == nullptr) {
      return;
    }
    std::unique_ptr<SampledAllocationHandle> handle(
        static_cast<SampledAllocationHandle*>(data));
    handle->sample->RecordFree(handle->size);
    handle->owner->has_unreported_activity_.store(true,
                                                  std::memory_order_release);
  }

  std::vector<SampleSnapshot> TakeSnapshot() {
    if (!has_unreported_activity_.exchange(false, std::memory_order_acq_rel)) {
      return {};
    }
    std::scoped_lock lock(mutex_);
    std::vector<SampleSnapshot> snapshots;
    snapshots.reserve(entries_.size());
    for (const auto& entry : entries_) {
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

  void Clear() {
    std::scoped_lock lock(mutex_);
    entries_.clear();
    has_unreported_activity_.store(false, std::memory_order_release);
  }

 private:
  struct SampledAllocationHandle {
    HeapSampleAggregator* owner = nullptr;
    fml::RefPtr<AggregatedSample> sample;
    uint64_t size = 0;
  };

  struct SampleHash {
    using is_transparent = void;
    size_t operator()(const SampleKeyView& k) const {
      return absl::HashOf(k.group_key, k.class_name,
                          absl::MakeConstSpan(k.pcs.data(), k.pcs.size()));
    }
    size_t operator()(const fml::RefPtr<AggregatedSample>& s) const {
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
    bool operator()(const fml::RefPtr<AggregatedSample>& a,
                    const SampleKeyView& b) const {
      return Equals(a->key(), b);
    }
    bool operator()(const SampleKeyView& a,
                    const fml::RefPtr<AggregatedSample>& b) const {
      return Equals(a, b->key());
    }
    bool operator()(const fml::RefPtr<AggregatedSample>& a,
                    const fml::RefPtr<AggregatedSample>& b) const {
      return a == b || Equals(a->key(), b->key());
    }
  };

  std::mutex mutex_;
  std::atomic<bool> has_unreported_activity_{false};
  absl::flat_hash_set<fml::RefPtr<AggregatedSample>, SampleHash, SampleEq>
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
      if (state->registered_starts.insert(start).second) {
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
    absl::flat_hash_set<uintptr_t> registered_starts;
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

/// Parsed configuration for a matched `ProfilingManager` `"android.heapprofd"`
/// session.
struct ParsedHeapprofdSession {
  bool matched = false;
  uint32_t target_buffer = 0;
  intptr_t sampling_interval = kDefaultSamplingInterval;
};

inline std::string_view GetCurrentProgName() {
  const char* name = ::getprogname();
  return name != nullptr ? std::string_view(name) : std::string_view();
}

/// Evaluates `DataSourceConfig` (and nested `HeapprofdConfig`) against
/// `self_pid` and `self_progname`.
inline ParsedHeapprofdSession ParseDataSourceConfigForProcess(
    std::span<const uint8_t> config_bytes,
    uint64_t self_pid,
    std::string_view self_progname) {
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
  bool has_target = false;
  bool target_matched = false;
  constexpr auto kMaxIntptr =
      static_cast<uint64_t>(std::numeric_limits<intptr_t>::max());

  protozero::ProtoDecoder hc(heapprofd_raw.data, heapprofd_raw.size);
  for (auto f = hc.ReadField(); f.valid(); f = hc.ReadField()) {
    switch (f.id()) {
      case 1:  // sampling_interval_bytes
        if (f.as_uint64() > 0) {
          res.sampling_interval =
              static_cast<intptr_t>(std::min(f.as_uint64(), kMaxIntptr));
        }
        break;
      case 2: {  // process_cmdline
        has_target = true;
        const std::string_view cmd(reinterpret_cast<const char*>(f.data()),
                                   f.size());
        if (!self_progname.empty() && cmd == self_progname) {
          target_matched = true;
        }
        break;
      }
      case 4:  // pid
        has_target = true;
        if (f.as_uint64() == self_pid) {
          target_matched = true;
        }
        break;
      case 5:  // all
        all_procs = f.as_bool();
        break;
      default:
        break;
    }
  }
  res.matched = all_procs || !has_target || target_matched;
  return res;
}

inline ParsedHeapprofdSession ParseDataSourceConfig(
    std::span<const uint8_t> config_bytes) {
  return ParseDataSourceConfigForProcess(
      config_bytes, static_cast<uint64_t>(fml::GetCurrentProcId()),
      GetCurrentProgName());
}

/// Stateful serializer for a single heap dump across one or more continued
/// `TracePacket` batches using Dart's pre-generated `.pbzero.h` descriptors.
class ProfileDumpSerializer {
 public:
  using TracePacket = perfetto::protos::pbzero::TracePacket;
  using InternedData = perfetto::protos::pbzero::InternedData;
  using InternedString = perfetto::protos::pbzero::InternedString;

  ProfileDumpSerializer(std::span<ElfSegment> segments,
                        intptr_t sampling_interval,
                        uint64_t boot_ns,
                        uint64_t mono_ns,
                        uint64_t* packet_index)
      : segments_(segments),
        sampling_interval_(sampling_interval),
        boot_ns_(boot_ns),
        mono_ns_(mono_ns),
        pid_(static_cast<uint64_t>(fml::GetCurrentProcId())),
        packet_index_(packet_index) {}

  void WriteBatch(std::span<const SampleSnapshot> batch,
                  bool is_first_batch,
                  bool continued,
                  TracePacket* packet) {
    const uint32_t seq_flags =
        is_first_batch ? (TracePacket::SEQ_INCREMENTAL_STATE_CLEARED |
                          TracePacket::SEQ_NEEDS_INCREMENTAL_STATE)
                       : TracePacket::SEQ_NEEDS_INCREMENTAL_STATE;
    if (is_first_batch && *packet_index_ == 0) {
      packet->AppendVarInt(proto_fields::kTracePacketFirstPacketOnSequence, 1u);
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
      interned->Finalize();
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
        entry, iid,
        std::span<const uint8_t>(reinterpret_cast<const uint8_t*>(str.data()),
                                 str.size()));
  }

  uint64_t InternSegmentMapping(InternedData* interned, ElfSegment& seg) {
    if (seg.mapping_iid != 0) {
      return seg.mapping_iid;
    }
    const uint64_t build_id_iid =
        seg.build_id_len > 0
            ? SetInternedBytes(interned->add_build_ids(), next_str_iid_++,
                               std::span<const uint8_t>(seg.build_id.data(),
                                                        seg.build_id_len))
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
    mp->AppendVarInt(proto_fields::kMappingExactOffset, seg.exact_offset);
    mp->set_start(seg.start);
    mp->set_end(seg.end);
    mp->AppendVarInt(proto_fields::kMappingLoadBias, seg.load_bias);
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
        InternClassLeafFrame(interned, sample.class_name());

    const uint64_t callstack_iid = next_callstack_iid_++;
    auto* cs = interned->add_callstacks();
    cs->set_iid(callstack_iid);
    for (size_t i = 0; i < frame_count; ++i) {
      cs->add_frame_ids(frame_iids[i]);
    }
    return callstack_iid;
  }

  void WriteProcessDump(
      TracePacket* packet,
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
  uint64_t pid_;
  uint64_t* packet_index_;

  uint64_t next_str_iid_ = 1;
  uint64_t next_map_iid_ = 1;
  uint64_t next_frame_iid_ = 1;
  uint64_t next_callstack_iid_ = 1;
  uint64_t synthetic_map_iid_ = 0;
};

/// Snapshots sampled heap allocations and emits them across one or more
/// `TracePacket` batches.
template <typename EmitPacketFn>
void WriteHeapProfilePackets(HeapSampleAggregator& aggregator,
                             intptr_t sampling_interval,
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

  ProfileDumpSerializer serializer(segments, sampling_interval, boot_ns,
                                   mono_ns, packet_index);
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

}  // namespace flutter::android_heap_profile_internal

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_DART_HEAP_PROFILER_INTERNAL_H_
