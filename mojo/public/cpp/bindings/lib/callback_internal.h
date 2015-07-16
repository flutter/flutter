// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_CALLBACK_INTERNAL_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_CALLBACK_INTERNAL_H_

#include "mojo/public/cpp/bindings/lib/template_util.h"

namespace mojo {
class String;

namespace internal {

template <typename T>
struct Callback_ParamTraits {
  typedef T ForwardType;
};

template <>
struct Callback_ParamTraits<String> {
  typedef const String& ForwardType;
};

template <typename T, typename... Args>
struct HasCompatibleCallOperator {
  // This template's second parameter is the signature of the operator()
  // overload we want to try to detect:
  //   void operator()(Args...) const;
  template <typename U,
            void (U::*)(
                typename internal::Callback_ParamTraits<Args>::ForwardType...)
                const>
  struct TestType {};

  // This matches type U if it has a call operator with the
  // expected signature.
  template <typename U>
  static YesType Test(TestType<U, &U::operator()>*);

  // This matches anything else.
  template <typename U>
  static NoType Test(...);

  // HasCompatibleCallOperator<T, Args...>::value will be true if T has a
  // compatible call operator.
  enum { value = (sizeof(Test<T>(nullptr)) == sizeof(YesType)) };
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_CALLBACK_INTERNAL_H_
