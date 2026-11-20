// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/build_config.h"

#if defined(FML_OS_LINUX) || defined(FML_OS_ANDROID)

#include <array>
#include <cstdint>
#include <functional>
#include <vector>

#include "flutter/runtime/dart_heap_profiler_internal.h"
#include "gtest/gtest.h"
#include "perfetto/protozero/packed_repeated_fields.h"

namespace flutter::testing {
namespace {

namespace hp = heap_profile_internal;

std::vector<uint8_t> BuildDataSourceConfig(
    uint32_t target_buffer,
    const std::function<void(protozero::Message*)>& fill_heapprofd) {
  protozero::HeapBuffered<protozero::Message> dsc;
  dsc->AppendVarInt(/*target_buffer=*/2, target_buffer);
  if (fill_heapprofd) {
    auto* hc =
        dsc->BeginNestedMessage<protozero::Message>(/*heapprofd_config=*/105);
    fill_heapprofd(hc);
    hc->Finalize();
  }
  return dsc.SerializeAsArray();
}

TEST(DartHeapProfilerTest, AggregatesAllocationsAndFreesByCallstackAndClass) {
  hp::HeapSampleAggregator agg;
  constexpr std::array<uintptr_t, 2> kStackA = {0x1004, 0x2008};
  constexpr std::array<uintptr_t, 2> kStackB = {0x3004, 0x2008};

  void* r1 = agg.RecordAllocWithPcs(nullptr, "_GrowableList", 1024, kStackA);
  void* r2 = agg.RecordAllocWithPcs(nullptr, "_GrowableList", 2048, kStackA);
  void* r3 = agg.RecordAllocWithPcs(nullptr, "_OneByteString", 512, kStackA);
  void* r4 = agg.RecordAllocWithPcs(nullptr, "_GrowableList", 4096, kStackB);
  ASSERT_NE(r1, nullptr);
  ASSERT_NE(r2, nullptr);
  ASSERT_NE(r3, nullptr);
  ASSERT_NE(r4, nullptr);

  hp::HeapSampleAggregator::RecordFree(r1);

  const std::vector<hp::SampleSnapshot> snaps = agg.TakeSnapshot();
  EXPECT_EQ(snaps.size(), 3u);

  bool found_list_a = false;
  for (const hp::SampleSnapshot& s : snaps) {
    if (s.sample->class_name() == "_GrowableList" &&
        s.sample->pcs()[0] == 0x1004) {
      found_list_a = true;
      EXPECT_EQ(s.self_allocated, 3072u);
      EXPECT_EQ(s.self_freed, 1024u);
      EXPECT_EQ(s.alloc_count, 2u);
      EXPECT_EQ(s.free_count, 1u);
    }
  }
  EXPECT_TRUE(found_list_a);

  // Unmodified entries are not re-emitted until dirtied again.
  EXPECT_TRUE(agg.TakeSnapshot().empty());

  hp::HeapSampleAggregator::RecordFree(r2);
  hp::HeapSampleAggregator::RecordFree(r3);
  hp::HeapSampleAggregator::RecordFree(r4);
  EXPECT_EQ(agg.TakeSnapshot().size(), 3u);
}

TEST(DartHeapProfilerTest, ParsesHeapprofdConfigFiltersAndIntervals) {
  auto malloc_only = BuildDataSourceConfig(3, [](protozero::Message* hc) {
    hc->AppendVarInt(/*sampling_interval_bytes=*/1, 4096u);
    hc->AppendVarInt(/*all=*/5, 1u);
  });
  EXPECT_FALSE(
      hp::ParseDataSourceConfigForProcess(malloc_only, 100, "com.app").matched);

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

  const hp::ParsedHeapprofdSession parsed = hp::ParseDataSourceConfigForProcess(
      matched_cfg, 42, "/system/bin/com.example.flutter_app");
  EXPECT_TRUE(parsed.matched);
  EXPECT_EQ(parsed.target_buffer, 7u);
  EXPECT_EQ(parsed.sampling_interval, 65536);
  EXPECT_EQ(parsed.dump_phase_ms, 250u);
  EXPECT_EQ(parsed.dump_interval_ms, 1000u);

  auto excluded_cfg = BuildDataSourceConfig(1, [](protozero::Message* hc) {
    hc->AppendVarInt(/*all=*/5, 1u);
    hc->AppendVarInt(/*all_heaps=*/21, 1u);
    hc->AppendString(/*exclude_heaps=*/27, "com.google.dart");
  });
  EXPECT_FALSE(
      hp::ParseDataSourceConfigForProcess(excluded_cfg, 42, "com.example")
          .matched);
}

TEST(DartHeapProfilerTest, EmitsValidMultiBatchProfilePacketsAndInternedData) {
  hp::HeapSampleAggregator agg;
  std::vector<void*> handles;
  handles.reserve(150);
  for (uintptr_t i = 0; i < 150; ++i) {
    const std::array<uintptr_t, 2> pcs = {
        reinterpret_cast<uintptr_t>(&BuildDataSourceConfig) + (i % 4),
        0xdead0000u + i,
    };
    handles.push_back(agg.RecordAllocWithPcs(nullptr, "Widget", 256, pcs));
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

  {
    protozero::ProtoDecoder p0(packets[0].data(), packets[0].size());
    EXPECT_EQ(
        p0.FindField(hp::proto_fields::kTracePacketSequenceFlags).as_uint32(),
        3u);
    auto interned_field =
        p0.FindField(hp::proto_fields::kTracePacketInternedData);
    ASSERT_TRUE(interned_field.valid());
    protozero::ProtoDecoder interned(interned_field.data(),
                                     interned_field.size());
    auto first_bid = interned.FindField(hp::proto_fields::kInternedBuildIds);
    ASSERT_TRUE(first_bid.valid());
    protozero::ProtoDecoder bid_dec(first_bid.data(), first_bid.size());
    EXPECT_EQ(
        bid_dec.FindField(hp::proto_fields::kInternedStringIid).as_uint64(),
        0u);

    auto prof_field = p0.FindField(hp::proto_fields::kTracePacketProfilePacket);
    ASSERT_TRUE(prof_field.valid());
    protozero::ProtoDecoder prof(prof_field.data(), prof_field.size());
    EXPECT_TRUE(
        prof.FindField(hp::proto_fields::kProfilePacketContinued).as_bool());
    EXPECT_EQ(prof.FindField(hp::proto_fields::kProfilePacketIndex).as_uint64(),
              0u);
  }

  {
    protozero::ProtoDecoder p1(packets[1].data(), packets[1].size());
    EXPECT_EQ(
        p1.FindField(hp::proto_fields::kTracePacketSequenceFlags).as_uint32(),
        2u);
    auto prof_field = p1.FindField(hp::proto_fields::kTracePacketProfilePacket);
    ASSERT_TRUE(prof_field.valid());
    protozero::ProtoDecoder prof(prof_field.data(), prof_field.size());
    EXPECT_FALSE(
        prof.FindField(hp::proto_fields::kProfilePacketContinued).as_bool());
    EXPECT_EQ(prof.FindField(hp::proto_fields::kProfilePacketIndex).as_uint64(),
              1u);
  }

  for (void* h : handles) {
    hp::HeapSampleAggregator::RecordFree(h);
  }
}

}  // namespace
}  // namespace flutter::testing

#endif  // defined(FML_OS_LINUX) || defined(FML_OS_ANDROID)
