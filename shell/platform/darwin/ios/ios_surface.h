// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/surface.h"

namespace shell {

class IOSSurface {
 public:
  IOSSurface();

  virtual ~IOSSurface();

  virtual bool IsValid() const = 0;

  virtual bool ResourceContextMakeCurrent() = 0;

  virtual void UpdateStorageSizeIfNecessary() = 0;

  virtual std::unique_ptr<Surface> CreateGPUSurface() = 0;

 public:
  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurface);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_
