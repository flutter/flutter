// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_SKY_SETTINGS_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_SKY_SETTINGS_H_

#include <stdint.h>

#include <string>
#include <vector>

namespace blink {

struct SkySettings {
  bool enable_observatory = false;
  // Port on target will be auto selected by the OS. A message will be printed
  // on the target with the port after it has been selected.
  uint32_t observatory_port = 0;
  bool start_paused = false;
  bool enable_dart_checked_mode = false;
  bool trace_startup = false;
  std::string aot_snapshot_path;
  std::string temp_directory_path;
  std::vector<std::string> dart_flags;

  static const SkySettings& Get();
  static void Set(const SkySettings& settings);
};

}  // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_SKY_SETTINGS_H_
