// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_SNAPSHOT_H_
#define FLUTTER_RUNTIME_DART_SNAPSHOT_H_

#include <memory>
#include <string>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/runtime/dart_snapshot_buffer.h"

namespace blink {

class DartSnapshot : public fml::RefCountedThreadSafe<DartSnapshot> {
 public:
  static const char* kVMDataSymbol;
  static const char* kVMInstructionsSymbol;
  static const char* kIsolateDataSymbol;
  static const char* kIsolateInstructionsSymbol;

  static fml::RefPtr<DartSnapshot> VMSnapshotFromSettings(
      const Settings& settings);

  static fml::RefPtr<DartSnapshot> IsolateSnapshotFromSettings(
      const Settings& settings);

  static fml::RefPtr<DartSnapshot> Empty();

  bool IsValid() const;

  bool IsValidForAOT() const;

  const DartSnapshotBuffer* GetData() const;

  const DartSnapshotBuffer* GetInstructions() const;

  const uint8_t* GetDataIfPresent() const;

  const uint8_t* GetInstructionsIfPresent() const;

 private:
  std::unique_ptr<DartSnapshotBuffer> data_;
  std::unique_ptr<DartSnapshotBuffer> instructions_;

  DartSnapshot(std::unique_ptr<DartSnapshotBuffer> data,
               std::unique_ptr<DartSnapshotBuffer> instructions);

  ~DartSnapshot();

  FML_FRIEND_REF_COUNTED_THREAD_SAFE(DartSnapshot);
  FML_FRIEND_MAKE_REF_COUNTED(DartSnapshot);
  FML_DISALLOW_COPY_AND_ASSIGN(DartSnapshot);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_SNAPSHOT_H_
