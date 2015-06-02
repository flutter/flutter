// SKY_ENGINE_CORE_PAINTING_CANVASIMAGE_H_
// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_LOADER_CANVASIMAGELOADER_H_
#define SKY_ENGINE_CORE_LOADER_CANVASIMAGELOADER_H_

#include "mojo/common/data_pipe_drainer.h"
#include "sky/engine/core/loader/ImageLoaderCallback.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/fetcher/MojoFetcher.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

class CanvasImageLoader : public MojoFetcher::Client,
                          public mojo::common::DataPipeDrainer::Client,
                          public RefCounted<CanvasImageLoader>,
                          public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  static PassRefPtr<CanvasImageLoader> create(const String& src, PassOwnPtr<ImageLoaderCallback> callback)
  {
    return adoptRef(new CanvasImageLoader(src, callback));
  }
  virtual ~CanvasImageLoader();

  // MojoFetcher::Client
  void OnReceivedResponse(mojo::URLResponsePtr) override;

  // mojo::common::DataPipeDrainer::Client
  void OnDataAvailable(const void*, size_t) override;
  void OnDataComplete() override;

 private:
  explicit CanvasImageLoader(const String& src, PassOwnPtr<ImageLoaderCallback> callback);

  OwnPtr<MojoFetcher> fetcher_;
  OwnPtr<mojo::common::DataPipeDrainer> drainer_;
  RefPtr<SharedBuffer> buffer_;
  OwnPtr<ImageLoaderCallback> callback_;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_LOADER_CANVASIMAGELOADER_H_
