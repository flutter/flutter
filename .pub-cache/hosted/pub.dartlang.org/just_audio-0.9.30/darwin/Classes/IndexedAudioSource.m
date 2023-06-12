#import "IndexedAudioSource.h"
#import "IndexedPlayerItem.h"
#import <AVFoundation/AVFoundation.h>

@implementation IndexedAudioSource {
    BOOL _isAttached;
    CMTime _queuedSeekPos;
    void (^_queuedSeekCompletionHandler)(BOOL);
}

- (instancetype)initWithId:(NSString *)sid {
    self = [super initWithId:sid];
    NSAssert(self, @"super init cannot be nil");
    _isAttached = NO;
    _queuedSeekPos = kCMTimeInvalid;
    _queuedSeekCompletionHandler = nil;
    return self;
}

- (void)onStatusChanged:(AVPlayerItemStatus)status {
    if (status == AVPlayerItemStatusReadyToPlay) {
        // This handles a pending seek during a load.
        // TODO: Test seeking during a seek.
        if (_queuedSeekCompletionHandler) {
            [self seek:_queuedSeekPos completionHandler:_queuedSeekCompletionHandler];
            _queuedSeekPos = kCMTimeInvalid;
            _queuedSeekCompletionHandler = nil;
        }
    }
}

- (IndexedPlayerItem *)playerItem {
    return nil;
}

- (IndexedPlayerItem *)playerItem2 {
    return nil;
}

- (BOOL)isAttached {
    return _isAttached;
}

- (int)buildSequence:(NSMutableArray *)sequence treeIndex:(int)treeIndex {
    [sequence addObject:self];
    return treeIndex + 1;
}

- (void)attach:(AVQueuePlayer *)player initialPos:(CMTime)initialPos {
    _isAttached = YES;
    if (CMTIME_IS_VALID(initialPos)) {
        [self seek:initialPos];
    }
}

- (void)play:(AVQueuePlayer *)player {
}

- (void)pause:(AVQueuePlayer *)player {
}

- (void)stop:(AVQueuePlayer *)player {
}

- (void)seek:(CMTime)position {
    [self seek:position completionHandler:nil];
}

- (void)seek:(CMTime)position completionHandler:(void (^)(BOOL))completionHandler {
    if (completionHandler && (self.playerItem.status != AVPlayerItemStatusReadyToPlay)) {
        _queuedSeekPos = position;
        _queuedSeekCompletionHandler = completionHandler;
    }
}

- (void)flip {
}

- (void)preparePlayerItem2 {
}

- (CMTime)duration {
    return kCMTimeInvalid;
}

- (void)setDuration:(CMTime)duration {
}

- (CMTime)position {
    return kCMTimeInvalid;
}

- (CMTime)bufferedPosition {
    return kCMTimeInvalid;
}

- (void)applyPreferredForwardBufferDuration {
}

- (void)applyCanUseNetworkResourcesForLiveStreamingWhilePaused {
}

- (void)applyPreferredPeakBitRate {
}

@end
