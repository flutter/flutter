//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIKit/UIKit.h>

/**
 *  An enum for what phase of a touch action a @c GREYTouchInfo object is in.
 */
typedef NS_ENUM(NSUInteger, GREYTouchInfoPhase) {
  GREYTouchInfoPhaseTouchBegan,
  GREYTouchInfoPhaseTouchMoved,
  GREYTouchInfoPhaseTouchEnded,
};

NS_ASSUME_NONNULL_BEGIN

/**
 *  An object to encapsulate essential information about a touch.
 */
@interface GREYTouchInfo : NSObject

/**
 *  Points where touch should be delivered.
 */
@property(nonatomic, readonly) NSArray *points;

/**
 *  The phase (began, moved etc) of the touch object.
 */
@property(nonatomic, assign) GREYTouchInfoPhase phase;

/**
 *  Delays this touch for specified value since the last touch delivery.
 */
@property(nonatomic, readonly) NSTimeInterval deliveryTimeDeltaSinceLastTouch;
/**
 *  Indicates that this touch can be dropped if system delivering the touches experiences a
 *  lag causing it to miss the expected delivery time.
 */
@property(nonatomic, readonly, getter=isExpendable) BOOL expendable;

/**
 *  Initializes this object to represent a touch at the the given @c points.
 *
 *  @param points                         The CGPoints where the touches are to be delivered.
 *  @param phase                          The current phase of each touch point.
 *  @param timeDeltaSinceLastTouchSeconds The relative injection time from the time last
 *                                        touch point was injected. It is also used as the
 *                                        expected delivery time.
 *  @param expendable                     Used for time sensitive touches, it specified if the
 *                                        touch can be dropped if system lag causes the system to
 *                                        miss the expected delivery time. If @c NO, then the touch
 *                                        will be delivered regardless.
 *
 *  @return An instance of GREYTouchInfo, initialized with all required data.
 */
- (instancetype)initWithPoints:(NSArray *)points
                              phase:(GREYTouchInfoPhase)phase
    deliveryTimeDeltaSinceLastTouch:(NSTimeInterval)timeDeltaSinceLastTouchSeconds
                         expendable:(BOOL)expendable NS_DESIGNATED_INITIALIZER;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
