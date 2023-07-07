#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <Flutter/Flutter.h>
#import "SocketIOManager.h"

@interface AppDelegate ()

@property (nonatomic, strong) FlutterMethodChannel *methodChannel;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    // Override point for customization after application launch.
    FlutterViewController* controller =
    (FlutterViewController*)self.window.rootViewController;
    
    self.methodChannel = [FlutterMethodChannel
                          methodChannelWithName:@"flutter_socket_io"
                          binaryMessenger:controller];
    
    weakify(self);
    [self.methodChannel setMethodCallHandler:^(FlutterMethodCall* call,
                                               FlutterResult result) {
        strongify(weakSelf);
        NSString *socketNameSpace = call.arguments[SOCKET_NAME_SPACE];
        NSString *socketDomain = call.arguments[SOCKET_DOMAIN];
        NSString *callback = call.arguments[SOCKET_CALLBACK];
        if ([SOCKET_INIT isEqualToString:call.method]) {
            //NSString *query = @"userId=123123&abc=xxx";
            NSString *query = call.arguments[SOCKET_QUERY];
            NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
            NSArray *urlComponents = [query componentsSeparatedByString:@"&"];
            for (NSString *keyValuePair in urlComponents) {
                NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
                NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
                NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
                
                [queryStringDictionary setObject:value forKey:key];
            }
            [[SocketIOManager sharedSocketIOManager] initSocket:strongSelf.methodChannel domain:socketDomain query:queryStringDictionary namspace:socketNameSpace callBackStatus:callback];
        } else if ([SOCKET_CONNECT isEqualToString:call.method]) {
            [[SocketIOManager sharedSocketIOManager] connectSocket:socketDomain namspace:socketNameSpace];
        } else if ([SOCKET_DISCONNECT isEqualToString:call.method]) {
            [[SocketIOManager sharedSocketIOManager] disconnectDomain:socketDomain namspace:socketNameSpace];
        } else if ([SOCKET_SUBSCRIBES isEqualToString:call.method]) {
            NSString *socketData = call.arguments[SOCKET_DATA];
            NSData *data = [socketData dataUsingEncoding:NSUTF8StringEncoding];
            id map = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            [[SocketIOManager sharedSocketIOManager] subscribes:socketDomain namspace:socketNameSpace subscribes:map];
        } else if ([SOCKET_UNSUBSCRIBES isEqualToString:call.method]) {
            NSString *socketData = call.arguments[SOCKET_DATA];
            NSData *data = [socketData dataUsingEncoding:NSUTF8StringEncoding];
            id map = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            [[SocketIOManager sharedSocketIOManager] unSubscribes:socketDomain namspace:socketNameSpace subscribes:map];
        } else if ([SOCKET_UNSUBSCRIBES_ALL isEqualToString:call.method]) {
            [[SocketIOManager sharedSocketIOManager] unSubscribesAll:socketDomain namspace:socketNameSpace];
        } else if ([SOCKET_SEND_MESSAGE isEqualToString:call.method]) {
            NSLog(@"SOCKET_SEND_MESSAGE native");
            NSString *event = call.arguments[SOCKET_EVENT];
            NSString *message = call.arguments[SOCKET_MESSAGE];
            if (event && message) {
                [[SocketIOManager sharedSocketIOManager] sendMessage:event message:message domain:socketDomain namspace:socketNameSpace callBackStatus:callback];
            }
        } else if ([SOCKET_DESTROY isEqualToString:call.method]) {
            [[SocketIOManager sharedSocketIOManager] destroySocketDomain:socketDomain namspace:socketNameSpace];
        } else if ([SOCKET_DESTROY_ALL isEqualToString:call.method]) {
            [[SocketIOManager sharedSocketIOManager] destroyAllSocket];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
