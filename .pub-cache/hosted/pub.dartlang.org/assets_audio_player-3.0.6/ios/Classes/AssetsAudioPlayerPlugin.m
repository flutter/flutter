#import "AssetsAudioPlayerPlugin.h"
#if __has_include(<assets_audio_player/assets_audio_player-Swift.h>)
#import <assets_audio_player/assets_audio_player-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "assets_audio_player-Swift.h"
#endif

@implementation AssetsAudioPlayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAssetsAudioPlayerPlugin registerWithRegistrar:registrar];
}
@end
