// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dart_library_provider_webview.h"

#include "sky/engine/platform/fetcher/MojoFetcher.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/tonic/dart_converter.h"

namespace blink {

class DartLibraryProviderWebView::Job : public MojoFetcher::Client {
 public:
  Job(DartLibraryProviderWebView* provider,
      const String& name,
      DataPipeConsumerCallback callback)
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

  DartLibraryProviderWebView* provider_;
  DataPipeConsumerCallback callback_;
  OwnPtr<MojoFetcher> fetcher_;
};

DartLibraryProviderWebView::DartLibraryProviderWebView() {
}

DartLibraryProviderWebView::~DartLibraryProviderWebView() {
}

void DartLibraryProviderWebView::GetLibraryAsStream(
    const String& name,
    DataPipeConsumerCallback callback) {
  jobs_.add(adoptPtr(new Job(this, name, callback)));
}

Dart_Handle DartLibraryProviderWebView::CanonicalizeURL(Dart_Handle library,
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
