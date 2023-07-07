//
//  SocketListener.m
//  SocketTest
//
//  Created by AnhNguyen on 8/18/18.
//  Copyright © 2018 ATA_Studio. All rights reserved.
//

#import "SocketListener.h"

@implementation SocketListener

+ (instancetype)initSocketListener:(FlutterMethodChannel *)methodChannel
                             event:(NSString *)event
                          socketId:(NSString *)socketId
                          callBack:(NSString *)callBack {
    SocketListener *obj = [[SocketListener alloc] init];
    obj.methodChannel = methodChannel;
    obj.event = event;
    obj.socketId = socketId;
    obj.callBack = callBack;
    return obj;
}

- (NSString *)getCallback {
    return self.callBack;
}

- (void)call:(id)arg {
    if (self.event && self.callBack && self.methodChannel && arg) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arg options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self.methodChannel invokeMethod:[NSString stringWithFormat:@"%@|%@|%@", self.socketId, self.event, self.callBack] arguments:jsonString];
    }
}

@end
