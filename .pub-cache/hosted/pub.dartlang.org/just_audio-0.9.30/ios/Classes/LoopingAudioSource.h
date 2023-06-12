#import "AudioSource.h"
#import <Flutter/Flutter.h>

@interface LoopingAudioSource : AudioSource

- (instancetype)initWithId:(NSString *)sid audioSources:(NSArray<AudioSource *> *)audioSources;

@end
