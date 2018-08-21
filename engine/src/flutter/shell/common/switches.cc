// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <sstream>
#include <string>

#include "flutter/fml/paths.h"
#include "flutter/fml/string_view.h"
#include "flutter/shell/version/version.h"

// Include once for the default enum definition.
#include "flutter/shell/common/switches.h"

#undef SHELL_COMMON_SWITCHES_H_

struct SwitchDesc {
  shell::Switch sw;
  const fml::StringView flag;
  const char* help;
};

#undef DEF_SWITCHES_START
#undef DEF_SWITCH
#undef DEF_SWITCHES_END

// clang-format off
#define DEF_SWITCHES_START static const struct SwitchDesc gSwitchDescs[] = {
#define DEF_SWITCH(p_swtch, p_flag, p_help) \
  { shell::Switch:: p_swtch, p_flag, p_help },
#define DEF_SWITCHES_END };
// clang-format on

// Include again for struct definition.
#include "flutter/shell/common/switches.h"

namespace shell {

void PrintUsage(const std::string& executable_name) {
  std::cerr << std::endl << "  " << executable_name << std::endl << std::endl;

  std::cerr << "Versions: " << std::endl << std::endl;

  std::cerr << "Flutter Engine Version: " << GetFlutterEngineVersion()
            << std::endl;
  std::cerr << "Skia Version: " << GetSkiaVersion() << std::endl;

  std::cerr << "Dart Version: " << GetDartVersion() << std::endl << std::endl;

  std::cerr << "Available Flags:" << std::endl;

  const uint32_t column_width = 80;

  const uint32_t flags_count = static_cast<uint32_t>(Switch::Sentinel);

  uint32_t max_width = 2;
  for (uint32_t i = 0; i < flags_count; i++) {
    auto desc = gSwitchDescs[i];
    max_width = std::max<uint32_t>(desc.flag.size() + 2, max_width);
  }

  const uint32_t help_width = column_width - max_width - 3;

  std::cerr << std::string(column_width, '-') << std::endl;
  for (uint32_t i = 0; i < flags_count; i++) {
    auto desc = gSwitchDescs[i];

    std::cerr << std::setw(max_width)
              << std::string("--") + desc.flag.ToString() << " : ";

    std::istringstream stream(desc.help);
    int32_t remaining = help_width;

    std::string word;
    while (stream >> word && remaining > 0) {
      remaining -= (word.size() + 1);
      if (remaining <= 0) {
        std::cerr << std::endl
                  << std::string(max_width, ' ') << "   " << word << " ";
        remaining = help_width;
      } else {
        std::cerr << word << " ";
      }
    }

    std::cerr << std::endl;
  }
  std::cerr << std::string(column_width, '-') << std::endl;
}

const fml::StringView FlagForSwitch(Switch swtch) {
  for (uint32_t i = 0; i < static_cast<uint32_t>(Switch::Sentinel); i++) {
    if (gSwitchDescs[i].sw == swtch) {
      return gSwitchDescs[i].flag;
    }
  }
  return fml::StringView();
}

template <typename T>
static bool GetSwitchValue(const fml::CommandLine& command_line,
                           shell::Switch sw,
                           T* result) {
  std::string switch_string;

  if (!command_line.GetOptionValue(shell::FlagForSwitch(sw), &switch_string)) {
    return false;
  }

  std::stringstream stream(switch_string);
  T value = 0;
  if (stream >> value) {
    *result = value;
    return true;
  }

  return false;
}

blink::Settings SettingsFromCommandLine(const fml::CommandLine& command_line) {
  blink::Settings settings = {};

  // Enable Observatory
  settings.enable_observatory =
      !command_line.HasOption(FlagForSwitch(Switch::DisableObservatory));

  // Set Observatory Port
  if (command_line.HasOption(FlagForSwitch(Switch::DeviceObservatoryPort))) {
    if (!GetSwitchValue(command_line, Switch::DeviceObservatoryPort,
                        &settings.observatory_port)) {
      FML_LOG(INFO)
          << "Observatory port specified was malformed. Will default to "
          << settings.observatory_port;
    }
  }

  // Checked mode overrides.
  settings.dart_non_checked_mode =
      command_line.HasOption(FlagForSwitch(Switch::DartNonCheckedMode));

  settings.ipv6 = command_line.HasOption(FlagForSwitch(Switch::IPv6));

  settings.start_paused =
      command_line.HasOption(FlagForSwitch(Switch::StartPaused));

  settings.enable_dart_profiling =
      command_line.HasOption(FlagForSwitch(Switch::EnableDartProfiling));

  settings.enable_software_rendering =
      command_line.HasOption(FlagForSwitch(Switch::EnableSoftwareRendering));

  settings.endless_trace_buffer =
      command_line.HasOption(FlagForSwitch(Switch::EndlessTraceBuffer));

  settings.trace_startup =
      command_line.HasOption(FlagForSwitch(Switch::TraceStartup));

  settings.skia_deterministic_rendering_on_cpu =
      command_line.HasOption(FlagForSwitch(Switch::SkiaDeterministicRendering));

  settings.verbose_logging =
      command_line.HasOption(FlagForSwitch(Switch::VerboseLogging));

  command_line.GetOptionValue(FlagForSwitch(Switch::FLX), &settings.flx_path);

  command_line.GetOptionValue(FlagForSwitch(Switch::FlutterAssetsDir),
                              &settings.assets_path);

  command_line.GetOptionValue(FlagForSwitch(Switch::Snapshot),
                              &settings.script_snapshot_path);

  command_line.GetOptionValue(FlagForSwitch(Switch::MainDartFile),
                              &settings.main_dart_file_path);

  command_line.GetOptionValue(FlagForSwitch(Switch::Packages),
                              &settings.packages_file_path);

  std::string aot_shared_library_path;
  command_line.GetOptionValue(FlagForSwitch(Switch::AotSharedLibraryPath),
                              &aot_shared_library_path);

  std::string aot_snapshot_path;
  command_line.GetOptionValue(FlagForSwitch(Switch::AotSnapshotPath),
                              &aot_snapshot_path);

  std::string aot_vm_snapshot_data_filename;
  command_line.GetOptionValue(FlagForSwitch(Switch::AotVmSnapshotData),
                              &aot_vm_snapshot_data_filename);

  std::string aot_vm_snapshot_instr_filename;
  command_line.GetOptionValue(FlagForSwitch(Switch::AotVmSnapshotInstructions),
                              &aot_vm_snapshot_instr_filename);

  std::string aot_isolate_snapshot_data_filename;
  command_line.GetOptionValue(FlagForSwitch(Switch::AotIsolateSnapshotData),
                              &aot_isolate_snapshot_data_filename);

  std::string aot_isolate_snapshot_instr_filename;
  command_line.GetOptionValue(
      FlagForSwitch(Switch::AotIsolateSnapshotInstructions),
      &aot_isolate_snapshot_instr_filename);

  if (aot_shared_library_path.size() > 0) {
    settings.application_library_path = aot_shared_library_path;
  } else if (aot_snapshot_path.size() > 0) {
    settings.vm_snapshot_data_path = fml::paths::JoinPaths(
        {aot_snapshot_path, aot_vm_snapshot_data_filename});
    settings.vm_snapshot_instr_path = fml::paths::JoinPaths(
        {aot_snapshot_path, aot_vm_snapshot_instr_filename});
    settings.isolate_snapshot_data_path = fml::paths::JoinPaths(
        {aot_snapshot_path, aot_isolate_snapshot_data_filename});
    settings.isolate_snapshot_instr_path = fml::paths::JoinPaths(
        {aot_snapshot_path, aot_isolate_snapshot_instr_filename});
  }

  command_line.GetOptionValue(FlagForSwitch(Switch::CacheDirPath),
                              &settings.temp_directory_path);

  command_line.GetOptionValue(FlagForSwitch(Switch::ICUDataFilePath),
                              &settings.icu_data_path);

  settings.use_test_fonts =
      command_line.HasOption(FlagForSwitch(Switch::UseTestFonts));

  command_line.GetOptionValue(FlagForSwitch(Switch::LogTag), &settings.log_tag);
  std::string all_dart_flags;
  if (command_line.GetOptionValue(FlagForSwitch(Switch::DartFlags),
                                  &all_dart_flags)) {
    std::stringstream stream(all_dart_flags);
    std::istream_iterator<std::string> end;
    for (std::istream_iterator<std::string> it(stream); it != end; ++it)
      settings.dart_flags.push_back(*it);
  }

#if FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_RELEASE && \
    FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_DYNAMIC_RELEASE
  settings.trace_skia =
      command_line.HasOption(FlagForSwitch(Switch::TraceSkia));
#endif

  return settings;
}

}  // namespace shell
