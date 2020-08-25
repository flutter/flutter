// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_SETTINGS_H_
#define FLUTTER_COMMON_SETTINGS_H_

#include <fcntl.h>
#include <stdint.h>

#include <chrono>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/fml/unique_fd.h"

namespace flutter {

class FrameTiming {
 public:
  enum Phase {
    kVsyncStart,
    kBuildStart,
    kBuildFinish,
    kRasterStart,
    kRasterFinish,
    kCount
  };

  static constexpr Phase kPhases[kCount] = {
      kVsyncStart, kBuildStart, kBuildFinish, kRasterStart, kRasterFinish};

  fml::TimePoint Get(Phase phase) const { return data_[phase]; }
  fml::TimePoint Set(Phase phase, fml::TimePoint value) {
    return data_[phase] = value;
  }

 private:
  fml::TimePoint data_[kCount];
};

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
using MappingsCallback =
    std::function<std::vector<std::unique_ptr<const fml::Mapping>>(void)>;

using FrameRasterizedCallback = std::function<void(const FrameTiming&)>;

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

  // Path to a library containing the application's compiled Dart code.
  // This is a vector so that the embedder can provide fallback paths in
  // case the primary path to the library can not be loaded.
  std::vector<std::string> application_library_path;

  std::string application_kernel_asset;       // deprecated
  std::string application_kernel_list_asset;  // deprecated
  MappingsCallback application_kernels;

  std::string temp_directory_path;
  std::vector<std::string> dart_flags;
  // Arguments passed as a List<String> to Dart's entrypoint function.
  std::vector<std::string> dart_entrypoint_args;

  // Isolate settings
  bool enable_checked_mode = false;
  bool start_paused = false;
  bool trace_skia = false;
  std::string trace_allowlist;
  bool trace_startup = false;
  bool trace_systrace = false;
  bool dump_skp_on_shader_compilation = false;
  bool cache_sksl = false;
  bool purge_persistent_cache = false;
  bool endless_trace_buffer = false;
  bool enable_dart_profiling = false;
  bool disable_dart_asserts = false;

  // Whether embedder only allows secure connections.
  bool may_insecurely_connect_to_all_domains = true;
  // JSON-formatted domain network policy.
  std::string domain_network_policy;

  // Used as the script URI in debug messages. Does not affect how the Dart code
  // is executed.
  std::string advisory_script_uri = "main.dart";
  // Used as the script entrypoint in debug messages. Does not affect how the
  // Dart code is executed.
  std::string advisory_script_entrypoint = "main";

  // Observatory settings

  // Whether the Dart VM service should be enabled.
  bool enable_observatory = false;

  // The IP address to which the Dart VM service is bound.
  std::string observatory_host;

  // The port to which the Dart VM service is bound. When set to `0`, a free
  // port will be automatically selected by the OS. A message is logged on the
  // target indicating the URL at which the VM service can be accessed.
  uint32_t observatory_port = 0;

  // Determines whether an authentication code is required to communicate with
  // the VM service.
  bool disable_service_auth_codes = true;

  // Determine whether the vmservice should fallback to automatic port selection
  // after failing to bind to a specified port.
  bool enable_service_port_fallback = false;

  // Font settings
  bool use_test_fonts = false;

  // All shells in the process share the same VM. The last shell to shutdown
  // should typically shut down the VM as well. However, applications depend on
  // the behavior of "warming-up" the VM by creating a shell that does not do
  // anything. This used to work earlier when the VM could not be shut down (and
  // hence never was). Shutting down the VM now breaks such assumptions in
  // existing embedders. To keep this behavior consistent and allow existing
  // embedders the chance to migrate, this flag defaults to true. Any shell
  // launched with this flag set to true will leak the VM in the process. There
  // is no way to shut down the VM once such a shell has been started. All
  // shells in the platform (via their embedding APIs) should cooperate to make
  // sure this flag is never set if they want the VM to shutdown and free all
  // associated resources.
  bool leak_vm = true;

  // Engine settings
  TaskObserverAdd task_observer_add;
  TaskObserverRemove task_observer_remove;
  // The main isolate is current when this callback is made. This is a good spot
  // to perform native Dart bindings for libraries not built in.
  fml::closure root_isolate_create_callback;
  fml::closure isolate_create_callback;
  // The isolate is not current and may have already been destroyed when this
  // call is made.
  fml::closure root_isolate_shutdown_callback;
  fml::closure isolate_shutdown_callback;
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

  // Callback to handle the timings of a rasterized frame. This is called as
  // soon as a frame is rasterized.
  FrameRasterizedCallback frame_rasterized_callback;

  // This data will be available to the isolate immediately on launch via the
  // Window.getPersistentIsolateData callback. This is meant for information
  // that the isolate cannot request asynchronously (platform messages can be
  // used for that purpose). This data is held for the lifetime of the shell and
  // is available on isolate restarts in the shell instance. Due to this,
  // the buffer must be as small as possible.
  std::shared_ptr<const fml::Mapping> persistent_isolate_data;

  /// Max size of old gen heap size in MB, or 0 for unlimited, -1 for default
  /// value.
  ///
  /// See also:
  /// https://github.com/dart-lang/sdk/blob/ca64509108b3e7219c50d6c52877c85ab6a35ff2/runtime/vm/flag_list.h#L150
  int64_t old_gen_heap_size = -1;

  /// A timestamp representing when the engine started. The value is based
  /// on the clock used by the Dart timeline APIs. This timestamp is used
  /// to log a timeline event that tracks the latency of engine startup.
  std::chrono::microseconds engine_start_timestamp = {};

  /// Whether the application claims that it uses the android embedded view for
  /// platform views.
  ///
  /// A `true` value will result the raster task runner always run on the
  /// platform thread.
  // TODO(cyanlaz): Remove this when dynamic thread merging is done.
  // https://github.com/flutter/flutter/issues/59930
  bool use_embedded_view = false;

  std::string ToString() const;
};

}  // namespace flutter

#endif  // FLUTTER_COMMON_SETTINGS_H_
