// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TOOLKIT_INTEROP_FRAGMENT_PROGRAM_H_
#define FLUTTER_IMPELLER_TOOLKIT_INTEROP_FRAGMENT_PROGRAM_H_

#include "flutter/fml/mapping.h"
#include "impeller/runtime_stage/runtime_stage.h"
#include "impeller/toolkit/interop/impeller.h"
#include "impeller/toolkit/interop/object.h"

namespace impeller::interop {

class FragmentProgram final
    : public Object<FragmentProgram,
                    IMPELLER_INTERNAL_HANDLE_NAME(ImpellerFragmentProgram)> {
 public:
  explicit FragmentProgram(const std::shared_ptr<fml::Mapping>& mapping);

  ~FragmentProgram();

  FragmentProgram(const FragmentProgram&) = delete;

  FragmentProgram& operator=(const FragmentProgram&) = delete;

  bool IsValid() const;

  std::shared_ptr<RuntimeStage> FindRuntimeStage(
      RuntimeStageBackend backend) const;

 private:
  RuntimeStage::Map stages_;
  bool is_valid_ = false;

  std::set<RuntimeStageBackend> GetAvailableStages() const;
};

const char* RuntimeStageBackendToString(RuntimeStageBackend backend);

}  // namespace impeller::interop

#endif  // FLUTTER_IMPELLER_TOOLKIT_INTEROP_FRAGMENT_PROGRAM_H_
