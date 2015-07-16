// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WEAK_PTR_FACTORY_H_
#define WEAK_PTR_FACTORY_H_

namespace base {

template <typename T>
class WeakPtrFactory {
 public:
  explicit WeakPtrFactory(T*) {}
};

}  // namespace base

#endif  // WEAK_PTR_FACTORY_H_
