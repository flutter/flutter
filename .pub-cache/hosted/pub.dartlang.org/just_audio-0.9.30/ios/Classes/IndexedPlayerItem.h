#import <AVFoundation/AVFoundation.h>

@class IndexedAudioSource;

@interface IndexedPlayerItem : AVPlayerItem

@property (readwrite, nonatomic, weak) IndexedAudioSource *audioSource;

@end
