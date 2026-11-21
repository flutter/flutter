// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <string>
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
    std::string_view name,
    uint32_t target_buffer,
    uint32_t nested_field_id,
    const std::function<void(protozero::Message*)>& fill_nested) {
  protozero::HeapBuffered<protozero::Message> dsc;
  if (!name.empty()) {
    dsc->AppendBytes(/*name=*/1, name.data(), name.size());
  }
  dsc->AppendVarInt(/*target_buffer=*/2, target_buffer);
  if (fill_nested) {
    fill_nested(dsc->BeginNestedMessage<protozero::Message>(nested_field_id));
  }
  return dsc.SerializeAsArray();
}

std::vector<uint8_t> BuildHeapprofdDataSourceConfig(
    uint32_t target_buffer,
    const std::function<void(protozero::Message*)>& fill_heapprofd) {
  return BuildDataSourceConfig(hp::kHeapprofdDataSourceName, target_buffer,
                               /*heapprofd_config=*/105, fill_heapprofd);
}

std::vector<uint8_t> BuildJavaHprofDataSourceConfig(
    std::string_view ds_name,
    uint32_t target_buffer,
    const std::function<void(protozero::Message*)>& fill_hprof) {
  return BuildDataSourceConfig(ds_name, target_buffer,
                               /*java_hprof_config=*/110, fill_hprof);
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
    if (s.sample->class_name == "_GrowableList" &&
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
  auto other_app =
      BuildHeapprofdDataSourceConfig(3, [](protozero::Message* hc) {
        hc->AppendVarInt(/*sampling_interval_bytes=*/1, 4096u);
        hc->AppendString(/*process_cmdline=*/2, "com.other.app");
      });
  EXPECT_FALSE(
      hp::ParseDataSourceConfigForProcess(other_app, 100, "com.example.app")
          .matched);

  auto pm_cfg = BuildHeapprofdDataSourceConfig(7, [](protozero::Message* hc) {
    hc->AppendVarInt(/*sampling_interval_bytes=*/1, 65536u);
    hc->AppendString(/*process_cmdline=*/2,
                     "/system/bin/com.example.flutter_app@1.0");
    hc->AppendString(/*heaps=*/20, "libc.malloc");
    hc->AppendString(/*heaps=*/20, "com.android.art");
    auto* cdc = hc->BeginNestedMessage<protozero::Message>(
        /*continuous_dump_config=*/6);
    cdc->AppendVarInt(/*dump_phase_ms=*/5, 1000u);
    cdc->AppendVarInt(/*dump_interval_ms=*/6, 5000u);
    hc->AppendVarInt(/*no_startup=*/10, 1u);
  });

  const hp::ParsedSessionConfig parsed = hp::ParseDataSourceConfigForProcess(
      pm_cfg, 42, "com.example.flutter_app");
  EXPECT_EQ(parsed.kind, hp::SessionKind::kHeapprofd);
  EXPECT_TRUE(parsed.matched);
  EXPECT_EQ(parsed.target_buffer, 7u);
  EXPECT_EQ(parsed.sampling_interval, 65536);
  EXPECT_EQ(parsed.dump_phase_ms, 1000u);
  EXPECT_EQ(parsed.dump_interval_ms, 5000u);
  EXPECT_TRUE(parsed.no_startup);

  auto pid_cfg = BuildHeapprofdDataSourceConfig(
      2, [](protozero::Message* hc) { hc->AppendVarInt(/*pid=*/4, 42u); });
  EXPECT_TRUE(
      hp::ParseDataSourceConfigForProcess(pid_cfg, 42, "com.example").matched);
}

TEST(AndroidDartHeapProfilerTest, ParsesJavaHprofConfigWithWildcards) {
  auto cfg = BuildJavaHprofDataSourceConfig(
      hp::kJavaHprofOomDataSourceName, 5, [](protozero::Message* jhc) {
        jhc->AppendString(/*process_cmdline=*/1, "com.example.*");
      });

  const hp::ParsedSessionConfig matched =
      hp::ParseDataSourceConfigForProcess(cfg, 99, "com.example.flutter_shop");
  EXPECT_EQ(matched.kind, hp::SessionKind::kJavaHprof);
  EXPECT_TRUE(matched.matched);
  EXPECT_EQ(matched.target_buffer, 5u);

  EXPECT_FALSE(
      hp::ParseDataSourceConfigForProcess(cfg, 99, "org.other.app").matched);
}

TEST(AndroidDartHeapProfilerTest,
     PrunesIdleCallsitesAndSeedsSurvivingAllocationsIntoSession) {
  hp::HeapSampleAggregator agg;
  agg.EndSession();

  constexpr std::array<uintptr_t, 2> kDeadStack = {0x1110, 0x2220};
  constexpr std::array<uintptr_t, 2> kLiveStack = {0x3330, 0x4440};

  void* dead_handle = agg.RecordAllocWithPcs(1u, "ShortLived", 512, kDeadStack);
  void* live_handle =
      agg.RecordAllocWithPcs(1u, "LeakedCache", 8192, kLiveStack);
  ASSERT_NE(dead_handle, nullptr);
  ASSERT_NE(live_handle, nullptr);
  EXPECT_EQ(agg.TrackedCallsiteCount(), 2u);

  // Dead pre-session samples must auto-prune from entries_ while idle.
  hp::HeapSampleAggregator::RecordFree(dead_handle);
  EXPECT_EQ(agg.TrackedCallsiteCount(), 1u);

  // Start a session with startup surviving-allocation seeding enabled.
  agg.BeginSession();
  hp::HeapSampleAggregator::SeededBatch batch{.aggregator = &agg};
  hp::HeapSampleAggregator::SeedSurvivingSampleCallback(&batch, live_handle);
  agg.FinalizeSeededBatch(batch);

  const std::vector<hp::SampleSnapshot> snaps = agg.TakeSnapshot();
  ASSERT_EQ(snaps.size(), 1u);
  EXPECT_EQ(snaps[0].sample->class_name, "LeakedCache");
  EXPECT_EQ(snaps[0].self_allocated, 8192u);
  EXPECT_EQ(snaps[0].self_freed, 0u);
  EXPECT_EQ(snaps[0].alloc_count, 1u);

  // Freeing the seeded pre-session object during the session updates self_freed
  // monotonically (self_freed <= self_allocated).
  hp::HeapSampleAggregator::RecordFree(live_handle);
  const std::vector<hp::SampleSnapshot> after_free = agg.TakeSnapshot();
  ASSERT_EQ(after_free.size(), 1u);
  EXPECT_EQ(after_free[0].self_allocated, 8192u);
  EXPECT_EQ(after_free[0].self_freed, 8192u);
  EXPECT_EQ(after_free[0].free_count, 1u);

  agg.EndSession();
  EXPECT_EQ(agg.TrackedCallsiteCount(), 0u);
}

TEST(AndroidDartHeapProfilerTest,
     EmitsValidMultiBatchProfilePacketsAndPreservesCallstackIdAcrossFlushes) {
  hp::HeapSampleAggregator agg;
  std::vector<void*> handles;
  handles.reserve(150);
  for (uintptr_t i = 0; i < 150; ++i) {
    const std::array<uintptr_t, 2> pcs = {
        reinterpret_cast<uintptr_t>(&BuildHeapprofdDataSourceConfig) + (i % 4),
        0xdead0000u + i,
    };
    handles.push_back(agg.RecordAllocWithPcs(1u, "Widget", 256, pcs));
  }

  bool first_on_seq = true;
  uint64_t pkt_index = 0;
  std::vector<std::vector<uint8_t>> packets;
  hp::WriteHeapProfilePackets(agg, 65536, /*from_startup=*/true, &first_on_seq,
                              &pkt_index, [&](auto&& fill_fn) {
                                protozero::HeapBuffered<TracePacket> pkt;
                                fill_fn(pkt.get());
                                packets.push_back(pkt.SerializeAsArray());
                              });

  ASSERT_EQ(packets.size(), 2u);
  EXPECT_EQ(pkt_index, 2u);
  EXPECT_FALSE(first_on_seq);

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

    protozero::TypedProtoDecoder<87, false> raw_p0(packets[0].data(),
                                                   packets[0].size());
    EXPECT_TRUE(raw_p0.at<87>().as_bool());
    const auto prof_bytes = raw_p0.at<37>().as_bytes();
    ASSERT_NE(prof_bytes.data, nullptr);
    protozero::TypedProtoDecoder<7, true> prof(prof_bytes.data,
                                               prof_bytes.size);
    EXPECT_TRUE(prof.at<6>().as_bool());
    EXPECT_EQ(prof.at<7>().as_uint64(), 0u);
    const auto dump_bytes = prof.at<5>().as_bytes();
    ASSERT_NE(dump_bytes.data, nullptr);
    protozero::TypedProtoDecoder<13, true> dump(dump_bytes.data,
                                                dump_bytes.size);
    EXPECT_TRUE(dump.at<3>().as_bool());
  }

  {
    TracePacket::Decoder p1(packets[1].data(), packets[1].size());
    EXPECT_FALSE(p1.has_trusted_packet_sequence_id());
    EXPECT_EQ(p1.sequence_flags(),
              static_cast<uint32_t>(TracePacket::SEQ_NEEDS_INCREMENTAL_STATE));
    protozero::TypedProtoDecoder<87, false> raw_p1(packets[1].data(),
                                                   packets[1].size());
    EXPECT_FALSE(raw_p1.at<87>().valid());
    const auto prof_bytes = raw_p1.at<37>().as_bytes();
    ASSERT_NE(prof_bytes.data, nullptr);
    protozero::TypedProtoDecoder<7, true> prof(prof_bytes.data,
                                               prof_bytes.size);
    EXPECT_FALSE(prof.at<6>().as_bool());
    EXPECT_EQ(prof.at<7>().as_uint64(), 1u);
  }

  // Trigger a second incremental dump on the same writer sequence and verify
  // packet_index continues at 2 without re-setting first_packet_on_sequence.
  hp::HeapSampleAggregator::RecordFree(handles.front());
  handles.front() = nullptr;
  std::vector<std::vector<uint8_t>> second_dump;
  hp::WriteHeapProfilePackets(agg, 65536, /*from_startup=*/false, &first_on_seq,
                              &pkt_index, [&](auto&& fill_fn) {
                                protozero::HeapBuffered<TracePacket> pkt;
                                fill_fn(pkt.get());
                                second_dump.push_back(pkt.SerializeAsArray());
                              });
  ASSERT_EQ(second_dump.size(), 2u);
  protozero::TypedProtoDecoder<87, false> raw_second0(second_dump[0].data(),
                                                      second_dump[0].size());
  EXPECT_FALSE(raw_second0.at<87>().valid());
  const auto second_prof_bytes = raw_second0.at<37>().as_bytes();
  protozero::TypedProtoDecoder<7, true> second_prof(second_prof_bytes.data,
                                                    second_prof_bytes.size);
  EXPECT_EQ(second_prof.at<7>().as_uint64(), 2u);

  for (void* h : handles) {
    hp::HeapSampleAggregator::RecordFree(h);
  }
}

TEST(AndroidDartHeapProfilerTest,
     EmitsValidMultiBatchHeapGraphFromSurvivingSamples) {
  hp::HeapSampleAggregator agg;
  constexpr std::array<uintptr_t, 2> kStack = {0x1234, 0x5678};
  std::vector<void*> handles;
  handles.reserve(135);
  for (size_t i = 0; i < 135; ++i) {
    handles.push_back(agg.RecordAllocWithPcs(1u, "_Uint8List", 4096, kStack));
  }

  std::vector<hp::SurvivingObjectSample> surviving;
  for (void* h : handles) {
    hp::HeapSampleAggregator::CollectSurvivingSampleCallback(&surviving, h);
  }
  ASSERT_EQ(surviving.size(), 135u);

  bool first_on_seq = true;
  uint64_t pkt_index = 0;
  std::vector<std::vector<uint8_t>> packets;
  hp::WriteDartHeapGraphPackets(surviving, &first_on_seq, &pkt_index,
                                [&](auto&& fill_fn) {
                                  protozero::HeapBuffered<TracePacket> pkt;
                                  fill_fn(pkt.get());
                                  packets.push_back(pkt.SerializeAsArray());
                                });

  // 135 samples split across kSamplesPerPacketBatch (128) -> 2 packets.
  ASSERT_EQ(packets.size(), 2u);
  EXPECT_EQ(pkt_index, 2u);
  EXPECT_FALSE(first_on_seq);

  protozero::TypedProtoDecoder<87, false> p0(packets[0].data(),
                                             packets[0].size());
  EXPECT_TRUE(p0.at<87>().as_bool());
  const auto hg0_bytes = p0.at<56>().as_bytes();
  ASSERT_NE(hg0_bytes.data, nullptr);
  protozero::TypedProtoDecoder<9, true> hg0(hg0_bytes.data, hg0_bytes.size);
  EXPECT_TRUE(hg0.at<5>().as_bool());
  EXPECT_EQ(hg0.at<6>().as_uint64(), 0u);
  EXPECT_TRUE(hg0.at<7>().valid());

  protozero::TypedProtoDecoder<87, false> p1(packets[1].data(),
                                             packets[1].size());
  EXPECT_FALSE(p1.at<87>().valid());
  const auto hg1_bytes = p1.at<56>().as_bytes();
  ASSERT_NE(hg1_bytes.data, nullptr);
  protozero::TypedProtoDecoder<9, true> hg1(hg1_bytes.data, hg1_bytes.size);
  EXPECT_FALSE(hg1.at<5>().as_bool());
  EXPECT_EQ(hg1.at<6>().as_uint64(), 1u);
  EXPECT_TRUE(hg1.at<9>().valid());
  EXPECT_TRUE(hg1.at<4>().valid());
  EXPECT_TRUE(hg1.at<8>().valid());

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
