// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/cpu_affinity.h"

#include <fstream>
#include <optional>
#include <string>

namespace fml {

CPUSpeedTracker::CPUSpeedTracker(std::vector<CpuIndexAndSpeed> data)
    : cpu_speeds_(std::move(data)) {
  std::optional<int64_t> max_speed = std::nullopt;
  std::optional<int64_t> min_speed = std::nullopt;
  for (const auto& data : cpu_speeds_) {
    if (!max_speed.has_value() || data.speed > max_speed.value()) {
      max_speed = data.speed;
    }
    if (!min_speed.has_value() || data.speed < min_speed.value()) {
      min_speed = data.speed;
    }
  }
  if (!max_speed.has_value() || !min_speed.has_value() ||
      min_speed.value() == max_speed.value()) {
    return;
  }

  for (const auto& data : cpu_speeds_) {
    if (data.speed == max_speed.value()) {
      performance_.push_back(data.index);
    } else {
      not_performance_.push_back(data.index);
    }
    if (data.speed == min_speed.value()) {
      efficiency_.push_back(data.index);
    }
  }

  valid_ = true;
}

bool CPUSpeedTracker::IsValid() const {
  return valid_;
}

const std::vector<size_t>& CPUSpeedTracker::GetIndices(
    CpuAffinity affinity) const {
  switch (affinity) {
    case CpuAffinity::kPerformance:
      return performance_;
    case CpuAffinity::kEfficiency:
      return efficiency_;
    case CpuAffinity::kNotPerformance:
      return not_performance_;
  }
}

// Get the size of the cpuinfo file by reading it until the end. This is
// required because files under /proc do not always return a valid size
// when using fseek(0, SEEK_END) + ftell(). Nor can they be mmap()-ed.
std::optional<int64_t> ReadIntFromFile(const std::string& path) {
  // size_t data_length = 0u;
  std::ifstream file;
  file.open(path.c_str());

  // Dont use stoi because if this data isnt a parseable number then it
  // will abort, as we compile with exceptions disabled.
  int64_t speed = 0;
  file >> speed;
  if (speed > 0) {
    return speed;
  }
  return std::nullopt;
}

}  // namespace fml
