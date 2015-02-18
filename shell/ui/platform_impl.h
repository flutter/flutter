// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_PLATFORM_IMPL_H_
#define SKY_SHELL_UI_PLATFORM_IMPL_H_

#include "base/message_loop/message_loop.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"
#include "sky/engine/public/platform/Platform.h"

namespace sky {
namespace shell {

class PlatformImpl : public blink::Platform {
 public:
  explicit PlatformImpl(mojo::ServiceProviderPtr service_provider);
  ~PlatformImpl() override;

  // blink::Platform:
  blink::WebString defaultLocale() override;
  base::SingleThreadTaskRunner* mainThreadTaskRunner() override;
  mojo::NetworkService* networkService() override;

 private:
  scoped_refptr<base::SingleThreadTaskRunner> main_thread_task_runner_;
  mojo::ServiceProviderPtr service_provider_;
  mojo::NetworkServicePtr network_service_;

  DISALLOW_COPY_AND_ASSIGN(PlatformImpl);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_PLATFORM_IMPL_H_
