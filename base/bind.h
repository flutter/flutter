// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_BIND_H_
#define BASE_BIND_H_

#include "base/bind_internal.h"
#include "base/callback_internal.h"

// -----------------------------------------------------------------------------
// Usage documentation
// -----------------------------------------------------------------------------
//
// See base/callback.h for documentation.
//
//
// -----------------------------------------------------------------------------
// Implementation notes
// -----------------------------------------------------------------------------
//
// If you're reading the implementation, before proceeding further, you should
// read the top comment of base/bind_internal.h for a definition of common
// terms and concepts.
//
// RETURN TYPES
//
// Though Bind()'s result is meant to be stored in a Callback<> type, it
// cannot actually return the exact type without requiring a large amount
// of extra template specializations. The problem is that in order to
// discern the correct specialization of Callback<>, Bind would need to
// unwrap the function signature to determine the signature's arity, and
// whether or not it is a method.
//
// Each unique combination of (arity, function_type, num_prebound) where
// function_type is one of {function, method, const_method} would require
// one specialization.  We eventually have to do a similar number of
// specializations anyways in the implementation (see the Invoker<>,
// classes).  However, it is avoidable in Bind if we return the result
// via an indirection like we do below.
//
// TODO(ajwong): We might be able to avoid this now, but need to test.
//
// It is possible to move most of the static_assert into BindState<>, but it
// feels a little nicer to have the asserts here so people do not need to crack
// open bind_internal.h.  On the other hand, it makes Bind() harder to read.

namespace base {

template <typename Functor>
base::Callback<
    typename internal::BindState<
        typename internal::FunctorTraits<Functor>::RunnableType,
        typename internal::FunctorTraits<Functor>::RunType,
        internal::TypeList<>>::UnboundRunType>
Bind(Functor functor) {
  // Typedefs for how to store and run the functor.
  typedef typename internal::FunctorTraits<Functor>::RunnableType RunnableType;
  typedef typename internal::FunctorTraits<Functor>::RunType RunType;

  typedef internal::BindState<RunnableType, RunType,
                              internal::TypeList<>> BindState;

  return Callback<typename BindState::UnboundRunType>(
      new BindState(internal::MakeRunnable(functor)));
}

template <typename Functor, typename... Args>
base::Callback<
    typename internal::BindState<
        typename internal::FunctorTraits<Functor>::RunnableType,
        typename internal::FunctorTraits<Functor>::RunType,
        internal::TypeList<
            typename internal::CallbackParamTraits<Args>::StorageType...>>
            ::UnboundRunType>
Bind(Functor functor, const Args&... args) {
  // Typedefs for how to store and run the functor.
  typedef typename internal::FunctorTraits<Functor>::RunnableType RunnableType;
  typedef typename internal::FunctorTraits<Functor>::RunType RunType;

  // Use RunnableType::RunType instead of RunType above because our
  // checks should below for bound references need to know what the actual
  // functor is going to interpret the argument as.
  typedef typename RunnableType::RunType BoundRunType;

  // Do not allow binding a non-const reference parameter. Non-const reference
  // parameters are disallowed by the Google style guide.  Also, binding a
  // non-const reference parameter can make for subtle bugs because the
  // invoked function will receive a reference to the stored copy of the
  // argument and not the original.
  static_assert(!internal::HasNonConstReferenceParam<BoundRunType>::value,
                "do_not_bind_functions_with_nonconst_ref");

  const bool is_method = internal::HasIsMethodTag<RunnableType>::value;

  // For methods, we need to be careful for parameter 1.  We do not require
  // a scoped_refptr because BindState<> itself takes care of AddRef() for
  // methods. We also disallow binding of an array as the method's target
  // object.
  static_assert(!internal::BindsArrayToFirstArg<is_method, Args...>::value,
                "first_bound_argument_to_method_cannot_be_array");
  static_assert(
      !internal::HasRefCountedParamAsRawPtr<is_method, Args...>::value,
      "a_parameter_is_refcounted_type_and_needs_scoped_refptr");

  typedef internal::BindState<
      RunnableType, RunType,
      internal::TypeList<
          typename internal::CallbackParamTraits<Args>::StorageType...>>
      BindState;

  return Callback<typename BindState::UnboundRunType>(
      new BindState(internal::MakeRunnable(functor), args...));
}

}  // namespace base

#endif  // BASE_BIND_H_
