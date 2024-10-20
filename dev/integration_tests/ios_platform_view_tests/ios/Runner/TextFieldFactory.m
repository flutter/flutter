// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "TextFieldFactory.h"

@interface PlatformTextField: NSObject<FlutterPlatformView>

@property (strong, nonatomic) UITextField *textField;

@end

@implementation PlatformTextField

- (instancetype)init
{
  self = [super init];
  if (self) {
    _textField = [[UITextField alloc] init];
    _textField.text = @"Platform Text Field";
  }
  return self;
}

- (UIView *)view {
  return self.textField;
}

@end

@implementation TextFieldFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
  return [[PlatformTextField alloc] init];
}

@end
