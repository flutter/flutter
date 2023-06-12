#import "AudioSource.h"
#import <FlutterMacOS/FlutterMacOS.h>

@interface LoopingAudioSource : AudioSource

- (instancetype)initWithId:(NSString *)sid audioSources:(NSArray<AudioSource *> *)audioSources;

@end
