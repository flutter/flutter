//
//  UtilsSocket.m
//  SocketTest
//
//  Created by AnhNguyen on 8/18/18.
//  Copyright © 2018 ATA_Studio. All rights reserved.
//

#import "UtilsSocket.h"

@implementation UtilsSocket

+ (BOOL)isNullOrEmpty:(NSMutableDictionary *)dict {
    if (!dict || dict == nil || [dict isKindOfClass:[NSNull class]] || dict.count == 0) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)isNullOrEmptyArray:(NSArray *)arr {
    if (!arr || arr == nil || [arr isKindOfClass:[NSNull class]] || arr.count == 0) {
        return YES;
    } else {
        return NO;
    }
}

+ (SocketListener *)findListener:(NSArray *)listeners callBack:(NSString *)callBack {
    if (![UtilsSocket isNullOrEmptyArray:listeners]) {
        for (SocketListener *item in listeners) {
            if (item && [item.getCallback isEqualToString:callBack]) {
                return item;
            }
        }
    }
    return nil;
}

+ (BOOL)isExisted:(NSArray *)listeners listener:(SocketListener *)listener {
    if (![UtilsSocket isNullOrEmptyArray:listeners]) {
        for (SocketListener *item in listeners) {
            if (item && [item isEqual:listener]) {
                return YES;
            }
        }
    }
    return NO;
}

+ (BOOL)isExistedChannel:(NSMutableDictionary *)subscribes channel:(NSString *)channel {
    if (![UtilsSocket isNullOrEmpty:subscribes]) {
        if ([subscribes objectForKey:channel]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isExistedCallback:(NSArray *)listeners callBack:(NSString *)callBack {
    if (![UtilsSocket isNullOrEmptyArray:listeners]) {
        for (SocketListener *item in listeners) {
            if (item && [item.getCallback isEqualToString:callBack]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
