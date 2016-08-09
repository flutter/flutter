// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/handle.h"

#include <utility>

#include "mojo/edk/system/dispatcher.h"

using mojo::util::RefPtr;

namespace mojo {
namespace system {

Handle::Handle() : rights(MOJO_HANDLE_RIGHT_NONE) {}

Handle::Handle(const Handle&) = default;

Handle::Handle(Handle&&) = default;

Handle::Handle(RefPtr<Dispatcher>&& dispatcher, MojoHandleRights rights)
    : dispatcher(std::move(dispatcher)), rights(rights) {}

Handle::~Handle() {}

Handle& Handle::operator=(const Handle&) = default;

Handle& Handle::operator=(Handle&&) = default;

}  // namespace system
}  // namespace mojo
