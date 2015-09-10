// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UPDATER_UPDATE_TASK_H_
#define SKY_SHELL_UPDATER_UPDATE_TASK_H_

#include <jni.h>

#include "base/files/file_path.h"
#include "base/memory/scoped_ptr.h"
#include "base/task_runner.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"
#include "url/gurl.h"

namespace sky {
namespace shell {

struct Manifest;

// This class manages a single update check. The flow is:
// 1. Read the current manifest from disk.
// 2. Fetch a new manifest served at the update URL specified in our manifest.
// 3. Compare versions. If the remote one is newer, continue.
// 4. Download the new app bundle and replace the current one with it.
class UpdateTask {
 public:
  UpdateTask(const std::string& data_dir);
  virtual ~UpdateTask();

  void Start();
  virtual void Finish() = 0;

 private:
  void OnReadLocalManifest(scoped_ptr<Manifest> manifest);
  void DownloadManifest(const GURL& url);
  void OnManifestResponse(mojo::URLResponsePtr response);
  void OnManifestDownloaded(scoped_ptr<Manifest> manifest);
  void DownloadAppBundle(const GURL& url);
  void OnResponse(mojo::URLResponsePtr response);
  void OnCopied(bool success);
  void CallOnFinished();

  // Note: All methods are called on the main thread. The worker runner is for
  // background helper functions only.
  scoped_refptr<base::TaskRunner> worker_runner_;
  scoped_refptr<base::TaskRunner> main_runner_;
  mojo::NetworkServicePtr network_service_;
  mojo::URLLoaderPtr url_loader_;
  scoped_ptr<Manifest> current_manifest_;
  base::FilePath data_dir_;
  base::FilePath temp_path_;
};

bool RegisterUpdateService(JNIEnv* env);

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UPDATER_UPDATE_TASK_H_
