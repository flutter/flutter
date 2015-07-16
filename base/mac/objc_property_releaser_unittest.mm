// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "base/mac/objc_property_releaser.h"
#import "base/mac/scoped_nsautorelease_pool.h"
#include "testing/gtest/include/gtest/gtest.h"

// "When I'm alone, I count myself."
//   --Count von Count, http://www.youtube.com/watch?v=FKzszqa9WA4

namespace {

// The number of CountVonCounts outstanding.
int ah_ah_ah;

// NumberHolder exists to exercise the property attribute string parser by
// providing a named struct and an anonymous union.
struct NumberHolder {
  union {
    long long sixty_four;
    int thirty_two;
    short sixteen;
    char eight;
  } what;
  enum {
    SIXTY_FOUR,
    THIRTY_TWO,
    SIXTEEN,
    EIGHT
  } how;
};

}  // namespace

@interface CountVonCount : NSObject<NSCopying>

+ (CountVonCount*)countVonCount;

@end  // @interface CountVonCount

@implementation CountVonCount

+ (CountVonCount*)countVonCount {
  return [[[CountVonCount alloc] init] autorelease];
}

- (id)init {
  ++ah_ah_ah;
  return [super init];
}

- (void)dealloc {
  --ah_ah_ah;
  [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone {
  return [[CountVonCount allocWithZone:zone] init];
}

@end  // @implementation CountVonCount

@interface ObjCPropertyTestBase : NSObject {
 @private
  CountVonCount* baseCvcRetain_;
  CountVonCount* baseCvcCopy_;
  CountVonCount* baseCvcAssign_;
  CountVonCount* baseCvcNotProperty_;
  CountVonCount* baseCvcNil_;
  CountVonCount* baseCvcCustom_;
  int baseInt_;
  double baseDouble_;
  void* basePointer_;
  NumberHolder baseStruct_;

  base::mac::ObjCPropertyReleaser propertyReleaser_ObjCPropertyTestBase_;
}

@property(retain, nonatomic) CountVonCount* baseCvcRetain;
@property(copy, nonatomic) CountVonCount* baseCvcCopy;
@property(assign, nonatomic) CountVonCount* baseCvcAssign;
@property(retain, nonatomic) CountVonCount* baseCvcNil;
@property(retain, nonatomic, getter=baseCustom, setter=setBaseCustom:)
    CountVonCount* baseCvcCustom;
@property(retain, nonatomic) CountVonCount* baseCvcDynamic;
@property(assign, nonatomic) int baseInt;
@property(assign, nonatomic) double baseDouble;
@property(assign, nonatomic) void* basePointer;
@property(assign, nonatomic) NumberHolder baseStruct;

- (void)setBaseCvcNotProperty:(CountVonCount*)cvc;

@end  // @interface ObjCPropertyTestBase

@implementation ObjCPropertyTestBase

@synthesize baseCvcRetain = baseCvcRetain_;
@synthesize baseCvcCopy = baseCvcCopy_;
@synthesize baseCvcAssign = baseCvcAssign_;
@synthesize baseCvcNil = baseCvcNil_;
@synthesize baseCvcCustom = baseCvcCustom_;
@dynamic baseCvcDynamic;
@synthesize baseInt = baseInt_;
@synthesize baseDouble = baseDouble_;
@synthesize basePointer = basePointer_;
@synthesize baseStruct = baseStruct_;

- (id)init {
  if ((self = [super init])) {
    propertyReleaser_ObjCPropertyTestBase_.Init(
        self, [ObjCPropertyTestBase class]);
  }
  return self;
}

- (void)dealloc {
  [baseCvcNotProperty_ release];
  [super dealloc];
}

- (void)setBaseCvcNotProperty:(CountVonCount*)cvc {
  if (cvc != baseCvcNotProperty_) {
    [baseCvcNotProperty_ release];
    baseCvcNotProperty_ = [cvc retain];
  }
}

@end  // @implementation ObjCPropertyTestBase

@protocol ObjCPropertyTestProtocol

@property(retain, nonatomic) CountVonCount* protoCvcRetain;
@property(copy, nonatomic) CountVonCount* protoCvcCopy;
@property(assign, nonatomic) CountVonCount* protoCvcAssign;
@property(retain, nonatomic) CountVonCount* protoCvcNil;
@property(retain, nonatomic, getter=protoCustom, setter=setProtoCustom:)
    CountVonCount* protoCvcCustom;
@property(retain, nonatomic) CountVonCount* protoCvcDynamic;
@property(assign, nonatomic) int protoInt;
@property(assign, nonatomic) double protoDouble;
@property(assign, nonatomic) void* protoPointer;
@property(assign, nonatomic) NumberHolder protoStruct;

@end  // @protocol ObjCPropertyTestProtocol

@interface ObjCPropertyTestDerived
    : ObjCPropertyTestBase<ObjCPropertyTestProtocol> {
 @private
  CountVonCount* derivedCvcRetain_;
  CountVonCount* derivedCvcCopy_;
  CountVonCount* derivedCvcAssign_;
  CountVonCount* derivedCvcNotProperty_;
  CountVonCount* derivedCvcNil_;
  CountVonCount* derivedCvcCustom_;
  int derivedInt_;
  double derivedDouble_;
  void* derivedPointer_;
  NumberHolder derivedStruct_;

  CountVonCount* protoCvcRetain_;
  CountVonCount* protoCvcCopy_;
  CountVonCount* protoCvcAssign_;
  CountVonCount* protoCvcNil_;
  CountVonCount* protoCvcCustom_;
  int protoInt_;
  double protoDouble_;
  void* protoPointer_;
  NumberHolder protoStruct_;

  base::mac::ObjCPropertyReleaser propertyReleaser_ObjCPropertyTestDerived_;
}

@property(retain, nonatomic) CountVonCount* derivedCvcRetain;
@property(copy, nonatomic) CountVonCount* derivedCvcCopy;
@property(assign, nonatomic) CountVonCount* derivedCvcAssign;
@property(retain, nonatomic) CountVonCount* derivedCvcNil;
@property(retain, nonatomic, getter=derivedCustom, setter=setDerivedCustom:)
    CountVonCount* derivedCvcCustom;
@property(retain, nonatomic) CountVonCount* derivedCvcDynamic;
@property(assign, nonatomic) int derivedInt;
@property(assign, nonatomic) double derivedDouble;
@property(assign, nonatomic) void* derivedPointer;
@property(assign, nonatomic) NumberHolder derivedStruct;

- (void)setDerivedCvcNotProperty:(CountVonCount*)cvc;

@end  // @interface ObjCPropertyTestDerived

@implementation ObjCPropertyTestDerived

@synthesize derivedCvcRetain = derivedCvcRetain_;
@synthesize derivedCvcCopy = derivedCvcCopy_;
@synthesize derivedCvcAssign = derivedCvcAssign_;
@synthesize derivedCvcNil = derivedCvcNil_;
@synthesize derivedCvcCustom = derivedCvcCustom_;
@dynamic derivedCvcDynamic;
@synthesize derivedInt = derivedInt_;
@synthesize derivedDouble = derivedDouble_;
@synthesize derivedPointer = derivedPointer_;
@synthesize derivedStruct = derivedStruct_;

@synthesize protoCvcRetain = protoCvcRetain_;
@synthesize protoCvcCopy = protoCvcCopy_;
@synthesize protoCvcAssign = protoCvcAssign_;
@synthesize protoCvcNil = protoCvcNil_;
@synthesize protoCvcCustom = protoCvcCustom_;
@dynamic protoCvcDynamic;
@synthesize protoInt = protoInt_;
@synthesize protoDouble = protoDouble_;
@synthesize protoPointer = protoPointer_;
@synthesize protoStruct = protoStruct_;

- (id)init {
  if ((self = [super init])) {
    propertyReleaser_ObjCPropertyTestDerived_.Init(
        self, [ObjCPropertyTestDerived class]);
  }
  return self;
}

- (void)dealloc {
  [derivedCvcNotProperty_ release];
  [super dealloc];
}

- (void)setDerivedCvcNotProperty:(CountVonCount*)cvc {
  if (cvc != derivedCvcNotProperty_) {
    [derivedCvcNotProperty_ release];
    derivedCvcNotProperty_ = [cvc retain];
  }
}

@end  // @implementation ObjCPropertyTestDerived

namespace {

TEST(ObjCPropertyReleaserTest, SesameStreet) {
  ObjCPropertyTestDerived* test_object = [[ObjCPropertyTestDerived alloc] init];

  // Assure a clean slate.
  EXPECT_EQ(0, ah_ah_ah);
  EXPECT_EQ(1U, [test_object retainCount]);

  CountVonCount* baseAssign = [[CountVonCount alloc] init];
  CountVonCount* derivedAssign = [[CountVonCount alloc] init];
  CountVonCount* protoAssign = [[CountVonCount alloc] init];

  // Make sure that worked before things get more involved.
  EXPECT_EQ(3, ah_ah_ah);

  {
    base::mac::ScopedNSAutoreleasePool pool;

    test_object.baseCvcRetain = [CountVonCount countVonCount];
    test_object.baseCvcCopy = [CountVonCount countVonCount];
    test_object.baseCvcAssign = baseAssign;
    test_object.baseCvcCustom = [CountVonCount countVonCount];
    [test_object setBaseCvcNotProperty:[CountVonCount countVonCount]];

    // That added 4 objects, plus 1 more that was copied.
    EXPECT_EQ(8, ah_ah_ah);

    test_object.derivedCvcRetain = [CountVonCount countVonCount];
    test_object.derivedCvcCopy = [CountVonCount countVonCount];
    test_object.derivedCvcAssign = derivedAssign;
    test_object.derivedCvcCustom = [CountVonCount countVonCount];
    [test_object setDerivedCvcNotProperty:[CountVonCount countVonCount]];

    // That added 4 objects, plus 1 more that was copied.
    EXPECT_EQ(13, ah_ah_ah);

    test_object.protoCvcRetain = [CountVonCount countVonCount];
    test_object.protoCvcCopy = [CountVonCount countVonCount];
    test_object.protoCvcAssign = protoAssign;
    test_object.protoCvcCustom = [CountVonCount countVonCount];

    // That added 3 objects, plus 1 more that was copied.
    EXPECT_EQ(17, ah_ah_ah);
  }

  // Now that the autorelease pool has been popped, the 3 objects that were
  // copied when placed into the test object will have been deallocated.
  EXPECT_EQ(14, ah_ah_ah);

  // Make sure that the setters work and have the expected semantics.
  test_object.baseCvcRetain = nil;
  test_object.baseCvcCopy = nil;
  test_object.baseCvcAssign = nil;
  test_object.baseCvcCustom = nil;
  test_object.derivedCvcRetain = nil;
  test_object.derivedCvcCopy = nil;
  test_object.derivedCvcAssign = nil;
  test_object.derivedCvcCustom = nil;
  test_object.protoCvcRetain = nil;
  test_object.protoCvcCopy = nil;
  test_object.protoCvcAssign = nil;
  test_object.protoCvcCustom = nil;

  // The CountVonCounts marked "retain" and "copy" should have been
  // deallocated. Those marked assign should not have been. The only ones that
  // should exist now are the ones marked "assign" and the ones held in
  // non-property instance variables.
  EXPECT_EQ(5, ah_ah_ah);

  {
    base::mac::ScopedNSAutoreleasePool pool;

    // Put things back to how they were.
    test_object.baseCvcRetain = [CountVonCount countVonCount];
    test_object.baseCvcCopy = [CountVonCount countVonCount];
    test_object.baseCvcAssign = baseAssign;
    test_object.baseCvcCustom = [CountVonCount countVonCount];
    test_object.derivedCvcRetain = [CountVonCount countVonCount];
    test_object.derivedCvcCopy = [CountVonCount countVonCount];
    test_object.derivedCvcAssign = derivedAssign;
    test_object.derivedCvcCustom = [CountVonCount countVonCount];
    test_object.protoCvcRetain = [CountVonCount countVonCount];
    test_object.protoCvcCopy = [CountVonCount countVonCount];
    test_object.protoCvcAssign = protoAssign;
    test_object.protoCvcCustom = [CountVonCount countVonCount];

    // 9 more CountVonCounts, 3 of which were copied.
    EXPECT_EQ(17, ah_ah_ah);
  }

  // Now that the autorelease pool has been popped, the 3 copies are gone.
  EXPECT_EQ(14, ah_ah_ah);

  // Releasing the test object should get rid of everything that it owns.
  [test_object release];

  // The property releaser should have released all of the CountVonCounts
  // associated with properties marked "retain" or "copy". The -dealloc
  // methods in each should have released the single non-property objects in
  // each. Only the CountVonCounts assigned to the properties marked "assign"
  // should remain.
  EXPECT_EQ(3, ah_ah_ah);

  [baseAssign release];
  [derivedAssign release];
  [protoAssign release];

  // Zero! Zero counts! Ah, ah, ah.
  EXPECT_EQ(0, ah_ah_ah);
}

}  // namespace
