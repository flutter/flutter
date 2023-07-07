// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFInstanceManager.h"
#import "FWFInstanceManager_Test.h"

#import <objc/runtime.h>

// Attaches to an object to receive a callback when the object is deallocated.
@interface FWFFinalizer : NSObject
@end

// Attaches to an object to receive a callback when the object is deallocated.
@implementation FWFFinalizer {
  long _identifier;
  // Callbacks are no longer made once FWFInstanceManager is inaccessible.
  FWFOnDeallocCallback __weak _callback;
}

- (instancetype)initWithIdentifier:(long)identifier callback:(FWFOnDeallocCallback)callback {
  self = [self init];
  if (self) {
    _identifier = identifier;
    _callback = callback;
  }
  return self;
}

+ (void)attachToInstance:(NSObject *)instance
          withIdentifier:(long)identifier
                callback:(FWFOnDeallocCallback)callback {
  FWFFinalizer *finalizer = [[FWFFinalizer alloc] initWithIdentifier:identifier callback:callback];
  objc_setAssociatedObject(instance, _cmd, finalizer, OBJC_ASSOCIATION_RETAIN);
}

+ (void)detachFromInstance:(NSObject *)instance {
  objc_setAssociatedObject(instance, @selector(attachToInstance:withIdentifier:callback:), nil,
                           OBJC_ASSOCIATION_ASSIGN);
}

- (void)dealloc {
  if (_callback) {
    _callback(_identifier);
  }
}
@end

@interface FWFInstanceManager ()
@property dispatch_queue_t lockQueue;
@property NSMapTable<NSObject *, NSNumber *> *identifiers;
@property NSMapTable<NSNumber *, NSObject *> *weakInstances;
@property NSMapTable<NSNumber *, NSObject *> *strongInstances;
@property long nextIdentifier;
@end

@implementation FWFInstanceManager
// Identifiers are locked to a specific range to avoid collisions with objects
// created simultaneously from Dart.
// Host uses identifiers >= 2^16 and Dart is expected to use values n where,
// 0 <= n < 2^16.
static long const FWFMinHostCreatedIdentifier = 65536;

- (instancetype)init {
  self = [super init];
  if (self) {
    _deallocCallback = _deallocCallback ? _deallocCallback : ^(long identifier) {
    };
    _lockQueue = dispatch_queue_create("FWFInstanceManager", DISPATCH_QUEUE_SERIAL);
    _identifiers = [NSMapTable weakToStrongObjectsMapTable];
    _weakInstances = [NSMapTable strongToWeakObjectsMapTable];
    _strongInstances = [NSMapTable strongToStrongObjectsMapTable];
    _nextIdentifier = FWFMinHostCreatedIdentifier;
  }
  return self;
}

- (instancetype)initWithDeallocCallback:(FWFOnDeallocCallback)callback {
  self = [self init];
  if (self) {
    _deallocCallback = callback;
  }
  return self;
}

- (void)addDartCreatedInstance:(NSObject *)instance withIdentifier:(long)instanceIdentifier {
  NSParameterAssert(instance);
  NSParameterAssert(instanceIdentifier >= 0);
  dispatch_async(_lockQueue, ^{
    [self addInstance:instance withIdentifier:instanceIdentifier];
  });
}

- (long)addHostCreatedInstance:(nonnull NSObject *)instance {
  NSParameterAssert(instance);
  long __block identifier = -1;
  dispatch_sync(_lockQueue, ^{
    identifier = self.nextIdentifier++;
    [self addInstance:instance withIdentifier:identifier];
  });
  return identifier;
}

- (nullable NSObject *)removeInstanceWithIdentifier:(long)instanceIdentifier {
  NSObject *__block instance = nil;
  dispatch_sync(_lockQueue, ^{
    instance = [self.strongInstances objectForKey:@(instanceIdentifier)];
    if (instance) {
      [self.strongInstances removeObjectForKey:@(instanceIdentifier)];
    }
  });
  return instance;
}

- (nullable NSObject *)instanceForIdentifier:(long)instanceIdentifier {
  NSObject *__block instance = nil;
  dispatch_sync(_lockQueue, ^{
    instance = [self.weakInstances objectForKey:@(instanceIdentifier)];
  });
  return instance;
}

- (void)addInstance:(nonnull NSObject *)instance withIdentifier:(long)instanceIdentifier {
  [self.identifiers setObject:@(instanceIdentifier) forKey:instance];
  [self.weakInstances setObject:instance forKey:@(instanceIdentifier)];
  [self.strongInstances setObject:instance forKey:@(instanceIdentifier)];
  [FWFFinalizer attachToInstance:instance
                  withIdentifier:instanceIdentifier
                        callback:self.deallocCallback];
}

- (long)identifierWithStrongReferenceForInstance:(nonnull NSObject *)instance {
  NSNumber *__block identifierNumber = nil;
  dispatch_sync(_lockQueue, ^{
    identifierNumber = [self.identifiers objectForKey:instance];
    if (identifierNumber) {
      [self.strongInstances setObject:instance forKey:identifierNumber];
    }
  });
  return identifierNumber ? identifierNumber.longValue : NSNotFound;
}

- (BOOL)containsInstance:(nonnull NSObject *)instance {
  BOOL __block containsInstance;
  dispatch_sync(_lockQueue, ^{
    containsInstance = [self.identifiers objectForKey:instance];
  });
  return containsInstance;
}

- (NSUInteger)strongInstanceCount {
  NSUInteger __block count = -1;
  dispatch_sync(_lockQueue, ^{
    count = self.strongInstances.count;
  });
  return count;
}

- (NSUInteger)weakInstanceCount {
  NSUInteger __block count = -1;
  dispatch_sync(_lockQueue, ^{
    count = self.weakInstances.count;
  });
  return count;
}
@end
