//
//  ViewFactory.m
//  Runner
//
//  Created by Huan Lin on 6/10/22.
//

#import "ViewFactory.h"

@interface PlatformView: NSObject<FlutterPlatformView>

@property (strong, nonatomic) UIView *platformView;

@end

@implementation PlatformView

- (instancetype)init
{
  self = [super init];
  if (self) {
    _platformView = [[UIView alloc] init];
    _platformView.backgroundColor = [UIColor blueColor];
  }
  return self;
}

- (UIView *)view {
  return self.platformView;
}

@end


@implementation ViewFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
  return [[PlatformView alloc] init];
}

@end
