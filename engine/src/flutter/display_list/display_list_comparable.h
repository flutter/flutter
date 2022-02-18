// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COMPARABLE_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COMPARABLE_H_

#include "flutter/display_list/types.h"

namespace flutter {

// These templates implement deep pointer comparisons that compare not
// just the pointers to the objects, but also their contents (provided
// that the <T> class implements the == operator override).
// Any combination of shared_ptr<T> or T* are supported and null pointers
// are not equal to anything but another null pointer.

template <class T>
bool Equals(const T* a, const T* b) {
  if (a == b) {
    return true;
  }
  if (!a || !b) {
    return false;
  }
  return *a == *b;
}

template <class T>
bool Equals(std::shared_ptr<const T> a, const T* b) {
  if (!a) {
    return !b;
  }
  if (!b) {
    return false;
  }
  if (a.get() == b) {
    return true;
  }
  return *a.get() == *b;
}

template <class T>
bool Equals(const T* a, std::shared_ptr<const T> b) {
  return Equals(b, a);
}

template <class T>
bool Equals(std::shared_ptr<const T> a, std::shared_ptr<const T> b) {
  if (!a) {
    return !b;
  }
  if (!b) {
    return false;
  }
  if (a.get() == b.get()) {
    return true;
  }
  return *a.get() == *b.get();
}

template <class T>
bool NotEquals(const T* a, const T* b) {
  return !Equals<T>(a, b);
}

template <class T>
bool NotEquals(std::shared_ptr<const T> a, const T* b) {
  return !Equals<T>(a, b);
}

template <class T>
bool NotEquals(const T* a, std::shared_ptr<const T> b) {
  return !Equals<T>(b, a);
}

template <class T>
bool NotEquals(std::shared_ptr<const T> a, std::shared_ptr<const T> b) {
  return !Equals(a, b);
}

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COMPARABLE_H_
