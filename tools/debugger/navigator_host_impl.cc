// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/debugger/navigator_host_impl.h"

#include "sky/tools/debugger/debugger.h"

namespace sky {
namespace debugger {

NavigatorHostImpl::NavigatorHostImpl(SkyDebugger* debugger)
    : debugger_(debugger->GetWeakPtr()) {
}

NavigatorHostImpl::~NavigatorHostImpl() {
}

void NavigatorHostImpl::DidNavigateLocally(const mojo::String& url) {
  // TODO(abarth): Do something interesting.
}

void NavigatorHostImpl::RequestNavigate(mojo::Target target,
                                        mojo::URLRequestPtr request) {
  if (!debugger_)
    return;
  debugger_->NavigateToURL(request->url);
}

}  // namespace debugger
}  // namespace sky
