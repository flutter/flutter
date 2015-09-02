// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UPDATE_SERVICE_H_
#define SKY_SHELL_UPDATE_SERVICE_H_

#include <jni.h>

#include "base/android/jni_string.h"
#include "base/files/file_path.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"

namespace sky {
namespace shell {

class UpdateTask {
 public:
  UpdateTask(JNIEnv* env, jobject update_service, std::string data_dir);

  void DownloadAppBundle(const std::string& url);
  void Detach(JNIEnv* env, jobject jcaller);

 private:
  void OnResponse(mojo::URLResponsePtr response);
  void OnCopied(bool success);
  void CallOnFinished();

  base::android::ScopedJavaGlobalRef<jobject> update_service_;
  mojo::NetworkServicePtr network_service_;
  base::FilePath temp_path_;
  base::FilePath final_path_;
  mojo::URLLoaderPtr url_loader_;
};

bool RegisterUpdateService(JNIEnv* env);

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UPDATE_SERVICE_H_
