// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_ARGS_H_
#define SKY_ENGINE_TONIC_DART_ARGS_H_

#include <type_traits>

#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "dart/runtime/include/dart_api.h"

namespace blink {

class DartArgIterator {
 public:
  explicit DartArgIterator(Dart_NativeArguments args)
      : args_(args), index_(1), had_exception_(false) { }

  template<typename T>
  T GetNext() {
    if (had_exception_)
      return T();
    Dart_Handle exception = nullptr;
    T arg = DartConverter<T>::FromArguments(args_, index_++, exception);
    if (exception) {
      had_exception_ = true;
      Dart_ThrowException(exception);
    }
    return arg;
  }

  bool had_exception() const { return had_exception_; }

  Dart_NativeArguments args() const { return args_; }

 private:
  Dart_NativeArguments args_;
  int index_;
  bool had_exception_;

  DISALLOW_COPY_AND_ASSIGN(DartArgIterator);
};

// Classes for generating and storing an argument pack of integer indices
// (based on well-known "indices trick", see: http://goo.gl/bKKojn):
template <size_t... indices>
struct IndicesHolder {};

template <size_t requested_index, size_t... indices>
struct IndicesGenerator {
  using type = typename IndicesGenerator<requested_index - 1,
                                         requested_index - 1,
                                         indices...>::type;
};

template <size_t... indices>
struct IndicesGenerator<0, indices...> {
  using type = IndicesHolder<indices...>;
};

template <typename T>
class IndicesForSignature {};

template <typename ResultType,
          typename... ArgTypes>
struct IndicesForSignature<ResultType (*)(ArgTypes...)> {
  using type = typename IndicesGenerator<sizeof...(ArgTypes)>::type;
};

template <typename C,
          typename ResultType,
          typename... ArgTypes>
struct IndicesForSignature<ResultType (C::*)(ArgTypes...)> {
  using type = typename IndicesGenerator<sizeof...(ArgTypes)>::type;
};

template<size_t index, typename ArgType>
struct DartArgHolder {
  using ValueType = typename std::remove_const<
    typename std::remove_reference<ArgType>::type
  >::type;

  ValueType value;

  explicit DartArgHolder(DartArgIterator* it)
      : value(it->GetNext<ValueType>()) {}
};

template <typename IndicesType, typename T>
class DartDecoder {
};

template <size_t... indices,
          typename ResultType,
          typename... ArgTypes>
struct DartDecoder<IndicesHolder<indices...>, ResultType (*)(ArgTypes...)>
    : public DartArgHolder<indices, ArgTypes>... {
  using FunctionPtr = ResultType (*)(ArgTypes...);

  DartArgIterator* it_;

  explicit DartDecoder(DartArgIterator* it)
      : DartArgHolder<indices, ArgTypes>(it)..., it_(it) { }

  ResultType Dispatch(FunctionPtr func) {
    return (*func)(DartArgHolder<indices, ArgTypes>::value...);
  }
};

template <size_t... indices,
          typename C,
          typename ResultType,
          typename... ArgTypes>
struct DartDecoder<IndicesHolder<indices...>, ResultType (C::*)(ArgTypes...)>
    : public DartArgHolder<indices, ArgTypes>... {
  using FunctionPtr = ResultType (C::*)(ArgTypes...);

  DartArgIterator* it_;

  explicit DartDecoder(DartArgIterator* it)
      : DartArgHolder<indices, ArgTypes>(it)..., it_(it) { }

  ResultType Dispatch(FunctionPtr func) {
    return (GetReceiver<C>(it_->args())->*func)(
        DartArgHolder<indices, ArgTypes>::value...);
  }
};

template<typename T>
void DartReturn(T result, Dart_NativeArguments args) {
  DartConverter<T>::SetReturnValue(args, result);
}

template<typename Sig>
void DartCall(Sig func, Dart_NativeArguments args) {
  DartArgIterator it(args);
  using Indices = typename IndicesForSignature<Sig>::type;
  DartDecoder<Indices, Sig> decoder(&it);
  if (it.had_exception())
    return;
  decoder.Dispatch(func);
}

template<typename Sig>
void DartCallAndReturn(Sig func, Dart_NativeArguments args) {
  DartArgIterator it(args);
  using Indices = typename IndicesForSignature<Sig>::type;
  DartDecoder<Indices, Sig> decoder(&it);
  if (it.had_exception())
    return;
  DartReturn(decoder.Dispatch(func), args);
}

template<typename Sig>
void DartCallConstructor(Sig func, Dart_NativeArguments args) {
  DartArgIterator it(args);
  using Indices = typename IndicesForSignature<Sig>::type;
  DartDecoder<Indices, Sig> decoder(&it);
  if (it.had_exception())
    return;
  decoder.Dispatch(func)->AssociateWithDartWrapper(args);
}

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_ARGS_H_
