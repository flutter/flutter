// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/ndk/ndk_proc_table.h"

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"

namespace flutter {

namespace {

template <class Proc>
void Resolve(const fml::RefPtr<fml::NativeLibrary>& library,
             const char* name,
             Proc& proc) {
  proc = library->ResolveFunction<Proc>(name).value_or(nullptr);
}

}  // namespace

NDKProcTable::NDKProcTable(const fml::RefPtr<fml::NativeLibrary>& library)
    : library_(library) {
  if (!library_) {
    FML_LOG(ERROR) << "Could not open libandroid.so.";
    return;
  }
  Resolve(library_, "AChoreographer_getInstance", AChoreographer_getInstance);
  Resolve(library_, "AChoreographer_postFrameCallback",
          AChoreographer_postFrameCallback);
  Resolve(library_, "AChoreographer_postFrameCallback64",
          AChoreographer_postFrameCallback64);
  Resolve(library_, "ASurfaceTransaction_fromJava",
          ASurfaceTransaction_fromJava);
  Resolve(library_, "ATrace_isEnabled", ATrace_isEnabled);

  if (AChoreographer_postFrameCallback64) {
    AChoreographer_postFrameCallback = nullptr;
  }
#if FML_ARCH_CPU_32_BITS
  // On 32-bit platforms, the nanosecond resolution timestamp causes overflow on
  // the argument in the callback. Don't use it on those platforms.
  AChoreographer_postFrameCallback = nullptr;
#endif  // FML_ARCH_CPU_32_BITS
}

bool NDKProcTable::TraceIsEnabled() const {
  return ATrace_isEnabled ? ATrace_isEnabled() : false;
}

const NDKProcTable& GetNDKProcTable() {
  return GetMutableNDKProcTableForTesting();
}

NDKProcTable& GetMutableNDKProcTableForTesting() {
  static NDKProcTable table(fml::NativeLibrary::Create("libandroid.so"));
  return table;
}

}  // namespace flutter
