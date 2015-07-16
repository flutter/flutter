// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_BIND_OBJC_BLOCK_H_
#define BASE_MAC_BIND_OBJC_BLOCK_H_

#include <Block.h>

#include "base/bind.h"
#include "base/callback_forward.h"
#include "base/mac/scoped_block.h"

// BindBlock builds a callback from an Objective-C block. Example usages:
//
// Closure closure = BindBlock(^{DoSomething();});
//
// Callback<int(void)> callback = BindBlock(^{return 42;});
//
// Callback<void(const std::string&, const std::string&)> callback =
//     BindBlock(^(const std::string& arg0, const std::string& arg1) {
//         ...
//     });
//
// These variadic templates will accommodate any number of arguments, however
// the underlying templates in bind_internal.h and callback.h are limited to
// seven total arguments, and the bound block itself is used as one of these
// arguments, so functionally the templates are limited to binding blocks with
// zero through six arguments.

namespace base {

namespace internal {

// Helper function to run the block contained in the parameter.
template<typename R, typename... Args>
R RunBlock(base::mac::ScopedBlock<R(^)(Args...)> block, Args... args) {
  R(^extracted_block)(Args...) = block.get();
  return extracted_block(args...);
}

}  // namespace internal

// Construct a callback from an objective-C block with up to six arguments (see
// note above).
template<typename R, typename... Args>
base::Callback<R(Args...)> BindBlock(R(^block)(Args...)) {
  return base::Bind(&base::internal::RunBlock<R, Args...>,
                    base::mac::ScopedBlock<R(^)(Args...)>(Block_copy(block)));
}

}  // namespace base

#endif  // BASE_MAC_BIND_OBJC_BLOCK_H_
