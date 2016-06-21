// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/awakable_list.h"

#include <algorithm>

#include "base/logging.h"
#include "mojo/edk/system/awakable.h"
#include "mojo/edk/system/handle_signals_state.h"

namespace mojo {
namespace system {

AwakableList::AwakableList() {
}

AwakableList::~AwakableList() {
  DCHECK(awakables_.empty());
}

void AwakableList::AwakeForStateChange(const HandleSignalsState& state) {
  // Instead of deleting elements in-place, swap them with the last element and
  // erase the elements from the end.
  auto last = awakables_.end();
  for (AwakeInfoList::iterator it = awakables_.begin(); it != last;) {
    bool keep = true;
    if (state.satisfies(it->signals))
      keep = it->awakable->Awake(MOJO_RESULT_OK, it->context);
    else if (!state.can_satisfy(it->signals))
      keep = it->awakable->Awake(MOJO_RESULT_FAILED_PRECONDITION, it->context);

    if (!keep) {
      --last;
      std::swap(*it, *last);
    } else {
      ++it;
    }
  }
  awakables_.erase(last, awakables_.end());
}

void AwakableList::CancelAll() {
  for (AwakeInfoList::iterator it = awakables_.begin(); it != awakables_.end();
       ++it) {
    it->awakable->Awake(MOJO_RESULT_CANCELLED, it->context);
  }
  awakables_.clear();
}

void AwakableList::Add(Awakable* awakable,
                       MojoHandleSignals signals,
                       uint64_t context) {
  awakables_.push_back(AwakeInfo(awakable, signals, context));
}

void AwakableList::Remove(Awakable* awakable) {
  // We allow a thread to wait on the same handle multiple times simultaneously,
  // so we need to scan the entire list and remove all occurrences of |waiter|.
  auto last = awakables_.end();
  for (AwakeInfoList::iterator it = awakables_.begin(); it != last;) {
    if (it->awakable == awakable) {
      --last;
      std::swap(*it, *last);
    } else {
      ++it;
    }
  }
  awakables_.erase(last, awakables_.end());
}

}  // namespace system
}  // namespace mojo
