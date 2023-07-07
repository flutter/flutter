//
//  SocketIO.h
//  SocketTest
//
//  Created by AnhNguyen on 8/18/18.
//  Copyright © 2018 ATA_Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketIO.h"

@import Flutter;
@import SocketIO;

static SocketManager *manager;

@interface SocketIO : NSObject

@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSDictionary *query;
@property (nonatomic, strong) NSString *nameSpace;
@property (nonatomic, strong) NSString *statusCallback;
@property (nonatomic, strong) NSMutableDictionary *subscribes;
@property (nonatomic, strong) SocketIOClient *socket;

+ (instancetype)initSocketIO:(FlutterMethodChannel *)methodChannel
                       query:(NSDictionary *)query
                      domain:(NSString *)domain
                   nameSpace:(NSString *)nameSpace
              statusCallback:(NSString *)callBack;

- (NSString *)getId;
- (NSString *)getSocketUrl;
- (void)removeChannelAll;
- (void)connect;
- (void)initSocket;
- (void)sendMessage:(NSString *)eventName mess:(NSString *)message callBack:(NSString *)callBack;
- (void)subscribe:(NSString *)eventName callBack:(NSString *)callBack;
- (void)subscribeList:(NSMutableDictionary *)sub;
- (void)unSubscribe:(NSString *)eventName callBack:(NSString *)callBack;
- (void)unSubscribeList:(NSMutableDictionary *)sub;
- (void)unSubscribeAll;
- (BOOL)isConnected;
- (void)disconnect;
- (void)destroy;
- (void)onSocketCallback:(NSString *)status obj:(id)arg;

@end
