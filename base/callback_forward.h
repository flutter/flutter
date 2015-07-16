// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_CALLBACK_FORWARD_H_
#define BASE_CALLBACK_FORWARD_H_

namespace base {

template <typename Sig>
class Callback;

typedef Callback<void(void)> Closure;

}  // namespace base

#endif  // BASE_CALLBACK_FORWARD_H_
