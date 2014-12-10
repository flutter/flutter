// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/platform/fetcher/MojoFetcher.h"

#include "base/bind.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/public/platform/Platform.h"

namespace blink {

MojoFetcher::MojoFetcher(Client* client, const KURL& url)
    : client_(client),
      weak_factory_(this) {
  DCHECK(client_);

  mojo::NetworkService* net = Platform::current()->networkService();
  net->CreateURLLoader(GetProxy(&url_loader_));

  mojo::URLRequestPtr url_request = mojo::URLRequest::New();
  url_request->url = url.string().toUTF8();
  url_request->auto_follow_redirects = true;
  url_loader_->Start(url_request.Pass(),
                     base::Bind(&MojoFetcher::OnReceivedResponse,
                                weak_factory_.GetWeakPtr()));
}

MojoFetcher::~MojoFetcher() {
}

void MojoFetcher::OnReceivedResponse(mojo::URLResponsePtr response) {
  client_->OnReceivedResponse(response.Pass());
}

}  // namespace blink
