// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_SNAPSHOT_BUFFER_H_
#define FLUTTER_RUNTIME_DART_SNAPSHOT_BUFFER_H_

#include <initializer_list>
#include <memory>

#include "flutter/fml/file.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/native_library.h"

namespace blink {

class DartSnapshotBuffer {
 public:
  static std::unique_ptr<DartSnapshotBuffer> CreateWithSymbolInLibrary(
      fml::RefPtr<fml::NativeLibrary> library,
      const char* symbol_name);

  static std::unique_ptr<DartSnapshotBuffer> CreateWithContentsOfFile(
      const fml::UniqueFD& fd,
      std::initializer_list<fml::FileMapping::Protection> protection);

  static std::unique_ptr<DartSnapshotBuffer> CreateWithUnmanagedAllocation(
      const uint8_t* allocation);

  virtual ~DartSnapshotBuffer();

  virtual const uint8_t* GetSnapshotPointer() const = 0;

  virtual size_t GetSnapshotSize() const = 0;
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_SNAPSHOT_BUFFER_H_
