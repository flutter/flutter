// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/platform/ios/url_launcher_impl.h"
#include "base/mac/scoped_nsautorelease_pool.h"

#include <UIKit/UIKit.h>

namespace flutter {
namespace platform {

URLLauncherImpl::URLLauncherImpl(mojo::InterfaceRequest<URLLauncher> request)
    : binding_(this, request.Pass()) {}

URLLauncherImpl::~URLLauncherImpl() {}

void URLLauncherImpl::Launch(const mojo::String& urlString,
                             const LaunchCallback& callback) {
  base::mac::ScopedNSAutoreleasePool pool;

  NSURL* url = [NSURL URLWithString:@(urlString.data())];

  UIApplication* application = [UIApplication sharedApplication];

  return callback.Run([application canOpenURL:url] &&
                      [application openURL:url]);
}

}  // namespace platform
}  // namespace flutter
