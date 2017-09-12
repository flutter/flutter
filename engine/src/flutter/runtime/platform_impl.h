// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_PLATFORM_IMPL_H_
#define FLUTTER_RUNTIME_PLATFORM_IMPL_H_

#include "flutter/sky/engine/public/platform/Platform.h"
#include "lib/fxl/macros.h"

namespace blink {

class PlatformImpl : public Platform {
 public:
  explicit PlatformImpl();
  ~PlatformImpl() override;

  // blink::Platform methods:
  std::string defaultLocale() override;

 private:
  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformImpl);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_PLATFORM_IMPL_H_
