// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Support for using the Singleton<T> pattern with Objective-C objects.  A
// SingletonObjC is the same as a Singleton, except the default traits are
// appropriate for Objective-C objects.  A typical Objective-C object of type
// NSExampleType can be maintained as a singleton and accessed with:
//
//   NSExampleType* exampleSingleton = SingletonObjC<NSExampleType>::get();
//
// The first time this is used, it will create exampleSingleton as the result
// of [[NSExampleType alloc] init].  Subsequent calls will return the same
// NSExampleType* object.  The object will be released by calling
// -[NSExampleType release] when Singleton's atexit routines run
// (see singleton.h).
//
// For Objective-C objects initialized through means other than the
// no-parameter -init selector, DefaultSingletonObjCTraits may be extended
// as needed:
//
//   struct FooSingletonTraits : public DefaultSingletonObjCTraits<Foo> {
//     static Foo* New() {
//       return [[Foo alloc] initWithName:@"selecty"];
//     }
//   };
//   ...
//   Foo* widgetSingleton = SingletonObjC<Foo, FooSingletonTraits>::get();

#ifndef BASE_MEMORY_SINGLETON_OBJC_H_
#define BASE_MEMORY_SINGLETON_OBJC_H_

#import <Foundation/Foundation.h>
#include "base/memory/singleton.h"

// Singleton traits usable to manage traditional Objective-C objects, which
// are instantiated by sending |alloc| and |init| messages, and are deallocated
// in a memory-managed environment when their retain counts drop to 0 by
// sending |release| messages.
template<typename Type>
struct DefaultSingletonObjCTraits : public DefaultSingletonTraits<Type> {
  static Type* New() {
    return [[Type alloc] init];
  }

  static void Delete(Type* object) {
    [object release];
  }
};

// Exactly like Singleton, but without the DefaultSingletonObjCTraits as the
// default trait class.  This makes it straightforward for Objective-C++ code
// to hold Objective-C objects as singletons.
template<typename Type,
         typename Traits = DefaultSingletonObjCTraits<Type>,
         typename DifferentiatingType = Type>
class SingletonObjC : public Singleton<Type, Traits, DifferentiatingType> {
};

#endif  // BASE_MEMORY_SINGLETON_OBJC_H_
