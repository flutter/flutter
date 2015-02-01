// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/platform/platform_impl.h"

#include "mojo/public/cpp/application/application_impl.h"
#include "net/base/net_errors.h"
#include "sky/viewer/platform/weburlloader_impl.h"

namespace sky {

PlatformImpl::PlatformImpl(mojo::ApplicationImpl* app)
    : main_thread_task_runner_(base::MessageLoop::current()->task_runner()) {
  app->ConnectToService("mojo:network_service", &network_service_);
}

PlatformImpl::~PlatformImpl() {
}

blink::WebString PlatformImpl::defaultLocale() {
  return blink::WebString::fromUTF8("en-US");
}

base::SingleThreadTaskRunner* PlatformImpl::mainThreadTaskRunner() {
  return main_thread_task_runner_.get();
}

mojo::NetworkService* PlatformImpl::networkService() {
  return network_service_.get();
}

blink::WebURLLoader* PlatformImpl::createURLLoader() {
  return new WebURLLoaderImpl(network_service_.get());
}

blink::WebURLError PlatformImpl::cancelledError(const blink::WebURL& url)
    const {
  blink::WebURLError error;
  error.domain = blink::WebString::fromUTF8(net::kErrorDomain);
  error.reason = net::ERR_ABORTED;
  error.unreachableURL = url;
  error.staleCopyInCache = false;
  error.isCancellation = true;
  return error;
}

}  // namespace sky
