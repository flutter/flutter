// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_ELF_LOADER_H_
#define FLUTTER_TESTING_ELF_LOADER_H_

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "third_party/dart/runtime/bin/elf_loader.h"

namespace flutter {
namespace testing {

inline constexpr const char* kAOTAppELFFileName = "app_elf_snapshot.so";

struct LoadedELFDeleter {
  void operator()(Dart_LoadedElf* elf) { ::Dart_UnloadELF(elf); }
};

using UniqueLoadedELF = std::unique_ptr<Dart_LoadedElf, LoadedELFDeleter>;

struct ELFAOTSymbols {
  UniqueLoadedELF loaded_elf;
  const uint8_t* vm_snapshot_data = nullptr;
  const uint8_t* vm_snapshot_instrs = nullptr;
  const uint8_t* vm_isolate_data = nullptr;
  const uint8_t* vm_isolate_instrs = nullptr;
};

//------------------------------------------------------------------------------
/// @brief      Attempts to resolve AOT symbols from the portable ELF loader.
///             This location is automatically resolved from the fixtures
///             generator. This only returns valid symbols when the VM is
///             configured for AOT.
///
/// @return     The loaded ELF symbols.
///
ELFAOTSymbols LoadELFSymbolFromFixturesIfNeccessary();

//------------------------------------------------------------------------------
/// @brief      Prepare the settings objects various AOT mappings resolvers with
///             the symbols already loaded. This method does nothing in non-AOT
///             runtime modes.
///
/// @warning    The symbols must not be collected till all shell instantiations
///             made using the settings object are collected.
///
/// @param[in/out] settings  The settings whose AOT resolvers to populate.
/// @param[in]     symbols   The symbols used to populate the settings object.
///
/// @return     If the settings object was correctly updated.
///
bool PrepareSettingsForAOTWithSymbols(Settings& settings,
                                      const ELFAOTSymbols& symbols);

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_TESTING_ELF_LOADER_H_
