#import "AudioSessionPlugin.h"

static NSObject *configuration = nil;
static NSMutableArray<AudioSessionPlugin *> *plugins = nil;

@implementation AudioSessionPlugin {
    FlutterMethodChannel *_channel;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if (!plugins) {
        plugins = [[NSMutableArray alloc] init];
    }
    [[AudioSessionPlugin alloc] initWithRegistrar:registrar];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
	_channel = [FlutterMethodChannel
		methodChannelWithName:@"com.ryanheise.audio_session"
              binaryMessenger:[registrar messenger]];
	[registrar addMethodCallDelegate:self channel:_channel];
    [plugins addObject:self];
    return self;
}

- (FlutterMethodChannel *)channel {
    return _channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray* args = (NSArray*)call.arguments;
	if ([@"setConfiguration" isEqualToString:call.method]) {
        configuration = args[0];
        for (int i = 0; i < plugins.count; i++) {
            [plugins[i].channel invokeMethod:@"onConfigurationChanged" arguments:@[configuration]];
        }
		result(nil);
	} else if ([@"getConfiguration" isEqualToString:call.method]) {
        result(configuration);
	} else {
		result(FlutterMethodNotImplemented);
	}
}

- (void) dealloc {
    [plugins removeObject:self];
}

@end
