//
//  SocketIOManager.m
//  SocketTest
//
//  Created by AnhNguyen on 8/18/18.
//  Copyright © 2018 ATA_Studio. All rights reserved.
//

#ifndef SYNTHESIZE_SINGLETON_FOR_CLASS
#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname)           \
\
+ (classname *)shared##classname {                          \
static dispatch_once_t pred;                            \
static classname * shared##classname = nil;             \
dispatch_once( &pred, ^{                                \
shared##classname = [[self alloc] init];            \
});                                                     \
return shared##classname;                               \
}
#endif

#import "SocketIOManager.h"
#import "UtilsSocket.h"

@interface SocketIOManager ()

- (SocketIO *)getSocket:(NSString *)socketId;
- (BOOL)isExistedSocketIO:(NSString *)socketId;
- (void)addSocketIO:(SocketIO *)socketIO;
- (void)removeSocketIO:(SocketIO *)socketIO;
- (BOOL)isConnected:(SocketIO *)socketIO;
- (NSString *)getSocketId:(NSString *)domain nameSpace:(NSString *)nameSpace;
- (SocketIO *)createSocketIO:(FlutterMethodChannel *)channel
                      domain:(NSString *)domain
                       query:(NSDictionary *)query
                   nameSpace:(NSString *)nameSpace
              statusCallback:(NSString *)callBack;

@end

@implementation SocketIOManager

SYNTHESIZE_SINGLETON_FOR_CLASS(SocketIOManager)

- (SocketIO *)getSocket:(NSString *)socketId {
    SocketIO *result = nil;
    if (self.mSockets && ![UtilsSocket isNullOrEmpty:self.mSockets]) {
        NSLog(@"TOTAL SOCKETS: %zi", self.mSockets.count);
        result = [self.mSockets objectForKey:socketId];
    } else {
        NSLog(@"TOTAL SOCKETS: NULL");
    }
    return result;
}

- (BOOL)isExistedSocketIO:(NSString *)socketId {
    if (socketId) {
        if (![UtilsSocket isNullOrEmpty:self.mSockets]) {
            SocketIO *socketIO = [self getSocket:socketId];
            if (socketIO) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)addSocketIO:(SocketIO *)socketIO {
    if (!self.mSockets) {
        self.mSockets = [[NSMutableDictionary alloc] init];
    }
    if (![self isExistedSocketIO:socketIO.getId]) {
        NSLog(@"ADDED SOCKETIO %@", socketIO.getId);
        [self.mSockets setValue:socketIO forKey:socketIO.getId];
    }
}

- (void)removeSocketIO:(SocketIO *)socketIO {
    if (self.mSockets) {
        [self.mSockets removeObjectForKey:socketIO.getId];
    }
}

- (BOOL)isConnected:(SocketIO *)socketIO {
    return socketIO && socketIO.isConnected;
}

- (NSString *)getSocketId:(NSString *)domain nameSpace:(NSString *)nameSpace {
    NSString *result = nil;
    if (domain) {
        if (nameSpace) {
            result = [NSString stringWithFormat:@"%@%@", domain, nameSpace];
        } else {
            result = domain;
        }
    }
    return result;
}

- (SocketIO *)createSocketIO:(FlutterMethodChannel *)channel
                      domain:(NSString *)domain
                       query:(NSDictionary *)query
                   nameSpace:(NSString *)nameSpace
              statusCallback:(NSString *)callBack {
    return [SocketIO initSocketIO:channel query:query domain:domain nameSpace:nameSpace statusCallback:callBack];
}


#pragma mark SocketIO

- (void)initSocket:(FlutterMethodChannel *)channel
            domain:(NSString *)domain
             query:(id)query
          namspace:(NSString *)namspace
    callBackStatus:(NSString *)callback {
    if ([self isExistedSocketIO:[self getSocketId:domain nameSpace:namspace]]) {
        NSLog(@"SOCKET %@ ALREADY EXISTED!", [self getSocketId:domain nameSpace:namspace]);
    } else {
        SocketIO *socketIO = [self createSocketIO:channel domain:domain query:query nameSpace:namspace statusCallback:callback];
        [self addSocketIO:socketIO];
        [socketIO initSocket];
    }
}

- (void)connectSocket:(NSString *)domain
             namspace:(NSString *)namspace {
    SocketIO *socketIO = [self getSocket:[self getSocketId:domain nameSpace:namspace]];
    if (socketIO) {
        [socketIO connect];
    } else {
        NSLog(@"SOCKET %@ IS NOT INITIALIZED", [self getSocketId:domain nameSpace:namspace]);
    }
}

- (void)sendMessage:(NSString *)event
            message:(NSString *)message
             domain:(NSString *)domain
           namspace:(NSString *)namspace
     callBackStatus:(NSString *)callback {
    SocketIO *socketIO = [self getSocket:[self getSocketId:domain nameSpace:namspace]];
    if (socketIO) {
        [socketIO sendMessage:event mess:message callBack:callback];
    } else {
        [self errorNotFoundSocket:domain namspace:namspace];
    }
}

- (void)subscribes:(NSString *)domain
          namspace:(NSString *)namspace
        subscribes:(NSMutableDictionary *)subscribes {
    SocketIO *socketIO = [self getSocket:[self getSocketId:domain nameSpace:namspace]];
    if (socketIO) {
        [socketIO subscribeList:subscribes];
    } else {
        [self errorNotFoundSocket:domain namspace:namspace];
    }
}

- (void)unSubscribes:(NSString *)domain
            namspace:(NSString *)namspace
          subscribes:(NSMutableDictionary *)subscribes {
    SocketIO *socketIO = [self getSocket:[self getSocketId:domain nameSpace:namspace]];
    if (socketIO) {
        [socketIO unSubscribeList:subscribes];
    } else {
        [self errorNotFoundSocket:domain namspace:namspace];
    }
}

- (void)unSubscribesAll:(NSString *)domain
               namspace:(NSString *)namspace {
    NSLog(@"----- START UNSUBSCRIBESALL -----");
    SocketIO *socketIO = [self getSocket:[self getSocketId:domain nameSpace:namspace]];
    if (socketIO) {
        [socketIO unSubscribeAll];
    } else {
        [self errorNotFoundSocket:domain namspace:namspace];
    }
    NSLog(@"----- END UNSUBSCRIBESALL -----");
}

- (void)disconnectDomain:(NSString *)domain
                namspace:(NSString *)namspace {
    NSLog(@"----- START DISCONNECT -----");
    SocketIO *socketIO = [self getSocket:[self getSocketId:domain nameSpace:namspace]];
    if (socketIO) {
        [socketIO disconnect];
    } else {
        [self errorNotFoundSocket:domain namspace:namspace];
    }
    NSLog(@"----- END DISCONNECT -----");
}

- (void)destroySocketDomain:(NSString *)domain
                   namspace:(NSString *)namspace {
    SocketIO *socketIO = [self getSocket:[self getSocketId:domain nameSpace:namspace]];
    if (socketIO) {
        [self removeSocketIO:socketIO];
        [socketIO destroy];
    } else {
        [self errorNotFoundSocket:domain namspace:namspace];
    }
}

- (void)destroyAllSocket {
    if ([UtilsSocket isNullOrEmpty:self.mSockets]) {
        NSArray *keys = [self.mSockets allKeys];
        for (id key in keys) {
            SocketIO *socket = [self.mSockets objectForKey:key];
            if (socket) {
                [socket destroy];
            }
        }
        [self.mSockets removeAllObjects];
    }
}

- (void)errorNotFoundSocket:(NSString *)domain
                   namspace:(NSString *)namspace {
    NSLog(@"NOT FOUND SOCKET : %@", [self getSocketId:domain nameSpace:namspace]);
}

@end
