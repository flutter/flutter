// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_OBJC_PROPERTY_RELEASER_H_
#define BASE_MAC_OBJC_PROPERTY_RELEASER_H_

#import <Foundation/Foundation.h>

#include "base/base_export.h"

namespace base {
namespace mac {

// ObjCPropertyReleaser is a C++ class that can automatically release
// synthesized Objective-C properties marked "retain" or "copy". The expected
// use is to place an ObjCPropertyReleaser object within an Objective-C class
// definition. When built with the -fobjc-call-cxx-cdtors compiler option,
// the ObjCPropertyReleaser's destructor will be called when the Objective-C
// object that owns it is deallocated, and it will send a -release message to
// the instance variables backing the appropriate properties. If
// -fobjc-call-cxx-cdtors is not in use, ObjCPropertyReleaser's
// ReleaseProperties method can be called from -dealloc to achieve the same
// effect.
//
// Example usage:
//
// @interface AllaysIBF : NSObject {
//  @private
//   NSString* string_;
//   NSMutableDictionary* dictionary_;
//   NSString* notAProperty_;
//   IBFDelegate* delegate_;  // weak
//
//   // It's recommended to put the class name into the property releaser's
//   // instance variable name to gracefully handle subclassing, where
//   // multiple classes in a hierarchy might want their own property
//   // releasers.
//   base::mac::ObjCPropertyReleaser propertyReleaser_AllaysIBF_;
// }
//
// @property(retain, nonatomic) NSString* string;
// @property(copy, nonatomic) NSMutableDictionary* dictionary;
// @property(assign, nonatomic) IBFDelegate* delegate;
// @property(retain, nonatomic) NSString* autoProp;
//
// @end  // @interface AllaysIBF
//
// @implementation AllaysIBF
//
// @synthesize string = string_;
// @synthesize dictionary = dictionary_;
// @synthesize delegate = delegate_;
// @synthesize autoProp;
//
// - (id)init {
//   if ((self = [super init])) {
//     // Initialize with [AllaysIBF class]. Never use [self class] because
//     // in the case of subclassing, it will return the most specific class
//     // for |self|, which may not be the same as [AllaysIBF class]. This
//     // would cause AllaysIBF's -.cxx_destruct or -dealloc to release
//     // instance variables that only exist in subclasses, likely causing
//     // mass disaster.
//     propertyReleaser_AllaysIBF_.Init(self, [AllaysIBF class]);
//   }
//   return self;
// }
//
// @end  // @implementation AllaysIBF
//
// When an instance of AllaysIBF is deallocated, the ObjCPropertyReleaser will
// send a -release message to string_, dictionary_, and the compiler-created
// autoProp instance variables. No -release will be sent to delegate_ as it
// is marked "assign" and not "retain" or "copy". No -release will be sent to
// notAProperty_ because it doesn't correspond to any declared @property.
//
// Another way of doing this would be to provide a base class that others can
// inherit from, and to have the base class' -dealloc walk the property lists
// of all subclasses in an object to send the -release messages. Since this
// involves a base reaching into its subclasses, it's deemed scary, so don't
// do it. ObjCPropertyReleaser's design ensures that the property releaser
// will only operate on instance variables in the immediate object in which
// the property releaser is placed.

class BASE_EXPORT ObjCPropertyReleaser {
 public:
  // ObjCPropertyReleaser can only be owned by an Objective-C object, so its
  // memory is always guaranteed to be 0-initialized. Not defining the default
  // constructor can prevent an otherwise no-op -.cxx_construct method from
  // showing up in Objective-C classes that contain a ObjCPropertyReleaser.

  // Upon destruction (expected to occur from an Objective-C object's
  // -.cxx_destruct method), release all properties.
  ~ObjCPropertyReleaser() {
    ReleaseProperties();
  }

  // Initialize this object so that it's armed to release the properties of
  // object |object|, which must be of type |classy|. The class argument must
  // be supplied separately and cannot be gleaned from the object's own type
  // because an object will allays identify itself as the most-specific type
  // that describes it, but the ObjCPropertyReleaser needs to know which class
  // type in the class hierarchy it's responsible for releasing properties
  // for. For the same reason, Init must be called with a |classy| argument
  // initialized using a +class (class) method such as [MyClass class], and
  // never a -class (instance) method such as [self class].
  //
  // -.cxx_construct can only call the default constructor, but
  // ObjCPropertyReleaser needs to know about the Objective-C object that owns
  // it, so this can't be handled in a constructor, it needs to be a distinct
  // Init method.
  void Init(id object, Class classy);

  // Release all of the properties in object_ defined in class_ as either
  // "retain" or "copy" and with an identifiable backing instance variable.
  // Properties must be synthesized to have identifiable instance variables.
  void ReleaseProperties();

 private:
  id object_;
  Class class_;
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_OBJC_PROPERTY_RELEASER_H_
