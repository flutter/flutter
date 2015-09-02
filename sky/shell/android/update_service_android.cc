// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/android/update_service_android.h"

#include "base/android/jni_string.h"
#include "base/bind.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/threading/worker_pool.h"
#include "jni/UpdateService_jni.h"
#include "mojo/data_pipe_utils/data_pipe_utils.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {

namespace {

// TODO(mpcomplete): make this a utility method?
static mojo::URLLoaderPtr FetchURL(
    mojo::NetworkService* network_service,
    const std::string& url,
    base::Callback<void(mojo::URLResponsePtr)> callback) {
  mojo::URLLoaderPtr loader;
  network_service->CreateURLLoader(GetProxy(&loader));

  mojo::URLRequestPtr request = mojo::URLRequest::New();
  request->url = url;
  request->auto_follow_redirects = true;
  loader->Start(request.Pass(), callback);

  return loader.Pass();
}

}  // namespace

static jlong CheckForUpdates(JNIEnv* env, jobject jcaller, jstring j_data_dir) {
  std::string data_dir = base::android::ConvertJavaStringToUTF8(env, j_data_dir);
  scoped_ptr<UpdateTask> task(new UpdateTask(env, jcaller, data_dir));

  // TODO(mpcomplete): download a manifest and check the version.
  task->DownloadAppBundle("file://" + data_dir + "/app.skyx");

  return reinterpret_cast<jlong>(task.release());
}

bool RegisterUpdateService(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

UpdateTask::UpdateTask(JNIEnv* env, jobject update_service, std::string data_dir)
    : final_path_(base::FilePath(data_dir).AppendASCII("app.skyx")) {
  update_service_.Reset(env, update_service);

  mojo::ServiceProviderPtr service_provider =
      CreateServiceProvider(Shell::Shared().service_provider_context());
  mojo::ConnectToService(service_provider.get(), &network_service_);
}

void UpdateTask::DownloadAppBundle(const std::string& url) {
  LOG(INFO) << "Update downloading " << url << " to: " << final_path_.value();
  if (!base::CreateTemporaryFile(&temp_path_)) {
    CallOnFinished();
    return;
  }

  url_loader_ =
      FetchURL(network_service_.get(), url,
               base::Bind(&UpdateTask::OnResponse, base::Unretained(this)));
}

void UpdateTask::Detach(JNIEnv* env, jobject jcaller) {
  delete this;
}

void UpdateTask::OnResponse(mojo::URLResponsePtr response) {
  mojo::ScopedDataPipeConsumerHandle data;
  if (response->status_code == 200)
    data = response->body.Pass();
  if (!data.is_valid()) {
    LOG(ERROR) << "Update failed: Server responded " << response->status_code;
    CallOnFinished();
    return;
  }

  scoped_refptr<base::TaskRunner> worker_runner =
      base::WorkerPool::GetTaskRunner(true);
  mojo::common::CopyToFile(
      data.Pass(), temp_path_, worker_runner.get(),
      base::Bind(&UpdateTask::OnCopied, base::Unretained(this)));
}

void UpdateTask::OnCopied(bool success) {
  int64 size = 0;
  GetFileSize(temp_path_, &size);

  // This assumes temp files are created on the same volume as the data_dir.
  // TODO(mpcomplete): only replace on next startup. Otherwise, a currently
  // running version of the app will get confused.
  bool rv = base::ReplaceFile(temp_path_, final_path_, nullptr);
  LOG(INFO) << "Update finished: " << rv << " filesize(" << final_path_.value() << ")=" << size;

  CallOnFinished();
}

void UpdateTask::CallOnFinished() {
  // The Java side is responsible for deleting the UpdateTask when finished.
  Java_UpdateService_onUpdateFinished(base::android::AttachCurrentThread(),
                                      update_service_.obj());
}

}  // namespace shell
}  // namespace sky
