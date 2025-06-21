// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/elf_loader.h"

#include <utility>

#include "flutter/fml/file.h"
#include "flutter/fml/paths.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/testing/testing.h"

#if OS_FUCHSIA
#include <dlfcn.h>
#include <fuchsia/io/cpp/fidl.h>
#include <lib/fdio/directory.h>
#include <lib/fdio/io.h>
#include <zircon/dlfcn.h>
#include <zircon/status.h>
#endif

namespace flutter::testing {

ELFAOTSymbols LoadELFSymbolFromFixturesIfNeccessary(std::string elf_filename) {
  if (!DartVM::IsRunningPrecompiledCode()) {
    return {};
  }

  const auto elf_path =
      fml::paths::JoinPaths({GetFixturesPath(), std::move(elf_filename)});

  if (!fml::IsFile(elf_path)) {
    FML_LOG(ERROR) << "App AOT file does not exist for this fixture. Attempts "
                      "to launch the Dart VM with these AOT symbols will fail.";
    return {};
  }

  ELFAOTSymbols symbols;

#if OS_FUCHSIA
  fuchsia::io::Flags flags =
      fuchsia::io::PERM_READABLE | fuchsia::io::PERM_EXECUTABLE;
  int fd_out = -1;
  zx_status_t status =
      fdio_open3_fd(elf_path.c_str(), uint64_t{flags}, &fd_out);
  fml::UniqueFD fd(fd_out);
  if (status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to load " << elf_filename << " "
                   << zx_status_get_string(status);
    return {};
  }
  zx_handle_t vmo = ZX_HANDLE_INVALID;
  status = fdio_get_vmo_exec(fd.get(), &vmo);
  if (status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to load " << elf_filename << " "
                   << zx_status_get_string(status);
    return {};
  }
  void* handle = dlopen_vmo(vmo, RTLD_LAZY);
  if (handle == nullptr) {
    FML_LOG(ERROR) << "Failed to load " << elf_filename << " " << dlerror();
    return {};
  }
  symbols.vm_snapshot_data =
      reinterpret_cast<const uint8_t*>(dlsym(handle, kVmSnapshotDataCSymbol));
  symbols.vm_snapshot_instrs = reinterpret_cast<const uint8_t*>(
      dlsym(handle, kVmSnapshotInstructionsCSymbol));
  symbols.vm_isolate_data = reinterpret_cast<const uint8_t*>(
      dlsym(handle, kIsolateSnapshotDataCSymbol));
  symbols.vm_isolate_instrs = reinterpret_cast<const uint8_t*>(
      dlsym(handle, kIsolateSnapshotInstructionsCSymbol));
  if (symbols.vm_snapshot_data == nullptr ||
      symbols.vm_snapshot_instrs == nullptr ||
      symbols.vm_isolate_data == nullptr ||
      symbols.vm_isolate_instrs == nullptr) {
    dlclose(handle);
    FML_LOG(ERROR) << "Failed to load " << elf_filename;
    return {};
  }

  symbols.handle.reset(handle);

  return symbols;
#else
  // Must not be freed.
  const char* error = nullptr;

  auto loaded_elf =
      Dart_LoadELF(elf_path.c_str(),             // file path
                   0,                            // file offset
                   &error,                       // error (out)
                   &symbols.vm_snapshot_data,    // vm snapshot data (out)
                   &symbols.vm_snapshot_instrs,  // vm snapshot instrs (out)
                   &symbols.vm_isolate_data,     // vm isolate data (out)
                   &symbols.vm_isolate_instrs    // vm isolate instr (out)
      );

  if (loaded_elf == nullptr) {
    FML_LOG(ERROR)
        << "Could not fetch AOT symbols from loaded ELF. Attempts "
           "to launch the Dart VM with these AOT symbols  will fail. Error: "
        << error;
    return {};
  }

  symbols.loaded_elf.reset(loaded_elf);

  return symbols;
#endif  // OS_FUCHSIA
}

ELFAOTSymbols LoadELFSplitSymbolFromFixturesIfNeccessary(
    std::string elf_split_filename) {
  if (!DartVM::IsRunningPrecompiledCode()) {
    return {};
  }

  const auto elf_path =
      fml::paths::JoinPaths({GetFixturesPath(), std::move(elf_split_filename)});

  if (!fml::IsFile(elf_path)) {
    // We do not log here, as there is no expectation for a split library to
    // exist.
    return {};
  }

  ELFAOTSymbols symbols;

#if OS_FUCHSIA
  // TODO(gw280): https://github.com/flutter/flutter/issues/50285
  // Dart doesn't implement Dart_LoadELF on Fuchsia
  FML_LOG(ERROR) << "Dart doesn't implement Dart_LoadELF on Fuchsia";
  return {};
#else
  // Must not be freed.
  const char* error = nullptr;

  auto loaded_elf =
      Dart_LoadELF(elf_path.c_str(),             // file path
                   0,                            // file offset
                   &error,                       // error (out)
                   &symbols.vm_snapshot_data,    // vm snapshot data (out)
                   &symbols.vm_snapshot_instrs,  // vm snapshot instrs (out)
                   &symbols.vm_isolate_data,     // vm isolate data (out)
                   &symbols.vm_isolate_instrs    // vm isolate instr (out)
      );

  if (loaded_elf == nullptr) {
    FML_LOG(ERROR)
        << "Could not fetch AOT symbols from loaded ELF. Attempts "
           "to launch the Dart VM with these AOT symbols  will fail. Error: "
        << error;
    return {};
  }

  symbols.loaded_elf.reset(loaded_elf);

  return symbols;
#endif
}

bool PrepareSettingsForAOTWithSymbols(Settings& settings,
                                      const ELFAOTSymbols& symbols) {
  if (!DartVM::IsRunningPrecompiledCode()) {
    return false;
  }
  settings.vm_snapshot_data = [&]() {
    return std::make_unique<fml::NonOwnedMapping>(symbols.vm_snapshot_data, 0u);
  };
  settings.isolate_snapshot_data = [&]() {
    return std::make_unique<fml::NonOwnedMapping>(symbols.vm_isolate_data, 0u);
  };
  settings.vm_snapshot_instr = [&]() {
    return std::make_unique<fml::NonOwnedMapping>(symbols.vm_snapshot_instrs,
                                                  0u);
  };
  settings.isolate_snapshot_instr = [&]() {
    return std::make_unique<fml::NonOwnedMapping>(symbols.vm_isolate_instrs,
                                                  0u);
  };
  return true;
}

}  // namespace flutter::testing
