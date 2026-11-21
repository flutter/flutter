// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <string_view>
#include <vector>

#include "flutter/shell/platform/android/android_dart_heap_profiler_internal.h"
#include "gtest/gtest.h"

namespace flutter::testing {
namespace {

namespace hp = android_heap_profile_internal;
using InternedData = perfetto::protos::pbzero::InternedData;
using InternedString = perfetto::protos::pbzero::InternedString;
using TracePacket = perfetto::protos::pbzero::TracePacket;

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

TEST(AndroidDartHeapProfilerTest,
     AggregatesAllocationsAndFreesByCallstackAndClass) {
  hp::HeapSampleAggregator agg;
  constexpr std::array<uintptr_t, 2> kStackA = {0x1004, 0x2008};
  constexpr std::array<uintptr_t, 2> kStackB = {0x3004, 0x2008};

  void* r1 = agg.RecordAllocWithPcs(1u, "_GrowableList", 1024, kStackA);
  void* r2 = agg.RecordAllocWithPcs(1u, "_GrowableList", 2048, kStackA);
  void* r3 = agg.RecordAllocWithPcs(1u, "_OneByteString", 512, kStackA);
  void* r4 = agg.RecordAllocWithPcs(1u, "_GrowableList", 4096, kStackB);
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

  EXPECT_TRUE(agg.TakeSnapshot().empty());

  hp::HeapSampleAggregator::RecordFree(r2);
  hp::HeapSampleAggregator::RecordFree(r3);
  hp::HeapSampleAggregator::RecordFree(r4);
  EXPECT_EQ(agg.TakeSnapshot().size(), 3u);
}

TEST(AndroidDartHeapProfilerTest, CapturesCurrentThreadBacktrace) {
  hp::HeapSampleAggregator agg;
  void* handle = agg.RecordCurrentThreadAlloc(1u, "Widget", 512);
  ASSERT_NE(handle, nullptr);
  const std::vector<hp::SampleSnapshot> snaps = agg.TakeSnapshot();
  ASSERT_EQ(snaps.size(), 1u);
  EXPECT_FALSE(snaps[0].sample->pcs().empty());
  hp::HeapSampleAggregator::RecordFree(handle);
}

TEST(AndroidDartHeapProfilerTest, ParsesProfilingManagerHeapprofdConfig) {
  auto other_app = BuildDataSourceConfig(3, [](protozero::Message* hc) {
    hc->AppendVarInt(/*sampling_interval_bytes=*/1, 4096u);
    hc->AppendString(/*process_cmdline=*/2, "com.other.app");
  });
  EXPECT_FALSE(
      hp::ParseDataSourceConfigForProcess(other_app, 100, "com.example.app")
          .matched);

  auto pm_cfg = BuildDataSourceConfig(7, [](protozero::Message* hc) {
    hc->AppendVarInt(/*sampling_interval_bytes=*/1, 65536u);
    hc->AppendString(/*process_cmdline=*/2, "com.example.flutter_app");
    hc->AppendString(/*heaps=*/20, "libc.malloc");
    hc->AppendString(/*heaps=*/20, "com.android.art");
  });

  const hp::ParsedHeapprofdSession parsed = hp::ParseDataSourceConfigForProcess(
      pm_cfg, 42, "com.example.flutter_app");
  EXPECT_TRUE(parsed.matched);
  EXPECT_EQ(parsed.target_buffer, 7u);
  EXPECT_EQ(parsed.sampling_interval, 65536);

  auto pid_cfg = BuildDataSourceConfig(
      2, [](protozero::Message* hc) { hc->AppendVarInt(/*pid=*/4, 42u); });
  EXPECT_TRUE(
      hp::ParseDataSourceConfigForProcess(pid_cfg, 42, "com.example").matched);
}

TEST(AndroidDartHeapProfilerTest,
     EmitsValidMultiBatchProfilePacketsAndInternedData) {
  hp::HeapSampleAggregator agg;
  std::vector<void*> handles;
  handles.reserve(150);
  for (uintptr_t i = 0; i < 150; ++i) {
    const std::array<uintptr_t, 2> pcs = {
        reinterpret_cast<uintptr_t>(&BuildDataSourceConfig) + (i % 4),
        0xdead0000u + i,
    };
    handles.push_back(agg.RecordAllocWithPcs(1u, "Widget", 256, pcs));
  }

  uint64_t pkt_index = 0;
  std::vector<std::vector<uint8_t>> packets;
  hp::WriteHeapProfilePackets(agg, 65536, &pkt_index, [&](auto&& fill_fn) {
    protozero::HeapBuffered<TracePacket> pkt;
    fill_fn(pkt.get());
    packets.push_back(pkt.SerializeAsArray());
  });

  ASSERT_EQ(packets.size(), 2u);
  EXPECT_EQ(pkt_index, 2u);

  {
    TracePacket::Decoder p0(packets[0].data(), packets[0].size());
    EXPECT_FALSE(p0.has_trusted_packet_sequence_id());
    EXPECT_EQ(p0.sequence_flags(),
              static_cast<uint32_t>(TracePacket::SEQ_INCREMENTAL_STATE_CLEARED |
                                    TracePacket::SEQ_NEEDS_INCREMENTAL_STATE));
    ASSERT_TRUE(p0.has_interned_data());
    InternedData::Decoder interned(p0.interned_data());
    ASSERT_TRUE(interned.has_build_ids());
    InternedString::Decoder first_bid(*interned.build_ids());
    EXPECT_EQ(first_bid.iid(), 0u);
    ASSERT_TRUE(interned.has_frames());
    for (auto it = interned.frames(); it; ++it) {
      perfetto::protos::pbzero::Frame::Decoder frame(*it);
      EXPECT_NE(frame.mapping_id(), 0u);
    }

    protozero::ProtoDecoder raw_p0(packets[0].data(), packets[0].size());
    EXPECT_TRUE(
        raw_p0.FindField(hp::proto_fields::kTracePacketFirstPacketOnSequence)
            .as_bool());
    auto prof_field =
        raw_p0.FindField(hp::proto_fields::kTracePacketProfilePacket);
    ASSERT_TRUE(prof_field.valid());
    protozero::ProtoDecoder prof(prof_field.data(), prof_field.size());
    EXPECT_TRUE(
        prof.FindField(hp::proto_fields::kProfilePacketContinued).as_bool());
    EXPECT_EQ(prof.FindField(hp::proto_fields::kProfilePacketIndex).as_uint64(),
              0u);
  }

  {
    TracePacket::Decoder p1(packets[1].data(), packets[1].size());
    EXPECT_FALSE(p1.has_trusted_packet_sequence_id());
    EXPECT_EQ(p1.sequence_flags(),
              static_cast<uint32_t>(TracePacket::SEQ_NEEDS_INCREMENTAL_STATE));
    protozero::ProtoDecoder raw_p1(packets[1].data(), packets[1].size());
    EXPECT_FALSE(
        raw_p1.FindField(hp::proto_fields::kTracePacketFirstPacketOnSequence)
            .valid());
    auto prof_field =
        raw_p1.FindField(hp::proto_fields::kTracePacketProfilePacket);
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

#if defined(__aarch64__) || defined(__x86_64__) || \
    (defined(__riscv) && (__riscv_xlen == 64))
TEST(AndroidDartHeapProfilerTest, DetectsDartSnapshotsMissingEhFrameHdr) {
  hp::ElfModuleScanner::SyntheticDartEhFrame eh;
  eh.pc_begin = 0x7a000e0000ULL;
  eh.pc_range = 0x250b00ULL;
  EXPECT_EQ(reinterpret_cast<const uint8_t*>(&eh.cie_pointer) - eh.cie_pointer,
            reinterpret_cast<const uint8_t*>(&eh.cie_length));

  constexpr std::string_view kDartDynstr(
      "\0_kDartSnapshotText\0_kDartSnapshotData\0", 39);
  constexpr std::string_view kOatDynstr("\0oatdata\0oatexec\0", 17);

  struct MockModule {
    std::array<char, 64> dynstr = {};
    std::array<ElfW(Dyn), 3> dyn = {};
    std::array<ElfW(Phdr), 3> phdrs = {};
  };

  MockModule mod;
  std::copy_n(kDartDynstr.data(), kDartDynstr.size(), mod.dynstr.data());
  const auto base = reinterpret_cast<uintptr_t>(&mod);
  mod.dyn[0].d_tag = DT_STRTAB;
  mod.dyn[0].d_un.d_ptr = offsetof(MockModule, dynstr);
  mod.dyn[1].d_tag = DT_STRSZ;
  mod.dyn[1].d_un.d_val = kDartDynstr.size();
  mod.dyn[2].d_tag = DT_NULL;

  mod.phdrs[0].p_type = PT_LOAD;
  mod.phdrs[0].p_vaddr = 0;
  mod.phdrs[0].p_memsz = sizeof(MockModule);
  mod.phdrs[1].p_type = PT_DYNAMIC;
  mod.phdrs[1].p_vaddr = offsetof(MockModule, dyn);
  mod.phdrs[1].p_memsz = sizeof(mod.dyn);
  mod.phdrs[2].p_type = PT_NOTE;

  dl_phdr_info info{};
  info.dlpi_addr = static_cast<ElfW(Addr)>(base);
  info.dlpi_phdr = mod.phdrs.data();
  info.dlpi_phnum = 2;
  EXPECT_TRUE(hp::ElfModuleScanner::IsDartSnapshotWithoutEhFrameHdr(&info));

  mod.phdrs[2].p_type = PT_GNU_EH_FRAME;
  mod.phdrs[2].p_memsz = 24;
  info.dlpi_phnum = 3;
  EXPECT_FALSE(hp::ElfModuleScanner::IsDartSnapshotWithoutEhFrameHdr(&info));

  info.dlpi_phnum = 2;
  mod.dynstr.fill(0);
  std::copy_n(kOatDynstr.data(), kOatDynstr.size(), mod.dynstr.data());
  mod.dyn[1].d_un.d_val = kOatDynstr.size();
  EXPECT_FALSE(hp::ElfModuleScanner::IsDartSnapshotWithoutEhFrameHdr(&info));
}
#endif

}  // namespace
}  // namespace flutter::testing
