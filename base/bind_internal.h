// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_BIND_INTERNAL_H_
#define BASE_BIND_INTERNAL_H_

#include "base/bind_helpers.h"
#include "base/callback_internal.h"
#include "base/memory/raw_scoped_refptr_mismatch_checker.h"
#include "base/memory/weak_ptr.h"
#include "base/template_util.h"
#include "base/tuple.h"
#include "build/build_config.h"

#if defined(OS_WIN)
#include "base/bind_internal_win.h"
#endif

namespace base {
namespace internal {

// See base/callback.h for user documentation.
//
//
// CONCEPTS:
//  Runnable -- A type (really a type class) that has a single Run() method
//              and a RunType typedef that corresponds to the type of Run().
//              A Runnable can declare that it should treated like a method
//              call by including a typedef named IsMethod.  The value of
//              this typedef is NOT inspected, only the existence.  When a
//              Runnable declares itself a method, Bind() will enforce special
//              refcounting + WeakPtr handling semantics for the first
//              parameter which is expected to be an object.
//  Functor -- A copyable type representing something that should be called.
//             All function pointers, Callback<>, and Runnables are functors
//             even if the invocation syntax differs.
//  RunType -- A function type (as opposed to function _pointer_ type) for
//             a Run() function.  Usually just a convenience typedef.
//  (Bound)ArgsType -- A function type that is being (ab)used to store the
//                     types of set of arguments.  The "return" type is always
//                     void here.  We use this hack so that we do not need
//                     a new type name for each arity of type. (eg.,
//                     BindState1, BindState2).  This makes forward
//                     declarations and friending much much easier.
//
// Types:
//  RunnableAdapter<> -- Wraps the various "function" pointer types into an
//                       object that adheres to the Runnable interface.
//  ForceVoidReturn<> -- Helper class for translating function signatures to
//                       equivalent forms with a "void" return type.
//  FunctorTraits<> -- Type traits used determine the correct RunType and
//                     RunnableType for a Functor.  This is where function
//                     signature adapters are applied.
//  MakeRunnable<> -- Takes a Functor and returns an object in the Runnable
//                    type class that represents the underlying Functor.
//                    There are |O(1)| MakeRunnable types.
//  InvokeHelper<> -- Take a Runnable + arguments and actully invokes it.
//                    Handle the differing syntaxes needed for WeakPtr<>
//                    support, and for ignoring return values.  This is separate
//                    from Invoker to avoid creating multiple version of
//                    Invoker<>.
//  Invoker<> -- Unwraps the curried parameters and executes the Runnable.
//  BindState<> -- Stores the curried parameters, and is the main entry point
//                 into the Bind() system, doing most of the type resolution.
//                 There are ARITY BindState types.

// HasNonConstReferenceParam selects true_type when any of the parameters in
// |Sig| is a non-const reference.
// Implementation note: This non-specialized case handles zero-arity case only.
// Non-zero-arity cases should be handled by the specialization below.
template <typename Sig>
struct HasNonConstReferenceParam : false_type {};

// Implementation note: Select true_type if the first parameter is a non-const
// reference.  Otherwise, skip the first parameter and check rest of parameters
// recursively.
template <typename R, typename T, typename... Args>
struct HasNonConstReferenceParam<R(T, Args...)>
    : SelectType<is_non_const_reference<T>::value,
                 true_type,
                 HasNonConstReferenceParam<R(Args...)>>::Type {};

// HasRefCountedTypeAsRawPtr selects true_type when any of the |Args| is a raw
// pointer to a RefCounted type.
// Implementation note: This non-specialized case handles zero-arity case only.
// Non-zero-arity cases should be handled by the specialization below.
template <typename... Args>
struct HasRefCountedTypeAsRawPtr : false_type {};

// Implementation note: Select true_type if the first parameter is a raw pointer
// to a RefCounted type. Otherwise, skip the first parameter and check rest of
// parameters recursively.
template <typename T, typename... Args>
struct HasRefCountedTypeAsRawPtr<T, Args...>
    : SelectType<NeedsScopedRefptrButGetsRawPtr<T>::value,
                 true_type,
                 HasRefCountedTypeAsRawPtr<Args...>>::Type {};

// BindsArrayToFirstArg selects true_type when |is_method| is true and the first
// item of |Args| is an array type.
// Implementation note: This non-specialized case handles !is_method case and
// zero-arity case only.  Other cases should be handled by the specialization
// below.
template <bool is_method, typename... Args>
struct BindsArrayToFirstArg : false_type {};

template <typename T, typename... Args>
struct BindsArrayToFirstArg<true, T, Args...> : is_array<T> {};

// HasRefCountedParamAsRawPtr is the same to HasRefCountedTypeAsRawPtr except
// when |is_method| is true HasRefCountedParamAsRawPtr skips the first argument.
// Implementation note: This non-specialized case handles !is_method case and
// zero-arity case only.  Other cases should be handled by the specialization
// below.
template <bool is_method, typename... Args>
struct HasRefCountedParamAsRawPtr : HasRefCountedTypeAsRawPtr<Args...> {};

template <typename T, typename... Args>
struct HasRefCountedParamAsRawPtr<true, T, Args...>
    : HasRefCountedTypeAsRawPtr<Args...> {};

// RunnableAdapter<>
//
// The RunnableAdapter<> templates provide a uniform interface for invoking
// a function pointer, method pointer, or const method pointer. The adapter
// exposes a Run() method with an appropriate signature. Using this wrapper
// allows for writing code that supports all three pointer types without
// undue repetition.  Without it, a lot of code would need to be repeated 3
// times.
//
// For method pointers and const method pointers the first argument to Run()
// is considered to be the received of the method.  This is similar to STL's
// mem_fun().
//
// This class also exposes a RunType typedef that is the function type of the
// Run() function.
//
// If and only if the wrapper contains a method or const method pointer, an
// IsMethod typedef is exposed.  The existence of this typedef (NOT the value)
// marks that the wrapper should be considered a method wrapper.

template <typename Functor>
class RunnableAdapter;

// Function.
template <typename R, typename... Args>
class RunnableAdapter<R(*)(Args...)> {
 public:
  typedef R (RunType)(Args...);

  explicit RunnableAdapter(R(*function)(Args...))
      : function_(function) {
  }

  R Run(typename CallbackParamTraits<Args>::ForwardType... args) {
    return function_(CallbackForward(args)...);
  }

 private:
  R (*function_)(Args...);
};

// Method.
template <typename R, typename T, typename... Args>
class RunnableAdapter<R(T::*)(Args...)> {
 public:
  typedef R (RunType)(T*, Args...);
  typedef true_type IsMethod;

  explicit RunnableAdapter(R(T::*method)(Args...))
      : method_(method) {
  }

  R Run(T* object, typename CallbackParamTraits<Args>::ForwardType... args) {
    return (object->*method_)(CallbackForward(args)...);
  }

 private:
  R (T::*method_)(Args...);
};

// Const Method.
template <typename R, typename T, typename... Args>
class RunnableAdapter<R(T::*)(Args...) const> {
 public:
  typedef R (RunType)(const T*, Args...);
  typedef true_type IsMethod;

  explicit RunnableAdapter(R(T::*method)(Args...) const)
      : method_(method) {
  }

  R Run(const T* object,
        typename CallbackParamTraits<Args>::ForwardType... args) {
    return (object->*method_)(CallbackForward(args)...);
  }

 private:
  R (T::*method_)(Args...) const;
};


// ForceVoidReturn<>
//
// Set of templates that support forcing the function return type to void.
template <typename Sig>
struct ForceVoidReturn;

template <typename R, typename... Args>
struct ForceVoidReturn<R(Args...)> {
  typedef void(RunType)(Args...);
};


// FunctorTraits<>
//
// See description at top of file.
template <typename T>
struct FunctorTraits {
  typedef RunnableAdapter<T> RunnableType;
  typedef typename RunnableType::RunType RunType;
};

template <typename T>
struct FunctorTraits<IgnoreResultHelper<T>> {
  typedef typename FunctorTraits<T>::RunnableType RunnableType;
  typedef typename ForceVoidReturn<
      typename RunnableType::RunType>::RunType RunType;
};

template <typename T>
struct FunctorTraits<Callback<T>> {
  typedef Callback<T> RunnableType;
  typedef typename Callback<T>::RunType RunType;
};


// MakeRunnable<>
//
// Converts a passed in functor to a RunnableType using type inference.

template <typename T>
typename FunctorTraits<T>::RunnableType MakeRunnable(const T& t) {
  return RunnableAdapter<T>(t);
}

template <typename T>
typename FunctorTraits<T>::RunnableType
MakeRunnable(const IgnoreResultHelper<T>& t) {
  return MakeRunnable(t.functor_);
}

template <typename T>
const typename FunctorTraits<Callback<T>>::RunnableType&
MakeRunnable(const Callback<T>& t) {
  DCHECK(!t.is_null());
  return t;
}


// InvokeHelper<>
//
// There are 3 logical InvokeHelper<> specializations: normal, void-return,
// WeakCalls.
//
// The normal type just calls the underlying runnable.
//
// We need a InvokeHelper to handle void return types in order to support
// IgnoreResult().  Normally, if the Runnable's RunType had a void return,
// the template system would just accept "return functor.Run()" ignoring
// the fact that a void function is being used with return. This piece of
// sugar breaks though when the Runnable's RunType is not void.  Thus, we
// need a partial specialization to change the syntax to drop the "return"
// from the invocation call.
//
// WeakCalls similarly need special syntax that is applied to the first
// argument to check if they should no-op themselves.
template <bool IsWeakCall, typename ReturnType, typename Runnable,
          typename ArgsType>
struct InvokeHelper;

template <typename ReturnType, typename Runnable, typename... Args>
struct InvokeHelper<false, ReturnType, Runnable, TypeList<Args...>> {
  static ReturnType MakeItSo(Runnable runnable, Args... args) {
    return runnable.Run(CallbackForward(args)...);
  }
};

template <typename Runnable, typename... Args>
struct InvokeHelper<false, void, Runnable, TypeList<Args...>> {
  static void MakeItSo(Runnable runnable, Args... args) {
    runnable.Run(CallbackForward(args)...);
  }
};

template <typename Runnable, typename BoundWeakPtr, typename... Args>
struct InvokeHelper<true, void, Runnable, TypeList<BoundWeakPtr, Args...>> {
  static void MakeItSo(Runnable runnable, BoundWeakPtr weak_ptr, Args... args) {
    if (!weak_ptr.get()) {
      return;
    }
    runnable.Run(weak_ptr.get(), CallbackForward(args)...);
  }
};

#if !defined(_MSC_VER)

template <typename ReturnType, typename Runnable, typename ArgsType>
struct InvokeHelper<true, ReturnType, Runnable, ArgsType> {
  // WeakCalls are only supported for functions with a void return type.
  // Otherwise, the function result would be undefined if the the WeakPtr<>
  // is invalidated.
  COMPILE_ASSERT(is_void<ReturnType>::value,
                 weak_ptrs_can_only_bind_to_methods_without_return_values);
};

#endif

// Invoker<>
//
// See description at the top of the file.
template <typename BoundIndices,
          typename StorageType, typename Unwrappers,
          typename InvokeHelperType, typename UnboundForwardRunType>
struct Invoker;

template <size_t... bound_indices,
          typename StorageType,
          typename... Unwrappers,
          typename InvokeHelperType,
          typename R,
          typename... UnboundForwardArgs>
struct Invoker<IndexSequence<bound_indices...>,
               StorageType, TypeList<Unwrappers...>,
               InvokeHelperType, R(UnboundForwardArgs...)> {
  static R Run(BindStateBase* base,
               UnboundForwardArgs... unbound_args) {
    StorageType* storage = static_cast<StorageType*>(base);
    // Local references to make debugger stepping easier. If in a debugger,
    // you really want to warp ahead and step through the
    // InvokeHelper<>::MakeItSo() call below.
    return InvokeHelperType::MakeItSo(
        storage->runnable_,
        Unwrappers::Unwrap(get<bound_indices>(storage->bound_args_))...,
        CallbackForward(unbound_args)...);
  }
};


// BindState<>
//
// This stores all the state passed into Bind() and is also where most
// of the template resolution magic occurs.
//
// Runnable is the functor we are binding arguments to.
// RunType is type of the Run() function that the Invoker<> should use.
// Normally, this is the same as the RunType of the Runnable, but it can
// be different if an adapter like IgnoreResult() has been used.
//
// BoundArgsType contains the storage type for all the bound arguments by
// (ab)using a function type.
template <typename Runnable, typename RunType, typename BoundArgList>
struct BindState;

template <typename Runnable,
          typename R,
          typename... Args,
          typename... BoundArgs>
struct BindState<Runnable, R(Args...), TypeList<BoundArgs...>> final
    : public BindStateBase {
 private:
  using StorageType = BindState<Runnable, R(Args...), TypeList<BoundArgs...>>;
  using RunnableType = Runnable;

  // true_type if Runnable is a method invocation and the first bound argument
  // is a WeakPtr.
  using IsWeakCall =
      IsWeakMethod<HasIsMethodTag<Runnable>::value, BoundArgs...>;

  using BoundIndices = MakeIndexSequence<sizeof...(BoundArgs)>;
  using Unwrappers = TypeList<UnwrapTraits<BoundArgs>...>;
  using UnboundForwardArgs = DropTypeListItem<
      sizeof...(BoundArgs),
      TypeList<typename CallbackParamTraits<Args>::ForwardType...>>;
  using UnboundForwardRunType = MakeFunctionType<R, UnboundForwardArgs>;

  using InvokeHelperArgs = ConcatTypeLists<
      TypeList<typename UnwrapTraits<BoundArgs>::ForwardType...>,
      UnboundForwardArgs>;
  using InvokeHelperType =
      InvokeHelper<IsWeakCall::value, R, Runnable, InvokeHelperArgs>;

  using UnboundArgs = DropTypeListItem<sizeof...(BoundArgs), TypeList<Args...>>;

 public:
  using InvokerType = Invoker<BoundIndices, StorageType, Unwrappers,
                              InvokeHelperType, UnboundForwardRunType>;
  using UnboundRunType = MakeFunctionType<R, UnboundArgs>;

  BindState(const Runnable& runnable, const BoundArgs&... bound_args)
      : BindStateBase(&Destroy),
        runnable_(runnable),
        ref_(bound_args...),
        bound_args_(bound_args...) {}

  RunnableType runnable_;
  MaybeScopedRefPtr<HasIsMethodTag<Runnable>::value, BoundArgs...> ref_;
  Tuple<BoundArgs...> bound_args_;

 private:
  ~BindState() {}

  static void Destroy(BindStateBase* self) {
    delete static_cast<BindState*>(self);
  }
};

}  // namespace internal
}  // namespace base

#endif  // BASE_BIND_INTERNAL_H_
