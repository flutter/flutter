// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_
#define SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_

#include "mojo/public/interfaces/application/service_provider.mojom.h"

#include <UIKit/UIKit.h>

@interface FlutterView : UIView

- (void)withAccessibility:(mojo::ServiceProvider*)serviceProvider;

@end

#endif  // SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_
