#import "AudioSource.h"
#import "ClippingAudioSource.h"
#import "IndexedPlayerItem.h"
#import "UriAudioSource.h"
#import <AVFoundation/AVFoundation.h>

@implementation ClippingAudioSource {
    UriAudioSource *_audioSource;
    CMTime _start;
    CMTime _end;
}

- (instancetype)initWithId:(NSString *)sid audioSource:(UriAudioSource *)audioSource start:(NSNumber *)start end:(NSNumber *)end {
    self = [super initWithId:sid];
    NSAssert(self, @"super init cannot be nil");
    _audioSource = audioSource;
    _start = start == (id)[NSNull null] ? kCMTimeZero : CMTimeMake([start longLongValue], 1000000);
    _end = end == (id)[NSNull null] ? kCMTimeInvalid : CMTimeMake([end longLongValue], 1000000);
    return self;
}

- (UriAudioSource *)audioSource {
    return _audioSource;
}

- (void)findById:(NSString *)sourceId matches:(NSMutableArray<AudioSource *> *)matches {
    [super findById:sourceId matches:matches];
    [_audioSource findById:sourceId matches:matches];
}

- (void)attach:(AVQueuePlayer *)player initialPos:(CMTime)initialPos {
    // Force super.attach to correct for the initial position.
    if (CMTIME_IS_INVALID(initialPos)) {
        initialPos = kCMTimeZero;
    }
    // Prepare clip to start/end at the right timestamps.
    _audioSource.playerItem.forwardPlaybackEndTime = _end;
    [super attach:player initialPos:initialPos];
}

- (IndexedPlayerItem *)playerItem {
    return _audioSource.playerItem;
}

- (IndexedPlayerItem *)playerItem2 {
    return _audioSource.playerItem2;
}

- (NSArray<NSNumber *> *)getShuffleIndices {
    return @[@(0)];
}

- (void)play:(AVQueuePlayer *)player {
}

- (void)pause:(AVQueuePlayer *)player {
}

- (void)stop:(AVQueuePlayer *)player {
}

- (void)seek:(CMTime)position completionHandler:(void (^)(BOOL))completionHandler {
    if (!completionHandler || (self.playerItem.status == AVPlayerItemStatusReadyToPlay)) {
        CMTime absPosition = CMTimeAdd(_start, position);
        [_audioSource.playerItem seekToTime:absPosition toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
    } else {
        [super seek:position completionHandler:completionHandler];
    }
}

- (void)flip {
    [_audioSource flip];
}

- (void)preparePlayerItem2 {
    if (self.playerItem2) return;
    [_audioSource preparePlayerItem2];
    IndexedPlayerItem *item = _audioSource.playerItem2;
    // Prepare loop clip to start/end at the right timestamps.
    item.forwardPlaybackEndTime = _end;
    [item seekToTime:_start toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
}

- (CMTime)duration {
    return CMTimeSubtract(CMTIME_IS_INVALID(_end) ? self.playerItem.duration : _end, _start);
}

- (void)setDuration:(CMTime)duration {
}

- (CMTime)position {
    return CMTimeSubtract(self.playerItem.currentTime, _start);
}

- (CMTime)bufferedPosition {
    CMTime pos = CMTimeSubtract(_audioSource.bufferedPosition, _start);
    CMTime dur = [self duration];
    return CMTimeCompare(pos, dur) >= 0 ? dur : pos;
}

- (void)applyPreferredForwardBufferDuration {
    [_audioSource applyPreferredForwardBufferDuration];
}

- (void)applyCanUseNetworkResourcesForLiveStreamingWhilePaused {
    [_audioSource applyCanUseNetworkResourcesForLiveStreamingWhilePaused];
}

- (void)applyPreferredPeakBitRate {
    [_audioSource applyPreferredPeakBitRate];
}

@end
