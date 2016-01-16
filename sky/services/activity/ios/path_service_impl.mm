// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/activity/ios/path_service_impl.h"

#include <Foundation/Foundation.h>
#include <string>

namespace sky {
namespace services {
namespace path {

PathServiceImpl::PathServiceImpl(
    mojo::InterfaceRequest<activity::PathService> request)
    : binding_(this, request.Pass()) {}

PathServiceImpl::~PathServiceImpl() {}

static std::string GetDirectoryOfType(NSSearchPathDirectory dir) {
  @autoreleasepool {
    NSArray* paths =
        NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);

    if (paths.count == 0) {
      return "";
    }

    return [paths.firstObject UTF8String];
  }
}

void PathServiceImpl::GetAppDataDir(const GetAppDataDirCallback& callback) {
  mojo::String directory(GetDirectoryOfType(NSDocumentDirectory));
  callback.Run(directory);
}

void PathServiceImpl::GetFilesDir(const GetFilesDirCallback& callback) {
  @autoreleasepool {
    mojo::String directory([[NSBundle mainBundle] bundlePath].UTF8String);
    callback.Run(directory);
  }
}

void PathServiceImpl::GetCacheDir(const GetCacheDirCallback& callback) {
  mojo::String directory(GetDirectoryOfType(NSCachesDirectory));
  callback.Run(directory);
}

void PathServiceFactory::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<activity::PathService> request) {
  new PathServiceImpl(request.Pass());
}

}  // namespace path
}  // namespace services
}  // namespace sky
