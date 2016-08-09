// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_UNZIP_JOB_H_
#define FLUTTER_ASSETS_UNZIP_JOB_H_

#include <map>
#include <vector>

#include "flutter/assets/unique_unzipper.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/ref_counted.h"
#include "lib/ftl/tasks/task_runner.h"
#include "mojo/public/cpp/environment/async_waiter.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"

namespace blink {

class UnzipJob {
 public:
  UnzipJob(std::string zip_path,
           std::string asset_name,
           mojo::ScopedDataPipeProducerHandle producer,
           ftl::RefPtr<ftl::TaskRunner> task_runner);
  ~UnzipJob();

 private:
  void Start();
  void OnHandleReady(MojoResult result);
  static void WaitComplete(void* context, MojoResult result);

  const std::string zip_path_;
  const std::string asset_name_;
  mojo::ScopedDataPipeProducerHandle producer_;
  ftl::RefPtr<ftl::TaskRunner> task_runner_;
  UniqueUnzipper zip_file_;

  const MojoAsyncWaiter* waiter_;
  MojoAsyncWaitID wait_id_;

  FTL_DISALLOW_COPY_AND_ASSIGN(UnzipJob);
};

}  // namespace blink

#endif  // FLUTTER_ASSETS_UNZIP_JOB_H_
