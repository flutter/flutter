#import "EchoPlugin.h"
#if __has_include(<echo/echo-Swift.h>)
#import <echo/echo-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "echo-Swift.h"
#endif

@implementation EchoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEchoPlugin registerWithRegistrar:registrar];
}
@end
