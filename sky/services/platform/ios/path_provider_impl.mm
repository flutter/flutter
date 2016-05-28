// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/platform/ios/path_provider_impl.h"
#include "base/mac/scoped_nsautorelease_pool.h"

#include <Foundation/Foundation.h>

#include <string>

namespace flutter {
namespace platform {

PathProviderImpl::PathProviderImpl(mojo::InterfaceRequest<PathProvider> request)
    : binding_(this, request.Pass()) {}

PathProviderImpl::~PathProviderImpl() {}

static std::string GetDirectoryOfType(NSSearchPathDirectory dir) {
  base::mac::ScopedNSAutoreleasePool pool;
  NSArray* paths =
      NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);

  if (paths.count == 0) {
    return "";
  }

  return [paths.firstObject UTF8String];
}

void PathProviderImpl::TemporaryDirectory(
    const TemporaryDirectoryCallback& callback) {
  callback.Run(GetDirectoryOfType(NSCachesDirectory));
}

void PathProviderImpl::ApplicationDocumentsDirectory(
    const ApplicationDocumentsDirectoryCallback& callback) {
  callback.Run(GetDirectoryOfType(NSDocumentDirectory));
}

}  // namespace platform
}  // namespace flutter
