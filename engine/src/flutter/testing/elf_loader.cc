// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/elf_loader.h"

#include "flutter/fml/file.h"
#include "flutter/fml/paths.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

ELFAOTSymbols LoadELFSymbolFromFixturesIfNeccessary() {
  if (!DartVM::IsRunningPrecompiledCode()) {
    return {};
  }

  const auto elf_path =
      fml::paths::JoinPaths({GetFixturesPath(), kAOTAppELFFileName});

  if (!fml::IsFile(elf_path)) {
    FML_LOG(ERROR) << "App AOT file does not exist for this fixture. Attempts "
                      "to launch the Dart VM with these AOT symbols will fail.";
    return {};
  }

  ELFAOTSymbols symbols;

  // Must not be freed.
  const char* error = nullptr;

#if OS_FUCHSIA
  // TODO(gw280): https://github.com/flutter/flutter/issues/50285
  // Dart doesn't implement Dart_LoadELF on Fuchsia
  auto loaded_elf = nullptr;
#else
  auto loaded_elf =
      Dart_LoadELF(elf_path.c_str(),             // file path
                   0,                            // file offset
                   &error,                       // error (out)
                   &symbols.vm_snapshot_data,    // vm snapshot data (out)
                   &symbols.vm_snapshot_instrs,  // vm snapshot instrs (out)
                   &symbols.vm_isolate_data,     // vm isolate data (out)
                   &symbols.vm_isolate_instrs    // vm isolate instr (out)
      );
#endif

  if (loaded_elf == nullptr) {
    FML_LOG(ERROR)
        << "Could not fetch AOT symbols from loaded ELF. Attempts "
           "to launch the Dart VM with these AOT symbols  will fail. Error: "
        << error;
    return {};
  }

  symbols.loaded_elf.reset(loaded_elf);

  return symbols;
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

}  // namespace testing
}  // namespace flutter
