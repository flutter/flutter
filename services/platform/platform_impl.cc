// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/platform/platform_impl.h"

#include "sky/services/platform/net_constants.h"
#include "sky/services/platform/weburlloader_impl.h"

namespace sky {

PlatformImpl::PlatformImpl(mojo::NetworkServicePtr network_service)
    : main_thread_task_runner_(base::MessageLoop::current()->task_runner()) {
  network_service_ = network_service.Pass();
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
  error.domain = blink::WebString::fromUTF8(kNetErrorDomain);
  error.reason = kNetErrorAborted;
  error.unreachableURL = url;
  error.staleCopyInCache = false;
  error.isCancellation = true;
  return error;
}

}  // namespace sky
