// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_metrics.h"

#include <sstream>
#include <string>

#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"


namespace base {
namespace debug {

// Tests for SystemMetrics.
// Exists as a class so it can be a friend of SystemMetrics.
class SystemMetricsTest : public testing::Test {
 public:
  SystemMetricsTest() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(SystemMetricsTest);
};

/////////////////////////////////////////////////////////////////////////////

#if defined(OS_LINUX) || defined(OS_ANDROID)
TEST_F(SystemMetricsTest, IsValidDiskName) {
  std::string invalid_input1 = "";
  std::string invalid_input2 = "s";
  std::string invalid_input3 = "sdz+";
  std::string invalid_input4 = "hda0";
  std::string invalid_input5 = "mmcbl";
  std::string invalid_input6 = "mmcblka";
  std::string invalid_input7 = "mmcblkb";
  std::string invalid_input8 = "mmmblk0";

  EXPECT_FALSE(IsValidDiskName(invalid_input1));
  EXPECT_FALSE(IsValidDiskName(invalid_input2));
  EXPECT_FALSE(IsValidDiskName(invalid_input3));
  EXPECT_FALSE(IsValidDiskName(invalid_input4));
  EXPECT_FALSE(IsValidDiskName(invalid_input5));
  EXPECT_FALSE(IsValidDiskName(invalid_input6));
  EXPECT_FALSE(IsValidDiskName(invalid_input7));
  EXPECT_FALSE(IsValidDiskName(invalid_input8));

  std::string valid_input1 = "sda";
  std::string valid_input2 = "sdaaaa";
  std::string valid_input3 = "hdz";
  std::string valid_input4 = "mmcblk0";
  std::string valid_input5 = "mmcblk999";

  EXPECT_TRUE(IsValidDiskName(valid_input1));
  EXPECT_TRUE(IsValidDiskName(valid_input2));
  EXPECT_TRUE(IsValidDiskName(valid_input3));
  EXPECT_TRUE(IsValidDiskName(valid_input4));
  EXPECT_TRUE(IsValidDiskName(valid_input5));
}

TEST_F(SystemMetricsTest, ParseMeminfo) {
  struct SystemMemoryInfoKB meminfo;
  std::string invalid_input1 = "abc";
  std::string invalid_input2 = "MemTotal:";
  // Partial file with no MemTotal
  std::string invalid_input3 =
    "MemFree:         3913968 kB\n"
    "Buffers:         2348340 kB\n"
    "Cached:         49071596 kB\n"
    "SwapCached:           12 kB\n"
    "Active:         36393900 kB\n"
    "Inactive:       21221496 kB\n"
    "Active(anon):    5674352 kB\n"
    "Inactive(anon):   633992 kB\n";
  EXPECT_FALSE(ParseProcMeminfo(invalid_input1, &meminfo));
  EXPECT_FALSE(ParseProcMeminfo(invalid_input2, &meminfo));
  EXPECT_FALSE(ParseProcMeminfo(invalid_input3, &meminfo));

  std::string valid_input1 =
    "MemTotal:        3981504 kB\n"
    "MemFree:          140764 kB\n"
    "Buffers:          116480 kB\n"
    "Cached:           406160 kB\n"
    "SwapCached:        21304 kB\n"
    "Active:          3152040 kB\n"
    "Inactive:         472856 kB\n"
    "Active(anon):    2972352 kB\n"
    "Inactive(anon):   270108 kB\n"
    "Active(file):     179688 kB\n"
    "Inactive(file):   202748 kB\n"
    "Unevictable:           0 kB\n"
    "Mlocked:               0 kB\n"
    "SwapTotal:       5832280 kB\n"
    "SwapFree:        3672368 kB\n"
    "Dirty:               184 kB\n"
    "Writeback:             0 kB\n"
    "AnonPages:       3101224 kB\n"
    "Mapped:           142296 kB\n"
    "Shmem:            140204 kB\n"
    "Slab:              54212 kB\n"
    "SReclaimable:      30936 kB\n"
    "SUnreclaim:        23276 kB\n"
    "KernelStack:        2464 kB\n"
    "PageTables:        24812 kB\n"
    "NFS_Unstable:          0 kB\n"
    "Bounce:                0 kB\n"
    "WritebackTmp:          0 kB\n"
    "CommitLimit:     7823032 kB\n"
    "Committed_AS:    7973536 kB\n"
    "VmallocTotal:   34359738367 kB\n"
    "VmallocUsed:      375940 kB\n"
    "VmallocChunk:   34359361127 kB\n"
    "DirectMap4k:       72448 kB\n"
    "DirectMap2M:     4061184 kB\n";
  // output from a much older kernel where the Active and Inactive aren't
  // broken down into anon and file and Huge Pages are enabled
  std::string valid_input2 =
    "MemTotal:       255908 kB\n"
    "MemFree:         69936 kB\n"
    "Buffers:         15812 kB\n"
    "Cached:         115124 kB\n"
    "SwapCached:          0 kB\n"
    "Active:          92700 kB\n"
    "Inactive:        63792 kB\n"
    "HighTotal:           0 kB\n"
    "HighFree:            0 kB\n"
    "LowTotal:       255908 kB\n"
    "LowFree:         69936 kB\n"
    "SwapTotal:      524280 kB\n"
    "SwapFree:       524200 kB\n"
    "Dirty:               4 kB\n"
    "Writeback:           0 kB\n"
    "Mapped:          42236 kB\n"
    "Slab:            25912 kB\n"
    "Committed_AS:   118680 kB\n"
    "PageTables:       1236 kB\n"
    "VmallocTotal:  3874808 kB\n"
    "VmallocUsed:      1416 kB\n"
    "VmallocChunk:  3872908 kB\n"
    "HugePages_Total:     0\n"
    "HugePages_Free:      0\n"
    "Hugepagesize:     4096 kB\n";

  EXPECT_TRUE(ParseProcMeminfo(valid_input1, &meminfo));
  EXPECT_EQ(meminfo.total, 3981504);
  EXPECT_EQ(meminfo.free, 140764);
  EXPECT_EQ(meminfo.buffers, 116480);
  EXPECT_EQ(meminfo.cached, 406160);
  EXPECT_EQ(meminfo.active_anon, 2972352);
  EXPECT_EQ(meminfo.active_file, 179688);
  EXPECT_EQ(meminfo.inactive_anon, 270108);
  EXPECT_EQ(meminfo.inactive_file, 202748);
  EXPECT_EQ(meminfo.swap_total, 5832280);
  EXPECT_EQ(meminfo.swap_free, 3672368);
  EXPECT_EQ(meminfo.dirty, 184);
#if defined(OS_CHROMEOS)
  EXPECT_EQ(meminfo.shmem, 140204);
  EXPECT_EQ(meminfo.slab, 54212);
#endif
  EXPECT_TRUE(ParseProcMeminfo(valid_input2, &meminfo));
  EXPECT_EQ(meminfo.total, 255908);
  EXPECT_EQ(meminfo.free, 69936);
  EXPECT_EQ(meminfo.buffers, 15812);
  EXPECT_EQ(meminfo.cached, 115124);
  EXPECT_EQ(meminfo.swap_total, 524280);
  EXPECT_EQ(meminfo.swap_free, 524200);
  EXPECT_EQ(meminfo.dirty, 4);
}

TEST_F(SystemMetricsTest, ParseVmstat) {
  struct SystemMemoryInfoKB meminfo;
  // part of vmstat from a 3.2 kernel with numa enabled
  std::string valid_input1 =
    "nr_free_pages 905104\n"
    "nr_inactive_anon 142478"
    "nr_active_anon 1520046\n"
    "nr_inactive_file 4481001\n"
    "nr_active_file 8313439\n"
    "nr_unevictable 5044\n"
    "nr_mlock 5044\n"
    "nr_anon_pages 1633780\n"
    "nr_mapped 104742\n"
    "nr_file_pages 12828218\n"
    "nr_dirty 245\n"
    "nr_writeback 0\n"
    "nr_slab_reclaimable 831609\n"
    "nr_slab_unreclaimable 41164\n"
    "nr_page_table_pages 31470\n"
    "nr_kernel_stack 1735\n"
    "nr_unstable 0\n"
    "nr_bounce 0\n"
    "nr_vmscan_write 406\n"
    "nr_vmscan_immediate_reclaim 281\n"
    "nr_writeback_temp 0\n"
    "nr_isolated_anon 0\n"
    "nr_isolated_file 0\n"
    "nr_shmem 28820\n"
    "nr_dirtied 84674644\n"
    "nr_written 75307109\n"
    "nr_anon_transparent_hugepages 0\n"
    "nr_dirty_threshold 1536206\n"
    "nr_dirty_background_threshold 768103\n"
    "pgpgin 30777108\n"
    "pgpgout 319023278\n"
    "pswpin 179\n"
    "pswpout 406\n"
    "pgalloc_dma 0\n"
    "pgalloc_dma32 20833399\n"
    "pgalloc_normal 1622609290\n"
    "pgalloc_movable 0\n"
    "pgfree 1644355583\n"
    "pgactivate 75391882\n"
    "pgdeactivate 4121019\n"
    "pgfault 2542879679\n"
    "pgmajfault 487192\n";
  std::string valid_input2 =
    "nr_free_pages 180125\n"
    "nr_inactive_anon 51\n"
    "nr_active_anon 38832\n"
    "nr_inactive_file 50171\n"
    "nr_active_file 47510\n"
    "nr_unevictable 0\n"
    "nr_mlock 0\n"
    "nr_anon_pages 38825\n"
    "nr_mapped 24043\n"
    "nr_file_pages 97733\n"
    "nr_dirty 0\n"
    "nr_writeback 0\n"
    "nr_slab_reclaimable 4032\n"
    "nr_slab_unreclaimable 2848\n"
    "nr_page_table_pages 1505\n"
    "nr_kernel_stack 626\n"
    "nr_unstable 0\n"
    "nr_bounce 0\n"
    "nr_vmscan_write 0\n"
    "nr_vmscan_immediate_reclaim 0\n"
    "nr_writeback_temp 0\n"
    "nr_isolated_anon 0\n"
    "nr_isolated_file 0\n"
    "nr_shmem 58\n"
    "nr_dirtied 435358\n"
    "nr_written 401258\n"
    "nr_anon_transparent_hugepages 0\n"
    "nr_dirty_threshold 18566\n"
    "nr_dirty_background_threshold 4641\n"
    "pgpgin 299464\n"
    "pgpgout 2437788\n"
    "pswpin 12\n"
    "pswpout 901\n"
    "pgalloc_normal 144213030\n"
    "pgalloc_high 164501274\n"
    "pgalloc_movable 0\n"
    "pgfree 308894908\n"
    "pgactivate 239320\n"
    "pgdeactivate 1\n"
    "pgfault 716044601\n"
    "pgmajfault 2023\n"
    "pgrefill_normal 0\n"
    "pgrefill_high 0\n"
    "pgrefill_movable 0\n";
  EXPECT_TRUE(ParseProcVmstat(valid_input1, &meminfo));
  EXPECT_EQ(meminfo.pswpin, 179);
  EXPECT_EQ(meminfo.pswpout, 406);
  EXPECT_EQ(meminfo.pgmajfault, 487192);
  EXPECT_TRUE(ParseProcVmstat(valid_input2, &meminfo));
  EXPECT_EQ(meminfo.pswpin, 12);
  EXPECT_EQ(meminfo.pswpout, 901);
  EXPECT_EQ(meminfo.pgmajfault, 2023);
}
#endif  // defined(OS_LINUX) || defined(OS_ANDROID)

#if defined(OS_LINUX) || defined(OS_ANDROID)
TEST(SystemMetrics2Test, GetSystemMemoryInfo) {
  base::SystemMemoryInfoKB info;
  EXPECT_TRUE(base::GetSystemMemoryInfo(&info));

  // Ensure each field received a value.
  EXPECT_GT(info.total, 0);
  EXPECT_GT(info.free, 0);
  EXPECT_GT(info.buffers, 0);
  EXPECT_GT(info.cached, 0);
  EXPECT_GT(info.active_anon, 0);
  EXPECT_GT(info.inactive_anon, 0);
  EXPECT_GT(info.active_file, 0);
  EXPECT_GT(info.inactive_file, 0);

  // All the values should be less than the total amount of memory.
  EXPECT_LT(info.free, info.total);
  EXPECT_LT(info.buffers, info.total);
  EXPECT_LT(info.cached, info.total);
  EXPECT_LT(info.active_anon, info.total);
  EXPECT_LT(info.inactive_anon, info.total);
  EXPECT_LT(info.active_file, info.total);
  EXPECT_LT(info.inactive_file, info.total);

#if defined(OS_CHROMEOS)
  // Chrome OS exposes shmem.
  EXPECT_GT(info.shmem, 0);
  EXPECT_LT(info.shmem, info.total);
  // Chrome unit tests are not run on actual Chrome OS hardware, so gem_objects
  // and gem_size cannot be tested here.
#endif
}
#endif  // defined(OS_LINUX) || defined(OS_ANDROID)

#if defined(OS_LINUX) || defined(OS_ANDROID)
TEST(ProcessMetricsTest, ParseProcStatCPU) {
  // /proc/self/stat for a process running "top".
  const char kTopStat[] = "960 (top) S 16230 960 16230 34818 960 "
      "4202496 471 0 0 0 "
      "12 16 0 0 "  // <- These are the goods.
      "20 0 1 0 121946157 15077376 314 18446744073709551615 4194304 "
      "4246868 140733983044336 18446744073709551615 140244213071219 "
      "0 0 0 138047495 0 0 0 17 1 0 0 0 0 0";
  EXPECT_EQ(12 + 16, base::ParseProcStatCPU(kTopStat));

  // cat /proc/self/stat on a random other machine I have.
  const char kSelfStat[] = "5364 (cat) R 5354 5364 5354 34819 5364 "
      "0 142 0 0 0 "
      "0 0 0 0 "  // <- No CPU, apparently.
      "16 0 1 0 1676099790 2957312 114 4294967295 134512640 134528148 "
      "3221224832 3221224344 3086339742 0 0 0 0 0 0 0 17 0 0 0";

  EXPECT_EQ(0, base::ParseProcStatCPU(kSelfStat));

  // Some weird long-running process with a weird name that I created for the
  // purposes of this test.
  const char kWeirdNameStat[] = "26115 (Hello) You ()))  ) R 24614 26115 24614"
      " 34839 26115 4218880 227 0 0 0 "
      "5186 11 0 0 "
      "20 0 1 0 36933953 4296704 90 18446744073709551615 4194304 4196116 "
      "140735857761568 140735857761160 4195644 0 0 0 0 0 0 0 17 14 0 0 0 0 0 "
      "6295056 6295616 16519168 140735857770710 140735857770737 "
      "140735857770737 140735857774557 0";
  EXPECT_EQ(5186 + 11, base::ParseProcStatCPU(kWeirdNameStat));
}
#endif // defined(OS_LINUX) || defined(OS_ANDROID)

// Disable on Android because base_unittests runs inside a Dalvik VM that
// starts and stop threads (crbug.com/175563).
#if defined(OS_LINUX)
// http://crbug.com/396455
TEST(ProcessMetricsTest, DISABLED_GetNumberOfThreads) {
  const base::ProcessHandle current = base::GetCurrentProcessHandle();
  const int initial_threads = base::GetNumberOfThreads(current);
  ASSERT_GT(initial_threads, 0);
  const int kNumAdditionalThreads = 10;
  {
    scoped_ptr<base::Thread> my_threads[kNumAdditionalThreads];
    for (int i = 0; i < kNumAdditionalThreads; ++i) {
      my_threads[i].reset(new base::Thread("GetNumberOfThreadsTest"));
      my_threads[i]->Start();
      ASSERT_EQ(base::GetNumberOfThreads(current), initial_threads + 1 + i);
    }
  }
  // The Thread destructor will stop them.
  ASSERT_EQ(initial_threads, base::GetNumberOfThreads(current));
}
#endif  // defined(OS_LINUX)

}  // namespace debug
}  // namespace base
