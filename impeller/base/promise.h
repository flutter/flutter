// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <future>

namespace impeller {

template <class T>
std::future<T> RealizedFuture(T t) {
  std::promise<T> promise;
  auto future = promise.get_future();
  promise.set_value(std::move(t));
  return future;
}

}  // namespace impeller
