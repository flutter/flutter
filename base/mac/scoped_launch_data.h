// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_LAUNCH_DATA_H_
#define BASE_MAC_SCOPED_LAUNCH_DATA_H_

#include <launch.h>

#include <algorithm>

#include "base/basictypes.h"
#include "base/compiler_specific.h"

namespace base {
namespace mac {

// Just like scoped_ptr<> but for launch_data_t.
class ScopedLaunchData {
 public:
  typedef launch_data_t element_type;

  explicit ScopedLaunchData(launch_data_t object = NULL)
      : object_(object) {
  }

  ~ScopedLaunchData() {
    if (object_)
      launch_data_free(object_);
  }

  void reset(launch_data_t object = NULL) {
    if (object != object_) {
      if (object_)
        launch_data_free(object_);
      object_ = object;
    }
  }

  bool operator==(launch_data_t that) const {
    return object_ == that;
  }

  bool operator!=(launch_data_t that) const {
    return object_ != that;
  }

  operator launch_data_t() const {
    return object_;
  }

  launch_data_t get() const {
    return object_;
  }

  void swap(ScopedLaunchData& that) {
    std::swap(object_, that.object_);
  }

  launch_data_t release() WARN_UNUSED_RESULT {
    launch_data_t temp = object_;
    object_ = NULL;
    return temp;
  }

 private:
  launch_data_t object_;

  DISALLOW_COPY_AND_ASSIGN(ScopedLaunchData);
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_SCOPED_LAUNCH_DATA_H_
