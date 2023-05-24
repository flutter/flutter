// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_GPU_H_
#define FLUTTER_LIB_UI_GPU_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "impeller/renderer/context.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/dart_wrappable.h"

namespace flutter {

class GpuContext : public RefCountedDartWrappable<GpuContext> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(GpuContext);

 public:
  explicit GpuContext(std::shared_ptr<impeller::Context> context);
  ~GpuContext() override;

  static std::string InitializeDefault(Dart_Handle wrapper);

 private:
  std::shared_ptr<impeller::Context> context_;

  FML_DISALLOW_COPY_AND_ASSIGN(GpuContext);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_GPU_H_
