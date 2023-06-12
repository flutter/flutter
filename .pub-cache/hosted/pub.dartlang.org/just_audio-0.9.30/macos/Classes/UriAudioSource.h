#import "IndexedAudioSource.h"
#import "LoadControl.h"
#import <FlutterMacOS/FlutterMacOS.h>

@interface UriAudioSource : IndexedAudioSource

@property (readonly, nonatomic) NSString *uri;

- (instancetype)initWithId:(NSString *)sid uri:(NSString *)uri loadControl:(LoadControl *)loadControl;

@end
