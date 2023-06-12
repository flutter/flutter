#import "AudioSource.h"
#import <AVFoundation/AVFoundation.h>

@implementation AudioSource {
    NSString *_sourceId;
}

- (instancetype)initWithId:(NSString *)sid {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _sourceId = sid;
    return self;
}

- (NSString *)sourceId {
    return _sourceId;
}

- (int)buildSequence:(NSMutableArray *)sequence treeIndex:(int)treeIndex {
    return 0;
}

- (void)findById:(NSString *)sourceId matches:(NSMutableArray<AudioSource *> *)matches {
    if ([_sourceId isEqualToString:sourceId]) {
        [matches addObject:self];
    }
}

- (NSArray<NSNumber *> *)getShuffleIndices {
    return @[];
}

- (void)decodeShuffleOrder:(NSDictionary *)dict {
}

@end
