// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_IOS_CRB_PROTOCOL_OBSERVERS_H_
#define BASE_IOS_CRB_PROTOCOL_OBSERVERS_H_

#import <Foundation/Foundation.h>

typedef void (^ExecutionWithObserverBlock)(id);

// Implements a container for observers that implement a specific Objective-C
// protocol. The container forwards method invocations to its contained
// observers, so that sending a message to all the observers is as simple as
// sending the message to the container.
// It is safe for an observer to remove itself or another observer while being
// notified. It is also safe to add an other observer while being notified but
// the newly added observer will not be notified as part of the current
// notification dispatch.
@interface CRBProtocolObservers : NSObject

// The Objective-C protocol that the observers in this container conform to.
@property(nonatomic, readonly) Protocol* protocol;

// Returns a CRBProtocolObservers container for observers that conform to
// |protocol|.
+ (instancetype)observersWithProtocol:(Protocol*)protocol;

// Adds |observer| to this container.
- (void)addObserver:(id)observer;

// Remove |observer| from this container.
- (void)removeObserver:(id)observer;

// Returns true if there are currently no observers.
- (BOOL)empty;

// Executes callback on every observer. |callback| cannot be nil.
- (void)executeOnObservers:(ExecutionWithObserverBlock)callback;

@end

#endif  // BASE_IOS_CRB_PROTOCOL_OBSERVERS_H_
