// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "cpu_affinity.h"

#include "fml/file.h"
#include "fml/mapping.h"
#include "gtest/gtest.h"
#include "logging.h"

namespace fml {
namespace testing {

TEST(CpuAffinity, NonAndroidPlatformDefaults) {
  ASSERT_FALSE(fml::EfficiencyCoreCount().has_value());
  ASSERT_TRUE(fml::RequestAffinity(fml::CpuAffinity::kEfficiency));
}

TEST(CpuAffinity, NormalSlowMedFastCores) {
  auto speeds = {CpuIndexAndSpeed{.index = 0, .speed = 1},
                 CpuIndexAndSpeed{.index = 1, .speed = 2},
                 CpuIndexAndSpeed{.index = 2, .speed = 3}};
  auto tracker = CPUSpeedTracker(speeds);

  ASSERT_TRUE(tracker.IsValid());
  ASSERT_EQ(tracker.GetIndices(CpuAffinity::kEfficiency)[0], 0u);
  ASSERT_EQ(tracker.GetIndices(CpuAffinity::kPerformance)[0], 2u);
  ASSERT_EQ(tracker.GetIndices(CpuAffinity::kNotPerformance).size(), 2u);
  ASSERT_EQ(tracker.GetIndices(CpuAffinity::kNotPerformance)[0], 0u);
  ASSERT_EQ(tracker.GetIndices(CpuAffinity::kNotPerformance)[1], 1u);
  ASSERT_EQ(tracker.GetIndices(CpuAffinity::kNotLittle).size(), 2u);
  ASSERT_EQ(tracker.GetIndices(CpuAffinity::kNotLittle)[0], 1u);
  ASSERT_EQ(tracker.GetIndices(CpuAffinity::kNotLittle)[1], 2u);
}

TEST(CpuAffinity, NoLittleCores) {
  // Two prime and six performance cores, as read on a Snapdragon 8 Elite
  // Gen 5: the slowest cores are three quarters of the fastest.
  std::vector<CpuIndexAndSpeed> speeds;
  for (size_t i = 0; i < 8; i++) {
    speeds.push_back({.index = i,
                      .speed = i < 6 ? 3628800 : 4608000,
                      .capacity = i < 6 ? 762 : 1024});
  }
  auto tracker = CPUSpeedTracker(speeds);

  EXPECT_TRUE(tracker.IsValid());
  EXPECT_EQ(tracker.GetIndices(CpuAffinity::kNotLittle).size(), 8u);
  EXPECT_EQ(tracker.GetIndices(CpuAffinity::kEfficiency).size(), 6u);
  EXPECT_EQ(tracker.GetIndices(CpuAffinity::kPerformance).size(), 2u);
}

TEST(CpuAffinity, LittleCoresByCapacity) {
  auto speeds = {
      CpuIndexAndSpeed{.index = 0, .speed = 2265600, .capacity = 381},
      CpuIndexAndSpeed{.index = 1, .speed = 3148800, .capacity = 980},
      CpuIndexAndSpeed{.index = 2, .speed = 3302400, .capacity = 1024}};
  auto tracker = CPUSpeedTracker(speeds);

  EXPECT_TRUE(tracker.IsValid());
  // The size check guards the indexing below.
  ASSERT_EQ(tracker.GetIndices(CpuAffinity::kNotLittle).size(), 2u);
  EXPECT_EQ(tracker.GetIndices(CpuAffinity::kNotLittle)[0], 1u);
  EXPECT_EQ(tracker.GetIndices(CpuAffinity::kNotLittle)[1], 2u);
}

TEST(CpuAffinity, CapacitiesThatSayNothing) {
  // A kernel without capacity data reports 1024 for every CPU; a missing
  // capacity leaves the speeds to decide too.
  for (const auto& capacities :
       {std::vector<std::optional<int64_t>>{1024, 1024, 1024},
        std::vector<std::optional<int64_t>>{762, std::nullopt, 1024}}) {
    std::vector<CpuIndexAndSpeed> speeds;
    for (size_t i = 0; i < 3; i++) {
      speeds.push_back({.index = i,
                        .speed = static_cast<int64_t>(i + 1),
                        .capacity = capacities[i]});
    }
    auto tracker = CPUSpeedTracker(speeds);

    EXPECT_TRUE(tracker.IsValid());
    ASSERT_EQ(tracker.GetIndices(CpuAffinity::kNotLittle).size(), 2u);
    EXPECT_EQ(tracker.GetIndices(CpuAffinity::kNotLittle)[0], 1u);
  }
}

TEST(CpuAffinity, NoCpuData) {
  auto tracker = CPUSpeedTracker({});

  ASSERT_FALSE(tracker.IsValid());
}

TEST(CpuAffinity, AllSameSpeed) {
  auto speeds = {CpuIndexAndSpeed{.index = 0, .speed = 1},
                 CpuIndexAndSpeed{.index = 1, .speed = 1},
                 CpuIndexAndSpeed{.index = 2, .speed = 1}};
  auto tracker = CPUSpeedTracker(speeds);

  ASSERT_FALSE(tracker.IsValid());
}

TEST(CpuAffinity, SingleCore) {
  auto speeds = {CpuIndexAndSpeed{.index = 0, .speed = 1}};
  auto tracker = CPUSpeedTracker(speeds);

  ASSERT_FALSE(tracker.IsValid());
}

TEST(CpuAffinity, FileParsing) {
  fml::ScopedTemporaryDirectory base_dir;
  ASSERT_TRUE(base_dir.fd().is_valid());

  // Generate a fake CPU speed file
  fml::DataMapping test_data(std::string("12345"));
  ASSERT_TRUE(fml::WriteAtomically(base_dir.fd(), "test_file", test_data));

  auto file = fml::OpenFileReadOnly(base_dir.fd(), "test_file");
  ASSERT_TRUE(file.is_valid());

  // Open file and parse speed.
  auto result = ReadIntFromFile(base_dir.path() + "/test_file");
  ASSERT_TRUE(result.has_value());
  ASSERT_EQ(result.value_or(0), 12345);
}

TEST(CpuAffinity, FileParsingWithNonNumber) {
  fml::ScopedTemporaryDirectory base_dir;
  ASSERT_TRUE(base_dir.fd().is_valid());

  // Generate a fake CPU speed file
  fml::DataMapping test_data(std::string("whoa this isnt a number"));
  ASSERT_TRUE(fml::WriteAtomically(base_dir.fd(), "test_file", test_data));

  auto file = fml::OpenFileReadOnly(base_dir.fd(), "test_file");
  ASSERT_TRUE(file.is_valid());

  // Open file and parse speed.
  auto result = ReadIntFromFile(base_dir.path() + "/test_file");
  ASSERT_FALSE(result.has_value());
}

TEST(CpuAffinity, MissingFileParsing) {
  auto result = ReadIntFromFile("/does_not_exist");
  ASSERT_FALSE(result.has_value());
}

}  // namespace testing
}  // namespace fml
