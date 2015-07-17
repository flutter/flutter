// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "base/ios/crb_protocol_observers.h"
#include "base/ios/weak_nsobject.h"
#include "base/logging.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "base/mac/scoped_nsobject.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/gtest_mac.h"
#include "testing/platform_test.h"

@protocol TestObserver

@required
- (void)requiredMethod;
- (void)reset;

@optional
- (void)optionalMethod;
- (void)mutateByAddingObserver:(id<TestObserver>)observer;
- (void)mutateByRemovingObserver:(id<TestObserver>)observer;
- (void)nestedMutateByAddingObserver:(id<TestObserver>)observer;
- (void)nestedMutateByRemovingObserver:(id<TestObserver>)observer;

@end

// Implements only the required methods in the TestObserver protocol.
@interface TestPartialObserver : NSObject<TestObserver>
@property(nonatomic, readonly) BOOL requiredMethodInvoked;
@end

// Implements all the methods in the TestObserver protocol.
@interface TestCompleteObserver : TestPartialObserver<TestObserver>
@property(nonatomic, readonly) BOOL optionalMethodInvoked;
@end

@interface TestMutateObserver : TestCompleteObserver
- (instancetype)initWithObserver:(CRBProtocolObservers*)observer
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

namespace {

class CRBProtocolObserversTest : public PlatformTest {
 public:
  CRBProtocolObserversTest() {}

 protected:
  void SetUp() override {
    PlatformTest::SetUp();

    observers_.reset([[CRBProtocolObservers observersWithProtocol:
        @protocol(TestObserver)] retain]);

    partial_observer_.reset([[TestPartialObserver alloc] init]);
    EXPECT_FALSE([partial_observer_ requiredMethodInvoked]);

    complete_observer_.reset([[TestCompleteObserver alloc] init]);
    EXPECT_FALSE([complete_observer_ requiredMethodInvoked]);
    EXPECT_FALSE([complete_observer_ optionalMethodInvoked]);

    mutate_observer_.reset(
        [[TestMutateObserver alloc] initWithObserver:observers_.get()]);
    EXPECT_FALSE([mutate_observer_ requiredMethodInvoked]);
  }

  base::scoped_nsobject<id> observers_;
  base::scoped_nsobject<TestPartialObserver> partial_observer_;
  base::scoped_nsobject<TestCompleteObserver> complete_observer_;
  base::scoped_nsobject<TestMutateObserver> mutate_observer_;
};

// Verifies basic functionality of -[CRBProtocolObservers addObserver:] and
// -[CRBProtocolObservers removeObserver:].
TEST_F(CRBProtocolObserversTest, AddRemoveObserver) {
  // Add an observer and verify that the CRBProtocolObservers instance forwards
  // an invocation to it.
  [observers_ addObserver:partial_observer_];
  [observers_ requiredMethod];
  EXPECT_TRUE([partial_observer_ requiredMethodInvoked]);

  [partial_observer_ reset];
  EXPECT_FALSE([partial_observer_ requiredMethodInvoked]);

  // Remove the observer and verify that the CRBProtocolObservers instance no
  // longer forwards an invocation to it.
  [observers_ removeObserver:partial_observer_];
  [observers_ requiredMethod];
  EXPECT_FALSE([partial_observer_ requiredMethodInvoked]);
}

// Verifies that CRBProtocolObservers correctly forwards the invocation of a
// required method in the protocol.
TEST_F(CRBProtocolObserversTest, RequiredMethods) {
  [observers_ addObserver:partial_observer_];
  [observers_ addObserver:complete_observer_];
  [observers_ requiredMethod];
  EXPECT_TRUE([partial_observer_ requiredMethodInvoked]);
  EXPECT_TRUE([complete_observer_ requiredMethodInvoked]);
}

// Verifies that CRBProtocolObservers correctly forwards the invocation of an
// optional method in the protocol.
TEST_F(CRBProtocolObserversTest, OptionalMethods) {
  [observers_ addObserver:partial_observer_];
  [observers_ addObserver:complete_observer_];
  [observers_ optionalMethod];
  EXPECT_FALSE([partial_observer_ requiredMethodInvoked]);
  EXPECT_FALSE([complete_observer_ requiredMethodInvoked]);
  EXPECT_TRUE([complete_observer_ optionalMethodInvoked]);
}

// Verifies that CRBProtocolObservers only holds a weak reference to an
// observer.
TEST_F(CRBProtocolObserversTest, WeakReference) {
  base::WeakNSObject<TestPartialObserver> weak_observer(
      partial_observer_);
  EXPECT_TRUE(weak_observer);

  [observers_ addObserver:partial_observer_];

  {
    // Need an autorelease pool here, because
    // -[CRBProtocolObservers forwardInvocation:] creates a temporary
    // autoreleased array that holds all the observers.
    base::mac::ScopedNSAutoreleasePool pool;
    [observers_ requiredMethod];
    EXPECT_TRUE([partial_observer_ requiredMethodInvoked]);
  }

  partial_observer_.reset();
  EXPECT_FALSE(weak_observer.get());
}

// Verifies that an observer can safely remove itself as observer while being
// notified.
TEST_F(CRBProtocolObserversTest, SelfMutateObservers) {
  [observers_ addObserver:mutate_observer_];
  EXPECT_FALSE([observers_ empty]);

  [observers_ requiredMethod];
  EXPECT_TRUE([mutate_observer_ requiredMethodInvoked]);

  [mutate_observer_ reset];

  [observers_ nestedMutateByRemovingObserver:mutate_observer_];
  EXPECT_FALSE([mutate_observer_ requiredMethodInvoked]);

  [observers_ addObserver:partial_observer_];

  [observers_ requiredMethod];
  EXPECT_FALSE([mutate_observer_ requiredMethodInvoked]);
  EXPECT_TRUE([partial_observer_ requiredMethodInvoked]);

  [observers_ removeObserver:partial_observer_];
  EXPECT_TRUE([observers_ empty]);
}

// Verifies that - [CRBProtocolObservers addObserver:] and
// - [CRBProtocolObservers removeObserver:] can be called while methods are
// being forwarded.
TEST_F(CRBProtocolObserversTest, MutateObservers) {
  // Indirectly add an observer while forwarding an observer method.
  [observers_ addObserver:mutate_observer_];

  [observers_ mutateByAddingObserver:partial_observer_];
  EXPECT_FALSE([partial_observer_ requiredMethodInvoked]);

  // Check that methods are correctly forwared to the indirectly added observer.
  [mutate_observer_ reset];
  [observers_ requiredMethod];
  EXPECT_TRUE([mutate_observer_ requiredMethodInvoked]);
  EXPECT_TRUE([partial_observer_ requiredMethodInvoked]);

  [mutate_observer_ reset];
  [partial_observer_ reset];

  // Indirectly remove an observer while forwarding an observer method.
  [observers_ mutateByRemovingObserver:partial_observer_];

  // Check that method is not forwared to the indirectly removed observer.
  [observers_ requiredMethod];
  EXPECT_TRUE([mutate_observer_ requiredMethodInvoked]);
  EXPECT_FALSE([partial_observer_ requiredMethodInvoked]);
}

// Verifies that - [CRBProtocolObservers addObserver:] and
// - [CRBProtocolObservers removeObserver:] can be called while methods are
// being forwarded with a nested invocation depth > 0.
TEST_F(CRBProtocolObserversTest, NestedMutateObservers) {
  // Indirectly add an observer while forwarding an observer method.
  [observers_ addObserver:mutate_observer_];

  [observers_ nestedMutateByAddingObserver:partial_observer_];
  EXPECT_FALSE([partial_observer_ requiredMethodInvoked]);

  // Check that methods are correctly forwared to the indirectly added observer.
  [mutate_observer_ reset];
  [observers_ requiredMethod];
  EXPECT_TRUE([mutate_observer_ requiredMethodInvoked]);
  EXPECT_TRUE([partial_observer_ requiredMethodInvoked]);

  [mutate_observer_ reset];
  [partial_observer_ reset];

  // Indirectly remove an observer while forwarding an observer method.
  [observers_ nestedMutateByRemovingObserver:partial_observer_];

  // Check that method is not forwared to the indirectly removed observer.
  [observers_ requiredMethod];
  EXPECT_TRUE([mutate_observer_ requiredMethodInvoked]);
  EXPECT_FALSE([partial_observer_ requiredMethodInvoked]);
}

}  // namespace

@implementation TestPartialObserver {
  BOOL _requiredMethodInvoked;
}

- (BOOL)requiredMethodInvoked {
  return _requiredMethodInvoked;
}

- (void)requiredMethod {
  _requiredMethodInvoked = YES;
}

- (void)reset {
  _requiredMethodInvoked = NO;
}

@end

@implementation TestCompleteObserver {
  BOOL _optionalMethodInvoked;
}

- (BOOL)optionalMethodInvoked {
  return _optionalMethodInvoked;
}

- (void)optionalMethod {
  _optionalMethodInvoked = YES;
}

- (void)reset {
  [super reset];
  _optionalMethodInvoked = NO;
}

@end

@implementation TestMutateObserver {
  __weak id _observers;
}

- (instancetype)initWithObserver:(CRBProtocolObservers*)observers {
  self = [super init];
  if (self) {
    _observers = observers;
  }
  return self;
}

- (instancetype)init {
  NOTREACHED();
  return nil;
}

- (void)mutateByAddingObserver:(id<TestObserver>)observer {
  [_observers addObserver:observer];
}

- (void)mutateByRemovingObserver:(id<TestObserver>)observer {
  [_observers removeObserver:observer];
}

- (void)nestedMutateByAddingObserver:(id<TestObserver>)observer {
  [_observers mutateByAddingObserver:observer];
}

- (void)nestedMutateByRemovingObserver:(id<TestObserver>)observer {
  [_observers mutateByRemovingObserver:observer];
}

@end
