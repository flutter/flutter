// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_CPU_AFFINITY_H_
#define FLUTTER_FML_CPU_AFFINITY_H_

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace fml {

/// The CPU Affinity provides a hint to the operating system on which cores a
/// particular thread should be scheduled on. The operating system may or may
/// not honor these requests.
///
/// The performance and efficiency cores here are the groups of cores with the
/// highest and the lowest cpuinfo_max_freq on the device. They are not the
/// industry's core types: on a chip with two prime and six performance cores,
/// the two prime cores are the performance cores here, and the six performance
/// cores are the efficiency cores.
enum class CpuAffinity {
  /// @brief Request affinity for the performance cores: those with the highest
  ///        cpuinfo_max_freq.
  kPerformance,

  /// @brief Request affinity for the efficiency cores: those with the lowest
  ///        cpuinfo_max_freq.
  kEfficiency,

  /// @brief Request affinity for every core except the performance cores.
  kNotPerformance,

  /// @brief Request affinity for every core except the little cores.
  ///
  ///        The efficiency cores count as little cores unless the kernel's
  ///        cpu_capacity values rule that out: every core reports one, they
  ///        are not all equal, and none is below half of the highest. Then
  ///        the device has no little cores, and this is every core, the
  ///        efficiency cores included.
  kNotLittle,
};

/// @brief Request count of efficiency cores.
///
///        Efficiency cores are defined as those with the lowest reported
///        cpu_max_freq. If the CPU speed could not be determined, or if all
///        cores have the same reported speed then this returns std::nullopt.
///        That is, the result will never be 0.
std::optional<size_t> EfficiencyCoreCount();

/// @brief Request the given affinity for the current thread.
///
///        Returns true if successfull, or if it was a no-op. This function is
///        only supported on Android devices.
///
///        Affinity requests are based on documented CPU speed. This speed data
///        is parsed from cpuinfo_max_freq files, see also:
///        https://www.kernel.org/doc/Documentation/cpu-freq/user-guide.txt
bool RequestAffinity(CpuAffinity affinity);

struct CpuIndexAndSpeed {
  // The index of the given CPU.
  size_t index;
  // CPU speed in kHZ
  int64_t speed;
  // The kernel's capacity of the CPU, if known: its performance at its
  // highest frequency, scaled so that the fastest CPU is 1024. Parsed from
  // cpu_capacity files, see also:
  // https://www.kernel.org/doc/Documentation/devicetree/bindings/cpu/cpu-capacity.txt
  std::optional<int64_t> capacity = std::nullopt;
};

/// @brief A class that computes the correct CPU indices for a requested CPU
///        affinity.
///
/// @note  This is visible for testing.
class CPUSpeedTracker {
 public:
  explicit CPUSpeedTracker(std::vector<CpuIndexAndSpeed> data);

  /// @brief The class is valid if it has more than one CPU index and a distinct
  ///        set of efficiency or performance CPUs.
  ///
  ///        If all CPUs are the same speed this returns false, and all requests
  ///        to set affinity are ignored.
  bool IsValid() const;

  /// @brief Return the set of CPU indices for the requested CPU affinity.
  ///
  ///        If the tracker is valid, this will always return a non-empty set.
  const std::vector<size_t>& GetIndices(CpuAffinity affinity) const;

 private:
  bool valid_ = false;
  std::vector<CpuIndexAndSpeed> cpu_speeds_;
  std::vector<size_t> efficiency_;
  std::vector<size_t> performance_;
  std::vector<size_t> not_performance_;
  std::vector<size_t> not_little_;
};

/// @note Visible for testing.
std::optional<int64_t> ReadIntFromFile(const std::string& path);

}  // namespace fml

#endif  // FLUTTER_FML_CPU_AFFINITY_H_
