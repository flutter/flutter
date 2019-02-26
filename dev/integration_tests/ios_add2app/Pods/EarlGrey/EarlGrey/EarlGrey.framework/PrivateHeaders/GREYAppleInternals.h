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

/**
 *  @file GREYAppleInternals.h
 *  @brief Exposes interfaces, structs and methods that are otherwise private.
 */

#import <UIKit/UIKit.h>

@interface UIWindow (GREYExposed)
- (id)firstResponder;
@end

@interface UIViewController (GREYExposed)
- (void)viewWillMoveToWindow:(id)window;
- (void)viewDidMoveToWindow:(id)window shouldAppearOrDisappear:(BOOL)arg;
@end

/**
 *  Structure that represents IOHIDEvents, which are sent from iOS to the application.
 */
typedef struct __IOHIDEvent *IOHIDEventRef;

/**
 *  Private class source:
 *  http://www.opensource.apple.com/source/IOHIDFamily/IOHIDFamily-503.92.1/IOHIDFamily/IOHIDEventTypes.h
 */
#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif

typedef UInt32 IOOptionBits;

/**
 *  Event mask detailing the events being dispatched by a digitizer. It is possible for digitizer
 *  events to contain child digitizer events, effectively, behaving as collections. In the
 *  collection case, the child event mask field referrence by
 *  kIOHIDEventFieldDigitizerChildEventMask will detail the cumulative event state of the child
 *  digitizer events. If you append a child digitizer event to a parent digitizer event, appropriate
 *  state will be transferred on to the parent.
 */
typedef enum {
  /**
   *  Issued when the range state has changed.
   */
  kIOHIDDigitizerEventRange = 0x00000001,
  /**
   *  Issued when the touch state has changed.
   */
  kIOHIDDigitizerEventTouch = 0x00000002,
  /**
   *  Issued when the position has changed.
   */
  kIOHIDDigitizerEventPosition = 0x00000004,
} IOHIDDigitizerEventMask;

/**
 *  Creates a digitizer event that sourced from a finger touching the screen.
 */
IOHIDEventRef IOHIDEventCreateDigitizerFingerEvent(CFAllocatorRef allocator,
                                                   AbsoluteTime timeStamp,
                                                   uint32_t index,
                                                   uint32_t identity,
                                                   IOHIDDigitizerEventMask eventMask,
                                                   IOHIDFloat x,
                                                   IOHIDFloat y,
                                                   IOHIDFloat z,
                                                   IOHIDFloat tipPressure,
                                                   IOHIDFloat twist,
                                                   Boolean range,
                                                   Boolean touch,
                                                   IOOptionBits options);

/**
 *  Private class for representing internal touch events.
 *  @see
 *  https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/UIKit.framework/UIInternalEvent.h
 */
@interface UIInternalEvent : UIEvent
/**
 *  Sets HIDEvent property for the event.
 *
 *  @param event The event for HIDEvent property.
 */
- (void)_setHIDEvent:(IOHIDEventRef)event;
@end

/**
 *  A private class that represents touch related events. This is sent to UIApplication whenever a
 *  touch occurs.
 */
@interface UITouchesEvent : UIInternalEvent
/**
 *  Adds a @c touch to the event. It's unclear what @c delayedDelivery does.
 *
 *  @param touch           The touch object to be added.
 *  @param delayedDelivery Unknown private API param.
 */
- (void)_addTouch:(UITouch *)touch forDelayedDelivery:(BOOL)delayedDelivery;

/**
 *  Removes all touch objects from the event.
 */
- (void)_clearTouches;
@end

/**
 *  A private class that represents backboard services accelerometer.
 */
@interface BKSAccelerometer : NSObject
/**
 *  Enable or disable accelerometer events.
 */
@property(nonatomic) BOOL accelerometerEventsEnabled;
@end

/**
 *  A private class that represents motion related events. This is sent to UIApplication whenever a
 *  motion occurs.
 */
@interface UIMotionEvent : NSObject {
  // The motion accelerometer of the event.
  BKSAccelerometer *_motionAccelerometer;
}
@end

@interface UIApplication (GREYExposed)
- (BOOL)_isSpringBoardShowingAnAlert;
- (UIWindow *)statusBarWindow;
/**
 *  Changes the main runloop to run in the specified mode, pushing it to the top of the stack of
 *  current modes.
 */
- (void)pushRunLoopMode:(NSString *)mode;
/**
 *  Changes the main runloop to run in the specified mode, pushing it to the top of the stack of
 *  current modes.
 */
- (void)pushRunLoopMode:(NSString *)mode requester:(id)requester;
/**
 *  Pops topmost mode from the runloop mode stack.
 */
- (void)popRunLoopMode:(NSString *)mode;
/**
 *  Pops topmost mode from the runloop mode stack.
 */
- (void)popRunLoopMode:(NSString *)mode requester:(id)requester;
/**
 *  @return The shared UITouchesEvent object of the application, which is used to keep track of
 *          UITouch objects, and the relevant touch interaction state.
 */
- (UITouchesEvent *)_touchesEvent;
/**
 *  @return The shared UIMotionEvent object of the application, used to force enable motion
 *          accelerometer events.
 */
- (UIMotionEvent *)_motionEvent;

/**
 *  Sends a motion began event for the specified subtype.
 */
- (void)_sendMotionBegan:(UIEventSubtype)subtype;

/**
 *  Sends a motion ended event for the specified subtype.
 */
- (void)_sendMotionEnded:(UIEventSubtype)subtype;
@end

@interface UIScrollView (GREYExposed)
/**
 *  Called when user finishes scrolling the content. @c deceleration is @c YES if scrolling movement
 *  will continue, but decelerate, after user stopped dragging the content. If @c deceleration is
 *  @c NO, scrolling stops immediately.
 *
 *  @param deceleration Indicating if scrollview was experiencing deceleration.
 */
- (void)_scrollViewDidEndDraggingWithDeceleration:(BOOL)deceleration;

/**
 *  Called when user is about to begin scrolling the content.
 */
- (void)_scrollViewWillBeginDragging;

/**
 *  Called when scrolling of content has finished, if content continued scrolling with deceleration
 *  after user stopped dragging it. @c notify determines whether UIScrollViewDelegate will be
 *  notified that scrolling has finished.
 *
 *  @param notify An indicator specifiying if scrolling has finished.
 */
- (void)_stopScrollDecelerationNotify:(BOOL)notify;
@end

@interface UIDevice (GREYExposed)
- (void)setOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated;
@end

@interface UITouch (GREYExposed)
/**
 *  Sets flag marking this touch as the first touch for view.
 *
 *  @param first A boolean to indicate if this is the first touch for the view.
 */
- (void)_setIsFirstTouchForView:(BOOL)first;

/**
 *  Sets flag marking this touch as a tap.
 *
 *  @param isTap A boolean to indicate that this is a tap.
 */
- (void)setIsTap:(BOOL)isTap;

/**
 *  Sets location property to @c location. If @c reset is @c NO, the original value of location will
 *  be stored in the UITouch's internal property @c previousLocation. If @c reset is @c YES, @c
 *  location will be stored in @c previousLocation.
 *
 *  @param location The new location relative to the touch's window.
 *  @param reset    An indicator to specify if @c previousLocation must be reset.
 */
- (void)_setLocationInWindow:(CGPoint)location resetPrevious:(BOOL)reset;

/**
 *  Sets phase property and notifies phaseChangeDelegate.
 *
 *  @param phase The new phase property.
 */
- (void)setPhase:(UITouchPhase)phase;

/**
 *  Sets tapCount property.
 *
 *  @param tapCount The new tap count.
 */
- (void)setTapCount:(NSUInteger)tapCount;

/**
 *  Sets timestamp property.
 *
 *  @param timestamp The new timestamp.
 */
- (void)setTimestamp:(NSTimeInterval)timestamp;

/**
 *  Sets view property.
 *
 *  @param view The new view property.
 */
- (void)setView:(UIView *)view;

/**
 *  Sets window property and converts stored CGPoint structs to the the window's coordinate system.
 *
 *  @param window The new window property.
 */
- (void)setWindow:(UIWindow *)window;

/**
 *  Sets HIDEvent property for this touch.
 *
 *  @param event The new HIDEvent property.
 */
- (void)_setHidEvent:(IOHIDEventRef)event;
@end

@interface UIKeyboardTaskQueue
/**
 *  Completes all pending or ongoing tasks in the task queue before returning. Must be called from
 *  the main thread.
 */
- (void)waitUntilAllTasksAreFinished;
@end

@interface UIKeyboardImpl
/**
 *  @return Shared instance of UIKeyboardImpl. It may be different from the active instance.
 */
+ (instancetype)sharedInstance;

/**
 *  @return The Active instance of UIKeyboardImpl, if one exists; otherwise returns @c nil. Active
 *          instance could exist even if the keyboard is not shown on the screen.
 */
+ (instancetype)activeInstance;

/**
 *  @return The current keyboard layout view, which contains accessibility elements for keyboard
 *          keys that are shown on the keyboard.
 */
- (UIView *)_layout;

/**
 *  @return The string shown on the return key on the keyboard.
 */
- (NSString *)returnKeyDisplayName;

/**
 *  @return The task queue keyboard is using to manage asynchronous tasks.
 */
- (UIKeyboardTaskQueue *)taskQueue;

/**
 *  Automatically hides the software keyboard if @c enabled is set to @c YES and hardware keyboard
 *  is available. Setting @c enabled to @c NO will always show software keyboard. This setting is
 *  global and applies to all instances of UIKeyboardImpl.
 *
 *  @param enabled A boolean that indicates automatic minimization (hiding) of the keyboard.
 */
- (void)setAutomaticMinimizationEnabled:(BOOL)enabled;

/**
 *  @return The delegate that the UIKeyboard is typing on.
 */
- (id)delegate;

/**
 *  Sets the current UIKeyboard's delegate.
 *
 *  @param delegate The element to set the UIKeyboard's delegate to.
 */
- (void)setDelegate:(id)delegate;
/**
 *  A method to hide the keyboard without resigning the first responder. This is used only
 *  in iOS 8.1 where we found that turning off the autocorrection type on the first responder
 *  using setAutomaticMinimizationEnabled: without toggling the keyboard caused keyboard touches
 *  to be ignored.
 */
- (void)hideKeyboard;

/**
 *  A method to show the keyboard without resigning the first responder. This is used only
 *  in iOS 8.1 where we found that turning off the autocorrection type on the first responder
 *  using setAutomaticMinimizationEnabled: without toggling the keyboard caused keyboard touches
 *  to be ignored.
 */
- (void)showKeyboard;
@end

/**
 * Text Input preferences controller to modify the keyboard preferences for iOS 8+.
 */
@interface TIPreferencesController : NSObject

/** Whether the autocorrection is enabled. */
@property BOOL autocorrectionEnabled;

/** Whether the predication is enabled. */
@property BOOL predictionEnabled;

/** The shared singleton instance. */
+ (instancetype)sharedPreferencesController;

/** Synchronize the change to save it on disk. */
- (void)synchronizePreferences;

/** Modify the preference @c value by @c key. */
- (void)setValue:(NSValue *)value forPreferenceKey:(NSString *)key;
@end

/**
 *  Used for enabling accessibility on simulator and device.
 */
@interface AXBackBoardServer

/**
 *  Returns backboard server instance.
 */
+ (id)server;

/**
 *  Sets preference with @c key to @c value and raises @c notification.
 */
- (void)setAccessibilityPreferenceAsMobile:(CFStringRef)key
                                     value:(CFBooleanRef)value
                              notification:(CFStringRef)notification;

@end

/**
 *  Used for enabling accessibility on device.
 */
@interface XCAXClient_iOS

/**
 *  Singleton shared instance when initialized will try to background the current process.
 */
+ (id)sharedClient;

/**
 *  Programatically enable accessibility on both simulator and device.
 *  Blocks until accessibility is fully loaded.
 *
 *  @return ignored.
 */
- (bool)_loadAccessibility:(void **)unused;

@end

@interface UIAccessibilityTextFieldElement

/**
 *  @return The UITextField that contains the accessibility text field element.
 */
-(UITextField *)textField;

@end
