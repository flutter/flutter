#import "AudioplayersPlugin.h"
#if __has_include(<audioplayers/audioplayers-Swift.h>)
#import <audioplayers/audioplayers-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "audioplayers-Swift.h"
#endif

@implementation AudioplayersPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAudioplayersPlugin registerWithRegistrar:registrar];
}
@end
