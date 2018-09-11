// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/settings.h"

#include <sstream>

namespace blink {

std::string Settings::ToString() const {
  std::stringstream stream;
  stream << "Settings: " << std::endl;
  stream << "vm_snapshot_data_path: " << vm_snapshot_data_path << std::endl;
  stream << "vm_snapshot_instr_path: " << vm_snapshot_instr_path << std::endl;
  stream << "isolate_snapshot_data_path: " << isolate_snapshot_data_path
         << std::endl;
  stream << "isolate_snapshot_instr_path: " << isolate_snapshot_instr_path
         << std::endl;
  stream << "application_library_path: " << application_library_path
         << std::endl;
  stream << "main_dart_file_path: " << main_dart_file_path << std::endl;
  stream << "packages_file_path: " << packages_file_path << std::endl;
  stream << "temp_directory_path: " << temp_directory_path << std::endl;
  stream << "dart_flags:" << std::endl;
  for (const auto& dart_flag : dart_flags) {
    stream << "    " << dart_flag << std::endl;
  }
  stream << "start_paused: " << start_paused << std::endl;
  stream << "trace_skia: " << trace_skia << std::endl;
  stream << "trace_startup: " << trace_startup << std::endl;
  stream << "endless_trace_buffer: " << endless_trace_buffer << std::endl;
  stream << "enable_dart_profiling: " << enable_dart_profiling << std::endl;
  stream << "dart_non_checked_mode: " << dart_non_checked_mode << std::endl;
  stream << "enable_observatory: " << enable_observatory << std::endl;
  stream << "observatory_port: " << observatory_port << std::endl;
  stream << "ipv6: " << ipv6 << std::endl;
  stream << "use_test_fonts: " << use_test_fonts << std::endl;
  stream << "enable_software_rendering: " << enable_software_rendering
         << std::endl;
  stream << "log_tag: " << log_tag << std::endl;
  stream << "icu_data_path: " << icu_data_path << std::endl;
  stream << "assets_dir: " << assets_dir << std::endl;
  stream << "assets_path: " << assets_path << std::endl;
  return stream.str();
}

}  // namespace blink
