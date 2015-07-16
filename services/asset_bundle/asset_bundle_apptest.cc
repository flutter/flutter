// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/run_loop.h"
#include "mojo/common/common_type_converters.h"
#include "mojo/common/data_pipe_utils.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/services/asset_bundle/public/interfaces/asset_bundle.mojom.h"
#include "third_party/zlib/google/zip.h"

namespace asset_bundle {

class AssetBundleAppTest : public mojo::test::ApplicationTestBase {
 public:
  AssetBundleAppTest() {}
  ~AssetBundleAppTest() override {}

  void SetUp() override {
    mojo::test::ApplicationTestBase::SetUp();
    application_impl()->ConnectToService("mojo:asset_bundle", &asset_unpacker_);
  }

 protected:
  mojo::asset_bundle::AssetUnpackerPtr asset_unpacker_;

  DISALLOW_COPY_AND_ASSIGN(AssetBundleAppTest);
};

TEST_F(AssetBundleAppTest, CanGetText) {
  std::string foo_content = "Some plain data";
  std::string bar_content = "The wrong data";

  base::ScopedTempDir zip_dir;
  ASSERT_TRUE(zip_dir.CreateUniqueTempDir());

  base::FilePath foo_path = zip_dir.path().Append("foo.txt");
  base::WriteFile(foo_path, foo_content.data(), foo_content.size());

  base::FilePath bar_path = zip_dir.path().Append("bar.txt");
  base::WriteFile(bar_path, bar_content.data(), bar_content.size());

  base::FilePath zip_path;
  ASSERT_TRUE(base::CreateTemporaryFile(&zip_path));

  zip::Zip(zip_dir.path(), zip_path, false);
  std::string zip_contents;
  ASSERT_TRUE(base::ReadFileToString(zip_path, &zip_contents));
  ASSERT_TRUE(base::DeleteFile(zip_path, false));

  mojo::DataPipe zip_pipe;
  mojo::asset_bundle::AssetBundlePtr asset_bundle;
  asset_unpacker_->UnpackZipStream(zip_pipe.consumer_handle.Pass(),
                                   GetProxy(&asset_bundle));

  EXPECT_TRUE(mojo::common::BlockingCopyFromString(
      zip_contents, zip_pipe.producer_handle));
  zip_pipe.producer_handle.reset();

  std::string asset_content;
  asset_bundle->GetAsStream("foo.txt",
      [&](mojo::ScopedDataPipeConsumerHandle asset_pipe) {
    mojo::common::BlockingCopyToString(asset_pipe.Pass(), &asset_content);
  });
  ASSERT_TRUE(asset_bundle.WaitForIncomingResponse());

  EXPECT_EQ(foo_content, asset_content)
      << "Failed to get the correct contents back from the asset bundle";

  std::string missing_content;
  asset_bundle->GetAsStream("missing.txt",
      [&](mojo::ScopedDataPipeConsumerHandle asset_pipe) {
    mojo::common::BlockingCopyToString(asset_pipe.Pass(), &missing_content);
  });
  ASSERT_TRUE(asset_bundle.WaitForIncomingResponse());

  EXPECT_EQ("", missing_content)
      << "Missing asset keys are treated as empty data streams";

  std::string outside_content;
  asset_bundle->GetAsStream("../../out-of-bundle.txt",
      [&](mojo::ScopedDataPipeConsumerHandle asset_pipe) {
    mojo::common::BlockingCopyToString(asset_pipe.Pass(), &outside_content);
  });
  ASSERT_TRUE(asset_bundle.WaitForIncomingResponse());

  EXPECT_EQ("", outside_content)
      << "Traversing outside of bundle is treated as an empty data stream";
}

}  // namespace asset_bundle
