// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <map>
#include <vector>

#include "base/scoped_generic.h"
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
class ZipAssetBundle : public base::RefCountedThreadSafe<ZipAssetBundle> {
  friend class ZipAssetService;

 public:
  // AssetBundle implementation
  void GetAsStream(
      const String& asset_name,
      const Callback<void(ScopedDataPipeConsumerHandle)>& callback);

  // Serve this asset from another file instead of using the ZIP contents.
  void AddOverlayFile(const std::string& asset_name,
                      const base::FilePath& file_path);

  // Read the asset into a buffer.
  bool GetAsBuffer(const std::string& asset_name, std::vector<uint8_t>* data);

 protected:
  friend class base::RefCountedThreadSafe<ZipAssetBundle>;
  virtual ~ZipAssetBundle();

 private:
  ZipAssetBundle(const base::FilePath& zip_path,
                 scoped_refptr<base::TaskRunner> worker_runner);

  const base::FilePath zip_path_;
  scoped_refptr<base::TaskRunner> worker_runner_;
  std::map<String, base::FilePath> overlay_files_;

  DISALLOW_COPY_AND_ASSIGN(ZipAssetBundle);
};

// Wrapper that exposes the ZipAssetBundle as a Mojo service.
class ZipAssetService : public AssetBundle {
 public:
  // Construct a ZipAssetBundle and register it as a Mojo service.
  static scoped_refptr<ZipAssetBundle> Create(
      InterfaceRequest<AssetBundle> request,
      const base::FilePath& zip_path,
      scoped_refptr<base::TaskRunner> worker_runner);

 public:
  void GetAsStream(
      const String& asset_name,
      const Callback<void(ScopedDataPipeConsumerHandle)>& callback) override;

  ~ZipAssetService() override;

 private:
  ZipAssetService(InterfaceRequest<AssetBundle> request,
                  const scoped_refptr<ZipAssetBundle>& zip_asset_bundle);

  StrongBinding<AssetBundle> binding_;
  scoped_refptr<ZipAssetBundle> zip_asset_bundle_;
};

struct ScopedUnzFileTraits {
  static unzFile InvalidValue();
  static void Free(unzFile file);
};

typedef base::ScopedGeneric<unzFile, ScopedUnzFileTraits> ScopedUnzFile;

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

  ScopedUnzFile zip_file_;

  void* buffer_;
  uint32_t buffer_size_;

  scoped_ptr<AsyncWaiter> waiter_;

  DISALLOW_COPY_AND_ASSIGN(ZipAssetHandler);
};

}  // namespace asset_bundle
}  // namespace mojo
