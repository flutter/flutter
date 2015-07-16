// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/builtin.h"

#include "base/logging.h"
#include "bin/io_natives.h"
#include "dart/runtime/include/dart_api.h"
#include "gen/sky/bindings/DartGlobal.h"
#include "sky/engine/bindings/builtin_natives.h"
#include "sky/engine/bindings/builtin_sky.h"
#include "sky/engine/bindings/mojo_natives.h"
#include "sky/engine/tonic/dart_builtin.h"

namespace blink {
namespace {

struct LibraryDescriptor {
  const char* url;
  bool has_natives;
  Dart_NativeEntrySymbol native_symbol;
  Dart_NativeEntryResolver native_resolver;
};

const LibraryDescriptor kBuiltinLibraries[] = {
    /* { url_, has_natives_, native_symbol_, native_resolver_ } */
    {"dart:sky_builtin_natives",
     true,
     BuiltinNatives::NativeSymbol,
     BuiltinNatives::NativeLookup},
    {"dart:sky", true, skySnapshotSymbolizer, skySnapshotResolver},
    {"dart:mojo.internal", true, MojoNativeSymbol, MojoNativeLookup},
    {"dart:io", true, dart::bin::IONativeSymbol, dart::bin::IONativeLookup },
};

}  // namespace

void Builtin::SetNativeResolver(BuiltinLibraryId id) {
  static_assert(arraysize(kBuiltinLibraries) == kInvalidLibrary,
      "Unexpected number of builtin libraries");
  DCHECK_GE(id, kBuiltinLibrary);
  DCHECK_LT(id, kInvalidLibrary);
  if (kBuiltinLibraries[id].has_natives) {
    Dart_Handle library = DartBuiltin::LookupLibrary(kBuiltinLibraries[id].url);
    // Setup the native resolver for built in library functions.
    DART_CHECK_VALID(
        Dart_SetNativeResolver(library,
                               kBuiltinLibraries[id].native_resolver,
                               kBuiltinLibraries[id].native_symbol));
  }
}

Dart_Handle Builtin::LoadAndCheckLibrary(BuiltinLibraryId id) {
  static_assert(arraysize(kBuiltinLibraries) == kInvalidLibrary,
      "Unexpected number of builtin libraries");
  DCHECK_GE(id, kBuiltinLibrary);
  DCHECK_LT(id, kInvalidLibrary);
  Dart_Handle library = DartBuiltin::LookupLibrary(kBuiltinLibraries[id].url);
  DART_CHECK_VALID(library);
  return library;
}

}  // namespace blink
