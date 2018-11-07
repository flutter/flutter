// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_SETTINGS_H_
#define FLUTTER_COMMON_SETTINGS_H_

#include <fcntl.h>
#include <stdint.h>

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/unique_fd.h"

namespace blink {

using TaskObserverAdd =
    std::function<void(intptr_t /* key */, fml::closure /* callback */)>;
using TaskObserverRemove = std::function<void(intptr_t /* key */)>;

struct Settings {
  // VM settings
  std::string vm_snapshot_data_path;
  std::string vm_snapshot_instr_path;
  std::string isolate_snapshot_data_path;
  std::string isolate_snapshot_instr_path;

  std::string application_library_path;
  std::string application_kernel_asset;
  std::string application_kernel_list_asset;

  std::string main_dart_file_path;
  std::string packages_file_path;

  std::string temp_directory_path;
  std::vector<std::string> dart_flags;

  // Isolate settings
  bool start_paused = false;
  bool trace_skia = false;
  bool trace_startup = false;
  bool endless_trace_buffer = false;
  bool enable_dart_profiling = false;
  bool dart_non_checked_mode = false;
  // Used as the script URI in debug messages. Does not affect how the Dart code
  // is executed.
  std::string advisory_script_uri = "main.dart";
  // Used as the script entrypoint in debug messages. Does not affect how the
  // Dart code is executed.
  std::string advisory_script_entrypoint = "main";

  // Observatory settings
  bool enable_observatory = false;
  // Port on target will be auto selected by the OS. A message will be printed
  // on the target with the port after it has been selected.
  uint32_t observatory_port = 0;
  bool ipv6 = false;

  // Font settings
  bool use_test_fonts = false;

  // Engine settings
  TaskObserverAdd task_observer_add;
  TaskObserverRemove task_observer_remove;
  // The main isolate is current when this callback is made. This is a good spot
  // to perform native Dart bindings for libraries not built in.
  fml::closure root_isolate_create_callback;
  // The isolate is not current and may have already been destroyed when this
  // call is made.
  fml::closure root_isolate_shutdown_callback;
  bool enable_software_rendering = false;
  bool skia_deterministic_rendering_on_cpu = false;
  bool verbose_logging = false;
  std::string log_tag = "flutter";
  std::string icu_data_path;

  // Assets settings
  fml::UniqueFD::element_type assets_dir =
      fml::UniqueFD::traits_type::InvalidValue();
  std::string assets_path;
  std::string flx_path;

  std::string ToString() const;
};

}  // namespace blink

#endif  // FLUTTER_COMMON_SETTINGS_H_
