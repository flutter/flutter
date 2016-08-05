// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GLUE_MOVABLE_WRAPPER_H_
#define GLUE_MOVABLE_WRAPPER_H_

#include <utility>

namespace glue {

template <typename T>
class MovableWrapper {
 public:
  explicit MovableWrapper(T object) : object_(std::move(object)) {}
  MovableWrapper(const MovableWrapper& other)
      : object_(std::move(other.object_)) {}

  MovableWrapper(MovableWrapper&& other) : object_(std::move(other.object_)) {}
  MovableWrapper& operator=(MovableWrapper&& other) {
    object_ = std::move(other.object_);
  }

  T Unwrap() { return std::move(object_); }

 private:
  mutable T object_;
};

template <typename T>
MovableWrapper<T> WrapMovable(T object) {
  return MovableWrapper<T>(std::move(object));
}

}  // namespace glue

#endif  // GLUE_MOVABLE_WRAPPER_H_
