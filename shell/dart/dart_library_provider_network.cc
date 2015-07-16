// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/dart/dart_library_provider_network.h"

#include "base/bind.h"
#include "base/strings/string_util.h"
#include "sky/engine/tonic/dart_converter.h"
#include "url/gurl.h"

namespace sky {
namespace shell {
namespace {

mojo::URLLoaderPtr Fetch(mojo::NetworkService* network_service,
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

class DartLibraryProviderNetwork::Job {
 public:
  Job(DartLibraryProviderNetwork* provider,
      const std::string& name,
      blink::DataPipeConsumerCallback callback)
      : provider_(provider), callback_(callback), weak_factory_(this) {
    url_loader_ =
        Fetch(provider_->network_service(), name,
              base::Bind(&Job::OnReceivedResponse, weak_factory_.GetWeakPtr()));
  }

 private:
  void OnReceivedResponse(mojo::URLResponsePtr response) {
    mojo::ScopedDataPipeConsumerHandle data;
    if (response->status_code == 200)
      data = response->body.Pass();
    callback_.Run(data.Pass());
    provider_->jobs_.remove(this);
    // We're deleted now.
  }

  DartLibraryProviderNetwork* provider_;
  blink::DataPipeConsumerCallback callback_;
  mojo::URLLoaderPtr url_loader_;

  base::WeakPtrFactory<Job> weak_factory_;
};

DartLibraryProviderNetwork::DartLibraryProviderNetwork(
    mojo::NetworkService* network_service)
    : network_service_(network_service) {
}

DartLibraryProviderNetwork::~DartLibraryProviderNetwork() {
}

void DartLibraryProviderNetwork::GetLibraryAsStream(
    const std::string& name,
    blink::DataPipeConsumerCallback callback) {
  jobs_.add(adoptPtr(new Job(this, name, callback)));
}

Dart_Handle DartLibraryProviderNetwork::CanonicalizeURL(Dart_Handle library,
                                                        Dart_Handle url) {
  std::string string = blink::StdStringFromDart(url);
  if (StartsWithASCII(string, "dart:", true))
    return url;
  // TODO(abarth): The package root should be configurable.
  if (StartsWithASCII(string, "package:", true))
    ReplaceFirstSubstringAfterOffset(&string, 0, "package:", "/packages/");
  GURL library_url(blink::StdStringFromDart(Dart_LibraryUrl(library)));
  GURL resolved_url = library_url.Resolve(string);
  return blink::StdStringToDart(resolved_url.spec());
}

}  // namespace shell
}  // namespace sky
