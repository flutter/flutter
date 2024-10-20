// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "DummyPlatformView.h"

@implementation DummyPlatformViewFactory {
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
  return [[DummyPlatformView alloc] initWithFrame:frame
                                   viewIdentifier:viewId
                                        arguments:args
                                  binaryMessenger:_messenger];
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStringCodec sharedInstance];
}

@end

@implementation DummyPlatformView {
  UITextView* _view;
  FlutterMethodChannel* _channel;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if ([super init]) {
    _view = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 250.0, 100.0)];
    _view.textColor = UIColor.blueColor;
    _view.backgroundColor = UIColor.lightGrayColor;
    [_view setFont:[UIFont systemFontOfSize:52]];
    _view.text = @"DummyPlatformView";
  }
  return self;
}

- (UIView*)view {
  return _view;
}

@end
