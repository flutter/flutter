// ViewController.h
#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>
#import "NativeViewController.h"



NS_ASSUME_NONNULL_BEGIN

@interface DynamicResizingViewController : UIViewController

@property (readonly, strong, nonatomic) FlutterViewController* flutterViewController;

@end

NS_ASSUME_NONNULL_END
