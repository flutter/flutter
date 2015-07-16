// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "base/mac/scoped_objc_class_swizzler.h"

#import "base/mac/scoped_nsobject.h"
#include "testing/gtest/include/gtest/gtest.h"

@interface ObjCClassSwizzlerTestOne : NSObject
+ (NSInteger)function;
- (NSInteger)method;
- (NSInteger)modifier;
@end

@interface ObjCClassSwizzlerTestTwo : NSObject
+ (NSInteger)function;
- (NSInteger)method;
- (NSInteger)modifier;
@end

@implementation ObjCClassSwizzlerTestOne : NSObject

+ (NSInteger)function {
  return 10;
}

- (NSInteger)method {
  // Multiply by a modifier to ensure |self| in a swizzled implementation
  // refers to the original object.
  return 1 * [self modifier];
}

- (NSInteger)modifier {
  return 3;
}

@end

@implementation ObjCClassSwizzlerTestTwo : NSObject

+ (NSInteger)function {
  return 20;
}

- (NSInteger)method {
  return 2 * [self modifier];
}

- (NSInteger)modifier {
  return 7;
}

@end

@interface ObjCClassSwizzlerTestOne (AlternateCategory)
- (NSInteger)alternate;
@end

@implementation ObjCClassSwizzlerTestOne (AlternateCategory)
- (NSInteger)alternate {
  return 3 * [self modifier];
}
@end

@interface ObjCClassSwizzlerTestOneChild : ObjCClassSwizzlerTestOne
- (NSInteger)childAlternate;
@end

@implementation ObjCClassSwizzlerTestOneChild
- (NSInteger)childAlternate {
  return 5 * [self modifier];
}
@end

namespace base {
namespace mac {

TEST(ObjCClassSwizzlerTest, SwizzleInstanceMethods) {
  base::scoped_nsobject<ObjCClassSwizzlerTestOne> object_one(
      [[ObjCClassSwizzlerTestOne alloc] init]);
  base::scoped_nsobject<ObjCClassSwizzlerTestTwo> object_two(
      [[ObjCClassSwizzlerTestTwo alloc] init]);
  EXPECT_EQ(3, [object_one method]);
  EXPECT_EQ(14, [object_two method]);

  {
    base::mac::ScopedObjCClassSwizzler swizzler(
        [ObjCClassSwizzlerTestOne class],
        [ObjCClassSwizzlerTestTwo class],
        @selector(method));
    EXPECT_EQ(6, [object_one method]);
    EXPECT_EQ(7, [object_two method]);

    IMP original = swizzler.GetOriginalImplementation();
    id expected_result = reinterpret_cast<id>(3);
    EXPECT_EQ(expected_result, original(object_one, @selector(method)));
  }

  EXPECT_EQ(3, [object_one method]);
  EXPECT_EQ(14, [object_two method]);
}

TEST(ObjCClassSwizzlerTest, SwizzleClassMethods) {
  EXPECT_EQ(10, [ObjCClassSwizzlerTestOne function]);
  EXPECT_EQ(20, [ObjCClassSwizzlerTestTwo function]);

  {
    base::mac::ScopedObjCClassSwizzler swizzler(
        [ObjCClassSwizzlerTestOne class],
        [ObjCClassSwizzlerTestTwo class],
        @selector(function));
    EXPECT_EQ(20, [ObjCClassSwizzlerTestOne function]);
    EXPECT_EQ(10, [ObjCClassSwizzlerTestTwo function]);

    IMP original = swizzler.GetOriginalImplementation();
    id expected_result = reinterpret_cast<id>(10);
    EXPECT_EQ(expected_result, original(nil, @selector(function)));
  }

  EXPECT_EQ(10, [ObjCClassSwizzlerTestOne function]);
  EXPECT_EQ(20, [ObjCClassSwizzlerTestTwo function]);
}

TEST(ObjCClassSwizzlerTest, SwizzleViaCategory) {
  base::scoped_nsobject<ObjCClassSwizzlerTestOne> object_one(
      [[ObjCClassSwizzlerTestOne alloc] init]);
  EXPECT_EQ(3, [object_one method]);

  {
    base::mac::ScopedObjCClassSwizzler swizzler(
        [ObjCClassSwizzlerTestOne class],
        @selector(method),
        @selector(alternate));
    EXPECT_EQ(9, [object_one method]);

    IMP original = swizzler.GetOriginalImplementation();
    id expected_result = reinterpret_cast<id>(3);
    EXPECT_EQ(expected_result, original(object_one, @selector(method)));
  }

  EXPECT_EQ(3, [object_one method]);
}

TEST(ObjCClassSwizzlerTest, SwizzleViaInheritance) {
  base::scoped_nsobject<ObjCClassSwizzlerTestOneChild> child(
      [[ObjCClassSwizzlerTestOneChild alloc] init]);
  EXPECT_EQ(3, [child method]);

  {
    base::mac::ScopedObjCClassSwizzler swizzler(
        [ObjCClassSwizzlerTestOneChild class],
        @selector(method),
        @selector(childAlternate));
    EXPECT_EQ(15, [child method]);

    IMP original = swizzler.GetOriginalImplementation();
    id expected_result = reinterpret_cast<id>(3);
    EXPECT_EQ(expected_result, original(child, @selector(method)));
  }

  EXPECT_EQ(3, [child method]);
}

}  // namespace mac
}  // namespace base
