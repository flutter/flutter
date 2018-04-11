// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_SNAPSHOT_H_
#define FLUTTER_RUNTIME_DART_SNAPSHOT_H_

#include <memory>
#include <string>

#include "flutter/common/settings.h"
#include "flutter/runtime/dart_snapshot_buffer.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_counted.h"

namespace blink {

class DartSnapshot : public fxl::RefCountedThreadSafe<DartSnapshot> {
 public:
  static const char* kVMDataSymbol;
  static const char* kVMInstructionsSymbol;
  static const char* kIsolateDataSymbol;
  static const char* kIsolateInstructionsSymbol;

  static fxl::RefPtr<DartSnapshot> VMSnapshotFromSettings(
      const Settings& settings);

  static fxl::RefPtr<DartSnapshot> IsolateSnapshotFromSettings(
      const Settings& settings);

  bool IsValid() const;

  bool IsValidForAOT() const;

  const DartSnapshotBuffer* GetData() const;

  const DartSnapshotBuffer* GetInstructions() const;

  const uint8_t* GetInstructionsIfPresent() const;

 private:
  std::unique_ptr<DartSnapshotBuffer> data_;
  std::unique_ptr<DartSnapshotBuffer> instructions_;

  DartSnapshot(std::unique_ptr<DartSnapshotBuffer> data,
               std::unique_ptr<DartSnapshotBuffer> instructions);

  ~DartSnapshot();

  FRIEND_REF_COUNTED_THREAD_SAFE(DartSnapshot);
  FRIEND_MAKE_REF_COUNTED(DartSnapshot);
  FXL_DISALLOW_COPY_AND_ASSIGN(DartSnapshot);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_SNAPSHOT_H_
