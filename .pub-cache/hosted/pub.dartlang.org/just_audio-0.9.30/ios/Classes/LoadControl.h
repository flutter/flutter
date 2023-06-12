@interface LoadControl : NSObject

@property (readwrite, nonatomic) NSNumber *preferredForwardBufferDuration;
@property (readwrite, nonatomic) BOOL canUseNetworkResourcesForLiveStreamingWhilePaused;
@property (readwrite, nonatomic) NSNumber *preferredPeakBitRate;

@end
