// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/asset_bundle/zip_asset_bundle.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/task_runner.h"
#include "base/message_loop/message_loop.h"
#include "mojo/data_pipe_utils/data_pipe_utils.h"
#include "third_party/zlib/contrib/minizip/unzip.h"

namespace mojo {
namespace asset_bundle {

namespace {

void Ignored(bool) {
}

}  // namespace

unzFile ScopedUnzFileTraits::InvalidValue() {
  return nullptr;
}

void ScopedUnzFileTraits::Free(unzFile file) {
  unzClose(file);
}

scoped_refptr<ZipAssetBundle> ZipAssetService::Create(
    InterfaceRequest<AssetBundle> request,
    const base::FilePath& zip_path,
    scoped_refptr<base::TaskRunner> worker_runner) {
  scoped_refptr<ZipAssetBundle> zip_asset_bundle(
      new ZipAssetBundle(zip_path, worker_runner.Pass()));

  // Register as a Mojo service.
  new ZipAssetService(request.Pass(), zip_asset_bundle);

  return zip_asset_bundle;
}

ZipAssetService::ZipAssetService(
    InterfaceRequest<AssetBundle> request,
    const scoped_refptr<ZipAssetBundle>& zip_asset_bundle)
    : binding_(this, request.Pass()),
      zip_asset_bundle_(zip_asset_bundle) {
}

ZipAssetService::~ZipAssetService() {
}

void ZipAssetService::GetAsStream(
    const String& asset_name,
    const Callback<void(ScopedDataPipeConsumerHandle)>& callback) {
  zip_asset_bundle_->GetAsStream(asset_name, callback);
}

ZipAssetBundle::ZipAssetBundle(
    const base::FilePath& zip_path,
    scoped_refptr<base::TaskRunner> worker_runner)
    : zip_path_(zip_path),
      worker_runner_(worker_runner.Pass()) {
}

ZipAssetBundle::~ZipAssetBundle() {
}

void ZipAssetBundle::AddOverlayFile(const std::string& asset_name,
                                    const base::FilePath& file_path) {
  overlay_files_.insert(std::make_pair(String(asset_name), file_path));
}

void ZipAssetBundle::GetAsStream(
    const String& asset_name,
    const Callback<void(ScopedDataPipeConsumerHandle)>& callback) {
  DataPipe pipe;
  callback.Run(pipe.consumer_handle.Pass());

  auto overlay = overlay_files_.find(asset_name);
  if (overlay != overlay_files_.end()) {
    common::CopyFromFile(overlay->second,
                         pipe.producer_handle.Pass(),
                         0,
                         worker_runner_.get(),
                         base::Bind(&Ignored));
    return;
  }

  ZipAssetHandler* handler = new ZipAssetHandler(
      zip_path_,
      asset_name.To<std::string>(),
      pipe.producer_handle.Pass(),
      worker_runner_);

  worker_runner_->PostTask(
      FROM_HERE,
      base::Bind(&ZipAssetHandler::Start, base::Unretained(handler)));
}

bool ZipAssetBundle::GetAsBuffer(const std::string& asset_name,
                                 std::vector<uint8_t>* data) {
  ScopedUnzFile zip_file(unzOpen2(zip_path_.AsUTF8Unsafe().c_str(), NULL));
  if (!zip_file.is_valid()) {
    LOG(ERROR) << "Unable to open ZIP file: " << zip_path_.value();
    return false;
  }

  int result = unzLocateFile(zip_file.get(), asset_name.c_str(), 0);
  if (result != UNZ_OK) {
    LOG(WARNING) << "Requested asset '" << asset_name << "' does not exist.";
    return false;
  }

  unz_file_info file_info;
  result = unzGetCurrentFileInfo(zip_file.get(), &file_info, nullptr, 0,
                                 nullptr, 0, nullptr, 0);
  if (result != UNZ_OK) {
    LOG(WARNING) << "unzGetCurrentFileInfo failed, error=" << result;
    return false;
  }

  result = unzOpenCurrentFile(zip_file.get());
  if (result != UNZ_OK) {
    LOG(WARNING) << "unzOpenCurrentFile failed, error=" << result;
    return false;
  }

  data->resize(file_info.uncompressed_size);
  int total_read = 0;
  while (total_read < static_cast<int>(data->size())) {
    int bytes_read = unzReadCurrentFile(zip_file.get(),
                                        data->data() + total_read,
                                        data->size() - total_read);
    if (bytes_read <= 0) {
      return false;
    }
    total_read += bytes_read;
  }

  return true;
}

ZipAssetHandler::ZipAssetHandler(
    const base::FilePath& zip_path,
    const std::string& asset_name,
    ScopedDataPipeProducerHandle producer,
    scoped_refptr<base::TaskRunner> worker_runner)
  : zip_path_(zip_path),
    asset_name_(asset_name),
    producer_(producer.Pass()),
    main_runner_(base::MessageLoop::current()->task_runner()),
    worker_runner_(worker_runner.Pass()),
    buffer_(nullptr),
    buffer_size_(0) {
}

ZipAssetHandler::~ZipAssetHandler() {

}

void ZipAssetHandler::Start() {
  zip_file_.reset(unzOpen2(zip_path_.AsUTF8Unsafe().c_str(), NULL));
  if (!zip_file_.is_valid()) {
    LOG(ERROR) << "Unable to open ZIP file: " << zip_path_.value();
    delete this;
    return;
  }

  int result = unzLocateFile(zip_file_.get(), asset_name_.c_str(), 0);
  if (result != UNZ_OK) {
    LOG(WARNING) << "Requested asset '" << asset_name_ << "' does not exist.";
    delete this;
    return;
  }

  result = unzOpenCurrentFile(zip_file_.get());
  if (result != UNZ_OK) {
    LOG(WARNING) << "unzOpenCurrentFile failed, error=" << result;
    delete this;
    return;
  }

  CopyData();
}

void ZipAssetHandler::CopyData() {
  while (true) {
    MojoResult mojo_result = BeginWriteDataRaw(producer_.get(),
                                               &buffer_, &buffer_size_,
                                               MOJO_WRITE_DATA_FLAG_NONE);
    if (mojo_result == MOJO_RESULT_SHOULD_WAIT) {
      main_runner_->PostTask(FROM_HERE,
                             base::Bind(&ZipAssetHandler::WaitForWritable,
                                        base::Unretained(this)));
      return;
    } else if (mojo_result != MOJO_RESULT_OK) {
      LOG(WARNING) << "Mojo BeginWrite failed, error=" << mojo_result;
      delete this;
      return;
    }

    int bytes_read = unzReadCurrentFile(zip_file_.get(), buffer_, buffer_size_);
    mojo_result = EndWriteDataRaw(producer_.get(), std::max(0, bytes_read));

    if (bytes_read == 0) {
      // Unzip is complete.
      delete this;
      return;
    }
    if (bytes_read < 0) {
      LOG(WARNING) << "Asset unzip failed, error=" << bytes_read;
      delete this;
      return;
    }
    if (mojo_result != MOJO_RESULT_OK) {
      LOG(WARNING) << "Mojo EndWrite failed, error=" << mojo_result;
      delete this;
      return;
    }
  }
}

void ZipAssetHandler::WaitForWritable() {
  waiter_.reset(new AsyncWaiter(
      producer_.get(), MOJO_HANDLE_SIGNAL_WRITABLE,
      base::Bind(&ZipAssetHandler::OnWritable, base::Unretained(this))));
}

void ZipAssetHandler::OnWritable(MojoResult mojo_result) {
  if (mojo_result == MOJO_RESULT_OK) {
    worker_runner_->PostTask(FROM_HERE,
                             base::Bind(&ZipAssetHandler::CopyData,
                                        base::Unretained(this)));
  } else {
    delete this;
  }
}

}  // namespace asset_bundle
}  // namespace mojo
