#import "AudioSource.h"
#import "ConcatenatingAudioSource.h"
#import <AVFoundation/AVFoundation.h>
#import <stdlib.h>

@implementation ConcatenatingAudioSource {
    NSMutableArray<AudioSource *> *_audioSources;
    NSArray<NSNumber *> *_shuffleOrder;
}

- (instancetype)initWithId:(NSString *)sid audioSources:(NSMutableArray<AudioSource *> *)audioSources shuffleOrder:(NSArray<NSNumber *> *)shuffleOrder {
    self = [super initWithId:sid];
    NSAssert(self, @"super init cannot be nil");
    _audioSources = audioSources;
    _shuffleOrder = shuffleOrder;
    return self;
}

- (int)count {
    return (int)_audioSources.count;
}

- (void)insertSource:(AudioSource *)audioSource atIndex:(int)index {
    [_audioSources insertObject:audioSource atIndex:index];
}

- (void)removeSourcesFromIndex:(int)start toIndex:(int)end {
    if (end == -1) end = (int)_audioSources.count;
    for (int i = start; i < end; i++) {
        [_audioSources removeObjectAtIndex:start];
    }
}

- (void)moveSourceFromIndex:(int)currentIndex toIndex:(int)newIndex {
    AudioSource *source = _audioSources[currentIndex];
    [_audioSources removeObjectAtIndex:currentIndex];
    [_audioSources insertObject:source atIndex:newIndex];
}

- (int)buildSequence:(NSMutableArray *)sequence treeIndex:(int)treeIndex {
    for (int i = 0; i < [_audioSources count]; i++) {
        treeIndex = [_audioSources[i] buildSequence:sequence treeIndex:treeIndex];
    }
    return treeIndex;
}

- (void)findById:(NSString *)sourceId matches:(NSMutableArray<AudioSource *> *)matches {
    [super findById:sourceId matches:matches];
    for (int i = 0; i < [_audioSources count]; i++) {
        [_audioSources[i] findById:sourceId matches:matches];
    }
}

- (NSArray<NSNumber *> *)getShuffleIndices {
    NSMutableArray<NSNumber *> *order = [NSMutableArray new];
    int offset = (int)[order count];
    NSMutableArray<NSArray<NSNumber *> *> *childOrders = [NSMutableArray new]; // array of array of ints
    for (int i = 0; i < [_audioSources count]; i++) {
        AudioSource *audioSource = _audioSources[i];
        NSArray<NSNumber *> *childShuffleIndices = [audioSource getShuffleIndices];
        NSMutableArray<NSNumber *> *offsetChildShuffleOrder = [NSMutableArray new];
        for (int j = 0; j < [childShuffleIndices count]; j++) {
            [offsetChildShuffleOrder addObject:@([childShuffleIndices[j] integerValue] + offset)];
        }
        [childOrders addObject:offsetChildShuffleOrder];
        offset += [childShuffleIndices count];
    }
    for (int i = 0; i < [_audioSources count]; i++) {
        [order addObjectsFromArray:childOrders[[_shuffleOrder[i] integerValue]]];
    }
    return order;
}

- (void)setShuffleOrder:(NSArray<NSNumber *> *)shuffleOrder {
    _shuffleOrder = shuffleOrder;
}

- (void)decodeShuffleOrder:(NSDictionary *)dict {
    _shuffleOrder = (NSArray<NSNumber *> *)dict[@"shuffleOrder"];
    NSArray *dictChildren = (NSArray *)dict[@"children"];
    if (_audioSources.count != dictChildren.count) {
        NSLog(@"decodeShuffleOrder Concatenating children don't match");
        return;
    }
    for (int i = 0; i < [_audioSources count]; i++) {
        AudioSource *child = _audioSources[i];
        NSDictionary *dictChild = (NSDictionary *)dictChildren[i];
        [child decodeShuffleOrder:dictChild];
    }
}

@end
