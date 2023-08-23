// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "dart_api.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "impeller/renderer/context.h"

namespace flutter {

class Context : public RefCountedDartWrappable<Context> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Context);

 public:
  static void SetOverrideContext(std::shared_ptr<impeller::Context> context);

  static std::shared_ptr<impeller::Context> GetDefaultContext();

  explicit Context(std::shared_ptr<impeller::Context> context);
  ~Context() override;

  std::shared_ptr<impeller::Context> GetContext();

 private:
  /// An Impeller context that takes precedent over the IO state context when
  /// set. This is used to inject the context when running with the Impeller
  /// playground, which doesn't instantiate an Engine instance.
  static std::shared_ptr<impeller::Context> default_context_;

  std::shared_ptr<impeller::Context> context_;

  FML_DISALLOW_COPY_AND_ASSIGN(Context);
};

}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_Context_InitializeDefault(
    Dart_Handle wrapper);

}  // extern "C"
