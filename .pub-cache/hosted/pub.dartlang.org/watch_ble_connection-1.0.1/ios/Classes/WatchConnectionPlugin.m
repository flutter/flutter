#import "WatchConnectionPlugin.h"
#if __has_include(<watchConnection/watchConnection-Swift.h>)
#import <watchConnection/watchConnection-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
//#import "watchConnection-Swift.h"
#endif

@implementation WatchConnectionPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if (@available(iOS 9.0, *)) {
//        [SwiftWatchConnectionPlugin registerWithRegistrar:registrar];
    } else {
        // Fallback on earlier versions
    }
}
@end
