#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    FlutterInit(argc, (const char**)argv);
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
                                 NSStringFromClass([AppDelegate class]));
    }
}
