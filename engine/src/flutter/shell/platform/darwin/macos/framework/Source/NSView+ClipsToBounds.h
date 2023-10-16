// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

@interface NSView (ClipsToBounds)
// This property is available since macOS 10.9 but only declared in macOS 14 SDK.
@property BOOL clipsToBounds API_AVAILABLE(macos(10.9));
@end
