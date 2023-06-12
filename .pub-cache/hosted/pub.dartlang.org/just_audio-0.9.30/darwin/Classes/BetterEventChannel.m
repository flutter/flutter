#import "BetterEventChannel.h"

@implementation BetterEventChannel {
    FlutterEventChannel *_eventChannel;
    FlutterEventSink _eventSink;
}

- (instancetype)initWithName:(NSString*)name messenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _eventChannel =
        [FlutterEventChannel eventChannelWithName:name binaryMessenger:messenger];
    [_eventChannel setStreamHandler:self];
    _eventSink = nil;
    return self;
}

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    _eventSink = nil;
    return nil;
}

- (void)sendEvent:(id)event {
    if (!_eventSink) return;
    _eventSink(event);
}

- (void)dispose {
    [_eventChannel setStreamHandler:nil];
}

@end
