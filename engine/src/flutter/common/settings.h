// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_SETTINGS_H_
#define FLUTTER_COMMON_SETTINGS_H_

#include <stdint.h>

#include <string>
#include <vector>

namespace blink {

struct Settings {
  bool enable_observatory = false;
  // Port on target will be auto selected by the OS. A message will be printed
  // on the target with the port after it has been selected.
  uint32_t observatory_port = 0;
  bool start_paused = false;
  bool enable_dart_checked_mode = false;
  bool trace_startup = false;
  bool endless_trace_buffer = false;
  std::string aot_snapshot_path;
  std::string aot_isolate_snapshot_file_name;
  std::string aot_vm_isolate_snapshot_file_name;
  std::string aot_instructions_blob_file_name;
  std::string aot_rodata_blob_file_name;
  std::string temp_directory_path;
  std::vector<std::string> dart_flags;

  static const Settings& Get();
  static void Set(const Settings& settings);
};

}  // namespace blink

#endif  // FLUTTER_COMMON_SETTINGS_H_
