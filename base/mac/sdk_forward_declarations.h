// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains forward declarations for items in later SDKs than the
// default one with which Chromium is built (currently 10.6).
// If you call any function from this header, be sure to check at runtime for
// respondsToSelector: before calling these functions (else your code will crash
// on older OS X versions that chrome still supports).

#ifndef BASE_MAC_SDK_FORWARD_DECLARATIONS_H_
#define BASE_MAC_SDK_FORWARD_DECLARATIONS_H_

#import <AppKit/AppKit.h>
#import <CoreWLAN/CoreWLAN.h>
#import <ImageCaptureCore/ImageCaptureCore.h>
#import <IOBluetooth/IOBluetooth.h>

#include "base/base_export.h"

// ----------------------------------------------------------------------------
// Either define or forward declare classes only available in OSX 10.7+.
// ----------------------------------------------------------------------------

#if !defined(MAC_OS_X_VERSION_10_7) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_7

@interface CWChannel : NSObject
@end

@interface CBPeripheral : NSObject
@end

@interface CBCentralManager : NSObject
@end

@interface CBUUID : NSObject
@end

#else

@class CWChannel;
@class CBPeripheral;
@class CBCentralManager;
@class CBUUID;

#endif  // MAC_OS_X_VERSION_10_7

#if !defined(MAC_OS_X_VERSION_10_8) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_8

@interface NSUUID : NSObject
@end

#else

@class NSUUID;

#endif  // MAC_OS_X_VERSION_10_8

#if !defined(MAC_OS_X_VERSION_10_9) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_9

// NSProgress is public API in 10.9, but a version of it exists and is usable
// in 10.8.
@interface NSProgress : NSObject
@end

@interface NSAppearance : NSObject
@end

#else

@class NSProgress;
@class NSAppearance;

#endif  // MAC_OS_X_VERSION_10_9

#if !defined(MAC_OS_X_VERSION_10_10) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_10

@interface NSUserActivity : NSObject
@end

#else

@class NSUserActivity;

#endif  // MAC_OS_X_VERSION_10_10

// ----------------------------------------------------------------------------
// Define typedefs, enums, and protocols not available in the version of the
// OSX SDK being compiled against.
// ----------------------------------------------------------------------------

#if !defined(MAC_OS_X_VERSION_10_7) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_7

enum {
  NSEventPhaseNone = 0,  // event not associated with a phase.
  NSEventPhaseBegan = 0x1 << 0,
  NSEventPhaseStationary = 0x1 << 1,
  NSEventPhaseChanged = 0x1 << 2,
  NSEventPhaseEnded = 0x1 << 3,
  NSEventPhaseCancelled = 0x1 << 4
};
typedef NSUInteger NSEventPhase;

enum {
  NSFullScreenWindowMask = 1 << 14,
};

enum {
  NSApplicationPresentationFullScreen = 1 << 10,
};

enum {
  NSWindowCollectionBehaviorFullScreenPrimary = 1 << 7,
  NSWindowCollectionBehaviorFullScreenAuxiliary = 1 << 8,
};

enum {
  NSEventSwipeTrackingLockDirection = 0x1 << 0,
  NSEventSwipeTrackingClampGestureAmount = 0x1 << 1,
};
typedef NSUInteger NSEventSwipeTrackingOptions;

enum {
  NSWindowAnimationBehaviorDefault = 0,
  NSWindowAnimationBehaviorNone = 2,
  NSWindowAnimationBehaviorDocumentWindow = 3,
  NSWindowAnimationBehaviorUtilityWindow = 4,
  NSWindowAnimationBehaviorAlertPanel = 5
};
typedef NSInteger NSWindowAnimationBehavior;

enum {
  NSWindowDocumentVersionsButton = 6,
  NSWindowFullScreenButton,
};
typedef NSUInteger NSWindowButton;

enum CWChannelBand {
  kCWChannelBandUnknown = 0,
  kCWChannelBand2GHz = 1,
  kCWChannelBand5GHz = 2,
};

enum {
  kCWSecurityNone = 0,
  kCWSecurityWEP = 1,
  kCWSecurityWPAPersonal = 2,
  kCWSecurityWPAPersonalMixed = 3,
  kCWSecurityWPA2Personal = 4,
  kCWSecurityPersonal = 5,
  kCWSecurityDynamicWEP = 6,
  kCWSecurityWPAEnterprise = 7,
  kCWSecurityWPAEnterpriseMixed = 8,
  kCWSecurityWPA2Enterprise = 9,
  kCWSecurityEnterprise = 10,
  kCWSecurityUnknown = NSIntegerMax,
};

typedef NSInteger CWSecurity;

enum {
  kBluetoothFeatureLESupportedController = (1 << 6L),
};

@protocol IOBluetoothDeviceInquiryDelegate
- (void)deviceInquiryStarted:(IOBluetoothDeviceInquiry*)sender;
- (void)deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry*)sender
                          device:(IOBluetoothDevice*)device;
- (void)deviceInquiryComplete:(IOBluetoothDeviceInquiry*)sender
                        error:(IOReturn)error
                      aborted:(BOOL)aborted;
@end

enum {
  CBPeripheralStateDisconnected = 0,
  CBPeripheralStateConnecting,
  CBPeripheralStateConnected,
};
typedef NSInteger CBPeripheralState;

enum {
  CBCentralManagerStateUnknown = 0,
  CBCentralManagerStateResetting,
  CBCentralManagerStateUnsupported,
  CBCentralManagerStateUnauthorized,
  CBCentralManagerStatePoweredOff,
  CBCentralManagerStatePoweredOn,
};
typedef NSInteger CBCentralManagerState;

@protocol CBCentralManagerDelegate;

@protocol CBCentralManagerDelegate<NSObject>
- (void)centralManagerDidUpdateState:(CBCentralManager*)central;
- (void)centralManager:(CBCentralManager*)central
    didDiscoverPeripheral:(CBPeripheral*)peripheral
        advertisementData:(NSDictionary*)advertisementData
                     RSSI:(NSNumber*)RSSI;
@end

#endif  // MAC_OS_X_VERSION_10_7

#if !defined(MAC_OS_X_VERSION_10_8) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_8

enum { NSEventPhaseMayBegin = 0x1 << 5 };

#endif  // MAC_OS_X_VERSION_10_8

#if !defined(MAC_OS_X_VERSION_10_9) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_9

enum {
  NSWindowOcclusionStateVisible = 1UL << 1,
};
typedef NSUInteger NSWindowOcclusionState;

enum { NSWorkspaceLaunchWithErrorPresentation = 0x00000040 };

#endif  // MAC_OS_X_VERSION_10_9

// ----------------------------------------------------------------------------
// Define NSStrings only available in newer versions of the OSX SDK to force
// them to be statically linked.
// ----------------------------------------------------------------------------

extern "C" {
#if !defined(MAC_OS_X_VERSION_10_7) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_7
BASE_EXPORT extern NSString* const NSWindowWillEnterFullScreenNotification;
BASE_EXPORT extern NSString* const NSWindowWillExitFullScreenNotification;
BASE_EXPORT extern NSString* const NSWindowDidEnterFullScreenNotification;
BASE_EXPORT extern NSString* const NSWindowDidExitFullScreenNotification;
BASE_EXPORT extern NSString* const
    NSWindowDidChangeBackingPropertiesNotification;
BASE_EXPORT extern NSString* const CBAdvertisementDataServiceDataKey;
BASE_EXPORT extern NSString* const
    NSPreferredScrollerStyleDidChangeNotification;
#endif  // MAC_OS_X_VERSION_10_7

#if !defined(MAC_OS_X_VERSION_10_9) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_9
BASE_EXPORT extern NSString* const NSWindowDidChangeOcclusionStateNotification;
BASE_EXPORT extern NSString* const CBAdvertisementDataIsConnectable;
#endif  // MAC_OS_X_VERSION_10_9

#if !defined(MAC_OS_X_VERSION_10_10) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
BASE_EXPORT extern NSString* const NSUserActivityTypeBrowsingWeb;
BASE_EXPORT extern NSString* const NSAppearanceNameVibrantDark;
#endif  // MAC_OS_X_VERSION_10_10
}  // extern "C"

// ----------------------------------------------------------------------------
// If compiling against an older version of the OSX SDK, declare functions that
// are available in newer versions of the OSX SDK. If compiling against a newer
// version of the OSX SDK, redeclare those same functions to suppress
// -Wpartial-availability warnings.
// ----------------------------------------------------------------------------

// Once Chrome no longer supports OSX 10.6, everything within this preprocessor
// block can be removed.
#if !defined(MAC_OS_X_VERSION_10_7) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_7

@interface NSEvent (LionSDK)
+ (BOOL)isSwipeTrackingFromScrollEventsEnabled;
- (NSEventPhase)momentumPhase;
- (NSEventPhase)phase;
- (BOOL)hasPreciseScrollingDeltas;
- (CGFloat)scrollingDeltaX;
- (CGFloat)scrollingDeltaY;
- (void)trackSwipeEventWithOptions:(NSEventSwipeTrackingOptions)options
          dampenAmountThresholdMin:(CGFloat)minDampenThreshold
                               max:(CGFloat)maxDampenThreshold
                      usingHandler:(void (^)(CGFloat gestureAmount,
                                             NSEventPhase phase,
                                             BOOL isComplete,
                                             BOOL* stop))trackingHandler;
- (BOOL)isDirectionInvertedFromDevice;
@end

@interface NSApplication (LionSDK)
- (void)disableRelaunchOnLogin;
@end

@interface CALayer (LionSDK)
- (CGFloat)contentsScale;
- (void)setContentsScale:(CGFloat)contentsScale;
@end

@interface NSScreen (LionSDK)
- (CGFloat)backingScaleFactor;
- (NSRect)convertRectToBacking:(NSRect)aRect;
@end

@interface NSWindow (LionSDK)
- (CGFloat)backingScaleFactor;
- (NSWindowAnimationBehavior)animationBehavior;
- (void)setAnimationBehavior:(NSWindowAnimationBehavior)newAnimationBehavior;
- (void)toggleFullScreen:(id)sender;
- (void)setRestorable:(BOOL)flag;
- (NSRect)convertRectFromScreen:(NSRect)aRect;
@end

@interface NSCursor (LionSDKDeclarations)
+ (NSCursor*)IBeamCursorForVerticalLayout;
@end

@interface NSAnimationContext (LionSDK)
+ (void)runAnimationGroup:(void (^)(NSAnimationContext* context))changes
        completionHandler:(void (^)(void))completionHandler;
@property(copy) void (^completionHandler)(void);
@end

@interface NSView (LionSDK)
- (NSSize)convertSizeFromBacking:(NSSize)size;
- (void)setWantsBestResolutionOpenGLSurface:(BOOL)flag;
@end

@interface NSObject (ICCameraDeviceDelegateLionSDK)
- (void)deviceDidBecomeReadyWithCompleteContentCatalog:(ICDevice*)device;
- (void)didDownloadFile:(ICCameraFile*)file
                  error:(NSError*)error
                options:(NSDictionary*)options
            contextInfo:(void*)contextInfo;
@end

@interface NSScroller (LionSDK)
+ (NSInteger)preferredScrollerStyle;
@end

@interface CWInterface (LionSDK)
- (BOOL)associateToNetwork:(CWNetwork*)network
                  password:(NSString*)password
                     error:(NSError**)error;
- (NSSet*)scanForNetworksWithName:(NSString*)networkName error:(NSError**)error;
@end

@interface CWChannel (LionSDK)
@property(readonly) CWChannelBand channelBand;
@end

@interface CWNetwork (LionSDK)
@property(readonly) CWChannel* wlanChannel;
@property(readonly) NSInteger rssiValue;
- (BOOL)supportsSecurity:(CWSecurity)security;
@end

@interface IOBluetoothHostController (LionSDK)
- (NSString*)nameAsString;
- (BluetoothHCIPowerState)powerState;
@end

@interface IOBluetoothL2CAPChannel (LionSDK)
@property(readonly) BluetoothL2CAPMTU outgoingMTU;
@end

@interface IOBluetoothDevice (LionSDK)
- (NSString*)addressString;
- (unsigned int)classOfDevice;
- (BluetoothConnectionHandle)connectionHandle;
- (BluetoothHCIRSSIValue)rawRSSI;
- (NSArray*)services;
- (IOReturn)performSDPQuery:(id)target uuids:(NSArray*)uuids;
@end

@interface CBPeripheral (LionSDK)
@property(readonly, nonatomic) CFUUIDRef UUID;
@property(retain, readonly) NSString* name;
@property(readonly) BOOL isConnected;
@end

@interface CBCentralManager (LionSDK)
@property(readonly) CBCentralManagerState state;
- (id)initWithDelegate:(id<CBCentralManagerDelegate>)delegate
                 queue:(dispatch_queue_t)queue;
- (void)scanForPeripheralsWithServices:(NSArray*)serviceUUIDs
                               options:(NSDictionary*)options;
- (void)stopScan;
@end

@interface CBUUID (LionSDK)
@property(nonatomic, readonly) NSData* data;
+ (CBUUID*)UUIDWithString:(NSString*)theString;
@end

#endif  // MAC_OS_X_VERSION_10_7

// Once Chrome no longer supports OSX 10.7, everything within this preprocessor
// block can be removed.
#if !defined(MAC_OS_X_VERSION_10_8) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_8

@interface NSColor (MountainLionSDK)
- (CGColorRef)CGColor;
@end

@interface NSUUID (MountainLionSDK)
- (NSString*)UUIDString;
@end

@interface NSControl (MountainLionSDK)
@property BOOL allowsExpansionToolTips;
@end

#endif  // MAC_OS_X_VERSION_10_8

// Once Chrome no longer supports OSX 10.8, everything within this preprocessor
// block can be removed.
#if !defined(MAC_OS_X_VERSION_10_9) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_9

@interface NSProgress (MavericksSDK)

- (instancetype)initWithParent:(NSProgress*)parentProgressOrNil
                      userInfo:(NSDictionary*)userInfoOrNil;
@property(copy) NSString* kind;

@property int64_t totalUnitCount;
@property int64_t completedUnitCount;

@property(getter=isCancellable) BOOL cancellable;
@property(getter=isPausable) BOOL pausable;
@property(readonly, getter=isCancelled) BOOL cancelled;
@property(readonly, getter=isPaused) BOOL paused;
@property(copy) void (^cancellationHandler)(void);
@property(copy) void (^pausingHandler)(void);
- (void)cancel;
- (void)pause;

- (void)setUserInfoObject:(id)objectOrNil forKey:(NSString*)key;
- (NSDictionary*)userInfo;

@property(readonly, getter=isIndeterminate) BOOL indeterminate;
@property(readonly) double fractionCompleted;

- (void)publish;
- (void)unpublish;

@end

@interface NSScreen (MavericksSDK)
+ (BOOL)screensHaveSeparateSpaces;
@end

@interface NSView (MavericksSDK)
- (void)setCanDrawSubviewsIntoLayer:(BOOL)flag;
- (NSAppearance*)effectiveAppearance;
@end

@interface NSWindow (MavericksSDK)
- (NSWindowOcclusionState)occlusionState;
@end

@interface NSAppearance (MavericksSDK)
+ (id<NSObject>)appearanceNamed:(NSString*)name;
@end

@interface CBPeripheral (MavericksSDK)
@property(readonly, nonatomic) NSUUID* identifier;
@end

#endif  // MAC_OS_X_VERSION_10_9

// Once Chrome no longer supports OSX 10.9, everything within this preprocessor
// block can be removed.
#if !defined(MAC_OS_X_VERSION_10_10) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10

@interface NSUserActivity (YosemiteSDK)

@property(readonly, copy) NSString* activityType;
@property(copy) NSDictionary* userInfo;
@property(copy) NSURL* webpageURL;

- (instancetype)initWithActivityType:(NSString*)activityType;
- (void)becomeCurrent;
- (void)invalidate;

@end

@interface CBUUID (YosemiteSDK)
- (NSString*)UUIDString;
@end

#endif  // MAC_OS_X_VERSION_10_10

// ----------------------------------------------------------------------------
// Chrome uses -[CWNetwork securityMode] and -[CWNetwork rssi] on OSX 10.6. The
// former method relies on the enum CWSecurityMode which was removed in the OSX
// 10.9 SDK. In order for Chrome to compile against an OSX 10.9+ SDK, Chrome
// must define this enum. Chrome must also declare these methods.
//
// These declarations and definitions will not be necessary once Chrome no
// longer runs on OSX 10.6.
// ----------------------------------------------------------------------------
#if defined(MAC_OS_X_VERSION_10_9) && \
    MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_6
typedef enum {
  kCWSecurityModeOpen = 0,
  kCWSecurityModeWEP,
  kCWSecurityModeWPA_PSK,
  kCWSecurityModeWPA2_PSK,
  kCWSecurityModeWPA_Enterprise,
  kCWSecurityModeWPA2_Enterprise,
  kCWSecurityModeWPS,
  kCWSecurityModeDynamicWEP
} CWSecurityMode;

@interface CWNetwork (SnowLeopardSDK)
@property(readonly) NSNumber* rssi;
@property(readonly) NSNumber* securityMode;
@end
#endif

// ----------------------------------------------------------------------------
// The symbol for kCWSSIDDidChangeNotification is available in the
// CoreWLAN.framework for OSX versions 10.6 through 10.10. The symbol is not
// declared in the OSX 10.9+ SDK, so when compiling against an OSX 10.9+ SDK,
// declare the symbol.
// ----------------------------------------------------------------------------
#if defined(MAC_OS_X_VERSION_10_9) && \
    MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_9
BASE_EXPORT extern "C" NSString* const kCWSSIDDidChangeNotification;
#endif
#endif  // BASE_MAC_SDK_FORWARD_DECLARATIONS_H_
