// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_PLATFORM_WEBURLLOADER_IMPL_H_
#define SKY_VIEWER_PLATFORM_WEBURLLOADER_IMPL_H_

#include "base/memory/weak_ptr.h"
#include "mojo/common/handle_watcher.h"
#include "mojo/services/public/interfaces/network/url_loader.mojom.h"
#include "sky/engine/public/platform/WebURLLoader.h"
#include "sky/engine/public/platform/WebURLRequest.h"

namespace mojo {
class NetworkService;
}

namespace sky {
// The concrete type of WebURLRequest::ExtraData.
class WebURLRequestExtraData : public blink::WebURLRequest::ExtraData {
 public:
  WebURLRequestExtraData();
  virtual ~WebURLRequestExtraData();

  mojo::URLResponsePtr synthetic_response;
};

class WebURLLoaderImpl : public blink::WebURLLoader {
 public:
  explicit WebURLLoaderImpl(mojo::NetworkService* network_service);

 private:
  virtual ~WebURLLoaderImpl();

  // blink::WebURLLoader methods:
  virtual void loadAsynchronously(
      const blink::WebURLRequest&, blink::WebURLLoaderClient* client) override;
  virtual void cancel() override;

  void OnReceivedResponse(mojo::URLResponsePtr response);
  void OnReceivedError(mojo::URLResponsePtr response);
  void OnReceivedRedirect(mojo::URLResponsePtr response);
  void ReadMore();
  void WaitToReadMore();
  void OnResponseBodyStreamReady(MojoResult result);

  blink::WebURLLoaderClient* client_;
  GURL url_;
  mojo::URLLoaderPtr url_loader_;
  mojo::ScopedDataPipeConsumerHandle response_body_stream_;
  mojo::common::HandleWatcher handle_watcher_;

  base::WeakPtrFactory<WebURLLoaderImpl> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(WebURLLoaderImpl);
};

}  // namespace sky

#endif  // SKY_VIEWER_PLATFORM_WEBURLLOADER_IMPL_H_
