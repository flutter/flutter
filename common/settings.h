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
#include "flutter/fml/mapping.h"
#include "flutter/fml/unique_fd.h"

namespace blink {

using TaskObserverAdd =
    std::function<void(intptr_t /* key */, fml::closure /* callback */)>;
using TaskObserverRemove = std::function<void(intptr_t /* key */)>;
using UnhandledExceptionCallback =
    std::function<bool(const std::string& /* error */,
                       const std::string& /* stack trace */)>;

// TODO(chinmaygarde): Deprecate all the "path" struct members in favor of the
// callback that generates the mapping from these paths.
// https://github.com/flutter/flutter/issues/26783
using MappingCallback = std::function<std::unique_ptr<fml::Mapping>(void)>;

struct Settings {
  Settings();

  Settings(const Settings& other);

  ~Settings();

  // VM settings
  std::string vm_snapshot_data_path;  // deprecated
  MappingCallback vm_snapshot_data;
  std::string vm_snapshot_instr_path;  // deprecated
  MappingCallback vm_snapshot_instr;

  std::string isolate_snapshot_data_path;  // deprecated
  MappingCallback isolate_snapshot_data;
  std::string isolate_snapshot_instr_path;  // deprecated
  MappingCallback isolate_snapshot_instr;

  // Returns the Mapping to a kernel buffer which contains sources for dart:*
  // libraries.
  MappingCallback dart_library_sources_kernel;

  std::string application_library_path;
  std::string application_kernel_asset;
  std::string application_kernel_list_asset;

  std::string temp_directory_path;
  std::vector<std::string> dart_flags;

  // Isolate settings
  bool start_paused = false;
  bool trace_skia = false;
  bool trace_startup = false;
  bool trace_systrace = false;
  bool dump_skp_on_shader_compilation = false;
  bool endless_trace_buffer = false;
  bool enable_dart_profiling = false;
  bool disable_dart_asserts = false;
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
  // The callback made on the UI thread in an isolate scope when the engine
  // detects that the framework is idle. The VM also uses this time to perform
  // tasks suitable when idling. Due to this, embedders are still advised to be
  // as fast as possible in returning from this callback. Long running
  // operations in this callback do have the capability of introducing jank.
  std::function<void(int64_t)> idle_notification_callback;
  // A callback given to the embedder to react to unhandled exceptions in the
  // running Flutter application. This callback is made on an internal engine
  // managed thread and embedders must re-thread as necessary. Performing
  // blocking calls in this callback will cause applications to jank.
  UnhandledExceptionCallback unhandled_exception_callback;
  bool enable_software_rendering = false;
  bool skia_deterministic_rendering_on_cpu = false;
  bool verbose_logging = false;
  std::string log_tag = "flutter";

  // The icu_initialization_required setting does not have a corresponding
  // switch because it is intended to be decided during build time, not runtime.
  // Some companies apply source modification here because their build system
  // brings its own ICU data files.
  bool icu_initialization_required = true;
  std::string icu_data_path;
  MappingCallback icu_mapper;

  // Assets settings
  fml::UniqueFD::element_type assets_dir =
      fml::UniqueFD::traits_type::InvalidValue();
  std::string assets_path;
  std::string flx_path;

  std::string ToString() const;
};

}  // namespace blink

#endif  // FLUTTER_COMMON_SETTINGS_H_
