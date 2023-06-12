#import <FlutterMacOS/FlutterMacOS.h>

@interface BetterEventChannel : NSObject<FlutterStreamHandler>

- (instancetype)initWithName:(NSString*)name messenger:(NSObject<FlutterBinaryMessenger> *)messenger;
- (void)sendEvent:(id)event;
- (void)dispose;

@end
