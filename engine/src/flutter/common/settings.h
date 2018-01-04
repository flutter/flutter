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
  bool ipv6 = false;
  bool start_paused = false;
  bool trace_startup = false;
  bool endless_trace_buffer = false;
  bool enable_dart_profiling = false;
  bool use_test_fonts = false;
  bool dart_non_checked_mode = false;
  bool dart_strong_mode = false;
  bool enable_software_rendering = false;
  bool using_blink = true;
  std::string aot_shared_library_path;
  std::string aot_snapshot_path;
  std::string aot_vm_snapshot_data_filename;
  std::string aot_vm_snapshot_instr_filename;
  std::string aot_isolate_snapshot_data_filename;
  std::string aot_isolate_snapshot_instr_filename;
  std::string application_library_path;
  std::string temp_directory_path;
  std::vector<std::string> dart_flags;
  std::string log_tag = "flutter";

  static const Settings& Get();
  static void Set(const Settings& settings);
};

}  // namespace blink

#endif  // FLUTTER_COMMON_SETTINGS_H_
