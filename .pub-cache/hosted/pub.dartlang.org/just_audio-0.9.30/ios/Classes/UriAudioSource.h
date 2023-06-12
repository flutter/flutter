#import "IndexedAudioSource.h"
#import "LoadControl.h"
#import <Flutter/Flutter.h>

@interface UriAudioSource : IndexedAudioSource

@property (readonly, nonatomic) NSString *uri;

- (instancetype)initWithId:(NSString *)sid uri:(NSString *)uri loadControl:(LoadControl *)loadControl;

@end
