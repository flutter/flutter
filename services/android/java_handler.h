// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_ANDROID_JAVA_HANDLER_H_
#define SERVICES_ANDROID_JAVA_HANDLER_H_

#include <jni.h>

#include "base/files/file_path.h"
#include "base/single_thread_task_runner.h"
#include "mojo/application/content_handler_factory.h"
#include "mojo/common/tracing_impl.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "mojo/services/content_handler/public/interfaces/content_handler.mojom.h"
#include "mojo/services/url_response_disk_cache/public/interfaces/url_response_disk_cache.mojom.h"

namespace services {
namespace android {

class JavaHandler : public mojo::ApplicationDelegate,
                    public mojo::ContentHandlerFactory::Delegate {
 public:
  JavaHandler();
  ~JavaHandler();

 private:
  // ApplicationDelegate:
  void Initialize(mojo::ApplicationImpl* app) override;
  bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override;

  // ContentHandlerFactory::Delegate:
  void RunApplication(
      mojo::InterfaceRequest<mojo::Application> application_request,
      mojo::URLResponsePtr response) override;

  void GetApplication(base::FilePath* archive_path,
                      base::FilePath* cache_dir,
                      mojo::URLResponsePtr response,
                      const base::Closure& callback);

  mojo::TracingImpl tracing_;
  mojo::ContentHandlerFactory content_handler_factory_;
  mojo::URLResponseDiskCachePtr url_response_disk_cache_;
  scoped_refptr<base::SingleThreadTaskRunner> handler_task_runner_;
  MOJO_DISALLOW_COPY_AND_ASSIGN(JavaHandler);
};

}  // namespace android
}  // namespace services

#endif  // SERVICES_ANDROID_JAVA_HANDLER_H_
