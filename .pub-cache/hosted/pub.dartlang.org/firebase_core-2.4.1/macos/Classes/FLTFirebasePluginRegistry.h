// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "FLTFirebasePlugin.h"

@interface FLTFirebasePluginRegistry : NSObject
/**
 * Get the shared singleton instance of the plugin registry.
 *
 * @return FLTFirebasePluginRegistry
 */
+ (instancetype _Nonnull)sharedInstance;

/**
 * Register a FlutterFire plugin with the plugin registry.
 *
 * Plugins must conform to the FLTFirebasePlugin protocol.
 *
 * @param firebasePlugin id<FLTFirebasePlugin>
 */
- (void)registerFirebasePlugin:(id<FLTFirebasePlugin> _Nonnull)firebasePlugin;

/**
 * Each FlutterFire plugin implementing FLTFirebasePlugin provides this method,
 * allowing it's constants to be initialized during FirebaseCore.initializeApp
 * in Dart. Here we call this method on each of the registered plugins and
 * gather their constants for use in Dart.
 *
 * Constants for specific plugins are stored using the Flutter plugins channel
 * name as the key.
 *
 * @param firebaseApp FIRApp Firebase App instance these constants relate to.
 * @return NSDictionary Dictionary of plugins and their constants.
 */
- (NSDictionary *_Nonnull)pluginConstantsForFIRApp:(FIRApp *_Nonnull)firebaseApp;

/**
 * Each FlutterFire plugin implementing this method are notified that
 * FirebaseCore#initializeCore was called again.
 *
 * This is used by plugins to know if they need to cleanup previous
 * resources between Hot Restarts as `initializeCore` can only be called once in
 * Dart.
 */
- (void)didReinitializeFirebaseCore:(void (^_Nonnull)(void))completion;
@end
