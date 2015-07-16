// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_FILTER_CHAIN_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_FILTER_CHAIN_H_

#include <vector>

#include "mojo/public/cpp/bindings/message.h"
#include "mojo/public/cpp/bindings/message_filter.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace internal {

class FilterChain {
  MOJO_MOVE_ONLY_TYPE(FilterChain)

 public:
  // Doesn't take ownership of |sink|. Therefore |sink| has to stay alive while
  // this object is alive.
  explicit FilterChain(MessageReceiver* sink = nullptr);

  FilterChain(FilterChain&& other);
  FilterChain& operator=(FilterChain&& other);
  ~FilterChain();

  template <typename FilterType>
  inline void Append();

  // Doesn't take ownership of |sink|. Therefore |sink| has to stay alive while
  // this object is alive.
  void SetSink(MessageReceiver* sink);

  // Returns a receiver to accept messages. Messages flow through all filters in
  // the same order as they were appended to the chain. If all filters allow a
  // message to pass, it will be forwarded to |sink_|.
  // The returned value is invalidated when this object goes away.
  MessageReceiver* GetHead();

 private:
  // Owned by this object.
  std::vector<MessageFilter*> filters_;

  MessageReceiver* sink_;
};

template <typename FilterType>
inline void FilterChain::Append() {
  FilterType* filter = new FilterType(sink_);
  if (!filters_.empty())
    filters_.back()->set_sink(filter);
  filters_.push_back(filter);
}

template <>
inline void FilterChain::Append<PassThroughFilter>() {
}

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_FILTER_CHAIN_H_
