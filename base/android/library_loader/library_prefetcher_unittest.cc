// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/library_loader/library_prefetcher.h"

#include <string>
#include <vector>
#include "base/debug/proc_maps_linux.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace android {

namespace {
const uint8 kRead = base::debug::MappedMemoryRegion::READ;
const uint8 kReadPrivate = base::debug::MappedMemoryRegion::READ |
                           base::debug::MappedMemoryRegion::PRIVATE;
const uint8 kExecutePrivate = base::debug::MappedMemoryRegion::EXECUTE |
                              base::debug::MappedMemoryRegion::PRIVATE;
}  // namespace

TEST(NativeLibraryPrefetcherTest, TestIsGoodToPrefetchNoRange) {
  const base::debug::MappedMemoryRegion regions[4] = {
      base::debug::MappedMemoryRegion{0x4000, 0x5000, 10, kReadPrivate, ""},
      base::debug::MappedMemoryRegion{0x4000, 0x5000, 10, kReadPrivate, "foo"},
      base::debug::MappedMemoryRegion{
          0x4000, 0x5000, 10, kReadPrivate, "foobar.apk"},
      base::debug::MappedMemoryRegion{
          0x4000, 0x5000, 10, kReadPrivate, "libchromium.so"}};
  for (int i = 0; i < 4; ++i) {
    ASSERT_FALSE(NativeLibraryPrefetcher::IsGoodToPrefetch(regions[i]));
  }
}

TEST(NativeLibraryPrefetcherTest, TestIsGoodToPrefetchUnreadableRange) {
  const base::debug::MappedMemoryRegion region = {
      0x4000, 0x5000, 10, kExecutePrivate, "base.apk"};
  ASSERT_FALSE(NativeLibraryPrefetcher::IsGoodToPrefetch(region));
}

TEST(NativeLibraryPrefetcherTest, TestIsGoodToPrefetchSkipSharedRange) {
  const base::debug::MappedMemoryRegion region = {
      0x4000, 0x5000, 10, kRead, "base.apk"};
  ASSERT_FALSE(NativeLibraryPrefetcher::IsGoodToPrefetch(region));
}

TEST(NativeLibraryPrefetcherTest, TestIsGoodToPrefetchLibchromeRange) {
  const base::debug::MappedMemoryRegion region = {
      0x4000, 0x5000, 10, kReadPrivate, "libchrome.so"};
  ASSERT_TRUE(NativeLibraryPrefetcher::IsGoodToPrefetch(region));
}

TEST(NativeLibraryPrefetcherTest, TestIsGoodToPrefetchBaseApkRange) {
  const base::debug::MappedMemoryRegion region = {
      0x4000, 0x5000, 10, kReadPrivate, "base.apk"};
  ASSERT_TRUE(NativeLibraryPrefetcher::IsGoodToPrefetch(region));
}

TEST(NativeLibraryPrefetcherTest,
     TestFilterLibchromeRangesOnlyIfPossibleNoLibchrome) {
  std::vector<base::debug::MappedMemoryRegion> regions;
  regions.push_back(
      base::debug::MappedMemoryRegion{0x1, 0x2, 0, kReadPrivate, "base.apk"});
  regions.push_back(
      base::debug::MappedMemoryRegion{0x3, 0x4, 0, kReadPrivate, "base.apk"});
  std::vector<NativeLibraryPrefetcher::AddressRange> ranges;
  NativeLibraryPrefetcher::FilterLibchromeRangesOnlyIfPossible(regions,
                                                               &ranges);
  EXPECT_EQ(ranges.size(), 2U);
  EXPECT_EQ(ranges[0].first, 0x1U);
  EXPECT_EQ(ranges[0].second, 0x2U);
  EXPECT_EQ(ranges[1].first, 0x3U);
  EXPECT_EQ(ranges[1].second, 0x4U);
}

TEST(NativeLibraryPrefetcherTest,
     TestFilterLibchromeRangesOnlyIfPossibleHasLibchrome) {
  std::vector<base::debug::MappedMemoryRegion> regions;
  regions.push_back(
      base::debug::MappedMemoryRegion{0x1, 0x2, 0, kReadPrivate, "base.apk"});
  regions.push_back(base::debug::MappedMemoryRegion{
      0x6, 0x7, 0, kReadPrivate, "libchrome.so"});
  regions.push_back(
      base::debug::MappedMemoryRegion{0x3, 0x4, 0, kReadPrivate, "base.apk"});
  std::vector<NativeLibraryPrefetcher::AddressRange> ranges;
  NativeLibraryPrefetcher::FilterLibchromeRangesOnlyIfPossible(regions,
                                                               &ranges);
  EXPECT_EQ(ranges.size(), 1U);
  EXPECT_EQ(ranges[0].first, 0x6U);
  EXPECT_EQ(ranges[0].second, 0x7U);
}

}  // namespace android
}  // namespace base
