// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_HEADLESS_PLATFORM_VIEW_IOS_H_
#define SHELL_PLATFORM_IOS_HEADLESS_PLATFORM_VIEW_IOS_H_

#include <memory>

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/platform_message_router.h"
#include "lib/fxl/functional/closure.h"
#include "lib/fxl/macros.h"

namespace shell {

class HeadlessPlatformViewIOS : public PlatformView {
 public:
  explicit HeadlessPlatformViewIOS(Delegate& delegate,
                                   blink::TaskRunners task_runners);
  virtual ~HeadlessPlatformViewIOS();

  PlatformMessageRouter& GetPlatformMessageRouter();

 private:
  PlatformMessageRouter platform_message_router_;

  // |shell::PlatformView|
  void HandlePlatformMessage(fxl::RefPtr<blink::PlatformMessage> message);

  FXL_DISALLOW_COPY_AND_ASSIGN(HeadlessPlatformViewIOS);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_HEADLESS_PLATFORM_VIEW_IOS_H_