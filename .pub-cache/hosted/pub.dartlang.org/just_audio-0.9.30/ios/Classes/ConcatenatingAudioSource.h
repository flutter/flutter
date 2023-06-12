#import "AudioSource.h"
#import <Flutter/Flutter.h>

@interface ConcatenatingAudioSource : AudioSource

@property (readonly, nonatomic) int count;

- (instancetype)initWithId:(NSString *)sid audioSources:(NSMutableArray<AudioSource *> *)audioSources shuffleOrder:(NSArray<NSNumber *> *)shuffleOrder;
- (void)insertSource:(AudioSource *)audioSource atIndex:(int)index;
- (void)removeSourcesFromIndex:(int)start toIndex:(int)end;
- (void)moveSourceFromIndex:(int)currentIndex toIndex:(int)newIndex;
- (void)setShuffleOrder:(NSArray<NSNumber *> *)shuffleOrder;

@end
