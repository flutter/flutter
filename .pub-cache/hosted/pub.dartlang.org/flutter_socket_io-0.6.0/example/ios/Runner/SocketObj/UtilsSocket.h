//
//  UtilsSocket.h
//  SocketTest
//
//  Created by AnhNguyen on 8/18/18.
//  Copyright © 2018 ATA_Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketListener.h"

@interface UtilsSocket : NSObject

+ (BOOL)isNullOrEmpty:(NSMutableDictionary *)dict;
+ (BOOL)isNullOrEmptyArray:(NSArray *)arr;
+ (SocketListener *)findListener:(NSArray *)listeners callBack:(NSString *)callBack;
+ (BOOL)isExisted:(NSArray *)listeners listener:(SocketListener *)listener;
+ (BOOL)isExistedChannel:(NSMutableDictionary *)subscribes channel:(NSString *)channel;
+ (BOOL)isExistedCallback:(NSArray *)listeners callBack:(NSString *)callBack;

@end
