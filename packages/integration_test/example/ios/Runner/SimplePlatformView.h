// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface SimplePlatformViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype _Nullable)initWithMessenger:(NSObject<FlutterBinaryMessenger>* _Nonnull)messenger;

@end

@interface SimplePlatformView : NSObject<FlutterPlatformView>

- (instancetype _Nullable)initWithFrame:(CGRect)frame
                         viewIdentifier:(int64_t)viewId
                              arguments:(id _Nullable)args
                        binaryMessenger:(NSObject<FlutterBinaryMessenger>* _Nonnull)messenger;

- (UIView* _Nonnull)view;

@end
