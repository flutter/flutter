// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^FWFOnDeallocCallback)(long identifier);

/**
 * Maintains instances used to communicate with the corresponding objects in Dart.
 *
 * When an instance is added with an identifier, either can be used to retrieve the other.
 *
 * Added instances are added as a weak reference and a strong reference. When the strong reference
 * is removed with `removeStrongReferenceWithIdentifier:` and the weak reference is deallocated,
 * the `deallocCallback` is made with the instance's identifier. However, if the strong reference is
 * removed and then the identifier is retrieved with the intention to pass the identifier to Dart
 * (e.g. calling  `identifierForInstance:identifierWillBePassedToFlutter:` with
 * `identifierWillBePassedToFlutter` set to YES), the strong reference to the instance is recreated.
 * The strong reference will then need to be removed manually again.
 *
 * Accessing and inserting to an InstanceManager is thread safe.
 */
@interface FWFInstanceManager : NSObject
@property(readonly) FWFOnDeallocCallback deallocCallback;
- (instancetype)initWithDeallocCallback:(FWFOnDeallocCallback)callback;
// TODO(bparrishMines): Pairs should not be able to be overwritten and this feature
// should be replaced with a call to clear the manager in the event of a hot restart.
/**
 * Adds a new instance that was instantiated from Dart.
 *
 * If an instance or identifier has already been added, it will be replaced by the new values. The
 * Dart InstanceManager is considered the source of truth and has the capability to overwrite stored
 * pairs in response to hot restarts.
 *
 * @param instance The instance to be stored.
 * @param instanceIdentifier The identifier to be paired with instance. This value must be >= 0.
 */
- (void)addDartCreatedInstance:(NSObject *)instance withIdentifier:(long)instanceIdentifier;

/**
 * Adds a new instance that was instantiated from the host platform.
 *
 * @param instance The instance to be stored.
 * @return The unique identifier stored with instance.
 */
- (long)addHostCreatedInstance:(nonnull NSObject *)instance;

/**
 * Removes `instanceIdentifier` and its associated strongly referenced instance, if present, from
 * the manager.
 *
 * @param instanceIdentifier The identifier paired to an instance.
 *
 * @return The removed instance if the manager contains the given instanceIdentifier, otherwise
 * nil.
 */
- (nullable NSObject *)removeInstanceWithIdentifier:(long)instanceIdentifier;

/**
 * Retrieves the instance associated with identifier.
 *
 * @param instanceIdentifier  The identifier paired to an instance.
 *
 * @return The  instance associated with `instanceIdentifier` if the manager contains the value,
 * otherwise nil.
 */
- (nullable NSObject *)instanceForIdentifier:(long)instanceIdentifier;

/**
 * Retrieves the identifier paired with an instance.
 *
 * If the manager contains `instance`, as a strong or weak reference, the strong reference to
 * `instance` will be recreated and will need to be removed again with
 * `removeInstanceWithIdentifier:`.
 *
 * This method also expects the Dart `InstanceManager` to have, or recreate, a weak reference to the
 * instance the identifier is associated with once it receives it.
 *
 * @param instance An instance that may be stored in the manager.
 *
 * @return The identifier associated with `instance` if the manager contains the value, otherwise
 * NSNotFound.
 */
- (long)identifierWithStrongReferenceForInstance:(nonnull NSObject *)instance;

/**
 * Returns whether this manager contains the given `instance`.
 *
 * @return Whether this manager contains the given `instance`.
 */
- (BOOL)containsInstance:(nonnull NSObject *)instance;
@end

NS_ASSUME_NONNULL_END
