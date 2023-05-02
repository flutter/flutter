// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "FlutterBinaryMessenger.h"
#import "FlutterChannels.h"
#import "FlutterMacros.h"
#import "FlutterPlatformViews.h"
#import "FlutterPluginMacOS.h"
#import "FlutterTexture.h"

// TODO: Merge this file and FlutterPluginMacOS.h with the iOS FlutterPlugin.h, sharing all but
// the platform-specific methods.

/**
 * The protocol for an object managing registration for a plugin. It provides access to application
 * context, as allowing registering for callbacks for handling various conditions.
 *
 * Currently the macOS PluginRegistrar has very limited functionality, but is expected to expand
 * over time to more closely match the functionality of FlutterPluginRegistrar.
 */
FLUTTER_DARWIN_EXPORT
@protocol FlutterPluginRegistrar <NSObject>

/**
 * The binary messenger used for creating channels to communicate with the Flutter engine.
 */
@property(nonnull, readonly) id<FlutterBinaryMessenger> messenger;

/**
 * Returns a `FlutterTextureRegistry` for registering textures
 * provided by the plugin.
 */
@property(nonnull, readonly) id<FlutterTextureRegistry> textures;

/**
 * The default view displaying Flutter content.
 *
 * This method may return |nil|, for instance in a headless environment.
 *
 * The default view is a special view operated by single-view APIs.
 */
@property(nullable, readonly) NSView* view;

/**
 * The `NSView` associated with the given view ID, if any.
 */
- (nullable NSView*)viewForId:(uint64_t)viewId;

/**
 * Registers |delegate| to receive handleMethodCall:result: callbacks for the given |channel|.
 */
- (void)addMethodCallDelegate:(nonnull id<FlutterPlugin>)delegate
                      channel:(nonnull FlutterMethodChannel*)channel;

/**
 * Registers a `FlutterPlatformViewFactory` for creation of platform views.
 *
 * Plugins expose `NSView` for embedding in Flutter apps by registering a view factory.
 *
 * @param factory The view factory that will be registered.
 * @param factoryId A unique identifier for the factory, the Dart code of the Flutter app can use
 *   this identifier to request creation of a `NSView` by the registered factory.
 */
- (void)registerViewFactory:(nonnull NSObject<FlutterPlatformViewFactory>*)factory
                     withId:(nonnull NSString*)factoryId;

/**
 * Returns the file name for the given asset.
 * The returned file name can be used to access the asset in the application's main bundle.
 *
 * @param asset The name of the asset. The name can be hierarchical.
 * @return the file name to be used for lookup in the main bundle.
 */
- (nonnull NSString*)lookupKeyForAsset:(nonnull NSString*)asset;

/**
 * Returns the file name for the given asset which originates from the specified package.
 * The returned file name can be used to access the asset in the application's main bundle.
 *
 *
 * @param asset The name of the asset. The name can be hierarchical.
 * @param package The name of the package from which the asset originates.
 * @return the file name to be used for lookup in the main bundle.
 */
- (nonnull NSString*)lookupKeyForAsset:(nonnull NSString*)asset
                           fromPackage:(nonnull NSString*)package;

@end

/**
 * A registry of Flutter macOS plugins.
 *
 * Plugins are identified by unique string keys, typically the name of the
 * plugin's main class.
 *
 * Plugins typically need contextual information and the ability to register
 * callbacks for various application events. To keep the API of the registry
 * focused, these facilities are not provided directly by the registry, but by
 * a `FlutterPluginRegistrar`, created by the registry in exchange for the unique
 * key of the plugin.
 *
 * There is no implied connection between the registry and the registrar.
 * Specifically, callbacks registered by the plugin via the registrar may be
 * relayed directly to the underlying iOS application objects.
 */
@protocol FlutterPluginRegistry <NSObject>

/**
 * Returns a registrar for registering a plugin.
 *
 * @param pluginKey The unique key identifying the plugin.
 */
- (nonnull id<FlutterPluginRegistrar>)registrarForPlugin:(nonnull NSString*)pluginKey;

@end
