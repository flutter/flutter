// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_LOADER_NEWIMAGELOADER_H_
#define SKY_ENGINE_CORE_LOADER_NEWIMAGELOADER_H_

#include "mojo/common/data_pipe_drainer.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/fetcher/MojoFetcher.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace blink {

class NewImageLoaderClient {
 public:
  virtual void OnLoadFinished(const SkBitmap& result) = 0;

 protected:
  NewImageLoaderClient() {}
};

class NewImageLoader : public MojoFetcher::Client,
                       public mojo::common::DataPipeDrainer::Client {
 public:
  explicit NewImageLoader(NewImageLoaderClient* client);
  virtual ~NewImageLoader();

  void Load(const KURL& src);

  // MojoFetcher::Client
  void OnReceivedResponse(mojo::URLResponsePtr) override;

  // mojo::common::DataPipeDrainer::Client
  void OnDataAvailable(const void*, size_t) override;
  void OnDataComplete() override;

 private:
  NewImageLoaderClient* client_;
  OwnPtr<MojoFetcher> fetcher_;
  OwnPtr<mojo::common::DataPipeDrainer> drainer_;
  RefPtr<SharedBuffer> buffer_;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_LOADER_NEWIMAGELOADER_H_
