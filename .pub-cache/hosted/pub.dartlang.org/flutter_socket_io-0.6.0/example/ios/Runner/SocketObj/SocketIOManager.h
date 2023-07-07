//
//  SocketIOManager.h
//  SocketTest
//
//  Created by AnhNguyen on 8/18/18.
//  Copyright © 2018 ATA_Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketIO.h"

/*--------------------------------------------------------------------
 * Macro weak and strong self
 ---------------------------------------------------------------------*/
#define weakify(object) __weak typeof(object)weakSelf = object
#define strongify(object) __strong typeof(object)strongSelf = object

#define SOCKET_DOMAIN               @"socketDomain"
#define SOCKET_NAME_SPACE           @"socketNameSpace"
#define SOCKET_CALLBACK             @"socketCallback"
#define SOCKET_EVENT                @"socketEvent"
#define SOCKET_MESSAGE              @"socketMessage"
#define SOCKET_DATA                 @"socketData"
#define SOCKET_QUERY                @"socketQuery"


#define SOCKET_INIT                 @"socketInit"
#define SOCKET_CONNECT              @"socketConnect"
#define SOCKET_DISCONNECT           @"socketDisconnect"
#define SOCKET_SUBSCRIBES           @"socketSubcribes"
#define SOCKET_UNSUBSCRIBES         @"socketUnsubcribes"
#define SOCKET_UNSUBSCRIBES_ALL     @"socketUnsubcribesAll"
#define SOCKET_SEND_MESSAGE         @"socketSendMessage"
#define SOCKET_DESTROY              @"socketDestroy"
#define SOCKET_DESTROY_ALL          @"socketDestroyAll"

@interface SocketIOManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *mSockets;

+ (SocketIOManager *)sharedSocketIOManager;

- (void)initSocket:(FlutterMethodChannel *)channel
            domain:(NSString *)domain
             query:(id)query
          namspace:(NSString *)namspace
    callBackStatus:(NSString *)callback;

- (void)connectSocket:(NSString *)domain
             namspace:(NSString *)namspace;

- (void)sendMessage:(NSString *)event
            message:(NSString *)message
             domain:(NSString *)domain
           namspace:(NSString *)namspace
     callBackStatus:(NSString *)callback;

- (void)subscribes:(NSString *)domain
          namspace:(NSString *)namspace
        subscribes:(NSMutableDictionary *)subscribes;

- (void)unSubscribes:(NSString *)domain
            namspace:(NSString *)namspace
          subscribes:(NSMutableDictionary *)subscribes;

- (void)unSubscribesAll:(NSString *)domain
               namspace:(NSString *)namspace;

- (void)disconnectDomain:(NSString *)domain
                namspace:(NSString *)namspace;

- (void)destroySocketDomain:(NSString *)domain
                   namspace:(NSString *)namspace;

- (void)destroyAllSocket;
@end
