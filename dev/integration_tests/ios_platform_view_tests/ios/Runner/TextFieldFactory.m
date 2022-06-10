//
//  TextFieldFactory.m
//  Runner
//
//  Created by Huan Lin on 6/10/22.
//

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
