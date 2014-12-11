// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_DEBUGGER_NAVIGATOR_HOST_IMPL_H_
#define SKY_TOOLS_DEBUGGER_NAVIGATOR_HOST_IMPL_H_

#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "mojo/services/navigation/public/interfaces/navigation.mojom.h"
#include "sky/tools/debugger/debugger.mojom.h"

namespace sky {
namespace debugger {
class SkyDebugger;

class NavigatorHostImpl : public mojo::InterfaceImpl<mojo::NavigatorHost> {
 public:
  explicit NavigatorHostImpl(SkyDebugger*);
  ~NavigatorHostImpl();

 private:
  void DidNavigateLocally(const mojo::String& url) override;
  void RequestNavigate(mojo::Target target, mojo::URLRequestPtr request) override;

  base::WeakPtr<SkyDebugger> debugger_;

  DISALLOW_COPY_AND_ASSIGN(NavigatorHostImpl);
};

typedef mojo::InterfaceFactoryImplWithContext<
    NavigatorHostImpl, SkyDebugger> NavigatorHostFactory;

}  // namespace debugger
}  // namespace sky

#endif  // SKY_TOOLS_DEBUGGER_NAVIGATOR_HOST_IMPL_H_
