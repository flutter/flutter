// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "base/mac/objc_property_releaser.h"

#import <objc/runtime.h>
#include <stdlib.h>

#include <string>

#include "base/logging.h"

namespace base {
namespace mac {

namespace {

// Returns the name of the instance variable backing the property, if known,
// if the property is marked "retain" or "copy". If the instance variable name
// is not known (perhaps because it was not automatically associated with the
// property by @synthesize) or if the property is not "retain" or "copy",
// returns an empty string.
std::string ReleasableInstanceName(objc_property_t property) {
  // TODO(mark): Starting in newer system releases, the Objective-C runtime
  // provides a function to break the property attribute string into
  // individual attributes (property_copyAttributeList), as well as a function
  // to look up the value of a specific attribute
  // (property_copyAttributeValue). When the SDK defining that interface is
  // final, this function should be adapted to walk the attribute list as
  // returned by property_copyAttributeList when that function is available in
  // preference to scanning through the attribute list manually.

  // The format of the string returned by property_getAttributes is documented
  // at
  // http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW6
  const char* property_attributes = property_getAttributes(property);

  std::string instance_name;
  bool releasable = false;
  while (*property_attributes) {
    char name = *property_attributes;

    const char* value = ++property_attributes;
    while (*property_attributes && *property_attributes != ',') {
      ++property_attributes;
    }

    switch (name) {
      // It might seem intelligent to check the type ('T') attribute to verify
      // that it identifies an NSObject-derived type (the attribute value
      // begins with '@'.) This is a bad idea beacuse it fails to identify
      // CFTypeRef-based properties declared as __attribute__((NSObject)),
      // which just show up as pointers to their underlying CFType structs.
      //
      // Quoting
      // http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjectiveC/Chapters/ocProperties.html#//apple_ref/doc/uid/TP30001163-CH17-SW27
      //
      // > In Mac OS X v10.6 and later, you can use the __attribute__ keyword
      // > to specify that a Core Foundation property should be treated like
      // > an Objective-C object for memory management:
      // >   @property(retain) __attribute__((NSObject)) CFDictionaryRef
      // >       myDictionary;
      case 'C':  // copy
      case '&':  // retain
        releasable = true;
        break;
      case 'V':  // instance variable name
        // 'V' is specified as the last attribute to occur in the
        // documentation, but empirically, it's not always the last. In
        // GC-supported or GC-required code, the 'P' (GC-eligible) attribute
        // occurs after 'V'.
        instance_name.assign(value, property_attributes - value);
        break;
    }

    if (*property_attributes) {
      ++property_attributes;
    }
  }

  if (releasable) {
    return instance_name;
  }

  return std::string();
}

}  // namespace

void ObjCPropertyReleaser::Init(id object, Class classy) {
  DCHECK(!object_);
  DCHECK(!class_);
  CHECK([object isKindOfClass:classy]);

  object_ = object;
  class_ = classy;
}

void ObjCPropertyReleaser::ReleaseProperties() {
  DCHECK(object_);
  DCHECK(class_);

  unsigned int property_count = 0;
  objc_property_t* properties = class_copyPropertyList(class_, &property_count);

  for (unsigned int property_index = 0;
       property_index < property_count;
       ++property_index) {
    objc_property_t property = properties[property_index];
    std::string instance_name = ReleasableInstanceName(property);
    if (!instance_name.empty()) {
      id instance_value = nil;
      Ivar instance_variable =
          object_getInstanceVariable(object_, instance_name.c_str(),
                                     (void**)&instance_value);
      DCHECK(instance_variable);
      [instance_value release];
    }
  }

  free(properties);

  // Clear object_ and class_ in case this ObjCPropertyReleaser will live on.
  // It's only expected to release the properties it supervises once per Init.
  object_ = nil;
  class_ = nil;
}

}  // namespace mac
}  // namespace base
