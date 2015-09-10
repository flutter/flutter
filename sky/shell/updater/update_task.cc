// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/updater/update_task.h"

#include "base/bind.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/task_runner_util.h"
#include "base/threading/worker_pool.h"
#include "mojo/data_pipe_utils/data_pipe_utils.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"
#include "sky/shell/shell.h"
#include "sky/shell/updater/manifest.h"

namespace sky {
namespace shell {

namespace {

const char kManifestFilename[] = "sky.yaml";
const char kAppBundleFilename[] = "app.skyx";

// TODO(mpcomplete): make this a utility method?
static mojo::URLLoaderPtr FetchURL(
    mojo::NetworkService* network_service,
    const GURL& url,
    base::Callback<void(mojo::URLResponsePtr)> callback) {
  mojo::URLLoaderPtr loader;
  network_service->CreateURLLoader(GetProxy(&loader));

  mojo::URLRequestPtr request = mojo::URLRequest::New();
  request->url = url.spec();
  request->auto_follow_redirects = true;
  loader->Start(request.Pass(), callback);

  return loader.Pass();
}

static scoped_ptr<Manifest> ReadManifestFromFile(const base::FilePath& path) {
  std::string manifest_data;
  base::ReadFileToString(path, &manifest_data);
  return Manifest::Parse(manifest_data);
}

static scoped_ptr<Manifest> ReadManifestFromDataPipe(
    mojo::ScopedDataPipeConsumerHandle source) {
  std::string manifest_data;
  mojo::common::BlockingCopyToString(source.Pass(), &manifest_data);
  return Manifest::Parse(manifest_data);
}

}  // namespace

UpdateTask::UpdateTask(const std::string& data_dir)
    : worker_runner_(base::WorkerPool::GetTaskRunner(true)),
      main_runner_(base::MessageLoop::current()->task_runner()),
      data_dir_(data_dir) {
  mojo::ServiceProviderPtr service_provider =
      CreateServiceProvider(Shell::Shared().service_provider_context());
  mojo::ConnectToService(service_provider.get(), &network_service_);
}

UpdateTask::~UpdateTask() {
}

void UpdateTask::Start() {
  base::FilePath manifest_path = data_dir_.AppendASCII(kManifestFilename);
  base::PostTaskAndReplyWithResult(
      worker_runner_.get(),
      FROM_HERE,
      base::Bind(&ReadManifestFromFile, manifest_path),
      base::Bind(&UpdateTask::OnReadLocalManifest, base::Unretained(this)));
}

void UpdateTask::OnReadLocalManifest(scoped_ptr<Manifest> manifest) {
  if (!manifest->IsValid()) {
    LOG(ERROR) << "Update failed reading local manifest: invalid.";
    Finish();
    return;
  }
  current_manifest_ = manifest.Pass();
  DownloadManifest(current_manifest_->update_url().Resolve(kManifestFilename));
}

void UpdateTask::DownloadManifest(const GURL& url) {
  url_loader_ = FetchURL(
      network_service_.get(), url,
      base::Bind(&UpdateTask::OnManifestResponse, base::Unretained(this)));
}

void UpdateTask::OnManifestResponse(mojo::URLResponsePtr response) {
  mojo::ScopedDataPipeConsumerHandle data;
  if (response->status_code == 200)
    data = response->body.Pass();
  if (!data.is_valid()) {
    LOG(ERROR) << "Update failed fetching manifest: Server responded "
               << response->status_code;
    Finish();
    return;
  }

  base::PostTaskAndReplyWithResult(
      worker_runner_.get(),
      FROM_HERE,
      base::Bind(&ReadManifestFromDataPipe, base::Passed(&data)),
      base::Bind(&UpdateTask::OnManifestDownloaded, base::Unretained(this)));
}

void UpdateTask::OnManifestDownloaded(scoped_ptr<Manifest> manifest) {
  if (!manifest->IsValid()) {
    LOG(ERROR) << "Update failed reading remote manifest: invalid.";
    Finish();
    return;
  }

  // TODO(mpcomplete): verify it's from the same publisher. (public key check)
  bool update_available =
      manifest->version().CompareTo(current_manifest_->version()) > 0;
  if (!update_available) {
    LOG(INFO) << "Update cancelled. No new version.";
    Finish();
    return;
  }

  // TODO(mpcomplete): replace local manifest with the one inside the bundle.
  // TODO(mpcomplete): check versions again after downloading bundle.
  DownloadAppBundle(manifest->update_url().Resolve(kAppBundleFilename));
}

void UpdateTask::DownloadAppBundle(const GURL& url) {
  if (!base::CreateTemporaryFile(&temp_path_)) {
    LOG(ERROR) << "Update failed when creating temp file.";
    Finish();
    return;
  }

  url_loader_ =
      FetchURL(network_service_.get(), url,
               base::Bind(&UpdateTask::OnResponse, base::Unretained(this)));
}

void UpdateTask::OnResponse(mojo::URLResponsePtr response) {
  mojo::ScopedDataPipeConsumerHandle data;
  if (response->status_code == 200)
    data = response->body.Pass();
  if (!data.is_valid()) {
    LOG(ERROR) << "Update failed: Server responded " << response->status_code;
    Finish();
    return;
  }

  mojo::common::CopyToFile(
      data.Pass(), temp_path_, worker_runner_.get(),
      base::Bind(&UpdateTask::OnCopied, base::Unretained(this)));
}

void UpdateTask::OnCopied(bool success) {
  int64 size = 0;
  GetFileSize(temp_path_, &size);

  // This assumes temp files are created on the same volume as the data_dir.
  // TODO(mpcomplete): only replace on next startup. Otherwise, a currently
  // running version of the app will get confused.
  base::FilePath final_path = data_dir_.AppendASCII(kAppBundleFilename);
  bool rv = base::ReplaceFile(temp_path_, final_path, nullptr);
  LOG(INFO) << "Update finished: " << rv << " filesize(" << final_path.value()
            << ")=" << size;

  Finish();
}

}  // namespace shell
}  // namespace sky
