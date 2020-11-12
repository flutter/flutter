// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <sstream>
#include <string>

#include "flutter/fml/native_library.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/size.h"
#include "flutter/shell/version/version.h"

// Include once for the default enum definition.
#include "flutter/shell/common/switches.h"

#undef SHELL_COMMON_SWITCHES_H_

struct SwitchDesc {
  flutter::Switch sw;
  const std::string_view flag;
  const char* help;
};

#undef DEF_SWITCHES_START
#undef DEF_SWITCH
#undef DEF_SWITCHES_END

// clang-format off
#define DEF_SWITCHES_START static const struct SwitchDesc gSwitchDescs[] = {
#define DEF_SWITCH(p_swtch, p_flag, p_help) \
  { flutter::Switch:: p_swtch, p_flag, p_help },
#define DEF_SWITCHES_END };
// clang-format on

// List of common and safe VM flags to allow to be passed directly to the VM.
#if FLUTTER_RELEASE

// clang-format off
static const std::string gAllowedDartFlags[] = {
    "--enable-isolate-groups",
    "--no-enable-isolate-groups",
    "--no-causal_async_stacks",
    "--lazy_async_stacks",
};
// clang-format on

#else

// clang-format off
static const std::string gAllowedDartFlags[] = {
    "--enable-isolate-groups",
    "--no-enable-isolate-groups",
    "--enable_mirrors",
    "--enable-service-port-fallback",
    "--lazy_async_stacks",
    "--max_profile_depth",
    "--no-causal_async_stacks",
    "--profile_period",
    "--random_seed",
    "--sample-buffer-duration",
    "--trace-reload",
    "--trace-reload-verbose",
    "--write-service-info",
    "--null_assertions",
};
// clang-format on

#endif  // FLUTTER_RELEASE

// Include again for struct definition.
#include "flutter/shell/common/switches.h"

// Define symbols for the ICU data that is linked into the Flutter library on
// Android.  This is a workaround for crashes seen when doing dynamic lookups
// of the engine's own symbols on some older versions of Android.
#if OS_ANDROID
extern uint8_t _binary_icudtl_dat_start[];
extern uint8_t _binary_icudtl_dat_end[];

static std::unique_ptr<fml::Mapping> GetICUStaticMapping() {
  return std::make_unique<fml::NonOwnedMapping>(
      _binary_icudtl_dat_start,
      _binary_icudtl_dat_end - _binary_icudtl_dat_start);
}
#endif

namespace flutter {

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
              << std::string("--") +
                     std::string{desc.flag.data(), desc.flag.size()}
              << " : ";

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

const std::string_view FlagForSwitch(Switch swtch) {
  for (uint32_t i = 0; i < static_cast<uint32_t>(Switch::Sentinel); i++) {
    if (gSwitchDescs[i].sw == swtch) {
      return gSwitchDescs[i].flag;
    }
  }
  return std::string_view();
}

static bool IsAllowedDartVMFlag(const std::string& flag) {
  for (uint32_t i = 0; i < fml::size(gAllowedDartFlags); ++i) {
    const std::string& allowed = gAllowedDartFlags[i];
    // Check that the prefix of the flag matches one of the allowed flags.
    // We don't need to worry about cases like "--safe --sneaky_dangerous" as
    // the VM will discard these as a single unrecognized flag.
    if (std::equal(allowed.begin(), allowed.end(), flag.begin())) {
      return true;
    }
  }
  return false;
}

template <typename T>
static bool GetSwitchValue(const fml::CommandLine& command_line,
                           Switch sw,
                           T* result) {
  std::string switch_string;

  if (!command_line.GetOptionValue(FlagForSwitch(sw), &switch_string)) {
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

std::unique_ptr<fml::Mapping> GetSymbolMapping(std::string symbol_prefix,
                                               std::string native_lib_path) {
  const uint8_t* mapping;
  intptr_t size;

  auto lookup_symbol = [&mapping, &size, symbol_prefix](
                           const fml::RefPtr<fml::NativeLibrary>& library) {
    mapping = library->ResolveSymbol((symbol_prefix + "_start").c_str());
    size = reinterpret_cast<intptr_t>(
        library->ResolveSymbol((symbol_prefix + "_size").c_str()));
  };

  fml::RefPtr<fml::NativeLibrary> library =
      fml::NativeLibrary::CreateForCurrentProcess();
  lookup_symbol(library);

  if (!(mapping && size)) {
    // Symbol lookup for the current process fails on some devices.  As a
    // fallback, try doing the lookup based on the path to the Flutter library.
    library = fml::NativeLibrary::Create(native_lib_path.c_str());
    lookup_symbol(library);
  }

  FML_CHECK(mapping && size) << "Unable to resolve symbols: " << symbol_prefix;
  return std::make_unique<fml::NonOwnedMapping>(mapping, size);
}

Settings SettingsFromCommandLine(const fml::CommandLine& command_line) {
  Settings settings = {};

  // Enable Observatory
  settings.enable_observatory =
      !command_line.HasOption(FlagForSwitch(Switch::DisableObservatory));

  // Enable mDNS Observatory Publication
  settings.enable_observatory_publication = !command_line.HasOption(
      FlagForSwitch(Switch::DisableObservatoryPublication));

  // Set Observatory Host
  if (command_line.HasOption(FlagForSwitch(Switch::DeviceObservatoryHost))) {
    command_line.GetOptionValue(FlagForSwitch(Switch::DeviceObservatoryHost),
                                &settings.observatory_host);
  }
  // Default the observatory port based on --ipv6 if not set.
  if (settings.observatory_host.empty()) {
    settings.observatory_host =
        command_line.HasOption(FlagForSwitch(Switch::IPv6)) ? "::1"
                                                            : "127.0.0.1";
  }

  // Set Observatory Port
  if (command_line.HasOption(FlagForSwitch(Switch::DeviceObservatoryPort))) {
    if (!GetSwitchValue(command_line, Switch::DeviceObservatoryPort,
                        &settings.observatory_port)) {
      FML_LOG(INFO)
          << "Observatory port specified was malformed. Will default to "
          << settings.observatory_port;
    }
  }

  settings.may_insecurely_connect_to_all_domains = !command_line.HasOption(
      FlagForSwitch(Switch::DisallowInsecureConnections));

  command_line.GetOptionValue(FlagForSwitch(Switch::DomainNetworkPolicy),
                              &settings.domain_network_policy);

  // Disable need for authentication codes for VM service communication, if
  // specified.
  settings.disable_service_auth_codes =
      command_line.HasOption(FlagForSwitch(Switch::DisableServiceAuthCodes));

  // Allow fallback to automatic port selection if binding to a specified port
  // fails.
  settings.enable_service_port_fallback =
      command_line.HasOption(FlagForSwitch(Switch::EnableServicePortFallback));

  // Checked mode overrides.
  settings.disable_dart_asserts =
      command_line.HasOption(FlagForSwitch(Switch::DisableDartAsserts));

  settings.start_paused =
      command_line.HasOption(FlagForSwitch(Switch::StartPaused));

  settings.enable_checked_mode =
      command_line.HasOption(FlagForSwitch(Switch::EnableCheckedMode));

  settings.enable_dart_profiling =
      command_line.HasOption(FlagForSwitch(Switch::EnableDartProfiling));

  settings.enable_software_rendering =
      command_line.HasOption(FlagForSwitch(Switch::EnableSoftwareRendering));

  settings.endless_trace_buffer =
      command_line.HasOption(FlagForSwitch(Switch::EndlessTraceBuffer));

  settings.trace_startup =
      command_line.HasOption(FlagForSwitch(Switch::TraceStartup));

  settings.trace_skia =
      command_line.HasOption(FlagForSwitch(Switch::TraceSkia));

  command_line.GetOptionValue(FlagForSwitch(Switch::TraceAllowlist),
                              &settings.trace_allowlist);

  if (settings.trace_allowlist.empty()) {
    command_line.GetOptionValue(FlagForSwitch(Switch::TraceWhitelist),
                                &settings.trace_allowlist);
    if (!settings.trace_allowlist.empty()) {
      FML_LOG(INFO)
          << "--trace-whitelist is deprecated. Use --trace-allowlist instead.";
    }
  }

  settings.trace_systrace =
      command_line.HasOption(FlagForSwitch(Switch::TraceSystrace));

  settings.skia_deterministic_rendering_on_cpu =
      command_line.HasOption(FlagForSwitch(Switch::SkiaDeterministicRendering));

  settings.verbose_logging =
      command_line.HasOption(FlagForSwitch(Switch::VerboseLogging));

  command_line.GetOptionValue(FlagForSwitch(Switch::FlutterAssetsDir),
                              &settings.assets_path);

  std::vector<std::string_view> aot_shared_library_name =
      command_line.GetOptionValues(FlagForSwitch(Switch::AotSharedLibraryName));

  std::string snapshot_asset_path;
  command_line.GetOptionValue(FlagForSwitch(Switch::SnapshotAssetPath),
                              &snapshot_asset_path);

  std::string vm_snapshot_data_filename;
  command_line.GetOptionValue(FlagForSwitch(Switch::VmSnapshotData),
                              &vm_snapshot_data_filename);

  std::string vm_snapshot_instr_filename;
  command_line.GetOptionValue(FlagForSwitch(Switch::VmSnapshotInstructions),
                              &vm_snapshot_instr_filename);

  std::string isolate_snapshot_data_filename;
  command_line.GetOptionValue(FlagForSwitch(Switch::IsolateSnapshotData),
                              &isolate_snapshot_data_filename);

  std::string isolate_snapshot_instr_filename;
  command_line.GetOptionValue(
      FlagForSwitch(Switch::IsolateSnapshotInstructions),
      &isolate_snapshot_instr_filename);

  if (aot_shared_library_name.size() > 0) {
    for (std::string_view name : aot_shared_library_name) {
      settings.application_library_path.emplace_back(name);
    }
  } else if (snapshot_asset_path.size() > 0) {
    settings.vm_snapshot_data_path =
        fml::paths::JoinPaths({snapshot_asset_path, vm_snapshot_data_filename});
    settings.vm_snapshot_instr_path = fml::paths::JoinPaths(
        {snapshot_asset_path, vm_snapshot_instr_filename});
    settings.isolate_snapshot_data_path = fml::paths::JoinPaths(
        {snapshot_asset_path, isolate_snapshot_data_filename});
    settings.isolate_snapshot_instr_path = fml::paths::JoinPaths(
        {snapshot_asset_path, isolate_snapshot_instr_filename});
  }

  command_line.GetOptionValue(FlagForSwitch(Switch::CacheDirPath),
                              &settings.temp_directory_path);

  if (settings.icu_initialization_required) {
    command_line.GetOptionValue(FlagForSwitch(Switch::ICUDataFilePath),
                                &settings.icu_data_path);
    if (command_line.HasOption(FlagForSwitch(Switch::ICUSymbolPrefix))) {
      std::string icu_symbol_prefix, native_lib_path;
      command_line.GetOptionValue(FlagForSwitch(Switch::ICUSymbolPrefix),
                                  &icu_symbol_prefix);
      command_line.GetOptionValue(FlagForSwitch(Switch::ICUNativeLibPath),
                                  &native_lib_path);

#if OS_ANDROID
      settings.icu_mapper = GetICUStaticMapping;
#else
      settings.icu_mapper = [icu_symbol_prefix, native_lib_path] {
        return GetSymbolMapping(icu_symbol_prefix, native_lib_path);
      };
#endif
    }
  }

  settings.use_test_fonts =
      command_line.HasOption(FlagForSwitch(Switch::UseTestFonts));

  std::string all_dart_flags;
  if (command_line.GetOptionValue(FlagForSwitch(Switch::DartFlags),
                                  &all_dart_flags)) {
    std::stringstream stream(all_dart_flags);
    std::string flag;

    // Assume that individual flags are comma separated.
    while (std::getline(stream, flag, ',')) {
      if (!IsAllowedDartVMFlag(flag)) {
        FML_LOG(FATAL) << "Encountered disallowed Dart VM flag: " << flag;
      }
      settings.dart_flags.push_back(flag);
    }
  }

#if !FLUTTER_RELEASE
  command_line.GetOptionValue(FlagForSwitch(Switch::LogTag), &settings.log_tag);
#endif

  settings.dump_skp_on_shader_compilation =
      command_line.HasOption(FlagForSwitch(Switch::DumpSkpOnShaderCompilation));

  settings.cache_sksl =
      command_line.HasOption(FlagForSwitch(Switch::CacheSkSL));

  settings.purge_persistent_cache =
      command_line.HasOption(FlagForSwitch(Switch::PurgePersistentCache));

  if (command_line.HasOption(FlagForSwitch(Switch::OldGenHeapSize))) {
    std::string old_gen_heap_size;
    command_line.GetOptionValue(FlagForSwitch(Switch::OldGenHeapSize),
                                &old_gen_heap_size);
    settings.old_gen_heap_size = std::stoi(old_gen_heap_size);
  }
  return settings;
}

}  // namespace flutter
