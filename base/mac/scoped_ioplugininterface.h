// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_IOPLUGININTERFACE_H_
#define BASE_MAC_SCOPED_IOPLUGININTERFACE_H_

#include <IOKit/IOKitLib.h>

#include "base/basictypes.h"
#include "base/compiler_specific.h"

namespace base {
namespace mac {

// Just like ScopedCFTypeRef but for IOCFPlugInInterface and friends
// (IOUSBInterfaceStruct and IOUSBDeviceStruct320 in particular).
template<typename T>
class ScopedIOPluginInterface {
 public:
  typedef T** InterfaceT;
  typedef InterfaceT element_type;

  explicit ScopedIOPluginInterface(InterfaceT object = NULL)
      : object_(object) {
  }

  ~ScopedIOPluginInterface() {
    if (object_)
      (*object_)->Release(object_);
  }

  void reset(InterfaceT object = NULL) {
    if (object_)
      (*object_)->Release(object_);
    object_ = object;
  }

  bool operator==(InterfaceT that) const {
    return object_ == that;
  }

  bool operator!=(InterfaceT that) const {
    return object_ != that;
  }

  operator InterfaceT() const {
    return object_;
  }

  InterfaceT get() const {
    return object_;
  }

  void swap(ScopedIOPluginInterface& that) {
    InterfaceT temp = that.object_;
    that.object_ = object_;
    object_ = temp;
  }

  InterfaceT release() WARN_UNUSED_RESULT {
    InterfaceT temp = object_;
    object_ = NULL;
    return temp;
  }

 private:
  InterfaceT object_;

  DISALLOW_COPY_AND_ASSIGN(ScopedIOPluginInterface);
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_SCOPED_IOPLUGININTERFACE_H_
