// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "TextPlatformView.h"

@implementation TextPlatformViewFactory {
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
  TextPlatformView* textPlatformView = [[TextPlatformView alloc] initWithFrame:frame
                                                                viewIdentifier:viewId
                                                                     arguments:args
                                                               binaryMessenger:_messenger];
  return textPlatformView;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStringCodec sharedInstance];
}

@end

@implementation TextPlatformView {
  int64_t _viewId;
  UITextView* _textView;
  FlutterMethodChannel* _channel;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if ([super init]) {
    _viewId = viewId;
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(50.0, 50.0, 250.0, 100.0)];
    _textView.textColor = UIColor.blueColor;
    _textView.backgroundColor = UIColor.lightGrayColor;
    [_textView setFont:[UIFont systemFontOfSize:52]];
    _textView.text = args;
  }
  return self;
}

- (UIView*)view {
  return _textView;
}

// - (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
// }

@end
