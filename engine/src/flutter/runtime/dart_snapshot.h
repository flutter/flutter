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

namespace flutter {

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

  const uint8_t* GetDataMapping() const;

  const uint8_t* GetInstructionsMapping() const;

 private:
  std::shared_ptr<const fml::Mapping> data_;
  std::shared_ptr<const fml::Mapping> instructions_;

  DartSnapshot(std::shared_ptr<const fml::Mapping> data,
               std::shared_ptr<const fml::Mapping> instructions);

  ~DartSnapshot();

  FML_FRIEND_REF_COUNTED_THREAD_SAFE(DartSnapshot);
  FML_FRIEND_MAKE_REF_COUNTED(DartSnapshot);
  FML_DISALLOW_COPY_AND_ASSIGN(DartSnapshot);
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_DART_SNAPSHOT_H_
