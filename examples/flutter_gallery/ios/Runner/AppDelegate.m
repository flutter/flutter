#import <Flutter/Flutter.h>
#include "AppDelegate.h"

@implementation AppDelegate

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];

  // Support scroll to top on status bar tap.
  UIViewController *viewController =
      [UIApplication sharedApplication].keyWindow.rootViewController;
  if ([viewController isKindOfClass:[FlutterViewController class]]) {
    [(FlutterViewController*)viewController handleStatusBarTouches:event];
  }
}

@end
