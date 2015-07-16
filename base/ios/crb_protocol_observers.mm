// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "base/ios/crb_protocol_observers.h"

#include <objc/runtime.h>
#include <algorithm>
#include <vector>

#include "base/logging.h"
#include "base/mac/scoped_nsobject.h"

@interface CRBProtocolObservers () {
  base::scoped_nsobject<Protocol> _protocol;
  // ivars declared here are private to the implementation but must be
  // public for allowing the C++ |Iterator| class access to those ivars.
 @public
  // vector of weak pointers to observers.
  std::vector<__unsafe_unretained id> _observers;
  // The nested level of observer iteration.
  // A depth of 0 means nobody is currently iterating on the list of observers.
  int _invocationDepth;
}

// Removes nil observers from the list and is called when the
// |_invocationDepth| reaches 0.
- (void)compact;

@end

namespace {

class Iterator {
 public:
  explicit Iterator(CRBProtocolObservers* protocol_observers);
  ~Iterator();
  id GetNext();

 private:
  CRBProtocolObservers* protocol_observers_;
  size_t index_;
  size_t max_index_;
};

Iterator::Iterator(CRBProtocolObservers* protocol_observers)
    : protocol_observers_(protocol_observers),
      index_(0),
      max_index_(protocol_observers->_observers.size()) {
  DCHECK(protocol_observers_);
  ++protocol_observers->_invocationDepth;
}

Iterator::~Iterator() {
  if (protocol_observers_ && --protocol_observers_->_invocationDepth == 0)
    [protocol_observers_ compact];
}

id Iterator::GetNext() {
  if (!protocol_observers_)
    return nil;
  auto& observers = protocol_observers_->_observers;
  // Skip nil elements.
  size_t max_index = std::min(max_index_, observers.size());
  while (index_ < max_index && !observers[index_])
    ++index_;
  return index_ < max_index ? observers[index_++] : nil;
}
}

@interface CRBProtocolObservers ()

// Designated initializer.
- (id)initWithProtocol:(Protocol*)protocol;

@end

@implementation CRBProtocolObservers

+ (instancetype)observersWithProtocol:(Protocol*)protocol {
  return [[[self alloc] initWithProtocol:protocol] autorelease];
}

- (id)init {
  NOTREACHED();
  return nil;
}

- (id)initWithProtocol:(Protocol*)protocol {
  self = [super init];
  if (self) {
    _protocol.reset([protocol retain]);
  }
  return self;
}

- (Protocol*)protocol {
  return _protocol.get();
}

- (void)addObserver:(id)observer {
  DCHECK(observer);
  DCHECK([observer conformsToProtocol:self.protocol]);

  if (std::find(_observers.begin(), _observers.end(), observer) !=
      _observers.end())
    return;

  _observers.push_back(observer);
}

- (void)removeObserver:(id)observer {
  DCHECK(observer);
  auto it = std::find(_observers.begin(), _observers.end(), observer);
  if (it != _observers.end()) {
    if (_invocationDepth)
      *it = nil;
    else
      _observers.erase(it);
  }
}

- (BOOL)empty {
  int count = 0;
  for (id observer : _observers) {
    if (observer != nil)
      ++count;
  }
  return count == 0;
}

#pragma mark - NSObject

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
  NSMethodSignature* signature = [super methodSignatureForSelector:selector];
  if (signature)
    return signature;

  // Look for a required method in the protocol. protocol_getMethodDescription
  // returns a struct whose fields are null if a method for the selector was
  // not found.
  struct objc_method_description description =
      protocol_getMethodDescription(self.protocol, selector, YES, YES);
  if (description.types)
    return [NSMethodSignature signatureWithObjCTypes:description.types];

  // Look for an optional method in the protocol.
  description = protocol_getMethodDescription(self.protocol, selector, NO, YES);
  if (description.types)
    return [NSMethodSignature signatureWithObjCTypes:description.types];

  // There is neither a required nor optional method with this selector in the
  // protocol, so invoke -[NSObject doesNotRecognizeSelector:] to raise
  // NSInvalidArgumentException.
  [self doesNotRecognizeSelector:selector];
  return nil;
}

- (void)forwardInvocation:(NSInvocation*)invocation {
  DCHECK(invocation);
  if (_observers.empty())
    return;
  SEL selector = [invocation selector];
  Iterator it(self);
  id observer;
  while ((observer = it.GetNext()) != nil) {
    if ([observer respondsToSelector:selector])
      [invocation invokeWithTarget:observer];
  }
}

- (void)executeOnObservers:(ExecutionWithObserverBlock)callback {
  DCHECK(callback);
  if (_observers.empty())
    return;
  Iterator it(self);
  id observer;
  while ((observer = it.GetNext()) != nil)
    callback(observer);
}

#pragma mark - Private

- (void)compact {
  DCHECK(!_invocationDepth);
  _observers.erase(std::remove(_observers.begin(), _observers.end(), nil),
                   _observers.end());
}

@end
