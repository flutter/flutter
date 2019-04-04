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

#import <EarlGrey/GREYDefines.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Error domain and codes

GREY_EXTERN NSString *const kGREYSyntheticEventInjectionErrorDomain;

/**
 *  Error codes for synthetic event injection failures.
 */
typedef NS_ENUM(NSInteger, GREYSyntheticEventInjectionErrorCode) {
  kGREYOrientationChangeFailedErrorCode = 0,  // Device orientation change has failed.
};

#pragma mark - Interface

/**
 *  Utility to deliver user actions such as touches, taps, gestures and device rotation to the
 *  application under test
 */
@interface GREYSyntheticEvents : NSObject

/**
 *  Rotate the device to a given @c deviceOrientation. All device orientations except for
 *  @c UIDeviceOrientationUnknown are supported. If a non-nil @c errorOrNil is provided, it will
 *  be populated with the failure reason if the orientation change fails, otherwise a test failure
 *  will be registered.
 *
 *  @param      deviceOrientation The desired orientation of the device.
 *  @param[out] errorOrNil        Error that will be populated on failure. If @c nil, the a test
 *                                failure will be reported if the rotation attempt fails.
 *
 *  @throws GREYFrameworkException if the action fails and @c errorOrNil is @c nil.
 *  @return @c YES if the rotation was successful, @c NO otherwise. If @c errorOrNil is @c nil and
 *          the operation fails, it will throw an exception.
 */
+ (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation
                       errorOrNil:(__strong NSError **)errorOrNil;

/**
 *  Shakes the device. If a non-nil @c errorOrNil is provided, it will
 *  be populated with the failure reason if the orientation change fails, otherwise a test failure
 *  will be registered.
 *
 *  @param[out] errorOrNil Error that will be populated on failure. If @c nil, the a test
 *                         failure will be reported if the shake attempt fails.
 *
 *  @throws GREYFrameworkException if the action fails and @c errorOrNil is @c nil.
 *  @return @c YES if the shake was successful, @c NO otherwise. If @c errorOrNil is @c nil and
 *          the operation fails, it will throw an exception.
 */
+ (BOOL)shakeDeviceWithError:(__strong NSError **)errorOrNil;

/**
 *  Touch along a specified path in a @c CGPoint array.
 *  This method blocks until all touches are delivered.
 *
 *  @param touchPath  An array of @c CGPoints. The first point in @c touchPath is the point where
                      touch begins, and the last point in @c touchPath is the final touch point
                      where touch ends. Points in @c touchPath must be in @c window coordinates.
 *  @param window     The UIWindow that contains the points in the @c touchPath where
 *                    the touches are performed. Interaction will begin on the view inside
 *                    @c window which passes the hit-test for the first point in @c touchPath.
 *  @param duration   The time interval over which to space the touches evenly. If 0, all
 *                    touches will be sent one after the other without any delay in-between them.
 *  @param expendable @c YES indicates if the touch path must be delivered with accurate timing even
 *                    if a few touch objects (excluding the last one) have to be skipped,
 *                    use it to model time sensitive gestures like swipes where timing is more
 *                    important than accuracy. Is ignored if @c NO.
 */
+ (void)touchAlongPath:(NSArray *)touchPath
      relativeToWindow:(UIWindow *)window
           forDuration:(NSTimeInterval)duration
            expendable:(BOOL)expendable;

/**
 *  Injects a multi touch sequence specified by the array of @c touchPaths in the specified @c
 *  duration.
 *  Note that a single touch path is an array of CGPoint structs identifying the path taken by it
 *  relative to the specified @c window. Here @c expendable indicates if the touch path must be
 *  delivered with accurate timing even if a few touch objects (excluding the last one) have to be
 *  skipped. Use it to model time sensitive gestures like pinch where timing is more important than
 *  accuracy.
 *
 *  @param touchPaths An array of @c touchpaths each of which are array of @c CGPoints.
 *                    The first point in @c touchPath is the point where touch begins, and the last
 *                    point in @c touchPath is the final touch point where touch ends. Points in @c
 *                    touchPath Points in @c touchPath must be in @c window coordinates.
 *  @param window     The UIWindow that contains the points in the @c touchPath where
 *                    the touches are performed. Interaction will begin on the view inside
 *                    @c window which passes the hit-test for the first point in @c touchPath.
 *  @param duration   The time interval over which to space the touches evenly. If 0, all
 *                    touches will be sent one after the other without any delay in-between them.
 *  @param expendable @c YES indicates if the touch path must be delivered with accurate timing even
 *                    if a few touch objects (excluding the last one) have to be skipped,
 *                    use it to model time sensitive gestures like swipes where timing is more
 *                    important than accuracy. Is ignored if @c NO.
 */
+ (void)touchAlongMultiplePaths:(NSArray *)touchPaths
               relativeToWindow:(UIWindow *)window
                    forDuration:(NSTimeInterval)duration
                     expendable:(BOOL)expendable;

/**
 *  Begins interaction with a new touch starting at a specified point within a specified
 *  window's coordinates.
 *
 *  @param point     The point where the touch is to start.
 *  @param window    The window that contains the coordinates of the touch points.
 *  @param immediate If @c YES, this method blocks until touch is delivered, otherwise the touch is
 *                   enqueued for delivery the next time runloop drains.
 */
- (void)beginTouchAtPoint:(CGPoint)point
         relativeToWindow:(UIWindow *)window
        immediateDelivery:(BOOL)immediate;

/**
 *  Continues the current interaction by moving touch to a new point. Providing the same point
 *  in consecutive calls is intepreted as stationary touches. While delivering these touch points,
 *  they may be buffered and during delivery if there are multiple stale touch points that
 *  are time sensitive some of them may be dropped.
 *
 *  @param point      The point to move the touch to.
 *  @param immediate  If @c YES, this method blocks until touch is delivered, otherwise the touch is
 *                    enqueued for delivery the next time runloop drains.
 *  @param expendable @c YES indicates that this touch point is intended to be delivered in a timely
 *                    manner rather than reliably. Is ignored if @c NO.
 */
- (void)continueTouchAtPoint:(CGPoint)point
           immediateDelivery:(BOOL)immediate
                  expendable:(BOOL)expendable;

/**
 *  Ends interaction started by GREYSyntheticEvents::beginTouchAtPoint:relativeToWindow.
 *  This method will block until all the touches since the beginning of the interaction have been
 *  delivered.
 */
- (void)endTouch;

@end

NS_ASSUME_NONNULL_END
