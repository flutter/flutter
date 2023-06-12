#import "AssetsAudioPlayerWebPlugin.h"
#if __has_include(<assets_audio_player_web/assets_audio_player_web-Swift.h>)
#import <assets_audio_player_web/assets_audio_player_web-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "assets_audio_player_web-Swift.h"
#endif

@implementation AssetsAudioPlayerWebPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAssetsAudioPlayerWebPlugin registerWithRegistrar:registrar];
}
@end
