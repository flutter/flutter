// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TOOLKIT_ANDROID_SURFACE_CONTROL_IMPL_H_
#define FLUTTER_IMPELLER_TOOLKIT_ANDROID_SURFACE_CONTROL_IMPL_H_

#include "flutter/fml/unique_object.h"
#include "impeller/toolkit/android/surface_control.h"

namespace impeller::android {

class SurfaceControlImpl final : public SurfaceControl {
 public:
  virtual ~SurfaceControlImpl();

  SurfaceControlImpl(const SurfaceControlImpl&) = delete;

  SurfaceControlImpl& operator=(const SurfaceControlImpl&) = delete;

  SurfaceControlImpl(ANativeWindow* window, const char* debug_name);

  bool IsValid() const override;

  ASurfaceControl* GetHandle() const override;

  bool RemoveFromParent() const override;

 private:
  friend class SurfaceControl;

  struct UniqueASurfaceControlTraits {
    static ASurfaceControl* InvalidValue() { return nullptr; }

    static bool IsValid(ASurfaceControl* value) {
      return value != InvalidValue();
    }

    static void Free(ASurfaceControl* value) {
      GetProcTable().ASurfaceControl_release(value);
    }
  };

  fml::UniqueObject<ASurfaceControl*, UniqueASurfaceControlTraits> control_;
};

}  // namespace impeller::android

#endif  // FLUTTER_IMPELLER_TOOLKIT_ANDROID_SURFACE_CONTROL_IMPL_H_
