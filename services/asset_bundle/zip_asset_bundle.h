// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/task_runner.h"
#include "base/files/file_path.h"
#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/environment/async_waiter.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "third_party/zlib/contrib/minizip/unzip.h"

namespace mojo {
namespace asset_bundle {

// An implementation of AssetBundle that serves assets directly out of a
// ZIP archive.
class ZipAssetBundle : public AssetBundle {
 public:
  static void Create(InterfaceRequest<AssetBundle> request,
                     const base::FilePath& zip_path,
                     scoped_refptr<base::TaskRunner> worker_runner);
  ~ZipAssetBundle() override;

  // AssetBundle implementation
  void GetAsStream(
      const String& asset_name,
      const Callback<void(ScopedDataPipeConsumerHandle)>& callback) override;

 private:
  ZipAssetBundle(InterfaceRequest<AssetBundle> request,
                 const base::FilePath& zip_path,
                 scoped_refptr<base::TaskRunner> worker_runner);

  StrongBinding<AssetBundle> binding_;
  const base::FilePath zip_path_;
  scoped_refptr<base::TaskRunner> worker_runner_;

  DISALLOW_COPY_AND_ASSIGN(ZipAssetBundle);
};

// Reads an asset from a ZIP archive and writes it to a Mojo pipe.
class ZipAssetHandler {
  friend class ZipAssetBundle;

 public:
  ZipAssetHandler(const base::FilePath& zip_path,
                    const std::string& asset_name,
                    ScopedDataPipeProducerHandle producer,
                    scoped_refptr<base::TaskRunner> worker_runner);
  ~ZipAssetHandler();

  void Start();

 private:
  void CopyData();
  void OnWritable(MojoResult result);
  void WaitForWritable();

  const base::FilePath zip_path_;
  const std::string asset_name_;
  ScopedDataPipeProducerHandle producer_;

  scoped_refptr<base::SingleThreadTaskRunner> main_runner_;
  scoped_refptr<base::TaskRunner> worker_runner_;

  unzFile zip_file_;

  void* buffer_;
  uint32_t buffer_size_;

  scoped_ptr<AsyncWaiter> waiter_;

  DISALLOW_COPY_AND_ASSIGN(ZipAssetHandler);
};

}  // namespace asset_bundle
}  // namespace mojo
