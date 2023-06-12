#import "AudioSource.h"
#import "IndexedPlayerItem.h"
#import <FlutterMacOS/FlutterMacOS.h>
#import <AVFoundation/AVFoundation.h>

@interface IndexedAudioSource : AudioSource

@property (readonly, nonatomic) IndexedPlayerItem *playerItem;
@property (readonly, nonatomic) IndexedPlayerItem *playerItem2;
@property (readwrite, nonatomic) CMTime duration;
@property (readonly, nonatomic) CMTime position;
@property (readonly, nonatomic) CMTime bufferedPosition;
@property (readonly, nonatomic) BOOL isAttached;

- (void)onStatusChanged:(AVPlayerItemStatus)status;
- (void)attach:(AVQueuePlayer *)player initialPos:(CMTime)initialPos;
- (void)play:(AVQueuePlayer *)player;
- (void)pause:(AVQueuePlayer *)player;
- (void)stop:(AVQueuePlayer *)player;
- (void)seek:(CMTime)position;
- (void)seek:(CMTime)position completionHandler:(void (^)(BOOL))completionHandler;
- (void)preparePlayerItem2;
- (void)flip;
- (void)applyPreferredForwardBufferDuration;
- (void)applyCanUseNetworkResourcesForLiveStreamingWhilePaused;
- (void)applyPreferredPeakBitRate;

@end
