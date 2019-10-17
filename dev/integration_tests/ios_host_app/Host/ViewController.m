#import "ViewController.h"

@import Flutter;
@import FlutterPluginRegistrant;

// Prove plugins can be module-imported from the host app.
@import device_info;
@import google_maps_flutter;

@implementation ViewController

// Boiler-plate add-to-app demo. Not integration tested anywhere.
- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self
               action:@selector(handleButtonAction)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Press me" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor blueColor]];
    button.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    [self.view addSubview:button];
}

- (void)handleButtonAction {
    FlutterViewController* flutterViewController = [[FlutterViewController alloc] init];
    [GeneratedPluginRegistrant registerWithRegistry:flutterViewController];
    [self presentViewController:flutterViewController animated:false completion:nil];
}

@end
