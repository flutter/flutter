// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DART_LIBRARY_PROVIDER_WEBVIEW_H_
#define SKY_ENGINE_CORE_SCRIPT_DART_LIBRARY_PROVIDER_WEBVIEW_H_

#include "sky/engine/tonic/dart_library_provider.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/OwnPtr.h"

namespace blink {

class DartLibraryProviderWebView : public DartLibraryProvider {
 public:
  explicit DartLibraryProviderWebView();
  ~DartLibraryProviderWebView() override;

 private:
  class Job;

  // |DartLibraryProvider| implementation:
  void GetLibraryAsStream(
      const String& name,
      DataPipeConsumerCallback callback)
      override;

  Dart_Handle CanonicalizeURL(Dart_Handle library, Dart_Handle url) override;

  HashSet<OwnPtr<Job>> jobs_;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_SCRIPT_DART_LIBRARY_PROVIDER_WEBVIEW_H_
