#import "AudioplayersDarwinPlugin.h"
#if __has_include(<audioplayers_darwin/audioplayers_darwin-Swift.h>)
#import <audioplayers_darwin/audioplayers_darwin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "audioplayers_darwin-Swift.h"
#endif

@implementation AudioplayersDarwinPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAudioplayersDarwinPlugin registerWithRegistrar:registrar];
}
@end
