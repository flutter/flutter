// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/darwin/weak_nsobject.h"
#include "flutter/fml/platform/darwin/scoped_nsautorelease_pool.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"

namespace {
// The key needed by objc_setAssociatedObject.
char sentinelObserverKey_;
}  // namespace

namespace fml {

WeakContainer::WeakContainer(id object, const debug::DebugThreadChecker& checker)
    : object_(object), checker_(checker) {}

WeakContainer::~WeakContainer() {}

}  // namespace fml

@interface CRBWeakNSProtocolSentinel ()
// Container to notify on dealloc.
@property(readonly, assign) fml::RefPtr<fml::WeakContainer> container;
// Designed initializer.
- (id)initWithContainer:(fml::RefPtr<fml::WeakContainer>)container;
@end

@implementation CRBWeakNSProtocolSentinel

+ (fml::RefPtr<fml::WeakContainer>)containerForObject:(id)object
                                        threadChecker:(debug::DebugThreadChecker)checker {
  if (object == nil) {
    return nullptr;
  }
  // The autoreleasePool is needed here as the call to objc_getAssociatedObject
  // returns an autoreleased object which is better released sooner than later.
  fml::ScopedNSAutoreleasePool pool;
  CRBWeakNSProtocolSentinel* sentinel = objc_getAssociatedObject(object, &sentinelObserverKey_);
  if (!sentinel) {
    fml::scoped_nsobject<CRBWeakNSProtocolSentinel> newSentinel([[CRBWeakNSProtocolSentinel alloc]
        initWithContainer:AdoptRef(new fml::WeakContainer(object, checker))]);
    sentinel = newSentinel;
    objc_setAssociatedObject(object, &sentinelObserverKey_, sentinel, OBJC_ASSOCIATION_RETAIN);
    // The retain count is 2. One retain is due to the alloc, the other to the
    // association with the weak object.
    FML_DCHECK(2u == [sentinel retainCount]);
  }
  return [sentinel container];
}

- (id)initWithContainer:(fml::RefPtr<fml::WeakContainer>)container {
  FML_DCHECK(container.get());
  self = [super init];
  if (self) {
    _container = container;
  }
  return self;
}

- (void)dealloc {
  _container->nullify();
  [super dealloc];
}

@end
