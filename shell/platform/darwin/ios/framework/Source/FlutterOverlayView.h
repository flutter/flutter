// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_OVERLAY_VIEW_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_OVERLAY_VIEW_H_

#include <UIKit/UIKit.h>

#include <memory>

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/common/shell.h"
#import "flutter/shell/platform/darwin/ios/ios_context_gl.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_gl.h"

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

/// UIViews that are used by |FlutterPlatformViews| to present Flutter
/// rendering on top of system compositor rendering (ex. a web view).
///
/// When there is a view composited by the system compositor within a Flutter
/// view hierarchy, instead of rendering into a single render target, Flutter
/// renders into multiple render targets (depending on the number of
/// interleaving levels between Flutter & non-Flutter contents). While the
/// FlutterView contains the backing store for the root render target, the
/// FlutterOverlay view contains the backing stores for the rest. The overlay
/// views also handle touch propagation and the like for touches that occurs
/// either on overlays or otherwise may be intercepted by the platform views.
@interface FlutterOverlayView : UIView

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithContentsScale:(CGFloat)contentsScale;

@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_OVERLAY_VIEW_H_
