// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/build_config.h"

#if defined(FML_OS_LINUX) || defined(FML_OS_ANDROID)

#include <string>
#include <vector>

#include "flutter/runtime/dart_heap_profiler_internal.h"
#include "gtest/gtest.h"

namespace flutter::testing {
namespace {

namespace hp = heap_profile_internal;

std::vector<uint8_t> BuildDataSourceConfig(
    uint32_t target_buffer,
    const std::function<void(protozero::Message*)>& fill_heapprofd) {
  protozero::HeapBuffered<protozero::Message> dsc;
  dsc->AppendVarInt(/*target_buffer=*/2, target_buffer);
  if (fill_heapprofd) {
    auto* hc = dsc->BeginNestedMessage<protozero::Message>(
        /*heapprofd_config=*/105);
    fill_heapprofd(hc);
    hc->Finalize();
  }
  return dsc.SerializeAsArray();
}

TEST(DartHeapProfilerTest, AggregatesAllocationsAndFreesByCallstackAndClass) {
  hp::HeapSampleAggregator agg;
  const uintptr_t stack_a[] = {0x1004, 0x2008};
  const uintptr_t stack_b[] = {0x3004, 0x2008};

  void* r1 = agg.RecordAllocWithPcs(nullptr, "_GrowableList", 1024, stack_a, 2);
  void* r2 = agg.RecordAllocWithPcs(nullptr, "_GrowableList", 2048, stack_a, 2);
  void* r3 = agg.RecordAllocWithPcs(nullptr, "_OneByteString", 512, stack_a, 2);
  void* r4 = agg.RecordAllocWithPcs(nullptr, "_GrowableList", 4096, stack_b, 2);
  ASSERT_NE(r1, nullptr);
  ASSERT_NE(r2, nullptr);
  ASSERT_NE(r3, nullptr);
  ASSERT_NE(r4, nullptr);

  hp::HeapSampleAggregator::RecordFree(r1);

  hp::SampleSnapshot* snaps = nullptr;
  const size_t n = agg.TakeSnapshot(&snaps);
  EXPECT_EQ(n, 3u);

  bool found_list_a = false;
  for (size_t i = 0; i < n; ++i) {
    if (std::strcmp(snaps[i].entry->cls_name(), "_GrowableList") == 0 &&
        snaps[i].entry->pcs()[0] == 0x1004) {
      found_list_a = true;
      EXPECT_EQ(snaps[i].self_allocated, 3072u);
      EXPECT_EQ(snaps[i].self_freed, 1024u);
      EXPECT_EQ(snaps[i].alloc_count, 2u);
      EXPECT_EQ(snaps[i].free_count, 1u);
    }
  }
  EXPECT_TRUE(found_list_a);
  hp::HeapSampleAggregator::FreeSnapshot(snaps, n);

  // Unmodified entries are not re-emitted until dirtied again.
  EXPECT_EQ(agg.TakeSnapshot(&snaps), 0u);

  hp::HeapSampleAggregator::RecordFree(r2);
  hp::HeapSampleAggregator::RecordFree(r3);
  hp::HeapSampleAggregator::RecordFree(r4);
  const size_t n2 = agg.TakeSnapshot(&snaps);
  EXPECT_EQ(n2, 3u);
  hp::HeapSampleAggregator::FreeSnapshot(snaps, n2);
}

TEST(DartHeapProfilerTest, ParsesHeapprofdConfigFiltersAndIntervals) {
  // Rejects default malloc-only config when com.google.dart is not requested.
  auto malloc_only = BuildDataSourceConfig(3, [](protozero::Message* hc) {
    hc->AppendVarInt(/*sampling_interval_bytes=*/1, 4096u);
    hc->AppendVarInt(/*all=*/5, 1u);
  });
  EXPECT_FALSE(hp::ParseDataSourceConfigForProcess(
                   malloc_only.data(), malloc_only.size(), 100, "com.app")
                   .matched);

  // Matches com.google.dart with per-heap sampling interval, wildcard cmdline,
  // and continuous_dump_config.
  auto matched_cfg = BuildDataSourceConfig(7, [](protozero::Message* hc) {
    hc->AppendVarInt(/*sampling_interval_bytes=*/1, 4096u);
    hc->AppendString(/*process_cmdline=*/2, "com.example.*");
    hc->AppendString(/*heaps=*/20, "libc.malloc");
    hc->AppendString(/*heaps=*/20, "com.google.dart");
    protozero::PackedVarInt packed_intervals;
    packed_intervals.Append(4096u);
    packed_intervals.Append(65536u);
    hc->AppendBytes(/*heap_sampling_intervals=*/22, packed_intervals.data(),
                    packed_intervals.size());
    auto* cdc = hc->BeginNestedMessage<protozero::Message>(
        /*continuous_dump_config=*/6);
    cdc->AppendVarInt(/*dump_phase_ms=*/5, 250u);
    cdc->AppendVarInt(/*dump_interval_ms=*/6, 1000u);
    cdc->Finalize();
  });

  hp::ParsedHeapprofdSession parsed = hp::ParseDataSourceConfigForProcess(
      matched_cfg.data(), matched_cfg.size(), 42,
      "/system/bin/com.example.flutter_app");
  EXPECT_TRUE(parsed.matched);
  EXPECT_EQ(parsed.target_buffer, 7u);
  EXPECT_EQ(parsed.sampling_interval, 65536);
  EXPECT_EQ(parsed.dump_phase_ms, 250u);
  EXPECT_EQ(parsed.dump_interval_ms, 1000u);

  // Honors exclude_heaps even when all_heaps = true.
  auto excluded_cfg = BuildDataSourceConfig(1, [](protozero::Message* hc) {
    hc->AppendVarInt(/*all=*/5, 1u);
    hc->AppendVarInt(/*all_heaps=*/21, 1u);
    hc->AppendString(/*exclude_heaps=*/27, "com.google.dart");
  });
  EXPECT_FALSE(hp::ParseDataSourceConfigForProcess(
                   excluded_cfg.data(), excluded_cfg.size(), 42, "com.example")
                   .matched);
}

TEST(DartHeapProfilerTest, EmitsValidMultiBatchProfilePacketsAndInternedData) {
  hp::HeapSampleAggregator agg;
  std::vector<void*> records;
  // Create 150 distinct callsites (> kSamplesPerPacketBatch = 128) to exercise
  // multi-packet continuation and incremental-state preservation.
  for (uintptr_t i = 0; i < 150; ++i) {
    const uintptr_t pcs[] = {
        reinterpret_cast<uintptr_t>(&BuildDataSourceConfig) + (i % 4),
        0xdead0000u + i,
    };
    records.push_back(agg.RecordAllocWithPcs(nullptr, "Widget", 256, pcs, 2));
  }

  uint64_t pkt_index = 0;
  uint64_t prev_mono_ns = 123456ULL;
  std::vector<std::vector<uint8_t>> packets;
  hp::WriteHeapProfilePackets(agg, 65536, &pkt_index, &prev_mono_ns,
                              [&](auto&& fill_fn) {
                                protozero::HeapBuffered<protozero::Message> pkt;
                                fill_fn(pkt.get());
                                packets.push_back(pkt.SerializeAsArray());
                              });

  ASSERT_EQ(packets.size(), 2u);
  EXPECT_EQ(pkt_index, 2u);

  // Packet 0 must clear incremental state (flags == 3), mark continued == true,
  // and include iid=0 empty interned strings.
  {
    protozero::ProtoDecoder p0(packets[0].data(), packets[0].size());
    EXPECT_EQ(p0.FindField(hp::kTracePacketSequenceFlagsField).as_uint32(), 3u);
    auto interned_field = p0.FindField(hp::kTracePacketInternedDataField);
    ASSERT_TRUE(interned_field.valid());
    protozero::ProtoDecoder interned(interned_field.data(),
                                     interned_field.size());
    auto first_bid = interned.FindField(hp::kInternedBuildIdsField);
    ASSERT_TRUE(first_bid.valid());
    protozero::ProtoDecoder bid_dec(first_bid.data(), first_bid.size());
    EXPECT_EQ(bid_dec.FindField(1).as_uint64(), 0u);

    auto prof_field = p0.FindField(hp::kTracePacketProfilePacketField);
    ASSERT_TRUE(prof_field.valid());
    protozero::ProtoDecoder prof(prof_field.data(), prof_field.size());
    EXPECT_TRUE(prof.FindField(hp::kProfilePacketContinuedField).as_bool());
    EXPECT_EQ(prof.FindField(hp::kProfilePacketIndexField).as_uint64(), 0u);
  }

  // Packet 1 must NOT clear incremental state (flags == 2) and must terminate
  // the dump with continued == false.
  {
    protozero::ProtoDecoder p1(packets[1].data(), packets[1].size());
    EXPECT_EQ(p1.FindField(hp::kTracePacketSequenceFlagsField).as_uint32(), 2u);
    auto prof_field = p1.FindField(hp::kTracePacketProfilePacketField);
    ASSERT_TRUE(prof_field.valid());
    protozero::ProtoDecoder prof(prof_field.data(), prof_field.size());
    EXPECT_FALSE(prof.FindField(hp::kProfilePacketContinuedField).as_bool());
    EXPECT_EQ(prof.FindField(hp::kProfilePacketIndexField).as_uint64(), 1u);
  }

  for (void* r : records) {
    hp::HeapSampleAggregator::RecordFree(r);
  }
}

}  // namespace
}  // namespace flutter::testing

#endif  // defined(FML_OS_LINUX) || defined(FML_OS_ANDROID)
