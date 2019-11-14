// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "GLTestPlatformView.h"

#define GLES_SILENCE_DEPRECATION

@implementation GLTestPlatformView {
  int64_t _viewId;
  GLTestView* _view;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if ([super init]) {
    _viewId = viewId;
    _view = [[GLTestView alloc] initWithFrame:CGRectMake(50.0, 50.0, 250.0, 100.0)];
  }
  return self;
}

- (UIView*)view {
  return _view;
}

@end

@implementation GLTestPlatformViewFactory {
  NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  self = [super init];
  if (self) {
    _messenger = messenger;
  }
  return self;
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  GLTestPlatformView* platformView = [[GLTestPlatformView alloc] initWithFrame:frame
                                                                viewIdentifier:viewId
                                                                     arguments:args
                                                               binaryMessenger:_messenger];
  return platformView;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStringCodec sharedInstance];
}

@end

@interface GLTestView ()

@property(strong, nonatomic) EAGLContext* context;

@end

@implementation GLTestView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    _context.debugLabel = @"platform view context";
    [EAGLContext setCurrentContext:_context];
    self.backgroundColor = [UIColor redColor];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     [self checkEAGLContext];
                   });
  }
  return self;
}

- (void)checkEAGLContext {
  if ([EAGLContext currentContext] != _context) {
    self.accessibilityIdentifier = @"gl_platformview_wrong_context";
  } else {
    self.accessibilityIdentifier = @"gl_platformview_correct_context";
  }
}

@end
