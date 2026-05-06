// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERKEYBOARDINSETMANAGER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERKEYBOARDINSETMANAGER_H_

#import <UIKit/UIKit.h>

@class FlutterEngine;
@class FlutterKeyboardInsetManager;

/**
 * @brief Manages the calculations and animations for software keyboard insets.
 *
 * This class is responsible for observing keyboard notifications, calculating the appropriate
 * insets for the Flutter view based on the keyboard mode (docked, floating, hidden),
 * and animating the transition of the insets.
 */
@protocol FlutterKeyboardInsetManagerDelegate <NSObject>

/**
 * @brief Updates the viewport metrics with the new bottom inset.
 */
- (void)updateViewportMetricsWithInset:(CGFloat)inset;

/**
 * @brief Returns the current physical bottom view inset.
 */
- (CGFloat)physicalViewInsetBottom;

/**
 * @brief Returns the view associated with the delegate.
 */
- (UIView*)view;

/**
 * @brief Returns the engine associated with the delegate.
 */
- (FlutterEngine*)engine;

/**
 * @brief Returns the UIScreen associated with the Flutter view, if the view is loaded.
 */
- (UIScreen*)flutterScreenIfViewLoaded;

/**
 * @brief Returns whether the device is an iPad and in Slide Over or Stage Manager mode.
 */
- (BOOL)isPadInSlideOverOrStageManagerMode;

/**
 * @brief Converts a rectangle from the view's coordinate system to the screen's coordinate system.
 */
- (CGRect)convertViewRectToScreen:(CGRect)rect;

/**
 * @brief Returns whether the delegate's view is currently loaded.
 */
- (BOOL)isViewLoaded;

@end

/**
 * @brief Coordinates the animation of the bottom viewport inset in response to system keyboard
 * visibility changes.
 *
 * This manager translates native iOS keyboard notifications into pixel insets for the engine. It
 * ensures that the Flutter app UI correctly resizes or scrolls when the software keyboard appears
 * or disappears.
 *
 * We synchronize the app's layout transitions with the native keyboard animation curve by tracking
 * a hidden internal view. When a keyboard notification is received, this view is animated using the
 * native iOS duration and curve. The manager tracks this animation and calls the delegate's update
 * methods on every vsync pulse until the transition completes.
 *
 * iOS doesn't provide us with a frame-by-frame callback for keyboard transitions, but we need to
 * animate our views smoothly to account for keyboard size/position changes. To ensure Flutter's
 * layout animates in perfect sync with the system keyboard, we use a "hidden view" synchronization
 * trick:
 *
 *  * When a keyboard notification (e.g., UIKeyboardWillShow) is received, the manager animates a
 *    hidden UIView's frame using the native iOS duration and curve.
 *  * A FlutterVSyncClient tracks the 'presentationLayer' of this hidden view on every vsync.
 *  * The intermediate positions are then translated into physical pixel insets and sent to the
 *    engine until the animation completes.
 *
 * To prevent incorrect layout shifts, the manager filters notifications based on the following
 * criteria:
 *
 * * Local notifications:
 *   In multitasking environments, such as iPad Split View, notifications triggered by interactions
 *   with other applications are ignored.
 *
 * * Keyboard attachment mode:
 *   The manager distinguishes between "docked" keyboards, which cover the bottom of the viewport,
 *   and "floating" or "undocked" keyboards. Floating keyboards do not typically require a viewport
 *   inset and are ignored to allow them to hover over the Flutter content without resizing the
 *   layout.
 *
 * * View lifecycle:
 *   Notifications are ignored if the associated view is not loaded or if the delegate is not the
 *   active view controller.
 *
 * @see [FlutterViewController], which owns this manager and acts as its delegate.
 */
@interface FlutterKeyboardInsetManager : NSObject

/**
 * @brief Initializes the manager with a delegate.
 *
 * The manager maintains a weak reference to the delegate.
 *
 * @param delegate The object that handles viewport updates. Typically a [FlutterViewController].
 */
- (instancetype)initWithDelegate:(id<FlutterKeyboardInsetManagerDelegate>)delegate;

/**
 * @brief Processes a system keyboard notification to update the target inset and begin any
 *        necessary animations.
 *
 * Consider calling this method from the view controller's keyboard notification observers. It
 * automatically performs filtering for non-local or floating keyboard events.
 *
 * @param notification The notification received from the [NSNotificationCenter].
 */
- (void)handleKeyboardNotification:(NSNotification*)notification;

/**
 * @brief Immediately stops any active keyboard animations and synchronizes the engine's viewport
 *        metrics with a zero inset.
 */
- (void)hideKeyboardImmediately;

/**
 * @brief Terminates any active animations and releases internal resources.
 *
 * Consider calling this method when the owner of the manager is being deallocated.
 */
- (void)invalidate;

/**
 * @brief The physical pixel value of the bottom inset once the current animation reaches its final
 *        state.
 */
@property(nonatomic, assign, readonly) CGFloat targetViewInsetBottom;

/**
 * @brief Indicates whether the keyboard is currently onscreen or in the process of transitioning
 *        from the background.
 */
@property(nonatomic, assign) BOOL isKeyboardInOrTransitioningFromBackground;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERKEYBOARDINSETMANAGER_H_
