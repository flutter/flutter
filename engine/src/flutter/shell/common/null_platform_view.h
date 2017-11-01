// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef COMMON_NULL_PLATFORM_VIEW_H_
#define COMMON_NULL_PLATFORM_VIEW_H_

#include "flutter/shell/common/platform_view.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"

namespace shell {

class NullPlatformView : public PlatformView {
 public:
  NullPlatformView();

  ~NullPlatformView();

  fxl::WeakPtr<NullPlatformView> GetWeakPtr();

  virtual void Attach() override;

  bool ResourceContextMakeCurrent() override;

  void RunFromSource(const std::string& assets_directory,
                     const std::string& main,
                     const std::string& packages) override;

 private:
  fxl::WeakPtrFactory<NullPlatformView> weak_factory_;

  FXL_DISALLOW_COPY_AND_ASSIGN(NullPlatformView);
};

}  // namespace shell

#endif  // COMMON_NULL_PLATFORM_VIEW_H_
