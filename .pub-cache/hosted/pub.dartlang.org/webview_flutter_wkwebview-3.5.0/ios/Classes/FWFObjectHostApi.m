// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFObjectHostApi.h"
#import <objc/runtime.h>
#import "FWFDataConverters.h"
#import "FWFURLHostApi.h"

@interface FWFObjectFlutterApiImpl ()
// BinaryMessenger must be weak to prevent a circular reference with the host API it
// references.
@property(nonatomic, weak) id<FlutterBinaryMessenger> binaryMessenger;
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFObjectFlutterApiImpl
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [self initWithBinaryMessenger:binaryMessenger];
  if (self) {
    _binaryMessenger = binaryMessenger;
    _instanceManager = instanceManager;
  }
  return self;
}

- (long)identifierForObject:(NSObject *)instance {
  return [self.instanceManager identifierWithStrongReferenceForInstance:instance];
}

- (void)observeValueForObject:(NSObject *)instance
                      keyPath:(NSString *)keyPath
                       object:(NSObject *)object
                       change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                   completion:(void (^)(FlutterError *_Nullable))completion {
  NSMutableArray<FWFNSKeyValueChangeKeyEnumData *> *changeKeys = [NSMutableArray array];
  NSMutableArray<id> *changeValues = [NSMutableArray array];

  [change enumerateKeysAndObjectsUsingBlock:^(NSKeyValueChangeKey key, id value, BOOL *stop) {
    [changeKeys addObject:FWFNSKeyValueChangeKeyEnumDataFromNativeNSKeyValueChangeKey(key)];
    BOOL isIdentifier = NO;
    if ([self.instanceManager containsInstance:value]) {
      isIdentifier = YES;
    } else if (object_getClass(value) == [NSURL class]) {
      FWFURLFlutterApiImpl *flutterApi =
          [[FWFURLFlutterApiImpl alloc] initWithBinaryMessenger:self.binaryMessenger
                                                instanceManager:self.instanceManager];
      [flutterApi create:value
              completion:^(FlutterError *error) {
                NSAssert(!error, @"%@", error);
              }];
      isIdentifier = YES;
    }

    id returnValue = isIdentifier
                         ? @([self.instanceManager identifierWithStrongReferenceForInstance:value])
                         : value;
    [changeValues addObject:[FWFObjectOrIdentifier makeWithValue:returnValue
                                                    isIdentifier:@(isIdentifier)]];
  }];

  NSNumber *objectIdentifier =
      @([self.instanceManager identifierWithStrongReferenceForInstance:object]);
  [self observeValueForObjectWithIdentifier:@([self identifierForObject:instance])
                                    keyPath:keyPath
                           objectIdentifier:objectIdentifier
                                 changeKeys:changeKeys
                               changeValues:changeValues
                                 completion:completion];
}
@end

@implementation FWFObject
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [self init];
  if (self) {
    _objectApi = [[FWFObjectFlutterApiImpl alloc] initWithBinaryMessenger:binaryMessenger
                                                          instanceManager:instanceManager];
  }
  return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  [self.objectApi observeValueForObject:self
                                keyPath:keyPath
                                 object:object
                                 change:change
                             completion:^(FlutterError *error) {
                               NSAssert(!error, @"%@", error);
                             }];
}
@end

@interface FWFObjectHostApiImpl ()
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFObjectHostApiImpl
- (instancetype)initWithInstanceManager:(FWFInstanceManager *)instanceManager {
  self = [self init];
  if (self) {
    _instanceManager = instanceManager;
  }
  return self;
}

- (NSObject *)objectForIdentifier:(NSNumber *)identifier {
  return (NSObject *)[self.instanceManager instanceForIdentifier:identifier.longValue];
}

- (void)addObserverForObjectWithIdentifier:(nonnull NSNumber *)identifier
                        observerIdentifier:(nonnull NSNumber *)observer
                                   keyPath:(nonnull NSString *)keyPath
                                   options:
                                       (nonnull NSArray<FWFNSKeyValueObservingOptionsEnumData *> *)
                                           options
                                     error:(FlutterError *_Nullable *_Nonnull)error {
  NSKeyValueObservingOptions optionsInt = 0;
  for (FWFNSKeyValueObservingOptionsEnumData *data in options) {
    optionsInt |= FWFNativeNSKeyValueObservingOptionsFromEnumData(data);
  }
  [[self objectForIdentifier:identifier] addObserver:[self objectForIdentifier:observer]
                                          forKeyPath:keyPath
                                             options:optionsInt
                                             context:nil];
}

- (void)removeObserverForObjectWithIdentifier:(nonnull NSNumber *)identifier
                           observerIdentifier:(nonnull NSNumber *)observer
                                      keyPath:(nonnull NSString *)keyPath
                                        error:(FlutterError *_Nullable *_Nonnull)error {
  [[self objectForIdentifier:identifier] removeObserver:[self objectForIdentifier:observer]
                                             forKeyPath:keyPath];
}

- (void)disposeObjectWithIdentifier:(nonnull NSNumber *)identifier
                              error:(FlutterError *_Nullable *_Nonnull)error {
  [self.instanceManager removeInstanceWithIdentifier:identifier.longValue];
}
@end
