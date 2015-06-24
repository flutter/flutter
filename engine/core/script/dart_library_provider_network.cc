// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dart_library_provider_network.h"

#include "sky/engine/platform/fetcher/MojoFetcher.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/tonic/dart_converter.h"

namespace blink {

typedef base::Callback<void(mojo::ScopedDataPipeConsumerHandle)>
    CompletionCallback;

class DartLibraryProviderNetwork::Job : public MojoFetcher::Client {
 public:
  Job(DartLibraryProviderNetwork* provider,
      const String& name,
      CompletionCallback callback)
      : provider_(provider), callback_(callback) {
    fetcher_ = adoptPtr(new MojoFetcher(this, KURL(ParsedURLString, name)));
  }

  ~Job() override {}

 private:
  void OnReceivedResponse(mojo::URLResponsePtr response) {
    if (response->status_code != 200) {
      callback_.Run(mojo::ScopedDataPipeConsumerHandle());
    } else {
      callback_.Run(response->body.Pass());
    }
    provider_->jobs_.remove(this);
    // We're deleted now.
  }

  DartLibraryProviderNetwork* provider_;
  CompletionCallback callback_;
  OwnPtr<MojoFetcher> fetcher_;
};

DartLibraryProviderNetwork::PrefetchedLibrary::PrefetchedLibrary() {
}

DartLibraryProviderNetwork::PrefetchedLibrary::~PrefetchedLibrary() {
}

DartLibraryProviderNetwork::DartLibraryProviderNetwork(
    PassOwnPtr<PrefetchedLibrary> prefetched)
    : prefetched_library_(prefetched) {
}

DartLibraryProviderNetwork::~DartLibraryProviderNetwork() {
}

void DartLibraryProviderNetwork::GetLibraryAsStream(
    const String& name,
    CompletionCallback callback) {
  if (prefetched_library_ && prefetched_library_->name == name) {
    mojo::ScopedDataPipeConsumerHandle pipe = prefetched_library_->pipe.Pass();
    prefetched_library_ = nullptr;
    callback.Run(pipe.Pass());
    return;
  }

  jobs_.add(adoptPtr(new Job(this, name, callback)));
}

Dart_Handle DartLibraryProviderNetwork::CanonicalizeURL(Dart_Handle library,
                                                        Dart_Handle url) {
  String string = StringFromDart(url);
  if (string.startsWith("dart:"))
    return url;
  // TODO(abarth): The package root should be configurable.
  if (string.startsWith("package:"))
    string.replace("package:", "/packages/");
  String library_url_string = StringFromDart(Dart_LibraryUrl(library));
  KURL library_url = KURL(ParsedURLString, library_url_string);
  KURL resolved_url = KURL(library_url, string);
  return StringToDart(DartState::Current(), resolved_url.string());
}

}  // namespace blink
